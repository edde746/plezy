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
	@override late final _Translations$app$ja app = _Translations$app$ja._(_root);
	@override late final _Translations$auth$ja auth = _Translations$auth$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
	@override late final _Translations$screens$ja screens = _Translations$screens$ja._(_root);
	@override late final _Translations$update$ja update = _Translations$update$ja._(_root);
	@override late final _Translations$settings$ja settings = _Translations$settings$ja._(_root);
	@override late final _Translations$search$ja search = _Translations$search$ja._(_root);
	@override late final _Translations$hotkeys$ja hotkeys = _Translations$hotkeys$ja._(_root);
	@override late final _Translations$fileInfo$ja fileInfo = _Translations$fileInfo$ja._(_root);
	@override late final _Translations$mediaMenu$ja mediaMenu = _Translations$mediaMenu$ja._(_root);
	@override late final _Translations$rateSheet$ja rateSheet = _Translations$rateSheet$ja._(_root);
	@override late final _Translations$accessibility$ja accessibility = _Translations$accessibility$ja._(_root);
	@override late final _Translations$tooltips$ja tooltips = _Translations$tooltips$ja._(_root);
	@override late final _Translations$audioTracks$ja audioTracks = _Translations$audioTracks$ja._(_root);
	@override late final _Translations$videoControls$ja videoControls = _Translations$videoControls$ja._(_root);
	@override late final _Translations$messages$ja messages = _Translations$messages$ja._(_root);
	@override late final _Translations$subtitlingStyling$ja subtitlingStyling = _Translations$subtitlingStyling$ja._(_root);
	@override late final _Translations$mpvConfig$ja mpvConfig = _Translations$mpvConfig$ja._(_root);
	@override late final _Translations$dialog$ja dialog = _Translations$dialog$ja._(_root);
	@override late final _Translations$profiles$ja profiles = _Translations$profiles$ja._(_root);
	@override late final _Translations$connections$ja connections = _Translations$connections$ja._(_root);
	@override late final _Translations$discover$ja discover = _Translations$discover$ja._(_root);
	@override late final _Translations$errors$ja errors = _Translations$errors$ja._(_root);
	@override late final _Translations$libraries$ja libraries = _Translations$libraries$ja._(_root);
	@override late final _Translations$about$ja about = _Translations$about$ja._(_root);
	@override late final _Translations$serverSelection$ja serverSelection = _Translations$serverSelection$ja._(_root);
	@override late final _Translations$hubDetail$ja hubDetail = _Translations$hubDetail$ja._(_root);
	@override late final _Translations$logs$ja logs = _Translations$logs$ja._(_root);
	@override late final _Translations$startup$ja startup = _Translations$startup$ja._(_root);
	@override late final _Translations$licenses$ja licenses = _Translations$licenses$ja._(_root);
	@override late final _Translations$navigation$ja navigation = _Translations$navigation$ja._(_root);
	@override late final _Translations$explore$ja explore = _Translations$explore$ja._(_root);
	@override late final _Translations$liveTv$ja liveTv = _Translations$liveTv$ja._(_root);
	@override late final _Translations$collections$ja collections = _Translations$collections$ja._(_root);
	@override late final _Translations$playlists$ja playlists = _Translations$playlists$ja._(_root);
	@override late final _Translations$music$ja music = _Translations$music$ja._(_root);
	@override late final _Translations$watchTogether$ja watchTogether = _Translations$watchTogether$ja._(_root);
	@override late final _Translations$downloads$ja downloads = _Translations$downloads$ja._(_root);
	@override late final _Translations$shaders$ja shaders = _Translations$shaders$ja._(_root);
	@override late final _Translations$companionRemote$ja companionRemote = _Translations$companionRemote$ja._(_root);
	@override late final _Translations$videoSettings$ja videoSettings = _Translations$videoSettings$ja._(_root);
	@override late final _Translations$performanceOverlay$ja performanceOverlay = _Translations$performanceOverlay$ja._(_root);
	@override late final _Translations$externalPlayer$ja externalPlayer = _Translations$externalPlayer$ja._(_root);
	@override late final _Translations$metadataEdit$ja metadataEdit = _Translations$metadataEdit$ja._(_root);
	@override late final _Translations$matchScreen$ja matchScreen = _Translations$matchScreen$ja._(_root);
	@override late final _Translations$serverTasks$ja serverTasks = _Translations$serverTasks$ja._(_root);
	@override late final _Translations$trakt$ja trakt = _Translations$trakt$ja._(_root);
	@override late final _Translations$seerr$ja seerr = _Translations$seerr$ja._(_root);
	@override late final _Translations$services$ja services = _Translations$services$ja._(_root);
	@override late final _Translations$addServer$ja addServer = _Translations$addServer$ja._(_root);
}

// Path: app
class _Translations$app$ja extends Translations$app$en {
	_Translations$app$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$ja extends Translations$auth$en {
	_Translations$auth$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plexでサインイン';
	@override String get showQRCode => 'QRコードを表示';
	@override String get authenticate => '認証';
	@override String get authenticationTimeout => '認証がタイムアウトしました。もう一度お試しください。';
	@override String get scanQRToSignIn => 'このQRコードをスキャンしてサインイン';
	@override String get waitingForAuth => '認証を待っています…\nブラウザでサインインしてください。';
	@override String get useBrowser => 'ブラウザを使用';
	@override String get or => 'または';
	@override String connectToMediaBrowser({required Object product}) => '${product}に接続';
	@override String get useQuickConnect => 'Quick Connect を使う';
	@override String get quickConnectInstructions => 'JellyfinでQuick Connectを開き、このコードを入力してください。';
	@override String get quickConnectWaiting => '承認を待っています…';
	@override String get quickConnectCancel => 'キャンセル';
	@override String get quickConnectExpired => 'Quick Connectの有効期限が切れました。もう一度お試しください。';
	@override String get localDataRecoveryRequired => 'ローカルのサインイン情報と保留中の再生データを安全に復元できませんでした。もう一度サインインしてください。';
	@override String get pinCheckRejected => 'Plex PINの確認が拒否されました';
}

// Path: common
class _Translations$common$ja extends Translations$common$en {
	_Translations$common$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get addTo => '追加先…';
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
	@override String get checkingNetwork => 'ネットワークを確認中…';
	@override String get loadingServers => 'サーバーを読み込み中…';
	@override String get connectingToServers => 'サーバーに接続中…';
	@override String get startingOfflineMode => 'オフラインモードを開始中…';
	@override String get loading => '読み込み中…';
	@override String get fullscreen => 'フルスクリーン';
	@override String get exitFullscreen => 'フルスクリーンを終了';
	@override String get pressBackAgainToExit => 'もう一度押すと終了します';
	@override late final _Translations$common$ratingSource$ja ratingSource = _Translations$common$ratingSource$ja._(_root);
	@override String get notAvailable => 'N/A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
}

// Path: screens
class _Translations$screens$ja extends Translations$screens$en {
	_Translations$screens$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'ライセンス';
	@override String get switchProfile => 'プロフィール切替';
	@override String get subtitleStyling => '字幕スタイル';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'ログ';
}

// Path: update
class _Translations$update$ja extends Translations$update$en {
	_Translations$update$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
class _Translations$settings$ja extends Translations$settings$en {
	_Translations$settings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get supportDeveloper => 'Plezyを支援';
	@override String get supportDeveloperDescription => 'Liberapayで寄付して開発を支援';
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
	@override String get displayScale => '表示スケール';
	@override String get compact => 'コンパクト';
	@override String get comfortable => 'ゆったり';
	@override String get tvCornerSpotlightBackdrop => '画面隅の注目コンテンツ背景';
	@override String get tvCornerSpotlightBackdropDescription => '画面全体ではなく、右上隅に注目コンテンツのアートワークを表示します';
	@override String get viewMode => '表示モード';
	@override String get gridView => 'グリッド';
	@override String get listView => 'リスト';
	@override String get showHeroSection => '注目コンテンツを表示';
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
	@override String get alwaysKeepSidebarOpenDescription => 'サイドバーを展開したままにし、コンテンツ領域を幅に合わせて調整します';
	@override String get showUnwatchedCount => '未視聴数を表示';
	@override String get showUnwatchedCountDescription => '番組とシーズンに未視聴エピソード数を表示';
	@override String get showEpisodeNumberOnCards => 'カードにエピソード番号を表示';
	@override String get showEpisodeNumberOnCardsDescription => 'エピソードカードにシーズン番号とエピソード番号を表示します';
	@override String get showSeasonPostersOnTabs => 'タブにシーズンポスターを表示';
	@override String get showSeasonPostersOnTabsDescription => '各シーズンのポスターをタブの上に表示します';
	@override String get tvFullCardLayout => 'フルTVカード';
	@override String get tvFullCardLayoutDescription => 'TVカードを画像のみで表示し、出演者名を重ねて表示します';
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
	@override String get playbackBuffer => '再生バッファー';
	@override String get playbackBufferAuto => '自動（推奨）';
	@override String get playbackBufferLarge => '大';
	@override String get playbackBufferExtraLarge => '特大';
	@override String get playbackBufferDescription => '不安定な接続に備えてより多くのバッファーを使用します。バッファーサイズによっても制限されます。';
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
	@override String get followServerTrackSelections => 'サーバーのエピソードごとのトラック選択を使用';
	@override String get followServerTrackSelectionsDescription => 'エピソード切り替え時に、現在の選択を引き継ぐ代わりにサーバーで選択された音声と字幕を適用します';
	@override String get showChapterMarkersOnTimeline => 'シークバーにチャプターマーカーを表示';
	@override String get showChapterMarkersOnTimelineDescription => 'チャプターの境界でシークバーを区切る';
	@override String get specialsOrdering => 'エピソード順にスペシャルを表示';
	@override String get specialsOrderingDescription => 'シリーズの視聴順でスペシャルを再生する位置';
	@override String get specialsOrderingServer => 'サーバーの順序に従う';
	@override String get specialsOrderingAirDate => '放送日順に挿入';
	@override String get specialsOrderingLast => '通常シーズンの後';
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
	@override String get watchTogetherRelayInvalid => '有効なHTTPまたはHTTPSのリレーサーバーURLを入力してください。';
	@override String get crashReporting => 'クラッシュレポート';
	@override String get crashReportingDescription => 'アプリの改善に役立つクラッシュレポートを送信';
	@override String get debugLogging => 'デバッグログ';
	@override String get debugLoggingDescription => 'トラブルシューティング用の詳細なログを有効化';
	@override String get viewLogs => 'ログを表示';
	@override String get viewLogsDescription => 'アプリケーションログを表示';
	@override String get clearImageCache => '画像キャッシュをクリア';
	@override String get clearImageCacheDescription => 'キャッシュされたアートワークとサムネイルをクリアします。再度ダウンロードされるまで画像の読み込みが遅くなる場合があります。';
	@override String get clearImageCacheSuccess => '画像キャッシュを正常にクリアしました';
	@override String get resetSettings => '設定をリセット';
	@override String get resetSettingsDescription => '設定を既定に戻します。元に戻せません。';
	@override String get resetSettingsSuccess => '設定を正常にリセットしました';
	@override String get backup => 'バックアップ';
	@override String get exportSettings => '設定をエクスポート';
	@override String get exportSettingsDescription => '設定をファイルに保存';
	@override String get exportSettingsSuccess => '設定をエクスポートしました';
	@override String get importSettings => '設定をインポート';
	@override String get importSettingsDescription => 'ファイルから設定を復元';
	@override String get importSettingsConfirm => '現在の設定を置き換えます。続行しますか？';
	@override String get importSettingsSuccess => '設定をインポートしました';
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
	@override String get saveFailed => '変更を保存できませんでした。もう一度お試しください。';
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
	@override String get downloadLocationPickerUnavailable => 'このデバイスではフォルダを選択できません';
	@override String get downloadOnWifiOnly => 'Wi-Fi接続時のみダウンロード';
	@override String get downloadOnWifiOnlyDescription => 'モバイルデータ通信中のダウンロードを防ぎます';
	@override String get autoRemoveWatchedDownloads => '視聴済みダウンロードの自動削除';
	@override String get autoRemoveWatchedDownloadsDescription => '視聴済みのダウンロードを自動削除します';
	@override String get cellularDownloadBlocked => 'モバイルデータ通信中はダウンロードできません。Wi-Fiを使用するか、設定を変更してください。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '静かなメディアに対して100%以上の音量ブーストを許可';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discordで視聴中の内容を表示';
	@override String get services => 'サービス';
	@override String get servicesDescription => 'Trakt、MyAnimeList、Seerrなどを接続';
	@override String get manageLibrariesDescription => 'ライブラリを並べ替えたり非表示にしたりできます';
	@override String get companionRemoteServer => 'コンパニオンリモートサーバー';
	@override String get companionRemoteServerDescription => 'ネットワーク上のモバイルデバイスからこのアプリを操作できるようにする';
	@override String get autoPip => '自動ピクチャーインピクチャー';
	@override String get autoPipDescription => '再生中にアプリを離れると、自動的にピクチャーインピクチャーに切り替えます';
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
	@override String get audioPassthroughDescriptionAppleTv => 'Dolby Atmosを含むDolby Digital PlusにはApple標準のDolbyデコーダーを使用します。DTSとTrueHDは引き続きマルチチャンネルPCMで再生されます。音が出ない場合は無効にしてください。';
	@override String get audioDownmix => 'ステレオにダウンミックス';
	@override String get audioDownmixDescription => 'サラウンド音声をステレオスピーカーやヘッドホン用に2チャンネルへミックスします';
	@override String get downmixCenterBoost => 'センターチャンネルブースト';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'ブースト (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'ダウンミックス時の音量正規化';
	@override String get audioDownmixNormalizeDescription => 'クリッピングを防ぐためにミックス音量を下げます。オフにすると元の音量を維持します（大音量シーンで歪む場合があります）。';
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
	@override String get showNavBarLabels => 'ナビゲーションバーのラベルを表示';
	@override String get showNavBarLabelsDescription => 'ナビゲーションバーのアイコンの下にテキストラベルを表示';
	@override String get startupSection => '起動時のセクション';
	@override String get showExploreTab => '「探す」タブを表示';
	@override String get showExploreTabDescription => 'Plex Discoverと接続済みのトラッカーのコンテンツを「探す」タブに表示します';
	@override String get liveTvDefaultFavorites => 'お気に入りチャンネルをデフォルトに';
	@override String get liveTvDefaultFavoritesDescription => 'ライブTVを開いたときにお気に入りチャンネルのみ表示';
	@override String get display => 'ディスプレイ';
	@override String get homeScreen => 'ホーム画面';
	@override String get navigation => 'ナビゲーション';
	@override String get window => 'ウィンドウ';
	@override String get content => 'コンテンツ';
	@override String get player => 'プレーヤー';
	@override String get subtitlesAndConfig => '字幕と設定';
	@override String get seekAndTiming => 'シークとタイミング';
	@override String get behavior => '動作';
	@override String get rememberPlayerChanges => 'プレーヤーの変更を記憶';
	@override String get rememberPlayerChangesDescription => '再生中に行った変更を保存し、再適用する場所';
	@override String get scopePlaybackSpeed => '再生速度';
	@override String get scopeShaderPreset => 'シェーダープリセット';
	@override String get scopeAspectRatio => 'アスペクト比';
	@override String get scopeSyncOffsets => '音声と字幕の同期';
	@override String get playerScopeOff => '保存しない';
	@override String get playerScopeGlobal => 'すべて';
	@override String get playerScopeLibrary => 'ライブラリごと';
	@override String get playerScopeTitle => '作品ごと';
	@override String get exportDialogTitle => 'Plezyの設定をエクスポート';
}

// Path: search
class _Translations$search$ja extends Translations$search$en {
	_Translations$search$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get hint => '映画、番組、音楽を検索…';
	@override String get tryDifferentTerm => '別の検索語をお試しください';
	@override String get searchYourMedia => 'メディアを検索';
	@override String get enterTitleActorOrKeyword => 'タイトル、俳優、またはキーワードを入力';
}

// Path: hotkeys
class _Translations$hotkeys$ja extends Translations$hotkeys$en {
	_Translations$hotkeys$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName}のショートカットを設定';
	@override String get clearShortcut => 'ショートカットをクリア';
	@override String get noShortcutSet => 'ショートカット未設定';
	@override String get currentShortcut => '現在のショートカット:';
	@override String get pressToRecord => '選択してショートカットを記録';
	@override String get recordingShortcut => 'ショートカットを押してください';
	@override late final _Translations$hotkeys$actions$ja actions = _Translations$hotkeys$actions$ja._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$ja extends Translations$fileInfo$en {
	_Translations$fileInfo$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ファイル情報';
	@override String get overview => '概要';
	@override String get video => '映像';
	@override String get audio => '音声';
	@override String get subtitles => '字幕';
	@override String get images => '埋め込み画像';
	@override String get dataStreams => 'データストリーム';
	@override String get lyrics => '歌詞';
	@override String get file => 'ファイル';
	@override String get attachments => '添付ファイル';
	@override String get delivery => '配信';
	@override String versionCounter({required Object index, required Object count}) => 'バージョン ${index} / ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'ファイル ${index} / ${count}';
	@override String get noStreams => 'サーバーはこのファイルにストリームがないと報告しました。';
	@override String get copyPath => 'パスをコピー';
	@override String get pathCopied => 'ファイルパスをコピーしました';
	@override String get codec => 'コーデック';
	@override String get codecTag => 'コーデックタグ';
	@override String get resolution => '解像度';
	@override String get codedResolution => '符号化解像度';
	@override String get bitrate => 'ビットレート';
	@override String get frameRate => 'フレームレート';
	@override String get rotation => '回転';
	@override String get comment => 'コメント';
	@override String get audioDescription => '音声解説';
	@override String get headerCompression => 'ヘッダー圧縮';
	@override String get sidecarFile => 'サイドカーファイル';
	@override String get transportTimestamp => 'トランスポートタイムスタンプ';
	@override String get displayOffset => '表示オフセット';
	@override String get previewFailureCode => 'プレビュー失敗コード';
	@override String get previewRetries => 'プレビュー再試行回数';
	@override String get aspectRatio => 'アスペクト比';
	@override String get pixelAspectRatio => 'ピクセルアスペクト比';
	@override String get profile => 'プロファイル';
	@override String get level => 'レベル';
	@override String get bitDepth => 'ビット深度';
	@override String get pixelFormat => 'ピクセルフォーマット';
	@override String get colorSpace => '色空間';
	@override String get colorRange => '色範囲';
	@override String get colorPrimaries => '色原色';
	@override String get colorTransfer => 'カラートランスファー';
	@override String get chromaSubsampling => 'クロマサブサンプリング';
	@override String get chromaLocation => 'クロマ位置';
	@override String get scanType => 'スキャンタイプ';
	@override String get interlaced => 'インターレース';
	@override String get anamorphic => 'アナモルフィック';
	@override String get referenceFrames => '参照フレーム数';
	@override String get dynamicRange => 'ダイナミックレンジ';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision レベル';
	@override String get dolbyVisionVersion => 'Dolby Vision バージョン';
	@override String get dolbyVisionLayers => 'Dolby Vision レイヤー';
	@override String get baseLayerCompatibility => 'ベースレイヤー互換性';
	@override String get avcBitstream => 'AVC ビットストリーム';
	@override String get nalLengthSize => 'NAL 長さサイズ';
	@override String get scalingMatrix => 'カスタムスケーリングマトリックス';
	@override String get streamIdentifier => 'ストリーム識別子';
	@override String get streamIndex => 'ストリームインデックス';
	@override String get streamId => 'ストリーム ID';
	@override String get language => '言語';
	@override String get languageCode => '言語コード';
	@override String get streamTitle => 'トラックタイトル';
	@override String get channels => 'チャンネル';
	@override String get sampleRate => 'サンプルレート';
	@override String get spatialAudio => '空間オーディオ';
	@override String get textBased => 'テキストベース';
	@override String get subtitleFormat => 'サイドカーフォーマット';
	@override String get provider => 'プロバイダー';
	@override String get matchScore => '一致スコア';
	@override String get externalDelivery => '個別に配信可能';
	@override String get sidecarPath => 'サイドカーパス';
	@override String get sourceStream => 'コピー元';
	@override String get temporary => '一時的';
	@override String get timeBase => 'タイムベース';
	@override String get overallBitrate => '全体ビットレート';
	@override String get path => 'パス';
	@override String get fileName => 'ファイル名';
	@override String get size => 'サイズ';
	@override String get totalSize => '合計サイズ';
	@override String get container => 'コンテナ';
	@override String get duration => '長さ';
	@override String get previewThumbnails => 'プレビューサムネイル';
	@override String get previewIndex => 'プレビューインデックス';
	@override String get packetLength => 'パケット長';
	@override String get filePresent => 'ファイルあり';
	@override String get fileReadable => 'サーバーから読み取り可能';
	@override String get streamPath => 'ストリームパス';
	@override String get optimizedForStreaming => 'ストリーミング最適化';
	@override String get has64bitOffsets => '64ビットオフセット';
	@override String get protocol => 'プロトコル';
	@override String get mediaType => 'メディアタイプ';
	@override String get sourceKind => 'ソース種別';
	@override String get optimizedVersion => '最適化バージョン';
	@override String get optimizationTarget => '最適化ターゲット';
	@override String get deletedAt => '削除済み';
	@override String get remoteSource => 'リモートソース';
	@override String get infiniteStream => '無限ストリーム';
	@override String get directPlay => 'ダイレクト再生';
	@override String get directStream => 'ダイレクトストリーム';
	@override String get transcoding => 'トランスコード';
	@override String get etag => 'ETag';
	@override String get versionId => 'バージョン ID';
	@override String get fileId => 'ファイル ID';
	@override String get defaultAudioTrack => 'デフォルト音声トラック';
	@override String get defaultSubtitleTrack => 'デフォルト字幕トラック';
	@override String get subtitlesOff => 'オフ';
	@override String get flagDefault => 'デフォルト';
	@override String get flagForced => '強制';
	@override String get flagSelected => '選択済み';
	@override String get flagExternal => '外部';
	@override String get flagHearingImpaired => '聴覚障害者向け';
	@override String get flagDub => '吹替';
	@override String get flagOriginal => 'オリジナル';
	@override String get channelsMono => 'モノラル';
	@override String dolbyVisionProfile({required Object profile}) => 'プロファイル${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$ja extends Translations$mediaMenu$en {
	_Translations$mediaMenu$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get deleteEpisodeFromServer => 'サーバーからエピソードを削除';
	@override String get deleteSeasonFromServer => 'サーバーからシーズンを削除';
	@override String get deleteShowFromServer => 'サーバーから番組を削除';
	@override String get deleteMovieFromServer => 'サーバーから映画を削除';
	@override String get deleteEpisodeTitle => 'このエピソードを削除しますか？';
	@override String get deleteSeasonTitle => 'このシーズンを削除しますか？';
	@override String get deleteShowTitle => 'この番組を削除しますか？';
	@override String get deleteMovieTitle => 'この映画を削除しますか？';
	@override String get deleteEpisodeConfirm => 'エピソードを削除';
	@override String get deleteSeasonConfirm => 'シーズンを削除';
	@override String get deleteShowConfirm => '番組を削除';
	@override String get deleteMovieConfirm => '映画を削除';
	@override String get deleteAnyway => 'それでも削除';
	@override String confirmDeleteTarget({required Object title}) => 'サーバーから「${title}」を完全に削除しますか？';
	@override String get deleteMultipleWarning => 'すべてのエピソードとそのファイルが含まれます。';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '中の全${n}エピソードとそのファイルが削除されます。',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: 'このアイテムは${n}個のファイルにまたがって保存されており、すべて削除されます。',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '同じファイルに保存されている他の${n}エピソードも削除されます：',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezyは削除対象のファイルを確認できなかったため、上記のアイテム以上に削除される可能性があります。キャンセルして再試行するか、それでも削除してください。';
	@override String get deleteScopeUnverifiedNoFileInfo => 'サーバーがこのアイテムのファイル情報を提供しなかったため、Plezyは削除対象のファイルを確認できません。上記のアイテム以上に削除される可能性があります。';
	@override String get mediaDeletedSuccessfully => 'メディアアイテムを正常に削除しました';
	@override String get mediaFailedToDelete => 'メディアアイテムの削除に失敗しました';
	@override String get rate => '評価';
	@override String get playFromBeginning => '最初から再生';
	@override String get playVersion => 'バージョンを選んで再生…';
}

// Path: rateSheet
class _Translations$rateSheet$ja extends Translations$rateSheet$en {
	_Translations$rateSheet$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
class _Translations$accessibility$ja extends Translations$accessibility$en {
	_Translations$accessibility$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get alphabetNavigation => 'アルファベットナビゲーション';
	@override String get alphabetScrollHint => '上下にスワイプして文字ごとに移動';
	@override String rowColumnPosition({required Object rowCount, required Object row, required Object columnCount, required Object column}) => '${rowCount}行中${row}行、${columnCount}列中${column}列';
	@override String rowPosition({required Object rowCount, required Object row}) => '${rowCount}行中${row}行';
	@override String get autoScrollPlay => '自動スクロールを再生';
	@override String get autoScrollPause => '自動スクロールを一時停止';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
}

// Path: tooltips
class _Translations$tooltips$ja extends Translations$tooltips$en {
	_Translations$tooltips$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'シャッフル再生';
	@override String get playTrailer => '予告編を再生';
	@override String get markAsWatched => '視聴済みにする';
	@override String get markAsUnwatched => '未視聴にする';
}

// Path: audioTracks
class _Translations$audioTracks$ja extends Translations$audioTracks$en {
	_Translations$audioTracks$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => '音声トラック${n}';
}

// Path: videoControls
class _Translations$videoControls$ja extends Translations$videoControls$en {
	_Translations$videoControls$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音声';
	@override String get subtitlesLabel => '字幕';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
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
	@override String get playbackPaused => '一時停止中';
	@override String get playbackResumed => '再生中';
	@override String get loadingVideo => '動画を読み込み中';
	@override String get showPlaybackControls => '再生コントロールを表示';
	@override String get hidePlaybackControls => '再生コントロールを非表示';
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
	@override String get subtitleUnavailableFallback => '選択した字幕を読み込めませんでした — 字幕なしで再生を続けます';
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
	@override late final _Translations$videoControls$pipErrors$ja pipErrors = _Translations$videoControls$pipErrors$ja._(_root);
	@override String get chapters => 'チャプター';
	@override String get noChaptersAvailable => 'チャプターがありません';
	@override String get queue => 'キュー';
	@override String get noQueueItems => 'キューにアイテムがありません';
	@override String get noAudioDevicesAvailable => 'オーディオデバイスがありません';
	@override String get searchSubtitles => '字幕を検索';
	@override String get language => '言語';
	@override String get noSubtitlesFound => '字幕が見つかりません';
	@override String get subtitleDownloaded => '字幕をダウンロードしました';
	@override String get subtitleDownloadedNotApplied => '字幕はダウンロードされましたが、選択できませんでした';
	@override String get subtitleDownloadFailed => '字幕のダウンロードに失敗しました';
	@override String get searchLanguages => '言語を検索…';
	@override String get skipIntro => 'イントロをスキップ';
	@override String get skipCredits => 'クレジットをスキップ';
	@override String get nextEpisode => '次のエピソード';
	@override String subtitleTrack({required Object n}) => 'トラック${n}';
	@override String subtitleFile({required Object name}) => '字幕${name}';
	@override String forcedTrack({required Object label}) => '${label}（強制）';
	@override String get osdSubtitlesOff => '字幕: オフ';
	@override String osdSubtitles({required Object track}) => '字幕: ${track}';
	@override String osdAudio({required Object track}) => '音声: ${track}';
}

// Path: messages
class _Translations$messages$ja extends Translations$messages$en {
	_Translations$messages$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get searchPartialResults => '一部のメディアサーバーを検索できませんでした。利用可能な結果を表示しています。';
	@override String get streamInterrupted => 'ストリームが中断されました。再生を押すかシークして再試行してください。';
	@override String get liveStreamInterrupted => 'ライブストリームが中断されました。再生を押して再試行してください。';
	@override String get fileInfoNotAvailable => 'ファイル情報が利用できません';
	@override String get playbackAuthenticationRequired => 'このアイテムを再生するには、メディアサーバーにもう一度サインインしてください。';
	@override String get playbackServerUnavailable => 'メディアサーバーを利用できません。しばらくしてからもう一度お試しください。';
	@override String get playbackDataInvalid => 'サーバーから無効な再生情報が返されました。';
	@override String get playbackCancelled => '再生がキャンセルされました。';
	@override String get playbackFailed => '再生を開始できませんでした。';
	@override String errorLoadingFileInfo({required Object error}) => 'ファイル情報の読み込みエラー: ${error}';
	@override String get errorLoadingSeries => 'シリーズの読み込みエラー';
	@override String get musicNotSupported => '音楽の再生はまだサポートされていません';
	@override String get noDescriptionAvailable => '説明はありません';
	@override String get noProfilesAvailable => '利用可能なプロフィールがありません';
	@override String get contactAdminForProfiles => 'プロフィールを追加するには、サーバー管理者に連絡してください';
	@override String get unableToDetermineLibrarySection => 'このアイテムのライブラリセクションを判別できません';
	@override String get logsCleared => 'ログをクリアしました';
	@override String get logsCopied => 'ログをクリップボードにコピーしました';
	@override String get noLogsAvailable => 'ログがありません';
	@override String libraryScanning({required Object title}) => '「${title}」をスキャン中…';
	@override String libraryScanStarted({required Object title}) => '"${title}"のライブラリスキャンを開始しました';
	@override String libraryScanFailed({required Object error}) => 'ライブラリのスキャンに失敗しました: ${error}';
	@override String metadataRefreshing({required Object title}) => '「${title}」のメタデータを更新中…';
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
	@override String get failedToCreatePlayQueueNoItems => '再生キューを作成できませんでした — アイテムがありません';
	@override String failedPlayback({required Object action, required Object error}) => '${action}に失敗しました: ${error}';
	@override String get switchingToCompatiblePlayer => '互換性のあるプレーヤーに切り替え中…';
	@override String get serverLimitTitle => '再生に失敗しました';
	@override String get serverLimitBody => 'サーバーエラー（HTTP 500）。帯域幅/トランスコード制限により拒否された可能性があります。所有者に調整を依頼してください。';
	@override String get mediaUnreadableTitle => 'ファイルを利用できません';
	@override String get mediaUnreadableBody => 'サーバーはこのアイテムを見つけましたが、そのファイルを読み取れませんでした（HTTP 404）。ファイルが移動・削除されたか、ストレージがオフラインの可能性があります。サーバーの管理者にファイルの確認とライブラリの再スキャンを依頼してください。';
	@override String get serverBusyTitle => 'ストリームを利用できません';
	@override String get serverBusyBody => 'サーバーがこのファイルのストリーミングを繰り返し拒否しました（HTTP 503）。サーバーが再起動中またはビジー状態か、ファイルのストレージがオフラインの可能性があります。しばらくしてからもう一度お試しください。問題が続く場合は、サーバーの所有者にサーバーとファイルのストレージを確認するよう依頼してください。';
	@override String get logsUploaded => 'ログをアップロードしました';
	@override String get logsUploadFailed => 'ログのアップロードに失敗しました';
	@override String get logId => 'ログID';
	@override String get burnedSubtitlesUseMenu => '字幕はこのストリームに焼き付けられています。字幕メニューから変更してください。';
	@override String get noVideoUrl => '利用可能な動画URLがありません';
	@override String get playbackNoMediaSources => 'サーバーから再生可能なメディアソースが返されませんでした';
	@override String get playbackDataNotPrepared => '再生データの準備が完了する前に再生が開始されました';
	@override String get streamSelectionUnavailable => 'このソースではストリームを選択できません';
	@override String get streamSelectionFailed => '選択したストリームを適用できませんでした';
	@override String get serverUnavailableForProfile => '現在のプロフィールで利用可能なサーバーがありません';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ja extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get anchorToScreen => '画面に固定';
	@override String get anchorToScreenDescription => 'ワイドスクリーン映像の下にある黒帯にテキスト字幕を表示します';
	@override String get bold => '太字';
	@override String get italic => '斜体';
	@override String get renderResolution => 'レンダリング解像度';
	@override String get renderResolutionScreen => '画面解像度';
	@override String get renderResolutionVideo => '動画解像度';
}

// Path: mpvConfig
class _Translations$mpvConfig$ja extends Translations$mpvConfig$en {
	_Translations$mpvConfig$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => '高度な動画プレーヤー設定';
	@override String get presets => 'プリセット';
	@override String get noPresets => '保存済みプリセットがありません';
	@override String get saveAsPreset => 'プリセットとして保存…';
	@override String get presetName => 'プリセット名';
	@override String get presetNameHint => 'プリセットの名前を入力';
	@override String get loadPreset => '読み込み';
	@override String get deletePreset => '削除';
	@override String get presetSaved => 'プリセットを保存しました';
	@override String get presetLoaded => 'プリセットを読み込みました';
	@override String get presetDeleted => 'プリセットを削除しました';
	@override String get confirmDeletePreset => 'このプリセットを削除してもよろしいですか？';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get embeddedVoHint => 'Linux では vo、gpu-context、gpu-api は無視されます。埋め込み動画は常にビデオプレーン上で vo=libmpv を通してレンダリングされ、gpu-next（ArtCNN のようなコンピュートシェーダーに必要）は埋め込みでは実行できません。';
}

// Path: dialog
class _Translations$dialog$ja extends Translations$dialog$en {
	_Translations$dialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '操作の確認';
}

// Path: profiles
class _Translations$profiles$ja extends Translations$profiles$en {
	_Translations$profiles$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Plezyプロフィールを追加';
	@override String get switchingProfile => 'プロフィールを切り替え中…';
	@override String get deleteThisProfileTitle => 'このプロフィールを削除しますか？';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName}を削除します。接続には影響しません。';
	@override String get active => 'アクティブ';
	@override String get manage => '管理';
	@override String get delete => '削除';
	@override String get signOut => 'サインアウト';
	@override String get signOutPlexTitle => 'Plexからサインアウトしますか？';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName}とすべてのPlex Homeユーザーを削除しますか？いつでも再度サインインできます。';
	@override String get signedOutPlex => 'Plexからサインアウトしました。';
	@override String get signOutFailed => 'サインアウトに失敗しました。';
	@override String get sectionTitle => 'プロフィール';
	@override String get summarySingle => 'プロフィールを追加すると、管理対象ユーザーとローカルユーザーを併用できます';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count}個のプロフィール · 使用中: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count}個のプロフィール';
	@override String get removeConnectionTitle => '接続を削除しますか？';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName}の${connectionLabel}へのアクセスを削除します。他のプロフィールには残ります。';
	@override String get deleteProfileTitle => 'プロフィールを削除しますか？';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName}とその接続を削除します。サーバーは引き続き利用できます。';
	@override String get profileNameLabel => 'プロフィール名';
	@override String get pinProtectionLabel => 'PIN保護';
	@override String get pinManagedByPlex => 'PINはPlexで管理されています。plex.tvで編集してください。';
	@override String get noPinSetEditOnPlex => 'PINが設定されていません。PINを必須にするには、plex.tvでHomeユーザーを編集してください。';
	@override String get setPin => 'PINを設定';
	@override String get setPinTitle => 'PINを設定';
	@override String get confirmPinTitle => 'PINを確認';
	@override String get pinSet => 'PIN設定済み';
	@override String get changePin => '変更';
	@override String get removePin => '削除';
	@override String get connectionsLabel => '接続';
	@override String get add => '追加';
	@override String get deleteProfileButton => 'プロフィールを削除';
	@override String get noConnectionsHint => '接続がありません — このプロフィールを使うには接続を追加してください。';
	@override String get noConnections => '接続がありません';
	@override String get plexHomeAccount => 'Plex Homeアカウント';
	@override String plexAccountChip({required Object account}) => 'Plexアカウント: ${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account}経由の${user}';
	@override String get connectionDefault => 'デフォルト';
	@override String connectionAs({required Object displayName}) => '${displayName}として';
	@override String get makeDefault => 'デフォルトに設定';
	@override String get removeConnection => '削除';
	@override String get profileRenamed => 'プロフィール名を変更しました。';
	@override String borrowAddTo({required Object displayName}) => '${displayName}に追加';
	@override String get borrowExplain => '別のプロフィールの接続を利用します。PINで保護されたプロフィールにはPINが必要です。';
	@override String get borrowEmpty => '利用できる接続はまだありません。';
	@override String get borrowEmptySubtitle => 'まず、別のプロフィールをPlexまたはJellyfinに接続してください。';
	@override String get borrowLoadFailed => '利用可能な接続を読み込めませんでした。もう一度お試しください。';
	@override String borrowFromProfile({required Object displayName}) => '${displayName}から利用';
	@override String get borrowConnectionBorrowed => '接続を追加しました。';
	@override String get borrowFailed => '接続を追加できませんでした。';
	@override String get incorrectPin => 'PINが正しくありません。';
	@override String get incorrectPinTryAgain => 'PINが正しくありません。もう一度お試しください。';
	@override String get sourceProfileMissingParentAccount => '元のプロフィールに親アカウントがありません。';
	@override String get failedToLoadHomeUsers => 'Plex Homeユーザーを読み込めませんでした。接続を確認して、もう一度お試しください。';
	@override String get failedToVerifyPin => 'PINを確認できませんでした。';
	@override String get newProfile => '新しいプロフィール';
	@override String get profileNameHint => '例：ゲスト、キッズ、ファミリールーム';
	@override String get pinProtectionOptional => 'PIN保護（オプション）';
	@override String get pinExplain => 'プロフィール切り替えには4桁のPINが必要です。';
	@override String get continueButton => '続ける';
	@override String get pinsDontMatch => 'PINが一致しません';
	@override String get tokenIdentityMismatch => 'Plexプロフィールのトークンから予期しないサーバーが特定されました';
}

// Path: connections
class _Translations$connections$ja extends Translations$connections$en {
	_Translations$connections$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '接続';
	@override String get addConnection => '接続を追加';
	@override String get addConnectionSubtitleNoProfile => 'Plexでサインインするか、Jellyfinサーバーに接続';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}に追加：Plex、Jellyfin、または別のプロフィールの接続';
	@override String sessionExpiredOne({required Object name}) => '${name} のセッションの有効期限が切れました';
	@override String sessionExpiredMany({required Object count}) => '${count} 台のサーバーのセッションの有効期限が切れました';
	@override String get signInAgain => '再度サインイン';
	@override String editMediaBrowserTitle({required Object product}) => '${product}接続を編集';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName}のURLを追加または削除します。Plezyは到達可能なURLのうち、レイテンシーが最も低いものを使用します。';
}

// Path: discover
class _Translations$discover$ja extends Translations$discover$en {
	_Translations$discover$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '探す';
	@override String get noContentAvailable => 'コンテンツがありません';
	@override String get addMediaToLibraries => 'ライブラリにメディアを追加してください';
	@override String get continueWatching => '視聴を続ける';
	@override String continueWatchingIn({required Object library}) => '${library}の視聴を続ける';
	@override String get nextUp => '次のエピソード';
	@override String nextUpIn({required Object library}) => '${library}の次のエピソード';
	@override String get recentlyAdded => '最近追加されたコンテンツ';
	@override String recentlyAddedIn({required Object library}) => '${library}に最近追加されたコンテンツ';
	@override String latestAlbumsIn({required Object library}) => '${library}の最新アルバム';
	@override String recentlyPlayedIn({required Object library}) => '${library}で最近再生したコンテンツ';
	@override String mostPlayedIn({required Object library}) => '${library}で最も再生したコンテンツ';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'あらすじ';
	@override String get cast => 'キャスト';
	@override String get extras => '予告編とエクストラ';
	@override String get studio => 'スタジオ';
	@override String get rating => '評価';
	@override String get director => '監督';
	@override String get directors => '監督';
	@override String get movie => '映画';
	@override String get tvShow => 'テレビ番組';
	@override String minutesLeft({required Object minutes}) => '残り${minutes}分';
	@override String get moreLikeThis => '似ている作品';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n}作品',
	);
}

// Path: errors
class _Translations$errors$ja extends Translations$errors$en {
	_Translations$errors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '検索に失敗しました: ${error}';
	@override String get searchUnavailable => '検索中にメディアサーバーへ接続できませんでした。';
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
class _Translations$libraries$ja extends Translations$libraries$en {
	_Translations$libraries$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String emptyingTrash({required Object title}) => '「${title}」のゴミ箱を空にしています…';
	@override String trashEmptied({required Object title}) => '「${title}」のゴミ箱を空にしました';
	@override String failedToEmptyTrash({required Object error}) => 'ゴミ箱を空にできませんでした: ${error}';
	@override String analyzing({required Object title}) => '「${title}」を解析中…';
	@override String analysisStarted({required Object title}) => '「${title}」の解析を開始しました';
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
	@override late final _Translations$libraries$tabs$ja tabs = _Translations$libraries$tabs$ja._(_root);
	@override late final _Translations$libraries$groupings$ja groupings = _Translations$libraries$groupings$ja._(_root);
	@override late final _Translations$libraries$filterCategories$ja filterCategories = _Translations$libraries$filterCategories$ja._(_root);
	@override late final _Translations$libraries$sortLabels$ja sortLabels = _Translations$libraries$sortLabels$ja._(_root);
}

// Path: about
class _Translations$about$ja extends Translations$about$en {
	_Translations$about$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'アプリについて';
	@override String get openSourceLicenses => 'オープンソースライセンス';
	@override String versionLabel({required Object version}) => 'バージョン ${version}';
	@override String get appDescription => 'Flutter製の美しいPlex・Jellyfinクライアント';
	@override String get viewLicensesDescription => 'サードパーティライブラリのライセンスを表示';
}

// Path: serverSelection
class _Translations$serverSelection$ja extends Translations$serverSelection$en {
	_Translations$serverSelection$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})のサーバーが見つかりません';
	@override String failedToLoadServers({required Object error}) => 'サーバーの読み込みに失敗しました: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$ja extends Translations$hubDetail$en {
	_Translations$hubDetail$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'タイトル';
	@override String get releaseYear => '公開年';
	@override String get dateAdded => '追加日';
	@override String get rating => '評価';
	@override String get noItemsFound => 'アイテムが見つかりません';
}

// Path: logs
class _Translations$logs$ja extends Translations$logs$en {
	_Translations$logs$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'ログをクリア';
	@override String get copyLogs => 'ログをコピー';
	@override String get uploadLogs => 'ログをアップロード';
}

// Path: startup
class _Translations$startup$ja extends Translations$startup$en {
	_Translations$startup$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezyを起動できませんでした';
	@override String get failedBody => '起動中に問題が発生しました。以下の詳細に失敗の原因が示されています。';
	@override String get failedBodyRepairable => 'Plezyの保存済み設定ファイルが破損しているため、Plezyを起動する前に再構築する必要があります。再試行しても解決しません —「ストレージを修復」を選択してください。';
	@override String get phaseLabel => 'ステップ';
	@override String get showDetails => '詳細を表示';
	@override String get hideDetails => '詳細を非表示';
	@override String get copyDetails => '詳細をコピー';
	@override String get detailsCopied => '詳細をクリップボードにコピーしました';
	@override String get uploadDetails => '詳細をアップロード';
	@override String get repairStorage => 'ストレージを修復';
	@override String get repairTitle => '保存データを修復しますか？';
	@override String get repairBodyCommon => 'Plezyの設定ファイルが破損しており読み取れません。修復するとすべての設定がデフォルトにリセットされます。';
	@override String get repairBodyOneCredential => '保存済みのサインインの1つが破損しており読み取れません。修復するとその1つだけが削除され、他の設定には影響しません。';
	@override String get repairBodySignInsKept => 'サーバーとプロフィールはサインインしたままになります。';
	@override String get repairBodySignInsLost => '保存済みのサインインを保護するキーをこのファイルから復元できないため、すべてのサーバーとプロフィールに再度サインインする必要があります。メディアサーバー上のデータには影響ありません。';
	@override String get repairBodySessionsUncertain => 'トラッカー（MAL、AniList、Simkl、Trakt）とSeerrは別途保存されており、保持されるかどうかは不明です。Plezyは保持した内容を正確にお知らせします。';
	@override String get repairConfirm => '修復';
	@override String get repairSucceeded => 'ストレージを修復しました';
	@override String get repairNeedsRestart => 'ストレージを修復しました — 再起動が必要です';
	@override String get restartRequiredBody => 'データは修復されましたが、Plezyはそれを使用する前に再起動する必要があります。Plezyを閉じて再度開いてください。';
	@override String get quitPlezy => 'Plezyを終了';
	@override String get repairFailed => '修復に失敗しました';
	@override String get repairKeptSignIns => 'サーバーとプロフィールはサインインしたままです。';
	@override String get repairLostSignIns => '保存済みのサインインを保護するキーを復元できませんでした。すべてのサーバーとプロフィールに再度サインインする必要があります。';
	@override String get repairLostSessions => '少なくとも1つのトラッカーまたはSeerr接続が失われたため、再接続が必要です。';
	@override String get backupTitle => '破損したファイルのコピーを保持しました';
	@override String get backupWarning => 'このコピーにはサインイン資格情報が含まれています。アップロードや共有はしないでください。';
	@override String get deleteBackup => 'コピーを削除';
	@override String get backupDeleted => 'コピーを削除しました。';
	@override String get previousFailureTitle => '前回、Plezyは起動に失敗しました';
}

// Path: licenses
class _Translations$licenses$ja extends Translations$licenses$en {
	_Translations$licenses$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '関連パッケージ';
	@override String get license => 'ライセンス';
	@override String licenseNumber({required Object number}) => 'ライセンス ${number}';
	@override String licensesCount({required Object count}) => '${count}件のライセンス';
}

// Path: navigation
class _Translations$navigation$ja extends Translations$navigation$en {
	_Translations$navigation$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'ライブラリ';
	@override String get downloads => 'ダウンロード';
	@override String get liveTv => 'ライブTV';
	@override String get explore => '見つける';
}

// Path: explore
class _Translations$explore$ja extends Translations$explore$en {
	_Translations$explore$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '見つける';
	@override String get selectSource => 'ソースを選択';
	@override late final _Translations$explore$rows$ja rows = _Translations$explore$rows$ja._(_root);
	@override late final _Translations$explore$status$ja status = _Translations$explore$status$ja._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n}話',
	);
	@override String get cast => 'キャスト';
	@override String get characters => 'キャラクター';
	@override String get addToWatchlist => 'ウォッチリストに追加';
	@override String get removeFromWatchlist => 'ウォッチリストから削除';
	@override String get addedToWatchlist => 'ウォッチリストに追加しました';
	@override String get removedFromWatchlist => 'ウォッチリストから削除しました';
	@override String get watchlistUpdateFailed => 'ウォッチリストを更新できませんでした';
	@override String get watchlistNoMatch => 'このアイテムに一致するウォッチリスト項目が見つかりませんでした';
	@override String get notInLibrary => 'ライブラリにありません';
	@override String get inTheseLibraries => 'これらのライブラリにあります';
	@override String get checkingLibrary => 'ライブラリを確認中…';
	@override String get emptyTitle => 'まだ何もありません';
	@override String emptyMessage({required Object source}) => '${source}にコンテンツが追加されると、ここに表示されます。';
	@override String searchHint({required Object source}) => '${source}を検索';
	@override String searchEmpty({required Object query}) => '「${query}」の結果が見つかりません';
	@override String searchPrompt({required Object source}) => '${source}で映画やテレビ番組を検索します。';
	@override String get searchFailed => '検索に失敗しました。接続を確認してもう一度お試しください。';
	@override late final _Translations$explore$badge$ja badge = _Translations$explore$badge$ja._(_root);
	@override late final _Translations$explore$stats$ja stats = _Translations$explore$stats$ja._(_root);
	@override late final _Translations$explore$season$ja season = _Translations$explore$season$ja._(_root);
	@override late final _Translations$explore$format$ja format = _Translations$explore$format$ja._(_root);
	@override late final _Translations$explore$sourceMaterial$ja sourceMaterial = _Translations$explore$sourceMaterial$ja._(_root);
	@override late final _Translations$explore$creditRole$ja creditRole = _Translations$explore$creditRole$ja._(_root);
	@override late final _Translations$explore$relation$ja relation = _Translations$explore$relation$ja._(_root);
	@override String broadcast({required Object day, required Object time}) => '${day} ${time}に放送';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '${day} ${time}（${timezone}）に放送';
	@override late final _Translations$explore$detail$ja detail = _Translations$explore$detail$ja._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n}件の結果',
	);
}

// Path: liveTv
class _Translations$liveTv$ja extends Translations$liveTv$en {
	_Translations$liveTv$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get reloadGuide => '番組表を再読み込み';
	@override String get now => '現在';
	@override String get today => '今日';
	@override String get tomorrow => '明日';
	@override String get midnight => '午前0時';
	@override String get overnight => '深夜';
	@override String get morning => '朝';
	@override String get daytime => '日中';
	@override String get evening => '夕方';
	@override String get lateNight => '夜更け';
	@override String get whatsOn => '放送中';
	@override String get watchChannel => 'チャンネルを視聴';
	@override String get favorites => 'お気に入り';
	@override String get reorderFavorites => 'お気に入りを並べ替え';
	@override String get noFavoriteChannels => 'お気に入りのチャンネルがありません';
	@override String get noFavoriteChannelsHint => 'すべてのチャンネルを表示し、チャンネルを長押ししてお気に入りに追加してください。';
	@override String get showAllChannels => 'すべてのチャンネルを表示';
	@override String get favoritesLoadFailed => 'お気に入りを読み込めませんでした。接続を確認してもう一度お試しください。';
	@override String get favoritesUpdateFailed => 'お気に入りを更新できませんでした。接続を確認してもう一度お試しください。';
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
	@override String cancelRecordingMessage({required Object title}) => '${title}は録画されなくなります。';
	@override String get deleteRule => 'ルールを削除';
	@override String get deleteRuleTitle => '録画ルールを削除しますか？';
	@override String deleteRuleMessage({required Object title}) => '${title}の今後のエピソードは録画されません。';
	@override String get recordingScheduled => '録画を予約しました';
	@override String get alreadyScheduled => 'この番組はすでに予約されています';
	@override String get dvrAdminRequired => 'DVR設定には管理者アカウントが必要です';
	@override String get recordingFailed => '録画を予約できませんでした';
	@override String get recordingTargetMissing => '録画ライブラリを特定できませんでした';
	@override String get recordNotAvailable => 'この番組は録画できません';
	@override String get recordingCancelled => '録画をキャンセルしました';
	@override String get recordingRuleDeleted => '録画ルールを削除しました';
	@override String get processRecordingRules => 'ルールを再評価';
	@override String get recordingInProgress => '録画中';
	@override String recordingsCount({required Object count}) => '${count}件予約済み';
	@override String get editRule => 'ルールを編集';
	@override String get editRuleAction => '編集';
	@override String get recordingRuleUpdated => '録画ルールを更新しました';
	@override String get guideReloadRequested => '番組表の更新をリクエストしました';
	@override String get rulesProcessRequested => '録画ルールの再評価をリクエストしました';
	@override String get recordShow => '番組を録画';
	@override String startingInMinutes({required Object minutes}) => '${minutes}分後に開始';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product}から無効なライブTV再生データが返されました';
	@override String get failedToStartChannel => 'ライブチャンネルを開始できませんでした';
	@override String get failedToBuildStreamUrl => 'ストリームURLを生成できませんでした';
}

// Path: collections
class _Translations$collections$ja extends Translations$collections$en {
	_Translations$collections$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コレクション';
	@override String get collection => 'コレクション';
	@override String get empty => 'コレクションは空です';
	@override String get deleteCollection => 'コレクションを削除';
	@override String deleteConfirm({required Object title}) => '「${title}」を削除しますか？この操作は元に戻せません。';
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
	@override String removeFromCollectionConfirm({required Object title}) => '「${title}」をこのコレクションから削除しますか？';
	@override String get removedFromCollection => 'コレクションから削除しました';
	@override String get removeFromCollectionFailed => 'コレクションからの削除に失敗しました';
	@override String removeFromCollectionError({required Object error}) => 'コレクションからの削除エラー: ${error}';
	@override String get searchCollections => 'コレクションを検索…';
}

// Path: playlists
class _Translations$playlists$ja extends Translations$playlists$en {
	_Translations$playlists$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String itemCount({required Object count}) => '${count}件';
	@override String get oneItem => '1件';
	@override String get emptyPlaylist => 'このプレイリストは空です';
	@override String get deleteConfirm => 'プレイリストを削除しますか？';
	@override String deleteMessage({required Object name}) => '「${name}」を削除しますか？';
	@override String get created => 'プレイリストを作成しました';
	@override String get deleted => 'プレイリストを削除しました';
	@override String get itemAdded => 'プレイリストに追加しました';
	@override String get itemRemoved => 'プレイリストから削除しました';
	@override String get selectPlaylist => 'プレイリストを選択';
	@override String get searchPlaylists => 'プレイリストを検索…';
	@override String get errorCreating => 'プレイリストの作成に失敗しました';
	@override String get errorDeleting => 'プレイリストの削除に失敗しました';
	@override String get errorLoading => 'プレイリストの読み込みに失敗しました';
	@override String get errorAdding => 'プレイリストへの追加に失敗しました';
	@override String get errorReordering => 'プレイリストアイテムの並べ替えに失敗しました';
	@override String get errorRemoving => 'プレイリストからの削除に失敗しました';
}

// Path: music
class _Translations$music$ja extends Translations$music$en {
	_Translations$music$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'アルバムへ移動';
	@override String get goToArtist => 'アーティストへ移動';
	@override String get instantMix => 'インスタントミックス';
	@override String get playNext => '次に再生';
	@override String get addToQueue => 'キューに追加';
	@override String discNumber({required Object n}) => 'ディスク ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n}曲',
	);
	@override String get nowPlaying => '再生中';
	@override String playingFrom({required Object title}) => '${title}から再生';
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
	@override String get instantMixNoServer => 'インスタントミックスに利用できるサーバーがありません';
	@override String noAudioUrl({required Object track}) => '${track}で利用可能な音声URLがありません';
	@override late final _Translations$music$discography$ja discography = _Translations$music$discography$ja._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$ja extends Translations$watchTogether$en {
	_Translations$watchTogether$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '一緒に見る';
	@override String get description => '友達や家族と同期してコンテンツを視聴';
	@override String get createSession => 'セッションを作成';
	@override String get creating => '作成中…';
	@override String get joinSession => 'セッションに参加';
	@override String get joining => '参加中…';
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
	@override String get hostBadge => 'ホスト';
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
	@override String get syncing => '同期中…';
	@override String get joinWatchSession => '視聴セッションに参加';
	@override String get enterCodeHint => '5文字のコードを入力';
	@override String get pasteFromClipboard => 'クリップボードから貼り付け';
	@override String get pleaseEnterCode => 'セッションコードを入力してください';
	@override String get codeMustBe5Chars => 'セッションコードは5文字である必要があります';
	@override String get joinInstructions => '参加するにはホストのセッションコードを入力してください。';
	@override String get failedToCreate => 'セッションの作成に失敗しました';
	@override String get failedToJoin => 'セッションへの参加に失敗しました';
	@override String get sessionCodeCopied => 'セッションコードをクリップボードにコピーしました';
	@override String get relayUnreachable => 'リレーサーバーに接続できません。ISPによるブロックのため「一緒に見る」を利用できない可能性があります。';
	@override String get reconnectingToHost => 'ホストに再接続中…';
	@override String get currentPlayback => '現在の再生';
	@override String get joinCurrentPlayback => '現在の再生に参加';
	@override String get joinCurrentPlaybackDescription => 'ホストが現在視聴中のコンテンツに戻る';
	@override String get failedToOpenCurrentPlayback => '現在の再生を開けませんでした';
	@override String participantJoined({required Object name}) => '${name}が参加しました';
	@override String participantLeft({required Object name}) => '${name}が退出しました';
	@override String participantPaused({required Object name}) => '${name}が一時停止しました';
	@override String participantResumed({required Object name}) => '${name}が再開しました';
	@override String participantSeeked({required Object name}) => '${name}が再生位置を変更しました';
	@override String participantBuffering({required Object name}) => '${name}がバッファリング中';
	@override String participantNeedsUpdate({required Object name}) => '${name}は古いバージョンのアプリを使用しているため、同期できません';
	@override String resumingWithout({required Object name}) => '${name}抜きで再開';
	@override String get waitingForParticipants => '他の参加者の読み込みを待っています…';
	@override String waitingForName({required Object name}) => '${name}を待っています…';
	@override String get recentRooms => '最近のルーム';
	@override String get renameRoom => 'ルーム名を変更';
	@override String get removeRoom => '削除';
	@override String get guestSwitchUnavailable => '切り替えられません — 同期に必要なサーバーを利用できません';
	@override String get guestSwitchFailed => '切り替えられません — このサーバーにコンテンツが見つかりません';
	@override String get defaultDisplayName => 'ユーザー';
}

// Path: downloads
class _Translations$downloads$ja extends Translations$downloads$en {
	_Translations$downloads$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ダウンロード';
	@override String get manage => '管理';
	@override String get tvShows => 'テレビ番組';
	@override String get movies => '映画';
	@override String get music => '音楽';
	@override String tracksQueued({required Object count}) => '${count} 曲をダウンロード待機中';
	@override String get noDownloads => 'ダウンロードはまだありません';
	@override String get noDownloadsDescription => 'ダウンロードしたコンテンツはここに表示され、オフラインで視聴できます';
	@override String get downloadNow => 'ダウンロード';
	@override String get deleteDownload => 'ダウンロードを削除';
	@override String get retryDownload => 'ダウンロードを再試行';
	@override String get downloadQueued => 'ダウンロードをキューに追加しました';
	@override String get downloadResumed => 'ダウンロードを再開しました';
	@override String get serverErrorBitrate => 'サーバーエラー: ファイルがリモートビットレート制限を超えている可能性があります';
	@override String get storageFull => 'デバイスのストレージがいっぱいのため、ダウンロードを停止しました。空き容量を確保してから、もう一度お試しください。';
	@override String episodesQueued({required Object count}) => '${count}エピソードをダウンロードキューに追加しました';
	@override String get downloadDeleted => 'ダウンロードを削除しました';
	@override String deleteConfirm({required Object title}) => 'このデバイスから「${title}」を削除しますか？';
	@override String get cancelledDownloadTitle => 'キャンセル済みのダウンロード';
	@override String get cancelledDownloadMessage => 'このダウンロードはキャンセルされました。どうしますか？';
	@override String get allEpisodesAlreadyDownloaded => 'すべてのエピソードはすでにダウンロード済みです';
	@override String get resumeDownload => 'ダウンロードを再開';
	@override String get cancelledDownload => 'キャンセル済みのダウンロード';
	@override String syncingFile({required Object file, required Object status}) => '${file}（${status}を同期中）';
	@override String downloadedFileClickToComplete({required Object file}) => '${file}をダウンロード済み — クリックして完了';
	@override String get partialDownloadClickToComplete => '一部ダウンロード済み — クリックして完了';
	@override String get deleting => '削除中…';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title}を削除中…（${current}/${total}）';
	@override String get queuedTooltip => 'キュー';
	@override String queuedFilesTooltip({required Object files}) => 'キュー：${files}';
	@override String get downloadingTooltip => 'ダウンロード中…';
	@override String downloadingFilesTooltip({required Object files}) => '${files}をダウンロード中';
	@override String get noDownloadsTree => 'ダウンロードなし';
	@override String get pauseAll => 'すべて一時停止';
	@override String get resumeAll => 'すべて再開';
	@override String get deleteAll => 'すべて削除';
	@override String get selectVersion => 'バージョンを選択';
	@override String get allEpisodes => 'すべてのエピソード';
	@override String get unwatchedOnly => '未視聴のみ';
	@override String nextNUnwatched({required Object count}) => '次の${count}件の未視聴';
	@override String get customAmount => '数を指定…';
	@override String get includeSpecials => 'スペシャルを含める';
	@override String get howManyEpisodes => 'エピソード数';
	@override String get invalidEpisodeCount => '有効なエピソード数を入力してください。';
	@override String get keepSynced => '同期を維持';
	@override String get downloadOnce => '一度だけダウンロード';
	@override String keepNUnwatched({required Object count}) => '未視聴を${count}件保持';
	@override String get editSyncRule => '同期ルールを編集';
	@override String get removeSyncRule => '同期ルールを削除';
	@override String removeSyncRuleConfirm({required Object title}) => '「${title}」の同期を停止しますか？ダウンロード済みのエピソードは保持されます。';
	@override String removeListSyncRuleConfirm({required Object title}) => '「${title}」の同期を停止しますか？';
	@override String get deleteSyncRuleDownloads => '関連するダウンロードも削除';
	@override String get deleteSyncRuleDownloadsDescription => '別の同期ルールやプロフィールで使用されているダウンロードは保持されます。';
	@override String syncRuleCreated({required Object count}) => '同期ルールを作成しました — 未視聴のエピソードを${count}件保持';
	@override String get syncRuleUpdated => '同期ルールを更新しました';
	@override String get syncRuleRemoved => '同期ルールを削除しました';
	@override String get syncRuleAndDownloadsRemoved => '同期ルールと関連するダウンロードを削除しました';
	@override String get syncRuleCleanupBusy => '同期ルールが更新中です。しばらくしてからもう一度お試しください。';
	@override String get syncRuleCleanupUnavailable => '関連するダウンロードを安全に特定できませんでした。サーバーに再接続して再試行するか、ダウンロードを削除せずにルールを削除してください。';
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
	@override late final _Translations$downloads$backgroundWarning$ja backgroundWarning = _Translations$downloads$backgroundWarning$ja._(_root);
	@override String get unknownShow => '不明な番組';
	@override String get unknownSeason => '不明なシーズン';
	@override String get unknownAlbum => '不明なアルバム';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total}完了';
	@override String get errorFileNotFound => 'ファイルが見つかりません（404）';
	@override String get errorDownloadFailed => 'ダウンロードに失敗しました';
	@override String errorPostProcessing({required Object error}) => '後処理に失敗しました: ${error}';
	@override String get notificationDownloading => 'ダウンロード中…';
	@override String get notificationComplete => 'ダウンロードが完了しました';
	@override String get notificationPaused => 'ダウンロードを一時停止しました';
}

// Path: shaders
class _Translations$shaders$ja extends Translations$shaders$en {
	_Translations$shaders$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'シェーダー';
	@override String get noShaderDescription => '映像補正なし';
	@override String get nvscalerDescription => 'NVIDIA画像スケーリングで映像をより鮮明にします';
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
	@override String deleteShaderConfirm({required Object name}) => '「${name}」を削除しますか？';
}

// Path: companionRemote
class _Translations$companionRemote$ja extends Translations$companionRemote$en {
	_Translations$companionRemote$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コンパニオンリモート';
	@override String connectedTo({required Object name}) => '${name}に接続中';
	@override String get unknownDevice => '不明なデバイス';
	@override late final _Translations$companionRemote$session$ja session = _Translations$companionRemote$session$ja._(_root);
	@override late final _Translations$companionRemote$pairing$ja pairing = _Translations$companionRemote$pairing$ja._(_root);
	@override late final _Translations$companionRemote$remote$ja remote = _Translations$companionRemote$remote$ja._(_root);
	@override late final _Translations$companionRemote$errors$ja errors = _Translations$companionRemote$errors$ja._(_root);
	@override String get closedBeforeAuth => '認証前に接続が切断されました';
}

// Path: videoSettings
class _Translations$videoSettings$ja extends Translations$videoSettings$en {
	_Translations$videoSettings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get hdrUnsupported => 'ここではHDRを利用できません。このデスクトップコンポジターまたは映像出力はHDRに対応していません。';
	@override String get hdrToneMapping => 'HDRトーンマッピング';
	@override String get hdrToneMappingCompositor => 'コンポジター';
	@override String get hdrToneMappingCompositorDescription => 'ソースのHDRメタデータをそのまま渡し、デスクトップコンポジターにマッピングさせます。';
	@override String get hdrToneMappingPlayer => 'プレーヤー';
	@override String get hdrToneMappingPlayerDescription => 'プレーヤーでディスプレイのピーク輝度に合わせてマッピングし、その結果をコンポジターに通知します。';
	@override String get hdrToneMappingFailed => 'HDRトーンマッピングを変更できませんでした。以前のモードが引き続き有効です。';
	@override String get audioOutput => '音声出力';
	@override String get performanceOverlay => 'パフォーマンスオーバーレイ';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'サラウンド';
	@override String get audioOutputSpatial => '空間オーディオ';
	@override String get audioOutputStereo => 'ステレオ';
	@override String get audioNormalization => 'ラウドネス正規化';
	@override String get audioDownmix => 'ステレオにダウンミックス';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$ja extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get transfer => '伝達特性';
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
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'ソフトウェア';
	@override String get decoderHardware => 'ハードウェア';
	@override String get tunnelingActive => '有効';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted}（${failures}件失敗）';
}

// Path: externalPlayer
class _Translations$externalPlayer$ja extends Translations$externalPlayer$en {
	_Translations$externalPlayer$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '外部プレーヤー';
	@override String get useExternalPlayer => '外部プレーヤーを使用';
	@override String get useExternalPlayerDescription => '動画を別のアプリで開きます';
	@override String get selectPlayer => 'プレーヤーを選択';
	@override String get customPlayers => 'カスタムプレーヤー';
	@override String get systemDefault => 'システム既定';
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
class _Translations$metadataEdit$ja extends Translations$metadataEdit$en {
	_Translations$metadataEdit$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => '編集…';
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
	@override String latestEpisodes({required Object count}) => '最新の${count}話';
	@override String get latestEpisode => '最新エピソード';
	@override String episodesAddedPastDays({required Object count}) => '過去${count}日間に追加されたエピソード';
	@override String get deleteAfterPlaying => '再生後にエピソードを削除';
	@override String get never => 'しない';
	@override String get afterADay => '1日後';
	@override String get afterAWeek => '1週間後';
	@override String get afterAMonth => '1か月後';
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
}

// Path: matchScreen
class _Translations$matchScreen$ja extends Translations$matchScreen$en {
	_Translations$matchScreen$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get match => '照合…';
	@override String get fixMatch => '照合を修正…';
	@override String get unmatch => '照合を解除';
	@override String get unmatchConfirm => 'この照合を解除しますか？再照合するまで、Plexでは未照合として扱われます。';
	@override String get unmatchSuccess => '照合を解除しました';
	@override String get unmatchFailed => '照合を解除できませんでした';
	@override String get matchApplied => '照合結果を適用しました';
	@override String get matchFailed => '照合結果を適用できませんでした';
	@override String get titleHint => 'タイトル';
	@override String get yearHint => '年';
	@override String get search => '検索';
	@override String get noMatchesFound => '一致する項目がありません';
}

// Path: serverTasks
class _Translations$serverTasks$ja extends Translations$serverTasks$en {
	_Translations$serverTasks$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'サーバータスク';
	@override String get failedToLoad => 'タスクの読み込みに失敗しました';
	@override String get noTasks => '実行中のタスクはありません';
}

// Path: trakt
class _Translations$trakt$ja extends Translations$trakt$en {
	_Translations$trakt$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '接続済み';
	@override String connectedAs({required Object username}) => '@${username}として接続済み';
	@override String get disconnectConfirm => 'Traktアカウントとの接続を解除しますか？';
	@override String get disconnectConfirmBody => 'PlezyはTraktへのイベント送信を停止します。いつでも再接続できます。';
	@override String get scrobble => 'リアルタイムのスクロブル';
	@override String get scrobbleDescription => '再生中に再生・一時停止・停止の各イベントをTraktに送信します。';
	@override String get watchedSync => '視聴済みステータスを同期';
	@override String get watchedSyncDescription => 'Plezyで項目を視聴済みにすると、Traktでも視聴済みになります。';
}

// Path: seerr
class _Translations$seerr$ja extends Translations$seerr$en {
	_Translations$seerr$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String couldNotReach({required Object url, required Object error}) => '${url}に接続できませんでした: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url}にSeerrインスタンスがありません（HTTP ${status}）';
	@override String get notInitialized => 'このSeerrインスタンスでは初回セットアップが完了していません';
	@override String get noPlexTokenForReauth => '再サインインに使用できるPlexトークンがありません';
	@override String get noStoredCredentials => '再サインインに使用できる保存済みの認証情報がありません';
	@override String get signInRejected => 'サインインが拒否されました';
	@override String get noSessionCookie => 'Seerrからセッションクッキーが発行されませんでした';
	@override String get freshCookieRejected => 'Seerrが新しいセッションクッキーを拒否しました';
	@override String get noUserInformation => 'Seerrからユーザー情報が返されませんでした';
	@override String get sessionRejectedAfterReauth => '再サインイン後にセッションが拒否されました';
}

// Path: services
class _Translations$services$ja extends Translations$services$en {
	_Translations$services$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override late final _Translations$services$names$ja names = _Translations$services$names$ja._(_root);
	@override late final _Translations$services$deviceCode$ja deviceCode = _Translations$services$deviceCode$ja._(_root);
	@override late final _Translations$services$oauthProxy$ja oauthProxy = _Translations$services$oauthProxy$ja._(_root);
	@override late final _Translations$services$pendingAuth$ja pendingAuth = _Translations$services$pendingAuth$ja._(_root);
	@override late final _Translations$services$libraryFilter$ja libraryFilter = _Translations$services$libraryFilter$ja._(_root);
}

// Path: addServer
class _Translations$addServer$ja extends Translations$addServer$en {
	_Translations$addServer$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product}サーバーを追加';
	@override String get serverUrls => 'サーバーURL';
	@override String get serverUrlsHelper => '複数のURLをカンマ区切りで入力できます。';
	@override String get findServer => 'サーバーを検索';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'ローカルの${product}サーバーを検索中…';
	@override String localMediaBrowserServers({required Object product}) => 'ローカルの${product}サーバー';
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
	@override String enterMediaBrowserUrlError({required Object product}) => '${product}サーバーのURLを入力してください';
	@override String get addConnectionTitle => '接続を追加';
	@override String addConnectionTitleScoped({required Object name}) => '${name}に追加';
	@override String get signInWithPlexCard => 'Plexでサインイン';
	@override String get signInWithPlexCardSubtitle => 'このデバイスを承認します。共有サーバーが追加されます。';
	@override String get signInWithPlexCardSubtitleScoped => 'Plexアカウントを承認します。Homeユーザーはプロフィールになります。';
	@override String connectToMediaBrowserCard({required Object product}) => '${product}に接続';
	@override String get connectToMediaBrowserCardSubtitle => 'サーバーのURL、ユーザー名、パスワードを入力してください。';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '${product}サーバーにサインインします。「${name}」に紐付けられます。';
	@override String get borrowFromAnotherProfile => '別のプロフィールの接続を利用';
	@override String get borrowFromAnotherProfileSubtitle => '別のプロフィールの接続を再利用します。PINで保護されたプロフィールにはPINが必要です。';
	@override String get invalidCredentials => 'ユーザー名またはパスワードが正しくありません';
	@override String get authResponseNotJson => '認証レスポンスが有効なJSONではありません';
	@override String get quickConnectRejected => 'Quick Connectがサーバーに拒否されました';
	@override String get quickConnectNotJson => 'Quick Connectのレスポンスが有効なJSONではありません';
	@override String get quickConnectMissingFields => 'Quick Connectのレスポンスにコードまたはシークレットがありません';
	@override String get quickConnectPollRejected => 'Quick Connectのポーリングがサーバーに拒否されました';
	@override String get serverTimedOut => 'サーバーが時間内に応答しませんでした';
	@override String get responseNotJson => 'サーバーのレスポンスが有効なJSONではありません';
	@override String responseMissingIdentity({required Object product}) => 'レスポンスにIDまたはサーバー名がありません。これは${product}サーバーですか？';
	@override String probeFailed({required Object error}) => 'サーバーに接続できませんでした: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => '${product}サーバーのURLを1つ以上入力してください';
	@override String noReachableServer({required Object product}) => '接続可能な${product}サーバーが見つかりませんでした';
	@override String urlsPointToDifferentServers({required Object product}) => 'これらのURLは異なる${product}サーバーを指しています';
	@override String urlDoesNotMatchServer({required Object product}) => 'このURLは${product}サーバーと一致しません';
	@override String get redirectUnsupported => 'サーバーからサポートされていないURLにリダイレクトされました';
	@override String redirectDifferentHost({required Object product}) => 'サーバーから別のホストにリダイレクトされました。最終的な${product}のURLを直接入力してください。';
	@override String get redirectInsecure => 'サーバーからHTTPSではない安全でないURLにリダイレクトされました';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'サーバーからサポートされていないURLにリダイレクトされました。最終的な${product}のURLを直接入力してください。';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ja extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get critic => '批評家';
	@override String get audience => '観客';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes 批評家';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes 観客';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$ja extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get playPause => '再生/一時停止';
	@override String get volumeUp => '音量を上げる';
	@override String get volumeDown => '音量を下げる';
	@override String seekForward({required Object seconds}) => '早送り（${seconds}秒）';
	@override String seekBackward({required Object seconds}) => '巻き戻し（${seconds}秒）';
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
class _Translations$videoControls$pipErrors$ja extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
class _Translations$libraries$tabs$ja extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'おすすめ';
	@override String get browse => 'ブラウズ';
	@override String get collections => 'コレクション';
	@override String get playlists => 'プレイリスト';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$ja extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
class _Translations$libraries$filterCategories$ja extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
class _Translations$libraries$sortLabels$ja extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
	@override String get premiereDate => '初公開日';
	@override String get startDate => '開始日';
	@override String get airTime => '放送時刻';
	@override String get studio => 'スタジオ';
	@override String get random => 'ランダム';
	@override String get dateShared => '共有日';
	@override String get latestEpisodeAirDate => '最新エピソード放送日';
	@override String get lastEpisodeDateAdded => '最新エピソード追加日';
}

// Path: explore.rows
class _Translations$explore$rows$ja extends Translations$explore$rows$en {
	_Translations$explore$rows$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'ウォッチリスト';
	@override String get recommendedMovies => 'おすすめの映画';
	@override String get recommendedShows => 'おすすめのテレビ番組';
	@override String get trendingMovies => 'トレンドの映画';
	@override String get trendingShows => 'トレンドのテレビ番組';
	@override String get popularMovies => '人気の映画';
	@override String get popularShows => '人気のテレビ番組';
	@override String get trendingAnime => 'トレンドのアニメ';
	@override String get suggestedAnime => 'おすすめのアニメ';
	@override String get airingAnime => '放送中の注目アニメ';
	@override String get popularAnime => '人気のアニメ';
	@override String get trending => 'トレンド';
	@override String get upcomingMovies => '近日公開の映画';
	@override String get upcomingShows => '放送予定の番組';
}

// Path: explore.status
class _Translations$explore$status$ja extends Translations$explore$status$en {
	_Translations$explore$status$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get airing => '放送中';
	@override String get ended => '放送終了';
	@override String get canceled => '打ち切り';
	@override String get upcoming => '放送予定';
}

// Path: explore.badge
class _Translations$explore$badge$ja extends Translations$explore$badge$en {
	_Translations$explore$badge$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '人気 #${n}';
	@override String rankAiring({required Object n}) => '放送中 #${n}';
	@override String rankRated({required Object n}) => '評価 #${n}';
	@override String rankTrending({required Object n}) => '急上昇 #${n}';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n}（${season}）';
	@override String watchingNow({required Object n}) => '${n}人視聴中';
	@override String get available => '視聴可能';
	@override String get partiallyAvailable => '一部視聴可能';
	@override String get availableIn4k => '4K対応';
	@override String get requested => 'リクエスト済み';
	@override String get pendingApproval => '承認待ち';
	@override String get processing => '処理中';
	@override String get declined => '却下';
	@override String get requestFailed => 'リクエスト失敗';
	@override String get requested4k => '4Kリクエスト済み';
	@override String seasonsAvailable({required Object available, required Object total}) => 'シーズン ${available}/${total}';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'エピソード${episode} あと${duration}';
	@override String nextAiringIn({required Object duration}) => '次回 あと${duration}';
	@override String episodesShort({required Object n}) => '${n}話';
	@override String minutesPerEpisode({required Object n}) => '${n}分/話';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$ja extends Translations$explore$stats$en {
	_Translations$explore$stats$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '登録者 ${n}人';
	@override String viewersDay({required Object n}) => '本日${n}人が視聴';
	@override String viewersWeek({required Object n}) => '今週${n}人が視聴';
	@override String viewersMonth({required Object n}) => '今月${n}人が視聴';
	@override String viewersYear({required Object n}) => '今年${n}人が視聴';
	@override String viewersAllTime({required Object n}) => '累計視聴者${n}人';
	@override String planning({required Object n}) => '${n}人が視聴予定';
	@override String favorited({required Object n}) => 'お気に入り ${n}件';
	@override String dropRate({required Object percent}) => '${percent}が視聴中止';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: 'コメント ${n}件',
	);
	@override String votes({required Object n}) => '投票 ${n}件';
	@override String watching({required Object n}) => '${n}人が視聴中';
	@override String completed({required Object n}) => '${n}人が視聴済み';
	@override String onHold({required Object n}) => '${n}人が保留中';
	@override String dropped({required Object n}) => '${n}人が視聴中止';
}

// Path: explore.season
class _Translations$explore$season$ja extends Translations$explore$season$en {
	_Translations$explore$season$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get winter => '冬';
	@override String get spring => '春';
	@override String get summer => '夏';
	@override String get fall => '秋';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$ja extends Translations$explore$format$en {
	_Translations$explore$format$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV短編';
	@override String get movie => '映画';
	@override String get special => 'スペシャル';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => '音楽';
	@override String get other => 'その他';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$ja extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get original => 'オリジナル';
	@override String get manga => '漫画';
	@override String get lightNovel => 'ライトノベル';
	@override String get novel => '小説';
	@override String get visualNovel => 'ビジュアルノベル';
	@override String get game => 'ゲーム';
	@override String get webComic => 'Web漫画';
	@override String get musicRelease => '音楽';
	@override String get otherMedia => 'その他';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$ja extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get director => '監督';
	@override String get writer => '脚本';
	@override String get producer => 'プロデューサー';
	@override String get creator => '原作者';
	@override String get composer => '作曲家';
}

// Path: explore.relation
class _Translations$explore$relation$ja extends Translations$explore$relation$en {
	_Translations$explore$relation$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get prequel => '前日譚';
	@override String get sequel => '続編';
	@override String get sideStory => 'サイドストーリー';
	@override String get spinOff => 'スピンオフ';
	@override String get alternativeVersion => '別バージョン';
	@override String get summary => '総集編';
	@override String get parentStory => '親作品';
	@override String get adaptation => '原作';
	@override String get other => '関連作品';
}

// Path: explore.detail
class _Translations$explore$detail$ja extends Translations$explore$detail$en {
	_Translations$explore$detail$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => '原題';
	@override String get alsoKnownAs => '別名';
	@override String get studios => '制作会社';
	@override String get country => '国';
	@override String get language => '言語';
	@override String get released => '公開日';
	@override String get physicalRelease => 'ディスク発売';
	@override String get ended => '放送終了';
	@override String addedOn({required Object date}) => '${date}に追加';
	@override String get yourRating => 'あなたの評価';
	@override String get budget => '制作費';
	@override String get revenue => '興行収入';
	@override String get contentAdvisory => '年齢区分';
	@override String get tags => 'タグ';
	@override String get revealSpoilerTags => 'ネタバレタグを表示';
	@override String get links => 'リンク';
	@override String get watchOn => '視聴先';
	@override String get watchTrailer => '予告編を見る';
	@override String openOn({required Object site}) => '${site}で開く';
	@override String get crew => 'スタッフ';
	@override String get ratings => '評価';
	@override String get schedule => '放送予定';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n}人のユーザーがおすすめ',
	);
	@override String recommendedBy({required Object who}) => '${who}がおすすめ';
	@override String favoritedBy({required Object who}) => '${who}がお気に入り登録';
	@override String unairedEpisodes({required Object n}) => '未放送 ${n}話';
	@override String recommendedByPercent({required Object percent}) => '視聴者の${percent}がおすすめ';
	@override String get relatedTitles => '関連作品';
	@override String get background => '背景';
}

// Path: music.discography
class _Translations$music$discography$ja extends Translations$music$discography$en {
	_Translations$music$discography$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'シングル・EP';
	@override String get live => 'ライブ';
	@override String get compilations => 'コンピレーション';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$ja extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'アプリの画面を離れると、ダウンロードが停止します';
	@override String get bannerDegraded => 'バックグラウンドダウンロードが制限される場合があります';
	@override String get bannerAction => '詳細';
	@override String get sheetTitle => 'バックグラウンドダウンロードはブロックされています';
	@override String get sheetTitleDegraded => 'バックグラウンドダウンロードが制限される場合があります';
	@override String get sheetIntro => 'Androidにより、Plezyはバックグラウンドで安定してダウンロードできません。';
	@override String get sheetIntroDegraded => '端末により、Plezyがバックグラウンドでダウンロードできるタイミングが制限されています。';
	@override String get reasonBackgroundRestricted => 'Plezyのバックグラウンド使用が制限されています。バッテリー使用量またはバックグラウンド使用を「制限なし」に設定してください。';
	@override String get reasonStandbyRestricted => 'Androidにより、Plezyが制限付きのスタンバイ状態に設定されています。バッテリー使用量を「制限なし」に設定してください。';
	@override String get reasonDownloadChannelBlocked => 'ダウンロード通知がオフのため、進行状況や操作ボタンを利用できない場合があります。';
	@override String get reasonNotificationsDisabled => '通知がオフです。Android 13以降では、長時間のバックグラウンドダウンロードに通知が必要です。';
	@override String get reasonDataSaver => 'データセーバーがオンのため、モバイルデータ通信ではバックグラウンドダウンロードがブロックされます。Wi-Fiでは引き続きダウンロードできるはずです。';
	@override String get reasonOemUnknown => 'Plezyがバックグラウンドで動作中に、ダウンロードが繰り返し停止しました。Plezyのバッテリー使用量またはバックグラウンド使用の設定を確認してください。';
	@override String get openSettings => '設定を開く';
	@override String get stillNotWorking => '端末別のヘルプ';
	@override String get stillNotWorkingDescription => 'お使いの端末向けの手順を確認してください。問題が続く場合は、設定 › ログを表示 からログを送信してください。';
	@override String get dialogTitle => 'ダウンロードが完了しない可能性があります';
	@override String get dialogDownloadAnyway => 'このままダウンロード';
	@override String get dialogFixFirst => '先に設定を修正';
	@override String get statusTile => 'バックグラウンドダウンロード';
	@override String get statusOk => 'バックグラウンドで実行可能';
	@override String get statusBlocked => 'システム設定によりブロック';
	@override String get statusDegraded => 'システム設定により制限';
	@override String get statusUnknown => '未確認';
	@override String get settingsUnavailable => 'この端末ではシステム設定を開けませんでした';
	@override String get linkUnavailable => 'この端末ではdontkillmyapp.comを開けませんでした';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$ja extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'リモートサーバーを起動中…';
	@override String get hostAddress => 'ホストアドレス';
	@override String get connected => '接続済み';
	@override String get serverRunning => 'リモートサーバー稼働中';
	@override String get serverStopped => 'リモートサーバー停止';
	@override String get serverRunningDescription => 'ネットワーク上のモバイルデバイスがこのアプリに接続できます';
	@override String get serverStoppedDescription => 'モバイルデバイスの接続を許可するにはサーバーを起動してください';
	@override String get usePhoneToControl => 'モバイルデバイスでこのアプリを操作できます';
	@override String get startServer => 'サーバーを起動';
	@override String get stopServer => 'サーバーを停止';
	@override String get minimize => '最小化';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$ja extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '同じPlexアカウントを使用しているPlezyデバイスがここに表示されます';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '接続中…';
	@override String get searchingForDevices => 'デバイスを検索中…';
	@override String get noDevicesFound => 'ネットワーク上にデバイスが見つかりません';
	@override String get noDevicesHint => 'デスクトップでPlezyを開き、同じWi-Fiネットワークに接続してください';
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
class _Translations$companionRemote$remote$ja extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'リモートセッションを切断しますか？';
	@override String get reconnecting => '再接続中…';
	@override String attemptOf({required Object current}) => '試行 ${current}/5';
	@override String get retryNow => '今すぐ再試行';
	@override String get tabRemote => 'リモコン';
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
	@override String get searchHint => 'デスクトップで検索…';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$ja extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
class _Translations$services$names$ja extends Translations$services$names$en {
	_Translations$services$names$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$ja extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} で Plezy を有効化';
	@override String get instructions => 'QRコードをスキャンするか、以下のアドレスにアクセスしてこのコードを入力してください:';
	@override String openToActivate({required Object service}) => '${service} を開いて有効化';
	@override String get copyCode => 'アクティベーションコードをコピー';
	@override String get waitingForAuthorization => '認証を待っています…';
	@override String get codeCopied => 'コードをコピーしました';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$ja extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} にサインイン';
	@override String get body => 'このQRコードをスキャンするか、任意のデバイスでURLを開いてください。';
	@override String openToSignIn({required Object service}) => '${service} を開いてサインイン';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$ja extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'サインインURLをコピー';
	@override String get urlCopied => 'URLをコピーしました';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$ja extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$ja._(TranslationsJa root) : this._root = root, super.internal(root);

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
			'auth.waitingForAuth' => '認証を待っています…\nブラウザでサインインしてください。',
			'auth.useBrowser' => 'ブラウザを使用',
			'auth.or' => 'または',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}に接続',
			'auth.useQuickConnect' => 'Quick Connect を使う',
			'auth.quickConnectInstructions' => 'JellyfinでQuick Connectを開き、このコードを入力してください。',
			'auth.quickConnectWaiting' => '承認を待っています…',
			'auth.quickConnectCancel' => 'キャンセル',
			'auth.quickConnectExpired' => 'Quick Connectの有効期限が切れました。もう一度お試しください。',
			'auth.localDataRecoveryRequired' => 'ローカルのサインイン情報と保留中の再生データを安全に復元できませんでした。もう一度サインインしてください。',
			'auth.pinCheckRejected' => 'Plex PINの確認が拒否されました',
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
			'common.addTo' => '追加先…',
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
			'common.checkingNetwork' => 'ネットワークを確認中…',
			'common.loadingServers' => 'サーバーを読み込み中…',
			'common.connectingToServers' => 'サーバーに接続中…',
			'common.startingOfflineMode' => 'オフラインモードを開始中…',
			'common.loading' => '読み込み中…',
			'common.fullscreen' => 'フルスクリーン',
			'common.exitFullscreen' => 'フルスクリーンを終了',
			'common.pressBackAgainToExit' => 'もう一度押すと終了します',
			'common.ratingSource.critic' => '批評家',
			'common.ratingSource.audience' => '観客',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes 批評家',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes 観客',
			'common.notAvailable' => 'N/A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
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
			'settings.supportDeveloper' => 'Plezyを支援',
			'settings.supportDeveloperDescription' => 'Liberapayで寄付して開発を支援',
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
			'settings.displayScale' => '表示スケール',
			'settings.compact' => 'コンパクト',
			'settings.comfortable' => 'ゆったり',
			'settings.tvCornerSpotlightBackdrop' => '画面隅の注目コンテンツ背景',
			'settings.tvCornerSpotlightBackdropDescription' => '画面全体ではなく、右上隅に注目コンテンツのアートワークを表示します',
			'settings.viewMode' => '表示モード',
			'settings.gridView' => 'グリッド',
			'settings.listView' => 'リスト',
			'settings.showHeroSection' => '注目コンテンツを表示',
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
			'settings.alwaysKeepSidebarOpenDescription' => 'サイドバーを展開したままにし、コンテンツ領域を幅に合わせて調整します',
			'settings.showUnwatchedCount' => '未視聴数を表示',
			'settings.showUnwatchedCountDescription' => '番組とシーズンに未視聴エピソード数を表示',
			'settings.showEpisodeNumberOnCards' => 'カードにエピソード番号を表示',
			'settings.showEpisodeNumberOnCardsDescription' => 'エピソードカードにシーズン番号とエピソード番号を表示します',
			'settings.showSeasonPostersOnTabs' => 'タブにシーズンポスターを表示',
			'settings.showSeasonPostersOnTabsDescription' => '各シーズンのポスターをタブの上に表示します',
			'settings.tvFullCardLayout' => 'フルTVカード',
			'settings.tvFullCardLayoutDescription' => 'TVカードを画像のみで表示し、出演者名を重ねて表示します',
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
			'settings.playbackBuffer' => '再生バッファー',
			'settings.playbackBufferAuto' => '自動（推奨）',
			'settings.playbackBufferLarge' => '大',
			'settings.playbackBufferExtraLarge' => '特大',
			'settings.playbackBufferDescription' => '不安定な接続に備えてより多くのバッファーを使用します。バッファーサイズによっても制限されます。',
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
			'settings.followServerTrackSelections' => 'サーバーのエピソードごとのトラック選択を使用',
			'settings.followServerTrackSelectionsDescription' => 'エピソード切り替え時に、現在の選択を引き継ぐ代わりにサーバーで選択された音声と字幕を適用します',
			'settings.showChapterMarkersOnTimeline' => 'シークバーにチャプターマーカーを表示',
			'settings.showChapterMarkersOnTimelineDescription' => 'チャプターの境界でシークバーを区切る',
			'settings.specialsOrdering' => 'エピソード順にスペシャルを表示',
			'settings.specialsOrderingDescription' => 'シリーズの視聴順でスペシャルを再生する位置',
			'settings.specialsOrderingServer' => 'サーバーの順序に従う',
			'settings.specialsOrderingAirDate' => '放送日順に挿入',
			'settings.specialsOrderingLast' => '通常シーズンの後',
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
			'settings.watchTogetherRelayInvalid' => '有効なHTTPまたはHTTPSのリレーサーバーURLを入力してください。',
			'settings.crashReporting' => 'クラッシュレポート',
			'settings.crashReportingDescription' => 'アプリの改善に役立つクラッシュレポートを送信',
			'settings.debugLogging' => 'デバッグログ',
			'settings.debugLoggingDescription' => 'トラブルシューティング用の詳細なログを有効化',
			'settings.viewLogs' => 'ログを表示',
			'settings.viewLogsDescription' => 'アプリケーションログを表示',
			'settings.clearImageCache' => '画像キャッシュをクリア',
			'settings.clearImageCacheDescription' => 'キャッシュされたアートワークとサムネイルをクリアします。再度ダウンロードされるまで画像の読み込みが遅くなる場合があります。',
			'settings.clearImageCacheSuccess' => '画像キャッシュを正常にクリアしました',
			'settings.resetSettings' => '設定をリセット',
			'settings.resetSettingsDescription' => '設定を既定に戻します。元に戻せません。',
			'settings.resetSettingsSuccess' => '設定を正常にリセットしました',
			'settings.backup' => 'バックアップ',
			'settings.exportSettings' => '設定をエクスポート',
			'settings.exportSettingsDescription' => '設定をファイルに保存',
			'settings.exportSettingsSuccess' => '設定をエクスポートしました',
			'settings.importSettings' => '設定をインポート',
			'settings.importSettingsDescription' => 'ファイルから設定を復元',
			'settings.importSettingsConfirm' => '現在の設定を置き換えます。続行しますか？',
			'settings.importSettingsSuccess' => '設定をインポートしました',
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
			'settings.saveFailed' => '変更を保存できませんでした。もう一度お試しください。',
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
			'settings.downloadLocationPickerUnavailable' => 'このデバイスではフォルダを選択できません',
			'settings.downloadOnWifiOnly' => 'Wi-Fi接続時のみダウンロード',
			'settings.downloadOnWifiOnlyDescription' => 'モバイルデータ通信中のダウンロードを防ぎます',
			'settings.autoRemoveWatchedDownloads' => '視聴済みダウンロードの自動削除',
			'settings.autoRemoveWatchedDownloadsDescription' => '視聴済みのダウンロードを自動削除します',
			'settings.cellularDownloadBlocked' => 'モバイルデータ通信中はダウンロードできません。Wi-Fiを使用するか、設定を変更してください。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '静かなメディアに対して100%以上の音量ブーストを許可',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discordで視聴中の内容を表示',
			'settings.services' => 'サービス',
			'settings.servicesDescription' => 'Trakt、MyAnimeList、Seerrなどを接続',
			'settings.manageLibrariesDescription' => 'ライブラリを並べ替えたり非表示にしたりできます',
			'settings.companionRemoteServer' => 'コンパニオンリモートサーバー',
			'settings.companionRemoteServerDescription' => 'ネットワーク上のモバイルデバイスからこのアプリを操作できるようにする',
			'settings.autoPip' => '自動ピクチャーインピクチャー',
			'settings.autoPipDescription' => '再生中にアプリを離れると、自動的にピクチャーインピクチャーに切り替えます',
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
			'settings.audioPassthroughDescriptionAppleTv' => 'Dolby Atmosを含むDolby Digital PlusにはApple標準のDolbyデコーダーを使用します。DTSとTrueHDは引き続きマルチチャンネルPCMで再生されます。音が出ない場合は無効にしてください。',
			'settings.audioDownmix' => 'ステレオにダウンミックス',
			'settings.audioDownmixDescription' => 'サラウンド音声をステレオスピーカーやヘッドホン用に2チャンネルへミックスします',
			'settings.downmixCenterBoost' => 'センターチャンネルブースト',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'ブースト (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'ダウンミックス時の音量正規化',
			'settings.audioDownmixNormalizeDescription' => 'クリッピングを防ぐためにミックス音量を下げます。オフにすると元の音量を維持します（大音量シーンで歪む場合があります）。',
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
			'settings.showNavBarLabels' => 'ナビゲーションバーのラベルを表示',
			'settings.showNavBarLabelsDescription' => 'ナビゲーションバーのアイコンの下にテキストラベルを表示',
			'settings.startupSection' => '起動時のセクション',
			'settings.showExploreTab' => '「探す」タブを表示',
			'settings.showExploreTabDescription' => 'Plex Discoverと接続済みのトラッカーのコンテンツを「探す」タブに表示します',
			'settings.liveTvDefaultFavorites' => 'お気に入りチャンネルをデフォルトに',
			'settings.liveTvDefaultFavoritesDescription' => 'ライブTVを開いたときにお気に入りチャンネルのみ表示',
			'settings.display' => 'ディスプレイ',
			'settings.homeScreen' => 'ホーム画面',
			'settings.navigation' => 'ナビゲーション',
			'settings.window' => 'ウィンドウ',
			'settings.content' => 'コンテンツ',
			'settings.player' => 'プレーヤー',
			'settings.subtitlesAndConfig' => '字幕と設定',
			'settings.seekAndTiming' => 'シークとタイミング',
			'settings.behavior' => '動作',
			'settings.rememberPlayerChanges' => 'プレーヤーの変更を記憶',
			'settings.rememberPlayerChangesDescription' => '再生中に行った変更を保存し、再適用する場所',
			'settings.scopePlaybackSpeed' => '再生速度',
			'settings.scopeShaderPreset' => 'シェーダープリセット',
			'settings.scopeAspectRatio' => 'アスペクト比',
			'settings.scopeSyncOffsets' => '音声と字幕の同期',
			'settings.playerScopeOff' => '保存しない',
			'settings.playerScopeGlobal' => 'すべて',
			'settings.playerScopeLibrary' => 'ライブラリごと',
			'settings.playerScopeTitle' => '作品ごと',
			'settings.exportDialogTitle' => 'Plezyの設定をエクスポート',
			'search.hint' => '映画、番組、音楽を検索…',
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
			'hotkeys.actions.seekForward' => ({required Object seconds}) => '早送り（${seconds}秒）',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => '巻き戻し（${seconds}秒）',
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
			'fileInfo.overview' => '概要',
			'fileInfo.video' => '映像',
			'fileInfo.audio' => '音声',
			'fileInfo.subtitles' => '字幕',
			'fileInfo.images' => '埋め込み画像',
			'fileInfo.dataStreams' => 'データストリーム',
			'fileInfo.lyrics' => '歌詞',
			'fileInfo.file' => 'ファイル',
			'fileInfo.attachments' => '添付ファイル',
			'fileInfo.delivery' => '配信',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'バージョン ${index} / ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'ファイル ${index} / ${count}',
			'fileInfo.noStreams' => 'サーバーはこのファイルにストリームがないと報告しました。',
			'fileInfo.copyPath' => 'パスをコピー',
			'fileInfo.pathCopied' => 'ファイルパスをコピーしました',
			'fileInfo.codec' => 'コーデック',
			'fileInfo.codecTag' => 'コーデックタグ',
			'fileInfo.resolution' => '解像度',
			'fileInfo.codedResolution' => '符号化解像度',
			'fileInfo.bitrate' => 'ビットレート',
			'fileInfo.frameRate' => 'フレームレート',
			'fileInfo.rotation' => '回転',
			'fileInfo.comment' => 'コメント',
			'fileInfo.audioDescription' => '音声解説',
			'fileInfo.headerCompression' => 'ヘッダー圧縮',
			'fileInfo.sidecarFile' => 'サイドカーファイル',
			'fileInfo.transportTimestamp' => 'トランスポートタイムスタンプ',
			'fileInfo.displayOffset' => '表示オフセット',
			'fileInfo.previewFailureCode' => 'プレビュー失敗コード',
			'fileInfo.previewRetries' => 'プレビュー再試行回数',
			'fileInfo.aspectRatio' => 'アスペクト比',
			'fileInfo.pixelAspectRatio' => 'ピクセルアスペクト比',
			'fileInfo.profile' => 'プロファイル',
			'fileInfo.level' => 'レベル',
			'fileInfo.bitDepth' => 'ビット深度',
			'fileInfo.pixelFormat' => 'ピクセルフォーマット',
			'fileInfo.colorSpace' => '色空間',
			'fileInfo.colorRange' => '色範囲',
			'fileInfo.colorPrimaries' => '色原色',
			'fileInfo.colorTransfer' => 'カラートランスファー',
			'fileInfo.chromaSubsampling' => 'クロマサブサンプリング',
			'fileInfo.chromaLocation' => 'クロマ位置',
			'fileInfo.scanType' => 'スキャンタイプ',
			'fileInfo.interlaced' => 'インターレース',
			'fileInfo.anamorphic' => 'アナモルフィック',
			'fileInfo.referenceFrames' => '参照フレーム数',
			'fileInfo.dynamicRange' => 'ダイナミックレンジ',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision レベル',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision バージョン',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision レイヤー',
			'fileInfo.baseLayerCompatibility' => 'ベースレイヤー互換性',
			'fileInfo.avcBitstream' => 'AVC ビットストリーム',
			'fileInfo.nalLengthSize' => 'NAL 長さサイズ',
			'fileInfo.scalingMatrix' => 'カスタムスケーリングマトリックス',
			'fileInfo.streamIdentifier' => 'ストリーム識別子',
			'fileInfo.streamIndex' => 'ストリームインデックス',
			'fileInfo.streamId' => 'ストリーム ID',
			'fileInfo.language' => '言語',
			'fileInfo.languageCode' => '言語コード',
			'fileInfo.streamTitle' => 'トラックタイトル',
			'fileInfo.channels' => 'チャンネル',
			'fileInfo.sampleRate' => 'サンプルレート',
			'fileInfo.spatialAudio' => '空間オーディオ',
			'fileInfo.textBased' => 'テキストベース',
			'fileInfo.subtitleFormat' => 'サイドカーフォーマット',
			'fileInfo.provider' => 'プロバイダー',
			'fileInfo.matchScore' => '一致スコア',
			'fileInfo.externalDelivery' => '個別に配信可能',
			'fileInfo.sidecarPath' => 'サイドカーパス',
			'fileInfo.sourceStream' => 'コピー元',
			'fileInfo.temporary' => '一時的',
			'fileInfo.timeBase' => 'タイムベース',
			'fileInfo.overallBitrate' => '全体ビットレート',
			'fileInfo.path' => 'パス',
			'fileInfo.fileName' => 'ファイル名',
			'fileInfo.size' => 'サイズ',
			'fileInfo.totalSize' => '合計サイズ',
			'fileInfo.container' => 'コンテナ',
			'fileInfo.duration' => '長さ',
			'fileInfo.previewThumbnails' => 'プレビューサムネイル',
			'fileInfo.previewIndex' => 'プレビューインデックス',
			'fileInfo.packetLength' => 'パケット長',
			'fileInfo.filePresent' => 'ファイルあり',
			'fileInfo.fileReadable' => 'サーバーから読み取り可能',
			'fileInfo.streamPath' => 'ストリームパス',
			'fileInfo.optimizedForStreaming' => 'ストリーミング最適化',
			'fileInfo.has64bitOffsets' => '64ビットオフセット',
			'fileInfo.protocol' => 'プロトコル',
			'fileInfo.mediaType' => 'メディアタイプ',
			'fileInfo.sourceKind' => 'ソース種別',
			'fileInfo.optimizedVersion' => '最適化バージョン',
			'fileInfo.optimizationTarget' => '最適化ターゲット',
			'fileInfo.deletedAt' => '削除済み',
			'fileInfo.remoteSource' => 'リモートソース',
			'fileInfo.infiniteStream' => '無限ストリーム',
			'fileInfo.directPlay' => 'ダイレクト再生',
			'fileInfo.directStream' => 'ダイレクトストリーム',
			'fileInfo.transcoding' => 'トランスコード',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'バージョン ID',
			'fileInfo.fileId' => 'ファイル ID',
			'fileInfo.defaultAudioTrack' => 'デフォルト音声トラック',
			'fileInfo.defaultSubtitleTrack' => 'デフォルト字幕トラック',
			'fileInfo.subtitlesOff' => 'オフ',
			'fileInfo.flagDefault' => 'デフォルト',
			'fileInfo.flagForced' => '強制',
			'fileInfo.flagSelected' => '選択済み',
			'fileInfo.flagExternal' => '外部',
			'fileInfo.flagHearingImpaired' => '聴覚障害者向け',
			'fileInfo.flagDub' => '吹替',
			'fileInfo.flagOriginal' => 'オリジナル',
			'fileInfo.channelsMono' => 'モノラル',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'プロファイル${profile}',
			'mediaMenu.markAsWatched' => '視聴済みにする',
			'mediaMenu.markAsUnwatched' => '未視聴にする',
			'mediaMenu.removeFromContinueWatching' => '視聴中から削除',
			'mediaMenu.viewDetails' => '詳細を表示',
			'mediaMenu.goToSeries' => 'シリーズへ移動',
			'mediaMenu.shufflePlay' => 'シャッフル再生',
			'mediaMenu.shuffleNotAvailableOffline' => 'オフラインではシャッフルを利用できません',
			'mediaMenu.fileInfo' => 'ファイル情報',
			'mediaMenu.deleteEpisodeFromServer' => 'サーバーからエピソードを削除',
			'mediaMenu.deleteSeasonFromServer' => 'サーバーからシーズンを削除',
			'mediaMenu.deleteShowFromServer' => 'サーバーから番組を削除',
			'mediaMenu.deleteMovieFromServer' => 'サーバーから映画を削除',
			'mediaMenu.deleteEpisodeTitle' => 'このエピソードを削除しますか？',
			'mediaMenu.deleteSeasonTitle' => 'このシーズンを削除しますか？',
			'mediaMenu.deleteShowTitle' => 'この番組を削除しますか？',
			'mediaMenu.deleteMovieTitle' => 'この映画を削除しますか？',
			'mediaMenu.deleteEpisodeConfirm' => 'エピソードを削除',
			'mediaMenu.deleteSeasonConfirm' => 'シーズンを削除',
			_ => null,
		} ?? switch (path) {
			'mediaMenu.deleteShowConfirm' => '番組を削除',
			'mediaMenu.deleteMovieConfirm' => '映画を削除',
			'mediaMenu.deleteAnyway' => 'それでも削除',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'サーバーから「${title}」を完全に削除しますか？',
			'mediaMenu.deleteMultipleWarning' => 'すべてのエピソードとそのファイルが含まれます。',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '中の全${n}エピソードとそのファイルが削除されます。', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: 'このアイテムは${n}個のファイルにまたがって保存されており、すべて削除されます。', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '同じファイルに保存されている他の${n}エピソードも削除されます：', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezyは削除対象のファイルを確認できなかったため、上記のアイテム以上に削除される可能性があります。キャンセルして再試行するか、それでも削除してください。',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'サーバーがこのアイテムのファイル情報を提供しなかったため、Plezyは削除対象のファイルを確認できません。上記のアイテム以上に削除される可能性があります。',
			'mediaMenu.mediaDeletedSuccessfully' => 'メディアアイテムを正常に削除しました',
			'mediaMenu.mediaFailedToDelete' => 'メディアアイテムの削除に失敗しました',
			'mediaMenu.rate' => '評価',
			'mediaMenu.playFromBeginning' => '最初から再生',
			'mediaMenu.playVersion' => 'バージョンを選んで再生…',
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
			'accessibility.alphabetNavigation' => 'アルファベットナビゲーション',
			'accessibility.alphabetScrollHint' => '上下にスワイプして文字ごとに移動',
			'accessibility.rowColumnPosition' => ({required Object rowCount, required Object row, required Object columnCount, required Object column}) => '${rowCount}行中${row}行、${columnCount}列中${column}列',
			'accessibility.rowPosition' => ({required Object rowCount, required Object row}) => '${rowCount}行中${row}行',
			'accessibility.autoScrollPlay' => '自動スクロールを再生',
			'accessibility.autoScrollPause' => '自動スクロールを一時停止',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'tooltips.shufflePlay' => 'シャッフル再生',
			'tooltips.playTrailer' => '予告編を再生',
			'tooltips.markAsWatched' => '視聴済みにする',
			'tooltips.markAsUnwatched' => '未視聴にする',
			'audioTracks.track' => ({required Object n}) => '音声トラック${n}',
			'videoControls.audioLabel' => '音声',
			'videoControls.subtitlesLabel' => '字幕',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
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
			'videoControls.playbackPaused' => '一時停止中',
			'videoControls.playbackResumed' => '再生中',
			'videoControls.loadingVideo' => '動画を読み込み中',
			'videoControls.showPlaybackControls' => '再生コントロールを表示',
			'videoControls.hidePlaybackControls' => '再生コントロールを非表示',
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
			'videoControls.subtitleUnavailableFallback' => '選択した字幕を読み込めませんでした — 字幕なしで再生を続けます',
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
			'videoControls.noAudioDevicesAvailable' => 'オーディオデバイスがありません',
			'videoControls.searchSubtitles' => '字幕を検索',
			'videoControls.language' => '言語',
			'videoControls.noSubtitlesFound' => '字幕が見つかりません',
			'videoControls.subtitleDownloaded' => '字幕をダウンロードしました',
			'videoControls.subtitleDownloadedNotApplied' => '字幕はダウンロードされましたが、選択できませんでした',
			'videoControls.subtitleDownloadFailed' => '字幕のダウンロードに失敗しました',
			'videoControls.searchLanguages' => '言語を検索…',
			'videoControls.skipIntro' => 'イントロをスキップ',
			'videoControls.skipCredits' => 'クレジットをスキップ',
			'videoControls.nextEpisode' => '次のエピソード',
			'videoControls.subtitleTrack' => ({required Object n}) => 'トラック${n}',
			'videoControls.subtitleFile' => ({required Object name}) => '字幕${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label}（強制）',
			'videoControls.osdSubtitlesOff' => '字幕: オフ',
			'videoControls.osdSubtitles' => ({required Object track}) => '字幕: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => '音声: ${track}',
			'messages.markedAsWatched' => '視聴済みにしました',
			'messages.markedAsUnwatched' => '未視聴にしました',
			'messages.markedAsWatchedOffline' => '視聴済みにしました（オンライン時に同期）',
			'messages.markedAsUnwatchedOffline' => '未視聴にしました（オンライン時に同期）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '自動削除: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '視聴済みダウンロードを${n}件自動削除しました', ), 
			'messages.removedFromContinueWatching' => '視聴中から削除しました',
			'messages.errorLoading' => ({required Object error}) => 'エラー: ${error}',
			'messages.searchPartialResults' => '一部のメディアサーバーを検索できませんでした。利用可能な結果を表示しています。',
			'messages.streamInterrupted' => 'ストリームが中断されました。再生を押すかシークして再試行してください。',
			'messages.liveStreamInterrupted' => 'ライブストリームが中断されました。再生を押して再試行してください。',
			'messages.fileInfoNotAvailable' => 'ファイル情報が利用できません',
			'messages.playbackAuthenticationRequired' => 'このアイテムを再生するには、メディアサーバーにもう一度サインインしてください。',
			'messages.playbackServerUnavailable' => 'メディアサーバーを利用できません。しばらくしてからもう一度お試しください。',
			'messages.playbackDataInvalid' => 'サーバーから無効な再生情報が返されました。',
			'messages.playbackCancelled' => '再生がキャンセルされました。',
			'messages.playbackFailed' => '再生を開始できませんでした。',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'ファイル情報の読み込みエラー: ${error}',
			'messages.errorLoadingSeries' => 'シリーズの読み込みエラー',
			'messages.musicNotSupported' => '音楽の再生はまだサポートされていません',
			'messages.noDescriptionAvailable' => '説明はありません',
			'messages.noProfilesAvailable' => '利用可能なプロフィールがありません',
			'messages.contactAdminForProfiles' => 'プロフィールを追加するには、サーバー管理者に連絡してください',
			'messages.unableToDetermineLibrarySection' => 'このアイテムのライブラリセクションを判別できません',
			'messages.logsCleared' => 'ログをクリアしました',
			'messages.logsCopied' => 'ログをクリップボードにコピーしました',
			'messages.noLogsAvailable' => 'ログがありません',
			'messages.libraryScanning' => ({required Object title}) => '「${title}」をスキャン中…',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}"のライブラリスキャンを開始しました',
			'messages.libraryScanFailed' => ({required Object error}) => 'ライブラリのスキャンに失敗しました: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '「${title}」のメタデータを更新中…',
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
			'messages.failedToCreatePlayQueueNoItems' => '再生キューを作成できませんでした — アイテムがありません',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action}に失敗しました: ${error}',
			'messages.switchingToCompatiblePlayer' => '互換性のあるプレーヤーに切り替え中…',
			'messages.serverLimitTitle' => '再生に失敗しました',
			'messages.serverLimitBody' => 'サーバーエラー（HTTP 500）。帯域幅/トランスコード制限により拒否された可能性があります。所有者に調整を依頼してください。',
			'messages.mediaUnreadableTitle' => 'ファイルを利用できません',
			'messages.mediaUnreadableBody' => 'サーバーはこのアイテムを見つけましたが、そのファイルを読み取れませんでした（HTTP 404）。ファイルが移動・削除されたか、ストレージがオフラインの可能性があります。サーバーの管理者にファイルの確認とライブラリの再スキャンを依頼してください。',
			'messages.serverBusyTitle' => 'ストリームを利用できません',
			'messages.serverBusyBody' => 'サーバーがこのファイルのストリーミングを繰り返し拒否しました（HTTP 503）。サーバーが再起動中またはビジー状態か、ファイルのストレージがオフラインの可能性があります。しばらくしてからもう一度お試しください。問題が続く場合は、サーバーの所有者にサーバーとファイルのストレージを確認するよう依頼してください。',
			'messages.logsUploaded' => 'ログをアップロードしました',
			'messages.logsUploadFailed' => 'ログのアップロードに失敗しました',
			'messages.logId' => 'ログID',
			'messages.burnedSubtitlesUseMenu' => '字幕はこのストリームに焼き付けられています。字幕メニューから変更してください。',
			'messages.noVideoUrl' => '利用可能な動画URLがありません',
			'messages.playbackNoMediaSources' => 'サーバーから再生可能なメディアソースが返されませんでした',
			'messages.playbackDataNotPrepared' => '再生データの準備が完了する前に再生が開始されました',
			'messages.streamSelectionUnavailable' => 'このソースではストリームを選択できません',
			'messages.streamSelectionFailed' => '選択したストリームを適用できませんでした',
			'messages.serverUnavailableForProfile' => '現在のプロフィールで利用可能なサーバーがありません',
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
			'subtitlingStyling.anchorToScreen' => '画面に固定',
			'subtitlingStyling.anchorToScreenDescription' => 'ワイドスクリーン映像の下にある黒帯にテキスト字幕を表示します',
			'subtitlingStyling.bold' => '太字',
			'subtitlingStyling.italic' => '斜体',
			'subtitlingStyling.renderResolution' => 'レンダリング解像度',
			'subtitlingStyling.renderResolutionScreen' => '画面解像度',
			'subtitlingStyling.renderResolutionVideo' => '動画解像度',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => '高度な動画プレーヤー設定',
			'mpvConfig.presets' => 'プリセット',
			'mpvConfig.noPresets' => '保存済みプリセットがありません',
			'mpvConfig.saveAsPreset' => 'プリセットとして保存…',
			'mpvConfig.presetName' => 'プリセット名',
			'mpvConfig.presetNameHint' => 'プリセットの名前を入力',
			'mpvConfig.loadPreset' => '読み込み',
			'mpvConfig.deletePreset' => '削除',
			'mpvConfig.presetSaved' => 'プリセットを保存しました',
			'mpvConfig.presetLoaded' => 'プリセットを読み込みました',
			'mpvConfig.presetDeleted' => 'プリセットを削除しました',
			'mpvConfig.confirmDeletePreset' => 'このプリセットを削除してもよろしいですか？',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.embeddedVoHint' => 'Linux では vo、gpu-context、gpu-api は無視されます。埋め込み動画は常にビデオプレーン上で vo=libmpv を通してレンダリングされ、gpu-next（ArtCNN のようなコンピュートシェーダーに必要）は埋め込みでは実行できません。',
			'dialog.confirmAction' => '操作の確認',
			'profiles.addPlezyProfile' => 'Plezyプロフィールを追加',
			'profiles.switchingProfile' => 'プロフィールを切り替え中…',
			'profiles.deleteThisProfileTitle' => 'このプロフィールを削除しますか？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName}を削除します。接続には影響しません。',
			'profiles.active' => 'アクティブ',
			'profiles.manage' => '管理',
			'profiles.delete' => '削除',
			'profiles.signOut' => 'サインアウト',
			'profiles.signOutPlexTitle' => 'Plexからサインアウトしますか？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName}とすべてのPlex Homeユーザーを削除しますか？いつでも再度サインインできます。',
			'profiles.signedOutPlex' => 'Plexからサインアウトしました。',
			'profiles.signOutFailed' => 'サインアウトに失敗しました。',
			'profiles.sectionTitle' => 'プロフィール',
			'profiles.summarySingle' => 'プロフィールを追加すると、管理対象ユーザーとローカルユーザーを併用できます',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count}個のプロフィール · 使用中: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count}個のプロフィール',
			'profiles.removeConnectionTitle' => '接続を削除しますか？',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName}の${connectionLabel}へのアクセスを削除します。他のプロフィールには残ります。',
			'profiles.deleteProfileTitle' => 'プロフィールを削除しますか？',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName}とその接続を削除します。サーバーは引き続き利用できます。',
			'profiles.profileNameLabel' => 'プロフィール名',
			'profiles.pinProtectionLabel' => 'PIN保護',
			'profiles.pinManagedByPlex' => 'PINはPlexで管理されています。plex.tvで編集してください。',
			'profiles.noPinSetEditOnPlex' => 'PINが設定されていません。PINを必須にするには、plex.tvでHomeユーザーを編集してください。',
			'profiles.setPin' => 'PINを設定',
			'profiles.setPinTitle' => 'PINを設定',
			'profiles.confirmPinTitle' => 'PINを確認',
			'profiles.pinSet' => 'PIN設定済み',
			'profiles.changePin' => '変更',
			'profiles.removePin' => '削除',
			'profiles.connectionsLabel' => '接続',
			'profiles.add' => '追加',
			'profiles.deleteProfileButton' => 'プロフィールを削除',
			'profiles.noConnectionsHint' => '接続がありません — このプロフィールを使うには接続を追加してください。',
			'profiles.noConnections' => '接続がありません',
			'profiles.plexHomeAccount' => 'Plex Homeアカウント',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plexアカウント: ${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account}経由の${user}',
			'profiles.connectionDefault' => 'デフォルト',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName}として',
			'profiles.makeDefault' => 'デフォルトに設定',
			'profiles.removeConnection' => '削除',
			'profiles.profileRenamed' => 'プロフィール名を変更しました。',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName}に追加',
			'profiles.borrowExplain' => '別のプロフィールの接続を利用します。PINで保護されたプロフィールにはPINが必要です。',
			'profiles.borrowEmpty' => '利用できる接続はまだありません。',
			'profiles.borrowEmptySubtitle' => 'まず、別のプロフィールをPlexまたはJellyfinに接続してください。',
			'profiles.borrowLoadFailed' => '利用可能な接続を読み込めませんでした。もう一度お試しください。',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName}から利用',
			'profiles.borrowConnectionBorrowed' => '接続を追加しました。',
			'profiles.borrowFailed' => '接続を追加できませんでした。',
			'profiles.incorrectPin' => 'PINが正しくありません。',
			'profiles.incorrectPinTryAgain' => 'PINが正しくありません。もう一度お試しください。',
			'profiles.sourceProfileMissingParentAccount' => '元のプロフィールに親アカウントがありません。',
			'profiles.failedToLoadHomeUsers' => 'Plex Homeユーザーを読み込めませんでした。接続を確認して、もう一度お試しください。',
			'profiles.failedToVerifyPin' => 'PINを確認できませんでした。',
			'profiles.newProfile' => '新しいプロフィール',
			'profiles.profileNameHint' => '例：ゲスト、キッズ、ファミリールーム',
			'profiles.pinProtectionOptional' => 'PIN保護（オプション）',
			'profiles.pinExplain' => 'プロフィール切り替えには4桁のPINが必要です。',
			'profiles.continueButton' => '続ける',
			'profiles.pinsDontMatch' => 'PINが一致しません',
			'profiles.tokenIdentityMismatch' => 'Plexプロフィールのトークンから予期しないサーバーが特定されました',
			'connections.sectionTitle' => '接続',
			'connections.addConnection' => '接続を追加',
			'connections.addConnectionSubtitleNoProfile' => 'Plexでサインインするか、Jellyfinサーバーに接続',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}に追加：Plex、Jellyfin、または別のプロフィールの接続',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} のセッションの有効期限が切れました',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 台のサーバーのセッションの有効期限が切れました',
			'connections.signInAgain' => '再度サインイン',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product}接続を編集',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName}のURLを追加または削除します。Plezyは到達可能なURLのうち、レイテンシーが最も低いものを使用します。',
			'discover.title' => '探す',
			'discover.noContentAvailable' => 'コンテンツがありません',
			'discover.addMediaToLibraries' => 'ライブラリにメディアを追加してください',
			'discover.continueWatching' => '視聴を続ける',
			'discover.continueWatchingIn' => ({required Object library}) => '${library}の視聴を続ける',
			'discover.nextUp' => '次のエピソード',
			'discover.nextUpIn' => ({required Object library}) => '${library}の次のエピソード',
			'discover.recentlyAdded' => '最近追加されたコンテンツ',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library}に最近追加されたコンテンツ',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library}の最新アルバム',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library}で最近再生したコンテンツ',
			'discover.mostPlayedIn' => ({required Object library}) => '${library}で最も再生したコンテンツ',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'あらすじ',
			'discover.cast' => 'キャスト',
			'discover.extras' => '予告編とエクストラ',
			'discover.studio' => 'スタジオ',
			'discover.rating' => '評価',
			'discover.director' => '監督',
			'discover.directors' => '監督',
			'discover.movie' => '映画',
			'discover.tvShow' => 'テレビ番組',
			'discover.minutesLeft' => ({required Object minutes}) => '残り${minutes}分',
			'discover.moreLikeThis' => '似ている作品',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n}作品', ), 
			'errors.searchFailed' => ({required Object error}) => '検索に失敗しました: ${error}',
			'errors.searchUnavailable' => '検索中にメディアサーバーへ接続できませんでした。',
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
			'libraries.emptyingTrash' => ({required Object title}) => '「${title}」のゴミ箱を空にしています…',
			'libraries.trashEmptied' => ({required Object title}) => '「${title}」のゴミ箱を空にしました',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'ゴミ箱を空にできませんでした: ${error}',
			'libraries.analyzing' => ({required Object title}) => '「${title}」を解析中…',
			'libraries.analysisStarted' => ({required Object title}) => '「${title}」の解析を開始しました',
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
			'libraries.sortLabels.premiereDate' => '初公開日',
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
			'startup.failedTitle' => 'Plezyを起動できませんでした',
			'startup.failedBody' => '起動中に問題が発生しました。以下の詳細に失敗の原因が示されています。',
			'startup.failedBodyRepairable' => 'Plezyの保存済み設定ファイルが破損しているため、Plezyを起動する前に再構築する必要があります。再試行しても解決しません —「ストレージを修復」を選択してください。',
			'startup.phaseLabel' => 'ステップ',
			'startup.showDetails' => '詳細を表示',
			'startup.hideDetails' => '詳細を非表示',
			'startup.copyDetails' => '詳細をコピー',
			'startup.detailsCopied' => '詳細をクリップボードにコピーしました',
			'startup.uploadDetails' => '詳細をアップロード',
			'startup.repairStorage' => 'ストレージを修復',
			'startup.repairTitle' => '保存データを修復しますか？',
			'startup.repairBodyCommon' => 'Plezyの設定ファイルが破損しており読み取れません。修復するとすべての設定がデフォルトにリセットされます。',
			'startup.repairBodyOneCredential' => '保存済みのサインインの1つが破損しており読み取れません。修復するとその1つだけが削除され、他の設定には影響しません。',
			'startup.repairBodySignInsKept' => 'サーバーとプロフィールはサインインしたままになります。',
			'startup.repairBodySignInsLost' => '保存済みのサインインを保護するキーをこのファイルから復元できないため、すべてのサーバーとプロフィールに再度サインインする必要があります。メディアサーバー上のデータには影響ありません。',
			'startup.repairBodySessionsUncertain' => 'トラッカー（MAL、AniList、Simkl、Trakt）とSeerrは別途保存されており、保持されるかどうかは不明です。Plezyは保持した内容を正確にお知らせします。',
			'startup.repairConfirm' => '修復',
			'startup.repairSucceeded' => 'ストレージを修復しました',
			'startup.repairNeedsRestart' => 'ストレージを修復しました — 再起動が必要です',
			'startup.restartRequiredBody' => 'データは修復されましたが、Plezyはそれを使用する前に再起動する必要があります。Plezyを閉じて再度開いてください。',
			'startup.quitPlezy' => 'Plezyを終了',
			'startup.repairFailed' => '修復に失敗しました',
			'startup.repairKeptSignIns' => 'サーバーとプロフィールはサインインしたままです。',
			'startup.repairLostSignIns' => '保存済みのサインインを保護するキーを復元できませんでした。すべてのサーバーとプロフィールに再度サインインする必要があります。',
			'startup.repairLostSessions' => '少なくとも1つのトラッカーまたはSeerr接続が失われたため、再接続が必要です。',
			'startup.backupTitle' => '破損したファイルのコピーを保持しました',
			'startup.backupWarning' => 'このコピーにはサインイン資格情報が含まれています。アップロードや共有はしないでください。',
			'startup.deleteBackup' => 'コピーを削除',
			'startup.backupDeleted' => 'コピーを削除しました。',
			'startup.previousFailureTitle' => '前回、Plezyは起動に失敗しました',
			'licenses.relatedPackages' => '関連パッケージ',
			'licenses.license' => 'ライセンス',
			'licenses.licenseNumber' => ({required Object number}) => 'ライセンス ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count}件のライセンス',
			'navigation.libraries' => 'ライブラリ',
			'navigation.downloads' => 'ダウンロード',
			'navigation.liveTv' => 'ライブTV',
			'navigation.explore' => '見つける',
			'explore.title' => '見つける',
			'explore.selectSource' => 'ソースを選択',
			'explore.rows.watchlist' => 'ウォッチリスト',
			'explore.rows.recommendedMovies' => 'おすすめの映画',
			'explore.rows.recommendedShows' => 'おすすめのテレビ番組',
			'explore.rows.trendingMovies' => 'トレンドの映画',
			'explore.rows.trendingShows' => 'トレンドのテレビ番組',
			'explore.rows.popularMovies' => '人気の映画',
			'explore.rows.popularShows' => '人気のテレビ番組',
			'explore.rows.trendingAnime' => 'トレンドのアニメ',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n}話', ), 
			'explore.cast' => 'キャスト',
			'explore.characters' => 'キャラクター',
			'explore.addToWatchlist' => 'ウォッチリストに追加',
			'explore.removeFromWatchlist' => 'ウォッチリストから削除',
			_ => null,
		} ?? switch (path) {
			'explore.addedToWatchlist' => 'ウォッチリストに追加しました',
			'explore.removedFromWatchlist' => 'ウォッチリストから削除しました',
			'explore.watchlistUpdateFailed' => 'ウォッチリストを更新できませんでした',
			'explore.watchlistNoMatch' => 'このアイテムに一致するウォッチリスト項目が見つかりませんでした',
			'explore.notInLibrary' => 'ライブラリにありません',
			'explore.inTheseLibraries' => 'これらのライブラリにあります',
			'explore.checkingLibrary' => 'ライブラリを確認中…',
			'explore.emptyTitle' => 'まだ何もありません',
			'explore.emptyMessage' => ({required Object source}) => '${source}にコンテンツが追加されると、ここに表示されます。',
			'explore.searchHint' => ({required Object source}) => '${source}を検索',
			'explore.searchEmpty' => ({required Object query}) => '「${query}」の結果が見つかりません',
			'explore.searchPrompt' => ({required Object source}) => '${source}で映画やテレビ番組を検索します。',
			'explore.searchFailed' => '検索に失敗しました。接続を確認してもう一度お試しください。',
			'explore.badge.rankPopular' => ({required Object n}) => '人気 #${n}',
			'explore.badge.rankAiring' => ({required Object n}) => '放送中 #${n}',
			'explore.badge.rankRated' => ({required Object n}) => '評価 #${n}',
			'explore.badge.rankTrending' => ({required Object n}) => '急上昇 #${n}',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n}（${season}）',
			'explore.badge.watchingNow' => ({required Object n}) => '${n}人視聴中',
			'explore.badge.available' => '視聴可能',
			'explore.badge.partiallyAvailable' => '一部視聴可能',
			'explore.badge.availableIn4k' => '4K対応',
			'explore.badge.requested' => 'リクエスト済み',
			'explore.badge.pendingApproval' => '承認待ち',
			'explore.badge.processing' => '処理中',
			'explore.badge.declined' => '却下',
			'explore.badge.requestFailed' => 'リクエスト失敗',
			'explore.badge.requested4k' => '4Kリクエスト済み',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => 'シーズン ${available}/${total}',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'エピソード${episode} あと${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => '次回 あと${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n}話',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n}分/話',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '登録者 ${n}人',
			'explore.stats.viewersDay' => ({required Object n}) => '本日${n}人が視聴',
			'explore.stats.viewersWeek' => ({required Object n}) => '今週${n}人が視聴',
			'explore.stats.viewersMonth' => ({required Object n}) => '今月${n}人が視聴',
			'explore.stats.viewersYear' => ({required Object n}) => '今年${n}人が視聴',
			'explore.stats.viewersAllTime' => ({required Object n}) => '累計視聴者${n}人',
			'explore.stats.planning' => ({required Object n}) => '${n}人が視聴予定',
			'explore.stats.favorited' => ({required Object n}) => 'お気に入り ${n}件',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent}が視聴中止',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: 'コメント ${n}件', ), 
			'explore.stats.votes' => ({required Object n}) => '投票 ${n}件',
			'explore.stats.watching' => ({required Object n}) => '${n}人が視聴中',
			'explore.stats.completed' => ({required Object n}) => '${n}人が視聴済み',
			'explore.stats.onHold' => ({required Object n}) => '${n}人が保留中',
			'explore.stats.dropped' => ({required Object n}) => '${n}人が視聴中止',
			'explore.season.winter' => '冬',
			'explore.season.spring' => '春',
			'explore.season.summer' => '夏',
			'explore.season.fall' => '秋',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV短編',
			'explore.format.movie' => '映画',
			'explore.format.special' => 'スペシャル',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => '音楽',
			'explore.format.other' => 'その他',
			'explore.sourceMaterial.original' => 'オリジナル',
			'explore.sourceMaterial.manga' => '漫画',
			'explore.sourceMaterial.lightNovel' => 'ライトノベル',
			'explore.sourceMaterial.novel' => '小説',
			'explore.sourceMaterial.visualNovel' => 'ビジュアルノベル',
			'explore.sourceMaterial.game' => 'ゲーム',
			'explore.sourceMaterial.webComic' => 'Web漫画',
			'explore.sourceMaterial.musicRelease' => '音楽',
			'explore.sourceMaterial.otherMedia' => 'その他',
			'explore.creditRole.director' => '監督',
			'explore.creditRole.writer' => '脚本',
			'explore.creditRole.producer' => 'プロデューサー',
			'explore.creditRole.creator' => '原作者',
			'explore.creditRole.composer' => '作曲家',
			'explore.relation.prequel' => '前日譚',
			'explore.relation.sequel' => '続編',
			'explore.relation.sideStory' => 'サイドストーリー',
			'explore.relation.spinOff' => 'スピンオフ',
			'explore.relation.alternativeVersion' => '別バージョン',
			'explore.relation.summary' => '総集編',
			'explore.relation.parentStory' => '親作品',
			'explore.relation.adaptation' => '原作',
			'explore.relation.other' => '関連作品',
			'explore.broadcast' => ({required Object day, required Object time}) => '${day} ${time}に放送',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '${day} ${time}（${timezone}）に放送',
			'explore.detail.originalTitle' => '原題',
			'explore.detail.alsoKnownAs' => '別名',
			'explore.detail.studios' => '制作会社',
			'explore.detail.country' => '国',
			'explore.detail.language' => '言語',
			'explore.detail.released' => '公開日',
			'explore.detail.physicalRelease' => 'ディスク発売',
			'explore.detail.ended' => '放送終了',
			'explore.detail.addedOn' => ({required Object date}) => '${date}に追加',
			'explore.detail.yourRating' => 'あなたの評価',
			'explore.detail.budget' => '制作費',
			'explore.detail.revenue' => '興行収入',
			'explore.detail.contentAdvisory' => '年齢区分',
			'explore.detail.tags' => 'タグ',
			'explore.detail.revealSpoilerTags' => 'ネタバレタグを表示',
			'explore.detail.links' => 'リンク',
			'explore.detail.watchOn' => '視聴先',
			'explore.detail.watchTrailer' => '予告編を見る',
			'explore.detail.openOn' => ({required Object site}) => '${site}で開く',
			'explore.detail.crew' => 'スタッフ',
			'explore.detail.ratings' => '評価',
			'explore.detail.schedule' => '放送予定',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n}人のユーザーがおすすめ', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who}がおすすめ',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who}がお気に入り登録',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '未放送 ${n}話',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '視聴者の${percent}がおすすめ',
			'explore.detail.relatedTitles' => '関連作品',
			'explore.detail.background' => '背景',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n}件の結果', ), 
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
			'liveTv.reloadGuide' => '番組表を再読み込み',
			'liveTv.now' => '現在',
			'liveTv.today' => '今日',
			'liveTv.tomorrow' => '明日',
			'liveTv.midnight' => '午前0時',
			'liveTv.overnight' => '深夜',
			'liveTv.morning' => '朝',
			'liveTv.daytime' => '日中',
			'liveTv.evening' => '夕方',
			'liveTv.lateNight' => '夜更け',
			'liveTv.whatsOn' => '放送中',
			'liveTv.watchChannel' => 'チャンネルを視聴',
			'liveTv.favorites' => 'お気に入り',
			'liveTv.reorderFavorites' => 'お気に入りを並べ替え',
			'liveTv.noFavoriteChannels' => 'お気に入りのチャンネルがありません',
			'liveTv.noFavoriteChannelsHint' => 'すべてのチャンネルを表示し、チャンネルを長押ししてお気に入りに追加してください。',
			'liveTv.showAllChannels' => 'すべてのチャンネルを表示',
			'liveTv.favoritesLoadFailed' => 'お気に入りを読み込めませんでした。接続を確認してもう一度お試しください。',
			'liveTv.favoritesUpdateFailed' => 'お気に入りを更新できませんでした。接続を確認してもう一度お試しください。',
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
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title}は録画されなくなります。',
			'liveTv.deleteRule' => 'ルールを削除',
			'liveTv.deleteRuleTitle' => '録画ルールを削除しますか？',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title}の今後のエピソードは録画されません。',
			'liveTv.recordingScheduled' => '録画を予約しました',
			'liveTv.alreadyScheduled' => 'この番組はすでに予約されています',
			'liveTv.dvrAdminRequired' => 'DVR設定には管理者アカウントが必要です',
			'liveTv.recordingFailed' => '録画を予約できませんでした',
			'liveTv.recordingTargetMissing' => '録画ライブラリを特定できませんでした',
			'liveTv.recordNotAvailable' => 'この番組は録画できません',
			'liveTv.recordingCancelled' => '録画をキャンセルしました',
			'liveTv.recordingRuleDeleted' => '録画ルールを削除しました',
			'liveTv.processRecordingRules' => 'ルールを再評価',
			'liveTv.recordingInProgress' => '録画中',
			'liveTv.recordingsCount' => ({required Object count}) => '${count}件予約済み',
			'liveTv.editRule' => 'ルールを編集',
			'liveTv.editRuleAction' => '編集',
			'liveTv.recordingRuleUpdated' => '録画ルールを更新しました',
			'liveTv.guideReloadRequested' => '番組表の更新をリクエストしました',
			'liveTv.rulesProcessRequested' => '録画ルールの再評価をリクエストしました',
			'liveTv.recordShow' => '番組を録画',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes}分後に開始',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product}から無効なライブTV再生データが返されました',
			'liveTv.failedToStartChannel' => 'ライブチャンネルを開始できませんでした',
			'liveTv.failedToBuildStreamUrl' => 'ストリームURLを生成できませんでした',
			'collections.title' => 'コレクション',
			'collections.collection' => 'コレクション',
			'collections.empty' => 'コレクションは空です',
			'collections.deleteCollection' => 'コレクションを削除',
			'collections.deleteConfirm' => ({required Object title}) => '「${title}」を削除しますか？この操作は元に戻せません。',
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
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '「${title}」をこのコレクションから削除しますか？',
			'collections.removedFromCollection' => 'コレクションから削除しました',
			'collections.removeFromCollectionFailed' => 'コレクションからの削除に失敗しました',
			'collections.removeFromCollectionError' => ({required Object error}) => 'コレクションからの削除エラー: ${error}',
			'collections.searchCollections' => 'コレクションを検索…',
			'playlists.title' => 'プレイリスト',
			'playlists.playlist' => 'プレイリスト',
			'playlists.noPlaylists' => 'プレイリストが見つかりません',
			'playlists.create' => 'プレイリストを作成',
			'playlists.playlistName' => 'プレイリスト名',
			'playlists.enterPlaylistName' => 'プレイリスト名を入力',
			'playlists.delete' => 'プレイリストを削除',
			'playlists.removeItem' => 'プレイリストから削除',
			'playlists.smartPlaylist' => 'スマートプレイリスト',
			'playlists.itemCount' => ({required Object count}) => '${count}件',
			'playlists.oneItem' => '1件',
			'playlists.emptyPlaylist' => 'このプレイリストは空です',
			'playlists.deleteConfirm' => 'プレイリストを削除しますか？',
			'playlists.deleteMessage' => ({required Object name}) => '「${name}」を削除しますか？',
			'playlists.created' => 'プレイリストを作成しました',
			'playlists.deleted' => 'プレイリストを削除しました',
			'playlists.itemAdded' => 'プレイリストに追加しました',
			'playlists.itemRemoved' => 'プレイリストから削除しました',
			'playlists.selectPlaylist' => 'プレイリストを選択',
			'playlists.searchPlaylists' => 'プレイリストを検索…',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n}曲', ), 
			'music.nowPlaying' => '再生中',
			'music.playingFrom' => ({required Object title}) => '${title}から再生',
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
			'music.instantMixNoServer' => 'インスタントミックスに利用できるサーバーがありません',
			'music.noAudioUrl' => ({required Object track}) => '${track}で利用可能な音声URLがありません',
			'music.discography.singlesAndEps' => 'シングル・EP',
			'music.discography.live' => 'ライブ',
			'music.discography.compilations' => 'コンピレーション',
			'watchTogether.title' => '一緒に見る',
			'watchTogether.description' => '友達や家族と同期してコンテンツを視聴',
			'watchTogether.createSession' => 'セッションを作成',
			'watchTogether.creating' => '作成中…',
			'watchTogether.joinSession' => 'セッションに参加',
			'watchTogether.joining' => '参加中…',
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
			'watchTogether.hostBadge' => 'ホスト',
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
			'watchTogether.syncing' => '同期中…',
			'watchTogether.joinWatchSession' => '視聴セッションに参加',
			'watchTogether.enterCodeHint' => '5文字のコードを入力',
			'watchTogether.pasteFromClipboard' => 'クリップボードから貼り付け',
			'watchTogether.pleaseEnterCode' => 'セッションコードを入力してください',
			'watchTogether.codeMustBe5Chars' => 'セッションコードは5文字である必要があります',
			'watchTogether.joinInstructions' => '参加するにはホストのセッションコードを入力してください。',
			'watchTogether.failedToCreate' => 'セッションの作成に失敗しました',
			'watchTogether.failedToJoin' => 'セッションへの参加に失敗しました',
			'watchTogether.sessionCodeCopied' => 'セッションコードをクリップボードにコピーしました',
			'watchTogether.relayUnreachable' => 'リレーサーバーに接続できません。ISPによるブロックのため「一緒に見る」を利用できない可能性があります。',
			'watchTogether.reconnectingToHost' => 'ホストに再接続中…',
			'watchTogether.currentPlayback' => '現在の再生',
			'watchTogether.joinCurrentPlayback' => '現在の再生に参加',
			'watchTogether.joinCurrentPlaybackDescription' => 'ホストが現在視聴中のコンテンツに戻る',
			'watchTogether.failedToOpenCurrentPlayback' => '現在の再生を開けませんでした',
			'watchTogether.participantJoined' => ({required Object name}) => '${name}が参加しました',
			'watchTogether.participantLeft' => ({required Object name}) => '${name}が退出しました',
			'watchTogether.participantPaused' => ({required Object name}) => '${name}が一時停止しました',
			'watchTogether.participantResumed' => ({required Object name}) => '${name}が再開しました',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name}が再生位置を変更しました',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name}がバッファリング中',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name}は古いバージョンのアプリを使用しているため、同期できません',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name}抜きで再開',
			'watchTogether.waitingForParticipants' => '他の参加者の読み込みを待っています…',
			'watchTogether.waitingForName' => ({required Object name}) => '${name}を待っています…',
			'watchTogether.recentRooms' => '最近のルーム',
			'watchTogether.renameRoom' => 'ルーム名を変更',
			'watchTogether.removeRoom' => '削除',
			'watchTogether.guestSwitchUnavailable' => '切り替えられません — 同期に必要なサーバーを利用できません',
			'watchTogether.guestSwitchFailed' => '切り替えられません — このサーバーにコンテンツが見つかりません',
			'watchTogether.defaultDisplayName' => 'ユーザー',
			'downloads.title' => 'ダウンロード',
			'downloads.manage' => '管理',
			'downloads.tvShows' => 'テレビ番組',
			'downloads.movies' => '映画',
			'downloads.music' => '音楽',
			'downloads.tracksQueued' => ({required Object count}) => '${count} 曲をダウンロード待機中',
			'downloads.noDownloads' => 'ダウンロードはまだありません',
			'downloads.noDownloadsDescription' => 'ダウンロードしたコンテンツはここに表示され、オフラインで視聴できます',
			'downloads.downloadNow' => 'ダウンロード',
			'downloads.deleteDownload' => 'ダウンロードを削除',
			'downloads.retryDownload' => 'ダウンロードを再試行',
			'downloads.downloadQueued' => 'ダウンロードをキューに追加しました',
			'downloads.downloadResumed' => 'ダウンロードを再開しました',
			'downloads.serverErrorBitrate' => 'サーバーエラー: ファイルがリモートビットレート制限を超えている可能性があります',
			'downloads.storageFull' => 'デバイスのストレージがいっぱいのため、ダウンロードを停止しました。空き容量を確保してから、もう一度お試しください。',
			'downloads.episodesQueued' => ({required Object count}) => '${count}エピソードをダウンロードキューに追加しました',
			'downloads.downloadDeleted' => 'ダウンロードを削除しました',
			'downloads.deleteConfirm' => ({required Object title}) => 'このデバイスから「${title}」を削除しますか？',
			'downloads.cancelledDownloadTitle' => 'キャンセル済みのダウンロード',
			'downloads.cancelledDownloadMessage' => 'このダウンロードはキャンセルされました。どうしますか？',
			'downloads.allEpisodesAlreadyDownloaded' => 'すべてのエピソードはすでにダウンロード済みです',
			'downloads.resumeDownload' => 'ダウンロードを再開',
			'downloads.cancelledDownload' => 'キャンセル済みのダウンロード',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file}（${status}を同期中）',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file}をダウンロード済み — クリックして完了',
			'downloads.partialDownloadClickToComplete' => '一部ダウンロード済み — クリックして完了',
			'downloads.deleting' => '削除中…',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title}を削除中…（${current}/${total}）',
			'downloads.queuedTooltip' => 'キュー',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'キュー：${files}',
			'downloads.downloadingTooltip' => 'ダウンロード中…',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '${files}をダウンロード中',
			'downloads.noDownloadsTree' => 'ダウンロードなし',
			'downloads.pauseAll' => 'すべて一時停止',
			'downloads.resumeAll' => 'すべて再開',
			'downloads.deleteAll' => 'すべて削除',
			'downloads.selectVersion' => 'バージョンを選択',
			'downloads.allEpisodes' => 'すべてのエピソード',
			'downloads.unwatchedOnly' => '未視聴のみ',
			'downloads.nextNUnwatched' => ({required Object count}) => '次の${count}件の未視聴',
			'downloads.customAmount' => '数を指定…',
			'downloads.includeSpecials' => 'スペシャルを含める',
			'downloads.howManyEpisodes' => 'エピソード数',
			'downloads.invalidEpisodeCount' => '有効なエピソード数を入力してください。',
			'downloads.keepSynced' => '同期を維持',
			'downloads.downloadOnce' => '一度だけダウンロード',
			'downloads.keepNUnwatched' => ({required Object count}) => '未視聴を${count}件保持',
			'downloads.editSyncRule' => '同期ルールを編集',
			'downloads.removeSyncRule' => '同期ルールを削除',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '「${title}」の同期を停止しますか？ダウンロード済みのエピソードは保持されます。',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '「${title}」の同期を停止しますか？',
			'downloads.deleteSyncRuleDownloads' => '関連するダウンロードも削除',
			'downloads.deleteSyncRuleDownloadsDescription' => '別の同期ルールやプロフィールで使用されているダウンロードは保持されます。',
			'downloads.syncRuleCreated' => ({required Object count}) => '同期ルールを作成しました — 未視聴のエピソードを${count}件保持',
			'downloads.syncRuleUpdated' => '同期ルールを更新しました',
			'downloads.syncRuleRemoved' => '同期ルールを削除しました',
			'downloads.syncRuleAndDownloadsRemoved' => '同期ルールと関連するダウンロードを削除しました',
			'downloads.syncRuleCleanupBusy' => '同期ルールが更新中です。しばらくしてからもう一度お試しください。',
			'downloads.syncRuleCleanupUnavailable' => '関連するダウンロードを安全に特定できませんでした。サーバーに再接続して再試行するか、ダウンロードを削除せずにルールを削除してください。',
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
			'downloads.backgroundWarning.bannerBlocked' => 'アプリの画面を離れると、ダウンロードが停止します',
			'downloads.backgroundWarning.bannerDegraded' => 'バックグラウンドダウンロードが制限される場合があります',
			'downloads.backgroundWarning.bannerAction' => '詳細',
			'downloads.backgroundWarning.sheetTitle' => 'バックグラウンドダウンロードはブロックされています',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'バックグラウンドダウンロードが制限される場合があります',
			'downloads.backgroundWarning.sheetIntro' => 'Androidにより、Plezyはバックグラウンドで安定してダウンロードできません。',
			'downloads.backgroundWarning.sheetIntroDegraded' => '端末により、Plezyがバックグラウンドでダウンロードできるタイミングが制限されています。',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezyのバックグラウンド使用が制限されています。バッテリー使用量またはバックグラウンド使用を「制限なし」に設定してください。',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Androidにより、Plezyが制限付きのスタンバイ状態に設定されています。バッテリー使用量を「制限なし」に設定してください。',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'ダウンロード通知がオフのため、進行状況や操作ボタンを利用できない場合があります。',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => '通知がオフです。Android 13以降では、長時間のバックグラウンドダウンロードに通知が必要です。',
			'downloads.backgroundWarning.reasonDataSaver' => 'データセーバーがオンのため、モバイルデータ通信ではバックグラウンドダウンロードがブロックされます。Wi-Fiでは引き続きダウンロードできるはずです。',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezyがバックグラウンドで動作中に、ダウンロードが繰り返し停止しました。Plezyのバッテリー使用量またはバックグラウンド使用の設定を確認してください。',
			'downloads.backgroundWarning.openSettings' => '設定を開く',
			'downloads.backgroundWarning.stillNotWorking' => '端末別のヘルプ',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'お使いの端末向けの手順を確認してください。問題が続く場合は、設定 › ログを表示 からログを送信してください。',
			'downloads.backgroundWarning.dialogTitle' => 'ダウンロードが完了しない可能性があります',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'このままダウンロード',
			'downloads.backgroundWarning.dialogFixFirst' => '先に設定を修正',
			'downloads.backgroundWarning.statusTile' => 'バックグラウンドダウンロード',
			'downloads.backgroundWarning.statusOk' => 'バックグラウンドで実行可能',
			'downloads.backgroundWarning.statusBlocked' => 'システム設定によりブロック',
			'downloads.backgroundWarning.statusDegraded' => 'システム設定により制限',
			'downloads.backgroundWarning.statusUnknown' => '未確認',
			'downloads.backgroundWarning.settingsUnavailable' => 'この端末ではシステム設定を開けませんでした',
			'downloads.backgroundWarning.linkUnavailable' => 'この端末ではdontkillmyapp.comを開けませんでした',
			'downloads.unknownShow' => '不明な番組',
			'downloads.unknownSeason' => '不明なシーズン',
			'downloads.unknownAlbum' => '不明なアルバム',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total}完了',
			'downloads.errorFileNotFound' => 'ファイルが見つかりません（404）',
			'downloads.errorDownloadFailed' => 'ダウンロードに失敗しました',
			'downloads.errorPostProcessing' => ({required Object error}) => '後処理に失敗しました: ${error}',
			'downloads.notificationDownloading' => 'ダウンロード中…',
			'downloads.notificationComplete' => 'ダウンロードが完了しました',
			'downloads.notificationPaused' => 'ダウンロードを一時停止しました',
			'shaders.title' => 'シェーダー',
			'shaders.noShaderDescription' => '映像補正なし',
			'shaders.nvscalerDescription' => 'NVIDIA画像スケーリングで映像をより鮮明にします',
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
			'shaders.deleteShaderConfirm' => ({required Object name}) => '「${name}」を削除しますか？',
			'companionRemote.title' => 'コンパニオンリモート',
			'companionRemote.connectedTo' => ({required Object name}) => '${name}に接続中',
			'companionRemote.unknownDevice' => '不明なデバイス',
			'companionRemote.session.startingServer' => 'リモートサーバーを起動中…',
			'companionRemote.session.hostAddress' => 'ホストアドレス',
			'companionRemote.session.connected' => '接続済み',
			'companionRemote.session.serverRunning' => 'リモートサーバー稼働中',
			'companionRemote.session.serverStopped' => 'リモートサーバー停止',
			'companionRemote.session.serverRunningDescription' => 'ネットワーク上のモバイルデバイスがこのアプリに接続できます',
			'companionRemote.session.serverStoppedDescription' => 'モバイルデバイスの接続を許可するにはサーバーを起動してください',
			'companionRemote.session.usePhoneToControl' => 'モバイルデバイスでこのアプリを操作できます',
			'companionRemote.session.startServer' => 'サーバーを起動',
			'companionRemote.session.stopServer' => 'サーバーを停止',
			'companionRemote.session.minimize' => '最小化',
			'companionRemote.pairing.discoveryDescription' => '同じPlexアカウントを使用しているPlezyデバイスがここに表示されます',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '接続中…',
			'companionRemote.pairing.searchingForDevices' => 'デバイスを検索中…',
			'companionRemote.pairing.noDevicesFound' => 'ネットワーク上にデバイスが見つかりません',
			'companionRemote.pairing.noDevicesHint' => 'デスクトップでPlezyを開き、同じWi-Fiネットワークに接続してください',
			'companionRemote.pairing.availableDevices' => '利用可能なデバイス',
			'companionRemote.pairing.manualConnection' => '手動接続',
			'companionRemote.pairing.cryptoInitFailed' => '安全な接続を開始できませんでした。先にPlexにサインインしてください。',
			'companionRemote.pairing.validationHostRequired' => 'ホストアドレスを入力してください',
			'companionRemote.pairing.validationHostFormat' => '形式はIP:ポートである必要があります（例: 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '接続がタイムアウトしました。両方のデバイスで同じネットワークを使用してください。',
			'companionRemote.pairing.sessionNotFound' => 'デバイスが見つかりません。ホストでPlezyが実行中か確認してください。',
			'companionRemote.pairing.authFailed' => '認証に失敗しました。両方のデバイスで同じPlexアカウントが必要です。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '接続に失敗しました: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'リモートセッションを切断しますか？',
			'companionRemote.remote.reconnecting' => '再接続中…',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '試行 ${current}/5',
			'companionRemote.remote.retryNow' => '今すぐ再試行',
			'companionRemote.remote.tabRemote' => 'リモコン',
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
			'companionRemote.remote.searchHint' => 'デスクトップで検索…',
			_ => null,
		} ?? switch (path) {
			'companionRemote.errors.noNetworkInterface' => 'ネットワークインターフェースが見つかりません',
			'companionRemote.errors.authenticationFailed' => '認証に失敗しました',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'リモートサーバーを起動できませんでした: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'リモートコマンドを送信できませんでした: ${error}',
			'companionRemote.errors.joinTimedOut' => 'セッション参加がタイムアウトしました',
			'companionRemote.errors.failedToConnectAnyAddress' => 'どのアドレスにも接続できませんでした',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts}回試行後に接続が切断されました',
			'companionRemote.errors.connectionLost' => '接続が切断されました',
			'companionRemote.closedBeforeAuth' => '認証前に接続が切断されました',
			'videoSettings.playbackSpeed' => '再生速度',
			'videoSettings.normalSpeed' => '標準',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '作動中（${duration}）',
			'videoSettings.zoom' => 'ズーム',
			'videoSettings.sleepTimer' => 'スリープタイマー',
			'videoSettings.audioSync' => '音声同期',
			'videoSettings.subtitleSync' => '字幕同期',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'ここではHDRを利用できません。このデスクトップコンポジターまたは映像出力はHDRに対応していません。',
			'videoSettings.hdrToneMapping' => 'HDRトーンマッピング',
			'videoSettings.hdrToneMappingCompositor' => 'コンポジター',
			'videoSettings.hdrToneMappingCompositorDescription' => 'ソースのHDRメタデータをそのまま渡し、デスクトップコンポジターにマッピングさせます。',
			'videoSettings.hdrToneMappingPlayer' => 'プレーヤー',
			'videoSettings.hdrToneMappingPlayerDescription' => 'プレーヤーでディスプレイのピーク輝度に合わせてマッピングし、その結果をコンポジターに通知します。',
			'videoSettings.hdrToneMappingFailed' => 'HDRトーンマッピングを変更できませんでした。以前のモードが引き続き有効です。',
			'videoSettings.audioOutput' => '音声出力',
			'videoSettings.performanceOverlay' => 'パフォーマンスオーバーレイ',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'サラウンド',
			'videoSettings.audioOutputSpatial' => '空間オーディオ',
			'videoSettings.audioOutputStereo' => 'ステレオ',
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
			'performanceOverlay.transfer' => '伝達特性',
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
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'ソフトウェア',
			'performanceOverlay.decoderHardware' => 'ハードウェア',
			'performanceOverlay.tunnelingActive' => '有効',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted}（${failures}件失敗）',
			'externalPlayer.title' => '外部プレーヤー',
			'externalPlayer.useExternalPlayer' => '外部プレーヤーを使用',
			'externalPlayer.useExternalPlayerDescription' => '動画を別のアプリで開きます',
			'externalPlayer.selectPlayer' => 'プレーヤーを選択',
			'externalPlayer.customPlayers' => 'カスタムプレーヤー',
			'externalPlayer.systemDefault' => 'システム既定',
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
			'metadataEdit.editMetadata' => '編集…',
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
			'metadataEdit.latestEpisodes' => ({required Object count}) => '最新の${count}話',
			'metadataEdit.latestEpisode' => '最新エピソード',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => '過去${count}日間に追加されたエピソード',
			'metadataEdit.deleteAfterPlaying' => '再生後にエピソードを削除',
			'metadataEdit.never' => 'しない',
			'metadataEdit.afterADay' => '1日後',
			'metadataEdit.afterAWeek' => '1週間後',
			'metadataEdit.afterAMonth' => '1か月後',
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
			'matchScreen.match' => '照合…',
			'matchScreen.fixMatch' => '照合を修正…',
			'matchScreen.unmatch' => '照合を解除',
			'matchScreen.unmatchConfirm' => 'この照合を解除しますか？再照合するまで、Plexでは未照合として扱われます。',
			'matchScreen.unmatchSuccess' => '照合を解除しました',
			'matchScreen.unmatchFailed' => '照合を解除できませんでした',
			'matchScreen.matchApplied' => '照合結果を適用しました',
			'matchScreen.matchFailed' => '照合結果を適用できませんでした',
			'matchScreen.titleHint' => 'タイトル',
			'matchScreen.yearHint' => '年',
			'matchScreen.search' => '検索',
			'matchScreen.noMatchesFound' => '一致する項目がありません',
			'serverTasks.title' => 'サーバータスク',
			'serverTasks.failedToLoad' => 'タスクの読み込みに失敗しました',
			'serverTasks.noTasks' => '実行中のタスクはありません',
			'trakt.title' => 'Trakt',
			'trakt.connected' => '接続済み',
			'trakt.connectedAs' => ({required Object username}) => '@${username}として接続済み',
			'trakt.disconnectConfirm' => 'Traktアカウントとの接続を解除しますか？',
			'trakt.disconnectConfirmBody' => 'PlezyはTraktへのイベント送信を停止します。いつでも再接続できます。',
			'trakt.scrobble' => 'リアルタイムのスクロブル',
			'trakt.scrobbleDescription' => '再生中に再生・一時停止・停止の各イベントをTraktに送信します。',
			'trakt.watchedSync' => '視聴済みステータスを同期',
			'trakt.watchedSyncDescription' => 'Plezyで項目を視聴済みにすると、Traktでも視聴済みになります。',
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
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url}に接続できませんでした: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url}にSeerrインスタンスがありません（HTTP ${status}）',
			'seerr.notInitialized' => 'このSeerrインスタンスでは初回セットアップが完了していません',
			'seerr.noPlexTokenForReauth' => '再サインインに使用できるPlexトークンがありません',
			'seerr.noStoredCredentials' => '再サインインに使用できる保存済みの認証情報がありません',
			'seerr.signInRejected' => 'サインインが拒否されました',
			'seerr.noSessionCookie' => 'Seerrからセッションクッキーが発行されませんでした',
			'seerr.freshCookieRejected' => 'Seerrが新しいセッションクッキーを拒否しました',
			'seerr.noUserInformation' => 'Seerrからユーザー情報が返されませんでした',
			'seerr.sessionRejectedAfterReauth' => '再サインイン後にセッションが拒否されました',
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
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => '${service} で Plezy を有効化',
			'services.deviceCode.instructions' => 'QRコードをスキャンするか、以下のアドレスにアクセスしてこのコードを入力してください:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '${service} を開いて有効化',
			'services.deviceCode.copyCode' => 'アクティベーションコードをコピー',
			'services.deviceCode.waitingForAuthorization' => '認証を待っています…',
			'services.deviceCode.codeCopied' => 'コードをコピーしました',
			'services.oauthProxy.title' => ({required Object service}) => '${service} にサインイン',
			'services.oauthProxy.body' => 'このQRコードをスキャンするか、任意のデバイスでURLを開いてください。',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '${service} を開いてサインイン',
			'services.pendingAuth.copyUrl' => 'サインインURLをコピー',
			'services.pendingAuth.urlCopied' => 'URLをコピーしました',
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
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product}サーバーを追加',
			'addServer.serverUrls' => 'サーバーURL',
			'addServer.serverUrlsHelper' => '複数のURLをカンマ区切りで入力できます。',
			'addServer.findServer' => 'サーバーを検索',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'ローカルの${product}サーバーを検索中…',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'ローカルの${product}サーバー',
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
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '${product}サーバーのURLを入力してください',
			'addServer.addConnectionTitle' => '接続を追加',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name}に追加',
			'addServer.signInWithPlexCard' => 'Plexでサインイン',
			'addServer.signInWithPlexCardSubtitle' => 'このデバイスを承認します。共有サーバーが追加されます。',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plexアカウントを承認します。Homeユーザーはプロフィールになります。',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '${product}に接続',
			'addServer.connectToMediaBrowserCardSubtitle' => 'サーバーのURL、ユーザー名、パスワードを入力してください。',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '${product}サーバーにサインインします。「${name}」に紐付けられます。',
			'addServer.borrowFromAnotherProfile' => '別のプロフィールの接続を利用',
			'addServer.borrowFromAnotherProfileSubtitle' => '別のプロフィールの接続を再利用します。PINで保護されたプロフィールにはPINが必要です。',
			'addServer.invalidCredentials' => 'ユーザー名またはパスワードが正しくありません',
			'addServer.authResponseNotJson' => '認証レスポンスが有効なJSONではありません',
			'addServer.quickConnectRejected' => 'Quick Connectがサーバーに拒否されました',
			'addServer.quickConnectNotJson' => 'Quick Connectのレスポンスが有効なJSONではありません',
			'addServer.quickConnectMissingFields' => 'Quick Connectのレスポンスにコードまたはシークレットがありません',
			'addServer.quickConnectPollRejected' => 'Quick Connectのポーリングがサーバーに拒否されました',
			'addServer.serverTimedOut' => 'サーバーが時間内に応答しませんでした',
			'addServer.responseNotJson' => 'サーバーのレスポンスが有効なJSONではありません',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'レスポンスにIDまたはサーバー名がありません。これは${product}サーバーですか？',
			'addServer.probeFailed' => ({required Object error}) => 'サーバーに接続できませんでした: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => '${product}サーバーのURLを1つ以上入力してください',
			'addServer.noReachableServer' => ({required Object product}) => '接続可能な${product}サーバーが見つかりませんでした',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'これらのURLは異なる${product}サーバーを指しています',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'このURLは${product}サーバーと一致しません',
			'addServer.redirectUnsupported' => 'サーバーからサポートされていないURLにリダイレクトされました',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'サーバーから別のホストにリダイレクトされました。最終的な${product}のURLを直接入力してください。',
			'addServer.redirectInsecure' => 'サーバーからHTTPSではない安全でないURLにリダイレクトされました',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'サーバーからサポートされていないURLにリダイレクトされました。最終的な${product}のURLを直接入力してください。',
			_ => null,
		};
	}
}
