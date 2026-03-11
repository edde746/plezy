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
class TranslationsJa with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

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
	@override late final _TranslationsPinEntryJa pinEntry = _TranslationsPinEntryJa._(_root);
	@override late final _TranslationsFileInfoJa fileInfo = _TranslationsFileInfoJa._(_root);
	@override late final _TranslationsMediaMenuJa mediaMenu = _TranslationsMediaMenuJa._(_root);
	@override late final _TranslationsAccessibilityJa accessibility = _TranslationsAccessibilityJa._(_root);
	@override late final _TranslationsTooltipsJa tooltips = _TranslationsTooltipsJa._(_root);
	@override late final _TranslationsVideoControlsJa videoControls = _TranslationsVideoControlsJa._(_root);
	@override late final _TranslationsUserStatusJa userStatus = _TranslationsUserStatusJa._(_root);
	@override late final _TranslationsMessagesJa messages = _TranslationsMessagesJa._(_root);
	@override late final _TranslationsSubtitlingStylingJa subtitlingStyling = _TranslationsSubtitlingStylingJa._(_root);
	@override late final _TranslationsMpvConfigJa mpvConfig = _TranslationsMpvConfigJa._(_root);
	@override late final _TranslationsDialogJa dialog = _TranslationsDialogJa._(_root);
	@override late final _TranslationsDiscoverJa discover = _TranslationsDiscoverJa._(_root);
	@override late final _TranslationsErrorsJa errors = _TranslationsErrorsJa._(_root);
	@override late final _TranslationsLibrariesJa libraries = _TranslationsLibrariesJa._(_root);
	@override late final _TranslationsAboutJa about = _TranslationsAboutJa._(_root);
	@override late final _TranslationsServerSelectionJa serverSelection = _TranslationsServerSelectionJa._(_root);
	@override late final _TranslationsHubDetailJa hubDetail = _TranslationsHubDetailJa._(_root);
	@override late final _TranslationsLogsJa logs = _TranslationsLogsJa._(_root);
	@override late final _TranslationsLicensesJa licenses = _TranslationsLicensesJa._(_root);
	@override late final _TranslationsNavigationJa navigation = _TranslationsNavigationJa._(_root);
	@override late final _TranslationsLiveTvJa liveTv = _TranslationsLiveTvJa._(_root);
	@override late final _TranslationsCollectionsJa collections = _TranslationsCollectionsJa._(_root);
	@override late final _TranslationsPlaylistsJa playlists = _TranslationsPlaylistsJa._(_root);
	@override late final _TranslationsWatchTogetherJa watchTogether = _TranslationsWatchTogetherJa._(_root);
	@override late final _TranslationsDownloadsJa downloads = _TranslationsDownloadsJa._(_root);
	@override late final _TranslationsShadersJa shaders = _TranslationsShadersJa._(_root);
	@override late final _TranslationsCompanionRemoteJa companionRemote = _TranslationsCompanionRemoteJa._(_root);
	@override late final _TranslationsVideoSettingsJa videoSettings = _TranslationsVideoSettingsJa._(_root);
	@override late final _TranslationsExternalPlayerJa externalPlayer = _TranslationsExternalPlayerJa._(_root);
	@override late final _TranslationsMetadataEditJa metadataEdit = _TranslationsMetadataEditJa._(_root);
}

// Path: app
class _TranslationsAppJa implements TranslationsAppEn {
	_TranslationsAppJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthJa implements TranslationsAuthEn {
	_TranslationsAuthJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plexでサインイン';
	@override String get showQRCode => 'QRコードを表示';
	@override String get authenticate => '認証';
	@override String get authenticationTimeout => '認証がタイムアウトしました。もう一度お試しください。';
	@override String get scanQRToSignIn => 'このQRコードをスキャンしてサインイン';
	@override String get waitingForAuth => '認証を待機中...\nブラウザでサインインを完了してください。';
	@override String get useBrowser => 'ブラウザを使用';
}

// Path: common
class _TranslationsCommonJa implements TranslationsCommonEn {
	_TranslationsCommonJa._(this._root);

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
	@override String get shuffle => 'シャッフル';
	@override String get addTo => '追加...';
	@override String get createNew => '新規作成';
	@override String get remove => '削除';
	@override String get paste => '貼り付け';
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
	@override String get loading => '読み込み中...';
	@override String get reconnect => '再接続';
	@override String get exitConfirmTitle => 'アプリを終了しますか？';
	@override String get exitConfirmMessage => '終了してもよろしいですか？';
	@override String get dontAskAgain => '次回から表示しない';
	@override String get exit => '終了';
	@override String get viewAll => 'すべて表示';
	@override String get checkingNetwork => 'ネットワークを確認中...';
	@override String get refreshingServers => 'サーバーを更新中...';
	@override String get loadingServers => 'サーバーを読み込み中...';
	@override String get connectingToServers => 'サーバーに接続中...';
	@override String get startingOfflineMode => 'オフラインモードを開始中...';
}

// Path: screens
class _TranslationsScreensJa implements TranslationsScreensEn {
	_TranslationsScreensJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'ライセンス';
	@override String get switchProfile => 'プロフィール切替';
	@override String get subtitleStyling => '字幕スタイル';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'ログ';
}

// Path: update
class _TranslationsUpdateJa implements TranslationsUpdateEn {
	_TranslationsUpdateJa._(this._root);

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
class _TranslationsSettingsJa implements TranslationsSettingsEn {
	_TranslationsSettingsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get language => '言語';
	@override String get theme => 'テーマ';
	@override String get appearance => '外観';
	@override String get videoPlayback => '動画再生';
	@override String get advanced => '詳細';
	@override String get episodePosterMode => 'エピソードポスタースタイル';
	@override String get seriesPoster => 'シリーズポスター';
	@override String get seriesPosterDescription => 'すべてのエピソードにシリーズポスターを表示';
	@override String get seasonPoster => 'シーズンポスター';
	@override String get seasonPosterDescription => 'エピソードにシーズン固有のポスターを表示';
	@override String get episodeThumbnail => 'エピソードサムネイル';
	@override String get episodeThumbnailDescription => '16:9のエピソードスクリーンショットサムネイルを表示';
	@override String get showHeroSectionDescription => 'ホーム画面に注目コンテンツのカルーセルを表示';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分';
	@override String get secondsShort => '秒';
	@override String get minutesShort => '分';
	@override String durationHint({required Object min, required Object max}) => '時間を入力 (${min}-${max})';
	@override String get systemTheme => 'システム';
	@override String get systemThemeDescription => 'システム設定に従う';
	@override String get lightTheme => 'ライト';
	@override String get darkTheme => 'ダーク';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'OLED画面向けの純粋な黒';
	@override String get libraryDensity => 'ライブラリの密度';
	@override String get compact => 'コンパクト';
	@override String get compactDescription => '小さいカード、より多くのアイテムを表示';
	@override String get normal => '標準';
	@override String get normalDescription => 'デフォルトサイズ';
	@override String get comfortable => 'ゆったり';
	@override String get comfortableDescription => '大きいカード、表示アイテム数を減少';
	@override String get viewMode => '表示モード';
	@override String get gridView => 'グリッド';
	@override String get gridViewDescription => 'グリッドレイアウトでアイテムを表示';
	@override String get listView => 'リスト';
	@override String get listViewDescription => 'リストレイアウトでアイテムを表示';
	@override String get showHeroSection => 'ヒーローセクションを表示';
	@override String get useGlobalHubs => 'Plex Homeレイアウトを使用';
	@override String get useGlobalHubsDescription => '公式Plexクライアントのようにホームページのハブを表示。オフにすると、ライブラリごとのおすすめを表示。';
	@override String get showServerNameOnHubs => 'ハブにサーバー名を表示';
	@override String get showServerNameOnHubsDescription => 'ハブタイトルに常にサーバー名を表示。オフにすると、重複名のみ表示。';
	@override String get alwaysKeepSidebarOpen => 'サイドバーを常に開いておく';
	@override String get alwaysKeepSidebarOpenDescription => 'サイドバーを展開したまま、コンテンツ領域が調整される';
	@override String get showUnwatchedCount => '未視聴数を表示';
	@override String get showUnwatchedCountDescription => '番組とシーズンに未視聴エピソード数を表示';
	@override String get hideSpoilers => '未視聴エピソードのネタバレを非表示';
	@override String get hideSpoilersDescription => 'まだ視聴していないエピソードのサムネイルをぼかし、説明を非表示';
	@override String get playerBackend => 'プレーヤーバックエンド';
	@override String get exoPlayer => 'ExoPlayer（推奨）';
	@override String get exoPlayerDescription => 'より良いハードウェアサポートのAndroidネイティブプレーヤー';
	@override String get mpv => 'mpv';
	@override String get mpvDescription => 'より多くの機能とASS字幕サポートの高度なプレーヤー';
	@override String get hardwareDecoding => 'ハードウェアデコード';
	@override String get hardwareDecodingDescription => '利用可能な場合にハードウェアアクセラレーションを使用';
	@override String get bufferSize => 'バッファサイズ';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => '自動（推奨）';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'デバイスのメモリは${heap}MBです。${size}MBのバッファは再生の問題を引き起こす可能性があります。';
	@override String get subtitleStyling => '字幕スタイル';
	@override String get subtitleStylingDescription => '字幕の外観をカスタマイズ';
	@override String get smallSkipDuration => '短いスキップ時間';
	@override String get largeSkipDuration => '長いスキップ時間';
	@override String secondsUnit({required Object seconds}) => '${seconds}秒';
	@override String get defaultSleepTimer => 'デフォルトスリープタイマー';
	@override String minutesUnit({required Object minutes}) => '${minutes}分';
	@override String get rememberTrackSelections => '番組/映画ごとにトラック選択を記憶';
	@override String get rememberTrackSelectionsDescription => '再生中にトラックを変更すると、音声と字幕の言語設定を自動保存';
	@override String get clickVideoTogglesPlayback => '動画クリックで再生/一時停止を切替';
	@override String get clickVideoTogglesPlaybackDescription => '有効にすると、動画プレーヤーをクリックで再生/一時停止。それ以外は再生コントロールの表示/非表示。';
	@override String get videoPlayerControls => '動画プレーヤーコントロール';
	@override String get keyboardShortcuts => 'キーボードショートカット';
	@override String get keyboardShortcutsDescription => 'キーボードショートカットをカスタマイズ';
	@override String get videoPlayerNavigation => '動画プレーヤーナビゲーション';
	@override String get videoPlayerNavigationDescription => '矢印キーで動画プレーヤーコントロールを操作';
	@override String get crashReporting => 'クラッシュレポート';
	@override String get crashReportingDescription => 'アプリの改善に役立つクラッシュレポートを送信';
	@override String get debugLogging => 'デバッグログ';
	@override String get debugLoggingDescription => 'トラブルシューティング用の詳細なログを有効化';
	@override String get viewLogs => 'ログを表示';
	@override String get viewLogsDescription => 'アプリケーションログを表示';
	@override String get clearCache => 'キャッシュをクリア';
	@override String get clearCacheDescription => 'キャッシュされたすべての画像とデータをクリアします。クリア後、コンテンツの読み込みに時間がかかる場合があります。';
	@override String get clearCacheSuccess => 'キャッシュを正常にクリアしました';
	@override String get resetSettings => '設定をリセット';
	@override String get resetSettingsDescription => 'すべての設定をデフォルト値にリセットします。この操作は元に戻せません。';
	@override String get resetSettingsSuccess => '設定を正常にリセットしました';
	@override String get shortcutsReset => 'ショートカットをデフォルトにリセットしました';
	@override String get about => 'アプリについて';
	@override String get aboutDescription => 'アプリ情報とライセンス';
	@override String get updates => 'アップデート';
	@override String get updateAvailable => 'アップデート利用可能';
	@override String get checkForUpdates => 'アップデートを確認';
	@override String get validationErrorEnterNumber => '有効な数値を入力してください';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '時間は${min}から${max} ${unit}の間である必要があります';
	@override String shortcutAlreadyAssigned({required Object action}) => 'ショートカットは既に${action}に割り当てられています';
	@override String shortcutUpdated({required Object action}) => '${action}のショートカットを更新しました';
	@override String get autoSkip => '自動スキップ';
	@override String get autoSkipIntro => 'イントロを自動スキップ';
	@override String get autoSkipIntroDescription => '数秒後にイントロマーカーを自動的にスキップ';
	@override String get autoSkipCredits => 'クレジットを自動スキップ';
	@override String get autoSkipCreditsDescription => 'クレジットを自動的にスキップして次のエピソードを再生';
	@override String get autoSkipDelay => '自動スキップの遅延';
	@override String autoSkipDelayDescription({required Object seconds}) => '自動スキップまで${seconds}秒待機';
	@override String get introPattern => 'イントロマーカーパターン';
	@override String get introPatternDescription => 'チャプタータイトルのイントロマーカーに一致する正規表現パターン';
	@override String get creditsPattern => 'クレジットマーカーパターン';
	@override String get creditsPatternDescription => 'チャプタータイトルのクレジットマーカーに一致する正規表現パターン';
	@override String get invalidRegex => '無効な正規表現';
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
	@override String get cellularDownloadBlocked => 'モバイルデータ通信ではダウンロードが無効です。WiFiに接続するか設定を変更してください。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '静かなメディアに対して100%以上の音量ブーストを許可';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discordで視聴中の内容を表示';
	@override String get autoPip => '自動ピクチャーインピクチャー';
	@override String get autoPipDescription => '再生中にアプリを離れると自動的にピクチャーインピクチャーに移行';
	@override String get matchContentFrameRate => 'コンテンツのフレームレートに合わせる';
	@override String get matchContentFrameRateDescription => '動画コンテンツに合わせてディスプレイのリフレッシュレートを調整し、ジャダーを低減しバッテリーを節約';
	@override String get tunneledPlayback => 'トンネル再生';
	@override String get tunneledPlaybackDescription => 'ハードウェアアクセラレーションされたビデオトンネリングを使用。HDRコンテンツで音声のみで画面が黒くなる場合は無効にしてください';
	@override String get requireProfileSelectionOnOpen => 'アプリ起動時にプロフィールを確認';
	@override String get requireProfileSelectionOnOpenDescription => 'アプリを開くたびにプロフィール選択を表示';
	@override String get confirmExitOnBack => '終了前に確認';
	@override String get confirmExitOnBackDescription => '戻るボタンでアプリを終了する際に確認ダイアログを表示';
	@override String get showNavBarLabels => 'ナビゲーションバーラベルを表示';
	@override String get showNavBarLabelsDescription => 'ナビゲーションバーアイコンの下にテキストラベルを表示';
}

// Path: search
class _TranslationsSearchJa implements TranslationsSearchEn {
	_TranslationsSearchJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get hint => '映画、番組、音楽を検索...';
	@override String get tryDifferentTerm => '別の検索語をお試しください';
	@override String get searchYourMedia => 'メディアを検索';
	@override String get enterTitleActorOrKeyword => 'タイトル、俳優、またはキーワードを入力';
}

// Path: hotkeys
class _TranslationsHotkeysJa implements TranslationsHotkeysEn {
	_TranslationsHotkeysJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName}のショートカットを設定';
	@override String get clearShortcut => 'ショートカットをクリア';
	@override late final _TranslationsHotkeysActionsJa actions = _TranslationsHotkeysActionsJa._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryJa implements TranslationsPinEntryEn {
	_TranslationsPinEntryJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'PINを入力';
	@override String get showPin => 'PINを表示';
	@override String get hidePin => 'PINを非表示';
}

// Path: fileInfo
class _TranslationsFileInfoJa implements TranslationsFileInfoEn {
	_TranslationsFileInfoJa._(this._root);

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
	@override String get path => 'パス';
	@override String get size => 'サイズ';
	@override String get container => 'コンテナ';
	@override String get duration => '長さ';
	@override String get optimizedForStreaming => 'ストリーミング最適化';
	@override String get has64bitOffsets => '64ビットオフセット';
}

// Path: mediaMenu
class _TranslationsMediaMenuJa implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '視聴済みにする';
	@override String get markAsUnwatched => '未視聴にする';
	@override String get removeFromContinueWatching => '視聴中から削除';
	@override String get goToSeries => 'シリーズへ移動';
	@override String get goToSeason => 'シーズンへ移動';
	@override String get shufflePlay => 'シャッフル再生';
	@override String get fileInfo => 'ファイル情報';
	@override String get deleteFromServer => 'サーバーから削除';
	@override String get confirmDelete => 'このメディアとそのファイルがサーバーから完全に削除されます。この操作は元に戻せません。';
	@override String get deleteMultipleWarning => 'すべてのエピソードとそのファイルが含まれます。';
	@override String get mediaDeletedSuccessfully => 'メディアアイテムを正常に削除しました';
	@override String get mediaFailedToDelete => 'メディアアイテムの削除に失敗しました';
	@override String get rate => '評価';
}

// Path: accessibility
class _TranslationsAccessibilityJa implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityJa._(this._root);

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
}

// Path: tooltips
class _TranslationsTooltipsJa implements TranslationsTooltipsEn {
	_TranslationsTooltipsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'シャッフル再生';
	@override String get playTrailer => '予告編を再生';
	@override String get markAsWatched => '視聴済みにする';
	@override String get markAsUnwatched => '未視聴にする';
}

// Path: videoControls
class _TranslationsVideoControlsJa implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsJa._(this._root);

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
	@override String get sleepTimerCompleted => 'スリープタイマー完了 - 再生を一時停止しました';
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
	@override String get settingsButton => '動画設定';
	@override String get audioTrackButton => '音声トラック';
	@override String get subtitlesButton => '字幕';
	@override String get tracksButton => '音声と字幕';
	@override String get chaptersButton => 'チャプター';
	@override String get versionsButton => '動画バージョン';
	@override String get pipButton => 'ピクチャーインピクチャーモード';
	@override String get aspectRatioButton => 'アスペクト比';
	@override String get ambientLighting => 'アンビエントライティング';
	@override String get ambientLightingOn => 'アンビエントライティングを有効化';
	@override String get ambientLightingOff => 'アンビエントライティングを無効化';
	@override String get fullscreenButton => 'フルスクリーンに入る';
	@override String get exitFullscreenButton => 'フルスクリーンを終了';
	@override String get alwaysOnTopButton => '常に前面に表示';
	@override String get rotationLockButton => '回転ロック';
	@override String get timelineSlider => '動画タイムライン';
	@override String get volumeSlider => '音量レベル';
	@override String endsAt({required Object time}) => '${time}に終了';
	@override String get pipActive => 'ピクチャーインピクチャーで再生中';
	@override String get pipFailed => 'ピクチャーインピクチャーの開始に失敗しました';
	@override late final _TranslationsVideoControlsPipErrorsJa pipErrors = _TranslationsVideoControlsPipErrorsJa._(_root);
	@override String get chapters => 'チャプター';
	@override String get noChaptersAvailable => 'チャプターがありません';
	@override String get queue => 'キュー';
	@override String get noQueueItems => 'キューにアイテムがありません';
}

// Path: userStatus
class _TranslationsUserStatusJa implements TranslationsUserStatusEn {
	_TranslationsUserStatusJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get admin => '管理者';
	@override String get restricted => '制限付き';
	@override String get protected => '保護済み';
	@override String get current => '現在';
}

// Path: messages
class _TranslationsMessagesJa implements TranslationsMessagesEn {
	_TranslationsMessagesJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '視聴済みにしました';
	@override String get markedAsUnwatched => '未視聴にしました';
	@override String get markedAsWatchedOffline => '視聴済みにしました（オンライン時に同期）';
	@override String get markedAsUnwatchedOffline => '未視聴にしました（オンライン時に同期）';
	@override String get removedFromContinueWatching => '視聴中から削除しました';
	@override String errorLoading({required Object error}) => 'エラー: ${error}';
	@override String get fileInfoNotAvailable => 'ファイル情報が利用できません';
	@override String errorLoadingFileInfo({required Object error}) => 'ファイル情報の読み込みエラー: ${error}';
	@override String get errorLoadingSeries => 'シリーズの読み込みエラー';
	@override String get errorLoadingSeason => 'シーズンの読み込みエラー';
	@override String get musicNotSupported => '音楽の再生はまだサポートされていません';
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
	@override String get noEpisodesFound => '最初のシーズンにエピソードが見つかりません';
	@override String get noEpisodesFoundGeneral => 'エピソードが見つかりません';
	@override String get noResultsFound => '結果が見つかりません';
	@override String sleepTimerSet({required Object label}) => 'スリープタイマーを${label}に設定しました';
	@override String get noItemsAvailable => 'アイテムがありません';
	@override String get failedToCreatePlayQueueNoItems => '再生キューの作成に失敗しました - アイテムがありません';
	@override String failedPlayback({required Object action, required Object error}) => '${action}に失敗しました: ${error}';
	@override String get switchingToCompatiblePlayer => '互換プレーヤーに切替中...';
	@override String get logsUploaded => 'ログをアップロードしました';
	@override String get logsUploadFailed => 'ログのアップロードに失敗しました';
	@override String get logId => 'ログID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingJa implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'スタイルオプション';
	@override String get fontSize => 'フォントサイズ';
	@override String get textColor => 'テキストの色';
	@override String get borderSize => '枠線サイズ';
	@override String get borderColor => '枠線の色';
	@override String get backgroundOpacity => '背景の不透明度';
	@override String get backgroundColor => '背景色';
	@override String get position => '位置';
}

// Path: mpvConfig
class _TranslationsMpvConfigJa implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigJa._(this._root);

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
class _TranslationsDialogJa implements TranslationsDialogEn {
	_TranslationsDialogJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '操作の確認';
}

// Path: discover
class _TranslationsDiscoverJa implements TranslationsDiscoverEn {
	_TranslationsDiscoverJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '探す';
	@override String get switchProfile => 'プロフィール切替';
	@override String get noContentAvailable => 'コンテンツがありません';
	@override String get addMediaToLibraries => 'ライブラリにメディアを追加してください';
	@override String get continueWatching => '視聴を続ける';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'あらすじ';
	@override String get cast => 'キャスト';
	@override String get extras => '予告編とエクストラ';
	@override String get seasons => 'シーズン';
	@override String get studio => 'スタジオ';
	@override String get rating => '評価';
	@override String episodeCount({required Object count}) => '${count}エピソード';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total}視聴済み';
	@override String get movie => '映画';
	@override String get tvShow => 'テレビ番組';
	@override String minutesLeft({required Object minutes}) => '残り${minutes}分';
}

// Path: errors
class _TranslationsErrorsJa implements TranslationsErrorsEn {
	_TranslationsErrorsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '検索に失敗しました: ${error}';
	@override String connectionTimeout({required Object context}) => '${context}の読み込み中に接続がタイムアウトしました';
	@override String get connectionFailed => 'Plexサーバーに接続できません';
	@override String failedToLoad({required Object context, required Object error}) => '${context}の読み込みに失敗しました: ${error}';
	@override String get noClientAvailable => 'クライアントが利用できません';
	@override String authenticationFailed({required Object error}) => '認証に失敗しました: ${error}';
	@override String get couldNotLaunchUrl => '認証URLを開けませんでした';
	@override String get pleaseEnterToken => 'トークンを入力してください';
	@override String get invalidToken => '無効なトークン';
	@override String failedToVerifyToken({required Object error}) => 'トークンの検証に失敗しました: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName}への切替に失敗しました';
}

// Path: libraries
class _TranslationsLibrariesJa implements TranslationsLibrariesEn {
	_TranslationsLibrariesJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ライブラリ';
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
	@override String get thisLibraryIsEmpty => 'このライブラリは空です';
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
}

// Path: about
class _TranslationsAboutJa implements TranslationsAboutEn {
	_TranslationsAboutJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'アプリについて';
	@override String get openSourceLicenses => 'オープンソースライセンス';
	@override String versionLabel({required Object version}) => 'バージョン ${version}';
	@override String get appDescription => 'Flutter製の美しいPlexクライアント';
	@override String get viewLicensesDescription => 'サードパーティライブラリのライセンスを表示';
}

// Path: serverSelection
class _TranslationsServerSelectionJa implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'どのサーバーにも接続できませんでした。ネットワークを確認してもう一度お試しください。';
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})のサーバーが見つかりません';
	@override String failedToLoadServers({required Object error}) => 'サーバーの読み込みに失敗しました: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailJa implements TranslationsHubDetailEn {
	_TranslationsHubDetailJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'タイトル';
	@override String get releaseYear => '公開年';
	@override String get dateAdded => '追加日';
	@override String get rating => '評価';
	@override String get noItemsFound => 'アイテムが見つかりません';
}

// Path: logs
class _TranslationsLogsJa implements TranslationsLogsEn {
	_TranslationsLogsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'ログをクリア';
	@override String get copyLogs => 'ログをコピー';
	@override String get uploadLogs => 'ログをアップロード';
	@override String get error => 'エラー:';
	@override String get stackTrace => 'スタックトレース:';
}

// Path: licenses
class _TranslationsLicensesJa implements TranslationsLicensesEn {
	_TranslationsLicensesJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '関連パッケージ';
	@override String get license => 'ライセンス';
	@override String licenseNumber({required Object number}) => 'ライセンス ${number}';
	@override String licensesCount({required Object count}) => '${count}件のライセンス';
}

// Path: navigation
class _TranslationsNavigationJa implements TranslationsNavigationEn {
	_TranslationsNavigationJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'ライブラリ';
	@override String get downloads => 'ダウンロード';
	@override String get liveTv => 'ライブTV';
}

// Path: liveTv
class _TranslationsLiveTvJa implements TranslationsLiveTvEn {
	_TranslationsLiveTvJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ライブTV';
	@override String get channels => 'チャンネル';
	@override String get guide => '番組表';
	@override String get noChannels => 'チャンネルがありません';
	@override String get noDvr => 'どのサーバーにもDVRが設定されていません';
	@override String get tuneFailed => 'チャンネルのチューニングに失敗しました';
	@override String get loading => 'チャンネルを読み込み中...';
	@override String get nowPlaying => '現在放送中';
	@override String get noPrograms => '番組データがありません';
	@override String channelNumber({required Object number}) => 'Ch. ${number}';
	@override String get live => 'ライブ';
	@override String get hd => 'HD';
	@override String get premiere => '新着';
	@override String get reloadGuide => '番組表を再読込';
	@override String get allChannels => 'すべてのチャンネル';
	@override String get now => '現在';
	@override String get today => '今日';
	@override String get midnight => '深夜';
	@override String get overnight => '深夜';
	@override String get morning => '朝';
	@override String get daytime => '昼';
	@override String get evening => '夕方';
	@override String get lateNight => '深夜';
	@override String get whatsOn => '放送中';
	@override String get watchChannel => 'チャンネルを視聴';
}

// Path: collections
class _TranslationsCollectionsJa implements TranslationsCollectionsEn {
	_TranslationsCollectionsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コレクション';
	@override String get collection => 'コレクション';
	@override String get empty => 'コレクションは空です';
	@override String get unknownLibrarySection => '削除できません：不明なライブラリセクション';
	@override String get deleteCollection => 'コレクションを削除';
	@override String deleteConfirm({required Object title}) => '"${title}"を削除してもよろしいですか？この操作は元に戻せません。';
	@override String get deleted => 'コレクションを削除しました';
	@override String get deleteFailed => 'コレクションの削除に失敗しました';
	@override String deleteFailedWithError({required Object error}) => 'コレクションの削除に失敗しました: ${error}';
	@override String failedToLoadItems({required Object error}) => 'コレクションアイテムの読み込みに失敗しました: ${error}';
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
}

// Path: playlists
class _TranslationsPlaylistsJa implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsJa._(this._root);

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
	@override String get errorCreating => 'プレイリストの作成に失敗しました';
	@override String get errorDeleting => 'プレイリストの削除に失敗しました';
	@override String get errorLoading => 'プレイリストの読み込みに失敗しました';
	@override String get errorAdding => 'プレイリストへの追加に失敗しました';
	@override String get errorReordering => 'プレイリストアイテムの並べ替えに失敗しました';
	@override String get errorRemoving => 'プレイリストからの削除に失敗しました';
}

// Path: watchTogether
class _TranslationsWatchTogetherJa implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherJa._(this._root);

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
	@override String get enterCodeHint => '8文字のコードを入力';
	@override String get pasteFromClipboard => 'クリップボードから貼り付け';
	@override String get pleaseEnterCode => 'セッションコードを入力してください';
	@override String get codeMustBe8Chars => 'セッションコードは8文字である必要があります';
	@override String get joinInstructions => 'ホストが共有したセッションコードを入力して視聴セッションに参加してください。';
	@override String get failedToCreate => 'セッションの作成に失敗しました';
	@override String get failedToJoin => 'セッションへの参加に失敗しました';
	@override String get sessionCodeCopied => 'セッションコードをクリップボードにコピーしました';
	@override String get relayUnreachable => 'リレーサーバーに到達できません。ISPが接続をブロックしている可能性があります。試すことはできますが、一緒に見る機能が動作しない場合があります。';
	@override String get reconnectingToHost => 'ホストに再接続中...';
	@override String get currentPlayback => '現在の再生';
	@override String get joinCurrentPlayback => '現在の再生に参加';
	@override String get joinCurrentPlaybackDescription => 'ホストが現在視聴中のコンテンツに戻る';
	@override String get failedToOpenCurrentPlayback => '現在の再生を開けませんでした';
	@override String participantJoined({required Object name}) => '${name}が参加しました';
	@override String participantLeft({required Object name}) => '${name}が退出しました';
}

// Path: downloads
class _TranslationsDownloadsJa implements TranslationsDownloadsEn {
	_TranslationsDownloadsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ダウンロード';
	@override String get manage => '管理';
	@override String get tvShows => 'テレビ番組';
	@override String get movies => '映画';
	@override String get noDownloads => 'ダウンロードなし';
	@override String get noDownloadsDescription => 'ダウンロードしたコンテンツはここに表示され、オフラインで視聴できます';
	@override String get downloadNow => 'ダウンロード';
	@override String get deleteDownload => 'ダウンロードを削除';
	@override String get retryDownload => 'ダウンロードを再試行';
	@override String get downloadQueued => 'ダウンロードをキューに追加しました';
	@override String episodesQueued({required Object count}) => '${count}エピソードをダウンロードキューに追加しました';
	@override String get downloadDeleted => 'ダウンロードを削除しました';
	@override String deleteConfirm({required Object title}) => '"${title}"を削除してもよろしいですか？ダウンロードしたファイルがデバイスから削除されます。';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title}を削除中... (${current}/${total})';
	@override String get noDownloadsTree => 'ダウンロードなし';
	@override String get pauseAll => 'すべて一時停止';
	@override String get resumeAll => 'すべて再開';
	@override String get deleteAll => 'すべて削除';
}

// Path: shaders
class _TranslationsShadersJa implements TranslationsShadersEn {
	_TranslationsShadersJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'シェーダー';
	@override String get noShaderDescription => '映像補正なし';
	@override String get nvscalerDescription => 'よりシャープな映像のためのNVIDIA画像スケーリング';
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
class _TranslationsCompanionRemoteJa implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コンパニオンリモート';
	@override String get connectToDevice => 'デバイスに接続';
	@override String get hostRemoteSession => 'リモートセッションをホスト';
	@override String get controlThisDevice => 'スマートフォンでこのデバイスを操作';
	@override String get remoteControl => 'リモコン';
	@override String get controlDesktop => 'デスクトップデバイスを操作';
	@override String connectedTo({required Object name}) => '${name}に接続中';
	@override late final _TranslationsCompanionRemoteSessionJa session = _TranslationsCompanionRemoteSessionJa._(_root);
	@override late final _TranslationsCompanionRemotePairingJa pairing = _TranslationsCompanionRemotePairingJa._(_root);
	@override late final _TranslationsCompanionRemoteRemoteJa remote = _TranslationsCompanionRemoteRemoteJa._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsJa implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => '再生設定';
	@override String get playbackSpeed => '再生速度';
	@override String get sleepTimer => 'スリープタイマー';
	@override String get audioSync => '音声同期';
	@override String get subtitleSync => '字幕同期';
	@override String get hdr => 'HDR';
	@override String get audioOutput => '音声出力';
	@override String get performanceOverlay => 'パフォーマンスオーバーレイ';
	@override String get audioPassthrough => 'オーディオパススルー';
	@override String get audioNormalization => '音声正規化';
}

// Path: externalPlayer
class _TranslationsExternalPlayerJa implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '外部プレーヤー';
	@override String get useExternalPlayer => '外部プレーヤーを使用';
	@override String get useExternalPlayerDescription => '内蔵プレーヤーの代わりに外部アプリで動画を開く';
	@override String get selectPlayer => 'プレーヤーを選択';
	@override String get systemDefault => 'システムデフォルト';
	@override String get addCustomPlayer => 'カスタムプレーヤーを追加';
	@override String get playerName => 'プレーヤー名';
	@override String get playerCommand => 'コマンド';
	@override String get playerPackage => 'パッケージ名';
	@override String get playerUrlScheme => 'URLスキーム';
	@override String get customPlayer => 'カスタムプレーヤー';
	@override String get off => 'オフ';
	@override String get launchFailed => '外部プレーヤーの起動に失敗しました';
	@override String appNotInstalled({required Object name}) => '${name}がインストールされていません';
	@override String get playInExternalPlayer => '外部プレーヤーで再生';
}

// Path: metadataEdit
class _TranslationsMetadataEditJa implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditJa._(this._root);

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
	@override String get selectPoster => 'ポスターを選択';
	@override String get selectBackground => '背景を選択';
	@override String get fromUrl => 'URLから';
	@override String get uploadFile => 'ファイルをアップロード';
	@override String get enterImageUrl => '画像URLを入力';
	@override String get imageUrl => '画像URL';
	@override String get metadataUpdated => 'メタデータを更新しました';
	@override String get metadataUpdateFailed => 'メタデータの更新に失敗しました';
	@override String get artworkUpdated => 'アートワークを更新しました';
	@override String get artworkUpdateFailed => 'アートワークの更新に失敗しました';
	@override String get noArtworkAvailable => 'アートワークがありません';
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
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsJa implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsJa._(this._root);

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
	@override String get speedIncrease => '速度を上げる';
	@override String get speedDecrease => '速度を下げる';
	@override String get speedReset => '速度をリセット';
	@override String get subSeekNext => '次の字幕にシーク';
	@override String get subSeekPrev => '前の字幕にシーク';
	@override String get shaderToggle => 'シェーダー切替';
	@override String get skipMarker => 'イントロ/クレジットをスキップ';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsJa implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0以降が必要です';
	@override String get iosVersion => 'iOS 15.0以降が必要です';
	@override String get permissionDisabled => 'ピクチャーインピクチャーの権限が無効です。設定 > アプリ > Plezy > ピクチャーインピクチャーで有効にしてください';
	@override String get notSupported => 'デバイスはピクチャーインピクチャーモードをサポートしていません';
	@override String get voSwitchFailed => 'ピクチャーインピクチャーの映像出力切替に失敗しました';
	@override String get failed => 'ピクチャーインピクチャーの開始に失敗しました';
	@override String unknown({required Object error}) => 'エラーが発生しました: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsJa implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'おすすめ';
	@override String get browse => 'ブラウズ';
	@override String get collections => 'コレクション';
	@override String get playlists => 'プレイリスト';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsJa implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get all => 'すべて';
	@override String get movies => '映画';
	@override String get shows => 'テレビ番組';
	@override String get seasons => 'シーズン';
	@override String get episodes => 'エピソード';
	@override String get folders => 'フォルダ';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionJa implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'リモートセッションを作成中...';
	@override String get failedToCreate => 'リモートセッションの作成に失敗しました:';
	@override String get noSession => '利用可能なセッションがありません';
	@override String get scanQrCode => 'QRコードをスキャン';
	@override String get orEnterManually => 'または手動で入力';
	@override String get hostAddress => 'ホストアドレス';
	@override String get sessionId => 'セッションID';
	@override String get pin => 'PIN';
	@override String get connected => '接続済み';
	@override String get waitingForConnection => '接続を待機中...';
	@override String get usePhoneToControl => 'モバイルデバイスでこのアプリを操作';
	@override String copiedToClipboard({required Object label}) => '${label}をクリップボードにコピーしました';
	@override String get copyToClipboard => 'クリップボードにコピー';
	@override String get newSession => '新しいセッション';
	@override String get minimize => '最小化';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingJa implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get scan => 'スキャン';
	@override String get manual => '手動';
	@override String get pairWithDesktop => 'デスクトップとペアリング';
	@override String get enterSessionDetails => 'デスクトップデバイスに表示されたセッション情報を入力';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => '8文字のセッションIDを入力';
	@override String get pinHint => '6桁のPINを入力';
	@override String get connecting => '接続中...';
	@override String get tips => 'ヒント';
	@override String get tipDesktop => 'デスクトップでPlezyを開き、設定またはメニューからコンパニオンリモートを有効にしてください';
	@override String get tipScan => 'スキャンタブを使用して、デスクトップのQRコードをスキャンして素早くペアリング';
	@override String get tipWifi => '両方のデバイスが同じWiFiネットワークに接続されていることを確認';
	@override String get cameraPermissionRequired => 'QRコードをスキャンするにはカメラの権限が必要です。\nデバイスの設定でカメラへのアクセスを許可してください。';
	@override String cameraError({required Object error}) => 'カメラを起動できませんでした: ${error}';
	@override String get scanInstruction => 'デスクトップに表示されたQRコードにカメラを向けてください';
	@override String get invalidQrCode => '無効なQRコード形式';
	@override String get validationHostRequired => 'ホストアドレスを入力してください';
	@override String get validationHostFormat => '形式はIP:ポートである必要があります（例: 192.168.1.100:48632）';
	@override String get validationSessionIdRequired => 'セッションIDを入力してください';
	@override String get validationSessionIdLength => 'セッションIDは8文字である必要があります';
	@override String get validationPinRequired => 'PINを入力してください';
	@override String get validationPinLength => 'PINは6桁である必要があります';
	@override String get connectionTimedOut => '接続がタイムアウトしました。セッションIDとPINを確認してください。';
	@override String get sessionNotFound => 'セッションが見つかりませんでした。認証情報を確認してください。';
	@override String failedToConnect({required Object error}) => '接続に失敗しました: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteJa implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'リモートセッションから切断しますか？';
	@override String get reconnecting => '再接続中...';
	@override String attemptOf({required Object current}) => '試行 ${current}/5';
	@override String get retryNow => '今すぐ再試行';
	@override String get connectionError => '接続エラー';
	@override String get notConnected => '未接続';
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
			'auth.waitingForAuth' => '認証を待機中...\nブラウザでサインインを完了してください。',
			'auth.useBrowser' => 'ブラウザを使用',
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
			'common.shuffle' => 'シャッフル',
			'common.addTo' => '追加...',
			'common.createNew' => '新規作成',
			'common.remove' => '削除',
			'common.paste' => '貼り付け',
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
			'common.loading' => '読み込み中...',
			'common.reconnect' => '再接続',
			'common.exitConfirmTitle' => 'アプリを終了しますか？',
			'common.exitConfirmMessage' => '終了してもよろしいですか？',
			'common.dontAskAgain' => '次回から表示しない',
			'common.exit' => '終了',
			'common.viewAll' => 'すべて表示',
			'common.checkingNetwork' => 'ネットワークを確認中...',
			'common.refreshingServers' => 'サーバーを更新中...',
			'common.loadingServers' => 'サーバーを読み込み中...',
			'common.connectingToServers' => 'サーバーに接続中...',
			'common.startingOfflineMode' => 'オフラインモードを開始中...',
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
			'settings.language' => '言語',
			'settings.theme' => 'テーマ',
			'settings.appearance' => '外観',
			'settings.videoPlayback' => '動画再生',
			'settings.advanced' => '詳細',
			'settings.episodePosterMode' => 'エピソードポスタースタイル',
			'settings.seriesPoster' => 'シリーズポスター',
			'settings.seriesPosterDescription' => 'すべてのエピソードにシリーズポスターを表示',
			'settings.seasonPoster' => 'シーズンポスター',
			'settings.seasonPosterDescription' => 'エピソードにシーズン固有のポスターを表示',
			'settings.episodeThumbnail' => 'エピソードサムネイル',
			'settings.episodeThumbnailDescription' => '16:9のエピソードスクリーンショットサムネイルを表示',
			'settings.showHeroSectionDescription' => 'ホーム画面に注目コンテンツのカルーセルを表示',
			'settings.secondsLabel' => '秒',
			'settings.minutesLabel' => '分',
			'settings.secondsShort' => '秒',
			'settings.minutesShort' => '分',
			'settings.durationHint' => ({required Object min, required Object max}) => '時間を入力 (${min}-${max})',
			'settings.systemTheme' => 'システム',
			'settings.systemThemeDescription' => 'システム設定に従う',
			'settings.lightTheme' => 'ライト',
			'settings.darkTheme' => 'ダーク',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'OLED画面向けの純粋な黒',
			'settings.libraryDensity' => 'ライブラリの密度',
			'settings.compact' => 'コンパクト',
			'settings.compactDescription' => '小さいカード、より多くのアイテムを表示',
			'settings.normal' => '標準',
			'settings.normalDescription' => 'デフォルトサイズ',
			'settings.comfortable' => 'ゆったり',
			'settings.comfortableDescription' => '大きいカード、表示アイテム数を減少',
			'settings.viewMode' => '表示モード',
			'settings.gridView' => 'グリッド',
			'settings.gridViewDescription' => 'グリッドレイアウトでアイテムを表示',
			'settings.listView' => 'リスト',
			'settings.listViewDescription' => 'リストレイアウトでアイテムを表示',
			'settings.showHeroSection' => 'ヒーローセクションを表示',
			'settings.useGlobalHubs' => 'Plex Homeレイアウトを使用',
			'settings.useGlobalHubsDescription' => '公式Plexクライアントのようにホームページのハブを表示。オフにすると、ライブラリごとのおすすめを表示。',
			'settings.showServerNameOnHubs' => 'ハブにサーバー名を表示',
			'settings.showServerNameOnHubsDescription' => 'ハブタイトルに常にサーバー名を表示。オフにすると、重複名のみ表示。',
			'settings.alwaysKeepSidebarOpen' => 'サイドバーを常に開いておく',
			'settings.alwaysKeepSidebarOpenDescription' => 'サイドバーを展開したまま、コンテンツ領域が調整される',
			'settings.showUnwatchedCount' => '未視聴数を表示',
			'settings.showUnwatchedCountDescription' => '番組とシーズンに未視聴エピソード数を表示',
			'settings.hideSpoilers' => '未視聴エピソードのネタバレを非表示',
			'settings.hideSpoilersDescription' => 'まだ視聴していないエピソードのサムネイルをぼかし、説明を非表示',
			'settings.playerBackend' => 'プレーヤーバックエンド',
			'settings.exoPlayer' => 'ExoPlayer（推奨）',
			'settings.exoPlayerDescription' => 'より良いハードウェアサポートのAndroidネイティブプレーヤー',
			'settings.mpv' => 'mpv',
			'settings.mpvDescription' => 'より多くの機能とASS字幕サポートの高度なプレーヤー',
			'settings.hardwareDecoding' => 'ハードウェアデコード',
			'settings.hardwareDecodingDescription' => '利用可能な場合にハードウェアアクセラレーションを使用',
			'settings.bufferSize' => 'バッファサイズ',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => '自動（推奨）',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'デバイスのメモリは${heap}MBです。${size}MBのバッファは再生の問題を引き起こす可能性があります。',
			'settings.subtitleStyling' => '字幕スタイル',
			'settings.subtitleStylingDescription' => '字幕の外観をカスタマイズ',
			'settings.smallSkipDuration' => '短いスキップ時間',
			'settings.largeSkipDuration' => '長いスキップ時間',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds}秒',
			'settings.defaultSleepTimer' => 'デフォルトスリープタイマー',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes}分',
			'settings.rememberTrackSelections' => '番組/映画ごとにトラック選択を記憶',
			'settings.rememberTrackSelectionsDescription' => '再生中にトラックを変更すると、音声と字幕の言語設定を自動保存',
			'settings.clickVideoTogglesPlayback' => '動画クリックで再生/一時停止を切替',
			'settings.clickVideoTogglesPlaybackDescription' => '有効にすると、動画プレーヤーをクリックで再生/一時停止。それ以外は再生コントロールの表示/非表示。',
			'settings.videoPlayerControls' => '動画プレーヤーコントロール',
			'settings.keyboardShortcuts' => 'キーボードショートカット',
			'settings.keyboardShortcutsDescription' => 'キーボードショートカットをカスタマイズ',
			'settings.videoPlayerNavigation' => '動画プレーヤーナビゲーション',
			'settings.videoPlayerNavigationDescription' => '矢印キーで動画プレーヤーコントロールを操作',
			'settings.crashReporting' => 'クラッシュレポート',
			'settings.crashReportingDescription' => 'アプリの改善に役立つクラッシュレポートを送信',
			'settings.debugLogging' => 'デバッグログ',
			'settings.debugLoggingDescription' => 'トラブルシューティング用の詳細なログを有効化',
			'settings.viewLogs' => 'ログを表示',
			'settings.viewLogsDescription' => 'アプリケーションログを表示',
			'settings.clearCache' => 'キャッシュをクリア',
			'settings.clearCacheDescription' => 'キャッシュされたすべての画像とデータをクリアします。クリア後、コンテンツの読み込みに時間がかかる場合があります。',
			'settings.clearCacheSuccess' => 'キャッシュを正常にクリアしました',
			'settings.resetSettings' => '設定をリセット',
			'settings.resetSettingsDescription' => 'すべての設定をデフォルト値にリセットします。この操作は元に戻せません。',
			'settings.resetSettingsSuccess' => '設定を正常にリセットしました',
			'settings.shortcutsReset' => 'ショートカットをデフォルトにリセットしました',
			'settings.about' => 'アプリについて',
			'settings.aboutDescription' => 'アプリ情報とライセンス',
			'settings.updates' => 'アップデート',
			'settings.updateAvailable' => 'アップデート利用可能',
			'settings.checkForUpdates' => 'アップデートを確認',
			'settings.validationErrorEnterNumber' => '有効な数値を入力してください',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '時間は${min}から${max} ${unit}の間である必要があります',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'ショートカットは既に${action}に割り当てられています',
			'settings.shortcutUpdated' => ({required Object action}) => '${action}のショートカットを更新しました',
			'settings.autoSkip' => '自動スキップ',
			'settings.autoSkipIntro' => 'イントロを自動スキップ',
			'settings.autoSkipIntroDescription' => '数秒後にイントロマーカーを自動的にスキップ',
			'settings.autoSkipCredits' => 'クレジットを自動スキップ',
			'settings.autoSkipCreditsDescription' => 'クレジットを自動的にスキップして次のエピソードを再生',
			'settings.autoSkipDelay' => '自動スキップの遅延',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自動スキップまで${seconds}秒待機',
			'settings.introPattern' => 'イントロマーカーパターン',
			'settings.introPatternDescription' => 'チャプタータイトルのイントロマーカーに一致する正規表現パターン',
			'settings.creditsPattern' => 'クレジットマーカーパターン',
			'settings.creditsPatternDescription' => 'チャプタータイトルのクレジットマーカーに一致する正規表現パターン',
			'settings.invalidRegex' => '無効な正規表現',
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
			'settings.cellularDownloadBlocked' => 'モバイルデータ通信ではダウンロードが無効です。WiFiに接続するか設定を変更してください。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '静かなメディアに対して100%以上の音量ブーストを許可',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discordで視聴中の内容を表示',
			'settings.autoPip' => '自動ピクチャーインピクチャー',
			'settings.autoPipDescription' => '再生中にアプリを離れると自動的にピクチャーインピクチャーに移行',
			'settings.matchContentFrameRate' => 'コンテンツのフレームレートに合わせる',
			'settings.matchContentFrameRateDescription' => '動画コンテンツに合わせてディスプレイのリフレッシュレートを調整し、ジャダーを低減しバッテリーを節約',
			'settings.tunneledPlayback' => 'トンネル再生',
			'settings.tunneledPlaybackDescription' => 'ハードウェアアクセラレーションされたビデオトンネリングを使用。HDRコンテンツで音声のみで画面が黒くなる場合は無効にしてください',
			'settings.requireProfileSelectionOnOpen' => 'アプリ起動時にプロフィールを確認',
			'settings.requireProfileSelectionOnOpenDescription' => 'アプリを開くたびにプロフィール選択を表示',
			'settings.confirmExitOnBack' => '終了前に確認',
			'settings.confirmExitOnBackDescription' => '戻るボタンでアプリを終了する際に確認ダイアログを表示',
			'settings.showNavBarLabels' => 'ナビゲーションバーラベルを表示',
			'settings.showNavBarLabelsDescription' => 'ナビゲーションバーアイコンの下にテキストラベルを表示',
			'search.hint' => '映画、番組、音楽を検索...',
			'search.tryDifferentTerm' => '別の検索語をお試しください',
			'search.searchYourMedia' => 'メディアを検索',
			'search.enterTitleActorOrKeyword' => 'タイトル、俳優、またはキーワードを入力',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName}のショートカットを設定',
			'hotkeys.clearShortcut' => 'ショートカットをクリア',
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
			'hotkeys.actions.speedIncrease' => '速度を上げる',
			'hotkeys.actions.speedDecrease' => '速度を下げる',
			'hotkeys.actions.speedReset' => '速度をリセット',
			'hotkeys.actions.subSeekNext' => '次の字幕にシーク',
			'hotkeys.actions.subSeekPrev' => '前の字幕にシーク',
			'hotkeys.actions.shaderToggle' => 'シェーダー切替',
			'hotkeys.actions.skipMarker' => 'イントロ/クレジットをスキップ',
			'pinEntry.enterPin' => 'PINを入力',
			'pinEntry.showPin' => 'PINを表示',
			'pinEntry.hidePin' => 'PINを非表示',
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
			'fileInfo.path' => 'パス',
			'fileInfo.size' => 'サイズ',
			'fileInfo.container' => 'コンテナ',
			'fileInfo.duration' => '長さ',
			'fileInfo.optimizedForStreaming' => 'ストリーミング最適化',
			'fileInfo.has64bitOffsets' => '64ビットオフセット',
			'mediaMenu.markAsWatched' => '視聴済みにする',
			'mediaMenu.markAsUnwatched' => '未視聴にする',
			'mediaMenu.removeFromContinueWatching' => '視聴中から削除',
			'mediaMenu.goToSeries' => 'シリーズへ移動',
			'mediaMenu.goToSeason' => 'シーズンへ移動',
			'mediaMenu.shufflePlay' => 'シャッフル再生',
			'mediaMenu.fileInfo' => 'ファイル情報',
			'mediaMenu.deleteFromServer' => 'サーバーから削除',
			'mediaMenu.confirmDelete' => 'このメディアとそのファイルがサーバーから完全に削除されます。この操作は元に戻せません。',
			'mediaMenu.deleteMultipleWarning' => 'すべてのエピソードとそのファイルが含まれます。',
			'mediaMenu.mediaDeletedSuccessfully' => 'メディアアイテムを正常に削除しました',
			'mediaMenu.mediaFailedToDelete' => 'メディアアイテムの削除に失敗しました',
			'mediaMenu.rate' => '評価',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}、映画',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}、テレビ番組',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}、${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}、${seasonInfo}',
			'accessibility.mediaCardWatched' => '視聴済み',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent}パーセント視聴済み',
			'accessibility.mediaCardUnwatched' => '未視聴',
			'accessibility.tapToPlay' => 'タップして再生',
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
			'videoControls.sleepTimerCompleted' => 'スリープタイマー完了 - 再生を一時停止しました',
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
			'videoControls.settingsButton' => '動画設定',
			'videoControls.audioTrackButton' => '音声トラック',
			'videoControls.subtitlesButton' => '字幕',
			'videoControls.tracksButton' => '音声と字幕',
			'videoControls.chaptersButton' => 'チャプター',
			'videoControls.versionsButton' => '動画バージョン',
			'videoControls.pipButton' => 'ピクチャーインピクチャーモード',
			'videoControls.aspectRatioButton' => 'アスペクト比',
			'videoControls.ambientLighting' => 'アンビエントライティング',
			'videoControls.ambientLightingOn' => 'アンビエントライティングを有効化',
			'videoControls.ambientLightingOff' => 'アンビエントライティングを無効化',
			'videoControls.fullscreenButton' => 'フルスクリーンに入る',
			'videoControls.exitFullscreenButton' => 'フルスクリーンを終了',
			'videoControls.alwaysOnTopButton' => '常に前面に表示',
			'videoControls.rotationLockButton' => '回転ロック',
			'videoControls.timelineSlider' => '動画タイムライン',
			'videoControls.volumeSlider' => '音量レベル',
			'videoControls.endsAt' => ({required Object time}) => '${time}に終了',
			'videoControls.pipActive' => 'ピクチャーインピクチャーで再生中',
			'videoControls.pipFailed' => 'ピクチャーインピクチャーの開始に失敗しました',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0以降が必要です',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0以降が必要です',
			'videoControls.pipErrors.permissionDisabled' => 'ピクチャーインピクチャーの権限が無効です。設定 > アプリ > Plezy > ピクチャーインピクチャーで有効にしてください',
			'videoControls.pipErrors.notSupported' => 'デバイスはピクチャーインピクチャーモードをサポートしていません',
			'videoControls.pipErrors.voSwitchFailed' => 'ピクチャーインピクチャーの映像出力切替に失敗しました',
			'videoControls.pipErrors.failed' => 'ピクチャーインピクチャーの開始に失敗しました',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'エラーが発生しました: ${error}',
			'videoControls.chapters' => 'チャプター',
			'videoControls.noChaptersAvailable' => 'チャプターがありません',
			'videoControls.queue' => 'キュー',
			'videoControls.noQueueItems' => 'キューにアイテムがありません',
			'userStatus.admin' => '管理者',
			'userStatus.restricted' => '制限付き',
			'userStatus.protected' => '保護済み',
			'userStatus.current' => '現在',
			'messages.markedAsWatched' => '視聴済みにしました',
			'messages.markedAsUnwatched' => '未視聴にしました',
			'messages.markedAsWatchedOffline' => '視聴済みにしました（オンライン時に同期）',
			'messages.markedAsUnwatchedOffline' => '未視聴にしました（オンライン時に同期）',
			'messages.removedFromContinueWatching' => '視聴中から削除しました',
			'messages.errorLoading' => ({required Object error}) => 'エラー: ${error}',
			'messages.fileInfoNotAvailable' => 'ファイル情報が利用できません',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'ファイル情報の読み込みエラー: ${error}',
			'messages.errorLoadingSeries' => 'シリーズの読み込みエラー',
			'messages.errorLoadingSeason' => 'シーズンの読み込みエラー',
			'messages.musicNotSupported' => '音楽の再生はまだサポートされていません',
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
			'messages.noEpisodesFound' => '最初のシーズンにエピソードが見つかりません',
			'messages.noEpisodesFoundGeneral' => 'エピソードが見つかりません',
			'messages.noResultsFound' => '結果が見つかりません',
			'messages.sleepTimerSet' => ({required Object label}) => 'スリープタイマーを${label}に設定しました',
			'messages.noItemsAvailable' => 'アイテムがありません',
			'messages.failedToCreatePlayQueueNoItems' => '再生キューの作成に失敗しました - アイテムがありません',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action}に失敗しました: ${error}',
			'messages.switchingToCompatiblePlayer' => '互換プレーヤーに切替中...',
			'messages.logsUploaded' => 'ログをアップロードしました',
			'messages.logsUploadFailed' => 'ログのアップロードに失敗しました',
			'messages.logId' => 'ログID',
			'subtitlingStyling.stylingOptions' => 'スタイルオプション',
			'subtitlingStyling.fontSize' => 'フォントサイズ',
			'subtitlingStyling.textColor' => 'テキストの色',
			'subtitlingStyling.borderSize' => '枠線サイズ',
			'subtitlingStyling.borderColor' => '枠線の色',
			'subtitlingStyling.backgroundOpacity' => '背景の不透明度',
			'subtitlingStyling.backgroundColor' => '背景色',
			'subtitlingStyling.position' => '位置',
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
			'discover.title' => '探す',
			'discover.switchProfile' => 'プロフィール切替',
			'discover.noContentAvailable' => 'コンテンツがありません',
			'discover.addMediaToLibraries' => 'ライブラリにメディアを追加してください',
			'discover.continueWatching' => '視聴を続ける',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'あらすじ',
			'discover.cast' => 'キャスト',
			'discover.extras' => '予告編とエクストラ',
			'discover.seasons' => 'シーズン',
			'discover.studio' => 'スタジオ',
			'discover.rating' => '評価',
			'discover.episodeCount' => ({required Object count}) => '${count}エピソード',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total}視聴済み',
			'discover.movie' => '映画',
			'discover.tvShow' => 'テレビ番組',
			'discover.minutesLeft' => ({required Object minutes}) => '残り${minutes}分',
			'errors.searchFailed' => ({required Object error}) => '検索に失敗しました: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => '${context}の読み込み中に接続がタイムアウトしました',
			'errors.connectionFailed' => 'Plexサーバーに接続できません',
			'errors.failedToLoad' => ({required Object context, required Object error}) => '${context}の読み込みに失敗しました: ${error}',
			'errors.noClientAvailable' => 'クライアントが利用できません',
			'errors.authenticationFailed' => ({required Object error}) => '認証に失敗しました: ${error}',
			'errors.couldNotLaunchUrl' => '認証URLを開けませんでした',
			'errors.pleaseEnterToken' => 'トークンを入力してください',
			'errors.invalidToken' => '無効なトークン',
			'errors.failedToVerifyToken' => ({required Object error}) => 'トークンの検証に失敗しました: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName}への切替に失敗しました',
			'libraries.title' => 'ライブラリ',
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
			'libraries.thisLibraryIsEmpty' => 'このライブラリは空です',
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
			'libraries.groupings.all' => 'すべて',
			'libraries.groupings.movies' => '映画',
			'libraries.groupings.shows' => 'テレビ番組',
			'libraries.groupings.seasons' => 'シーズン',
			'libraries.groupings.episodes' => 'エピソード',
			'libraries.groupings.folders' => 'フォルダ',
			'about.title' => 'アプリについて',
			'about.openSourceLicenses' => 'オープンソースライセンス',
			'about.versionLabel' => ({required Object version}) => 'バージョン ${version}',
			'about.appDescription' => 'Flutter製の美しいPlexクライアント',
			'about.viewLicensesDescription' => 'サードパーティライブラリのライセンスを表示',
			'serverSelection.allServerConnectionsFailed' => 'どのサーバーにも接続できませんでした。ネットワークを確認してもう一度お試しください。',
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
			'logs.error' => 'エラー:',
			'logs.stackTrace' => 'スタックトレース:',
			'licenses.relatedPackages' => '関連パッケージ',
			'licenses.license' => 'ライセンス',
			'licenses.licenseNumber' => ({required Object number}) => 'ライセンス ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count}件のライセンス',
			'navigation.libraries' => 'ライブラリ',
			'navigation.downloads' => 'ダウンロード',
			'navigation.liveTv' => 'ライブTV',
			'liveTv.title' => 'ライブTV',
			'liveTv.channels' => 'チャンネル',
			'liveTv.guide' => '番組表',
			'liveTv.noChannels' => 'チャンネルがありません',
			'liveTv.noDvr' => 'どのサーバーにもDVRが設定されていません',
			'liveTv.tuneFailed' => 'チャンネルのチューニングに失敗しました',
			'liveTv.loading' => 'チャンネルを読み込み中...',
			'liveTv.nowPlaying' => '現在放送中',
			'liveTv.noPrograms' => '番組データがありません',
			'liveTv.channelNumber' => ({required Object number}) => 'Ch. ${number}',
			'liveTv.live' => 'ライブ',
			_ => null,
		} ?? switch (path) {
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => '新着',
			'liveTv.reloadGuide' => '番組表を再読込',
			'liveTv.allChannels' => 'すべてのチャンネル',
			'liveTv.now' => '現在',
			'liveTv.today' => '今日',
			'liveTv.midnight' => '深夜',
			'liveTv.overnight' => '深夜',
			'liveTv.morning' => '朝',
			'liveTv.daytime' => '昼',
			'liveTv.evening' => '夕方',
			'liveTv.lateNight' => '深夜',
			'liveTv.whatsOn' => '放送中',
			'liveTv.watchChannel' => 'チャンネルを視聴',
			'collections.title' => 'コレクション',
			'collections.collection' => 'コレクション',
			'collections.empty' => 'コレクションは空です',
			'collections.unknownLibrarySection' => '削除できません：不明なライブラリセクション',
			'collections.deleteCollection' => 'コレクションを削除',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}"を削除してもよろしいですか？この操作は元に戻せません。',
			'collections.deleted' => 'コレクションを削除しました',
			'collections.deleteFailed' => 'コレクションの削除に失敗しました',
			'collections.deleteFailedWithError' => ({required Object error}) => 'コレクションの削除に失敗しました: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'コレクションアイテムの読み込みに失敗しました: ${error}',
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
			'playlists.errorCreating' => 'プレイリストの作成に失敗しました',
			'playlists.errorDeleting' => 'プレイリストの削除に失敗しました',
			'playlists.errorLoading' => 'プレイリストの読み込みに失敗しました',
			'playlists.errorAdding' => 'プレイリストへの追加に失敗しました',
			'playlists.errorReordering' => 'プレイリストアイテムの並べ替えに失敗しました',
			'playlists.errorRemoving' => 'プレイリストからの削除に失敗しました',
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
			'watchTogether.enterCodeHint' => '8文字のコードを入力',
			'watchTogether.pasteFromClipboard' => 'クリップボードから貼り付け',
			'watchTogether.pleaseEnterCode' => 'セッションコードを入力してください',
			'watchTogether.codeMustBe8Chars' => 'セッションコードは8文字である必要があります',
			'watchTogether.joinInstructions' => 'ホストが共有したセッションコードを入力して視聴セッションに参加してください。',
			'watchTogether.failedToCreate' => 'セッションの作成に失敗しました',
			'watchTogether.failedToJoin' => 'セッションへの参加に失敗しました',
			'watchTogether.sessionCodeCopied' => 'セッションコードをクリップボードにコピーしました',
			'watchTogether.relayUnreachable' => 'リレーサーバーに到達できません。ISPが接続をブロックしている可能性があります。試すことはできますが、一緒に見る機能が動作しない場合があります。',
			'watchTogether.reconnectingToHost' => 'ホストに再接続中...',
			'watchTogether.currentPlayback' => '現在の再生',
			'watchTogether.joinCurrentPlayback' => '現在の再生に参加',
			'watchTogether.joinCurrentPlaybackDescription' => 'ホストが現在視聴中のコンテンツに戻る',
			'watchTogether.failedToOpenCurrentPlayback' => '現在の再生を開けませんでした',
			'watchTogether.participantJoined' => ({required Object name}) => '${name}が参加しました',
			'watchTogether.participantLeft' => ({required Object name}) => '${name}が退出しました',
			'downloads.title' => 'ダウンロード',
			'downloads.manage' => '管理',
			'downloads.tvShows' => 'テレビ番組',
			'downloads.movies' => '映画',
			'downloads.noDownloads' => 'ダウンロードなし',
			'downloads.noDownloadsDescription' => 'ダウンロードしたコンテンツはここに表示され、オフラインで視聴できます',
			'downloads.downloadNow' => 'ダウンロード',
			'downloads.deleteDownload' => 'ダウンロードを削除',
			'downloads.retryDownload' => 'ダウンロードを再試行',
			'downloads.downloadQueued' => 'ダウンロードをキューに追加しました',
			'downloads.episodesQueued' => ({required Object count}) => '${count}エピソードをダウンロードキューに追加しました',
			'downloads.downloadDeleted' => 'ダウンロードを削除しました',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}"を削除してもよろしいですか？ダウンロードしたファイルがデバイスから削除されます。',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title}を削除中... (${current}/${total})',
			'downloads.noDownloadsTree' => 'ダウンロードなし',
			'downloads.pauseAll' => 'すべて一時停止',
			'downloads.resumeAll' => 'すべて再開',
			'downloads.deleteAll' => 'すべて削除',
			'shaders.title' => 'シェーダー',
			'shaders.noShaderDescription' => '映像補正なし',
			'shaders.nvscalerDescription' => 'よりシャープな映像のためのNVIDIA画像スケーリング',
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
			'companionRemote.connectToDevice' => 'デバイスに接続',
			'companionRemote.hostRemoteSession' => 'リモートセッションをホスト',
			'companionRemote.controlThisDevice' => 'スマートフォンでこのデバイスを操作',
			'companionRemote.remoteControl' => 'リモコン',
			'companionRemote.controlDesktop' => 'デスクトップデバイスを操作',
			'companionRemote.connectedTo' => ({required Object name}) => '${name}に接続中',
			'companionRemote.session.creatingSession' => 'リモートセッションを作成中...',
			'companionRemote.session.failedToCreate' => 'リモートセッションの作成に失敗しました:',
			'companionRemote.session.noSession' => '利用可能なセッションがありません',
			'companionRemote.session.scanQrCode' => 'QRコードをスキャン',
			'companionRemote.session.orEnterManually' => 'または手動で入力',
			'companionRemote.session.hostAddress' => 'ホストアドレス',
			'companionRemote.session.sessionId' => 'セッションID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => '接続済み',
			'companionRemote.session.waitingForConnection' => '接続を待機中...',
			'companionRemote.session.usePhoneToControl' => 'モバイルデバイスでこのアプリを操作',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label}をクリップボードにコピーしました',
			'companionRemote.session.copyToClipboard' => 'クリップボードにコピー',
			'companionRemote.session.newSession' => '新しいセッション',
			'companionRemote.session.minimize' => '最小化',
			'companionRemote.pairing.scan' => 'スキャン',
			'companionRemote.pairing.manual' => '手動',
			'companionRemote.pairing.pairWithDesktop' => 'デスクトップとペアリング',
			'companionRemote.pairing.enterSessionDetails' => 'デスクトップデバイスに表示されたセッション情報を入力',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => '8文字のセッションIDを入力',
			'companionRemote.pairing.pinHint' => '6桁のPINを入力',
			'companionRemote.pairing.connecting' => '接続中...',
			'companionRemote.pairing.tips' => 'ヒント',
			'companionRemote.pairing.tipDesktop' => 'デスクトップでPlezyを開き、設定またはメニューからコンパニオンリモートを有効にしてください',
			'companionRemote.pairing.tipScan' => 'スキャンタブを使用して、デスクトップのQRコードをスキャンして素早くペアリング',
			'companionRemote.pairing.tipWifi' => '両方のデバイスが同じWiFiネットワークに接続されていることを確認',
			'companionRemote.pairing.cameraPermissionRequired' => 'QRコードをスキャンするにはカメラの権限が必要です。\nデバイスの設定でカメラへのアクセスを許可してください。',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'カメラを起動できませんでした: ${error}',
			'companionRemote.pairing.scanInstruction' => 'デスクトップに表示されたQRコードにカメラを向けてください',
			'companionRemote.pairing.invalidQrCode' => '無効なQRコード形式',
			'companionRemote.pairing.validationHostRequired' => 'ホストアドレスを入力してください',
			'companionRemote.pairing.validationHostFormat' => '形式はIP:ポートである必要があります（例: 192.168.1.100:48632）',
			'companionRemote.pairing.validationSessionIdRequired' => 'セッションIDを入力してください',
			'companionRemote.pairing.validationSessionIdLength' => 'セッションIDは8文字である必要があります',
			'companionRemote.pairing.validationPinRequired' => 'PINを入力してください',
			'companionRemote.pairing.validationPinLength' => 'PINは6桁である必要があります',
			'companionRemote.pairing.connectionTimedOut' => '接続がタイムアウトしました。セッションIDとPINを確認してください。',
			'companionRemote.pairing.sessionNotFound' => 'セッションが見つかりませんでした。認証情報を確認してください。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '接続に失敗しました: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'リモートセッションから切断しますか？',
			'companionRemote.remote.reconnecting' => '再接続中...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '試行 ${current}/5',
			'companionRemote.remote.retryNow' => '今すぐ再試行',
			'companionRemote.remote.connectionError' => '接続エラー',
			'companionRemote.remote.notConnected' => '未接続',
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
			'videoSettings.playbackSettings' => '再生設定',
			'videoSettings.playbackSpeed' => '再生速度',
			'videoSettings.sleepTimer' => 'スリープタイマー',
			'videoSettings.audioSync' => '音声同期',
			'videoSettings.subtitleSync' => '字幕同期',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => '音声出力',
			'videoSettings.performanceOverlay' => 'パフォーマンスオーバーレイ',
			'videoSettings.audioPassthrough' => 'オーディオパススルー',
			'videoSettings.audioNormalization' => '音声正規化',
			'externalPlayer.title' => '外部プレーヤー',
			'externalPlayer.useExternalPlayer' => '外部プレーヤーを使用',
			'externalPlayer.useExternalPlayerDescription' => '内蔵プレーヤーの代わりに外部アプリで動画を開く',
			'externalPlayer.selectPlayer' => 'プレーヤーを選択',
			'externalPlayer.systemDefault' => 'システムデフォルト',
			'externalPlayer.addCustomPlayer' => 'カスタムプレーヤーを追加',
			'externalPlayer.playerName' => 'プレーヤー名',
			'externalPlayer.playerCommand' => 'コマンド',
			'externalPlayer.playerPackage' => 'パッケージ名',
			'externalPlayer.playerUrlScheme' => 'URLスキーム',
			'externalPlayer.customPlayer' => 'カスタムプレーヤー',
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
			'metadataEdit.selectPoster' => 'ポスターを選択',
			'metadataEdit.selectBackground' => '背景を選択',
			'metadataEdit.fromUrl' => 'URLから',
			'metadataEdit.uploadFile' => 'ファイルをアップロード',
			'metadataEdit.enterImageUrl' => '画像URLを入力',
			'metadataEdit.imageUrl' => '画像URL',
			'metadataEdit.metadataUpdated' => 'メタデータを更新しました',
			'metadataEdit.metadataUpdateFailed' => 'メタデータの更新に失敗しました',
			'metadataEdit.artworkUpdated' => 'アートワークを更新しました',
			'metadataEdit.artworkUpdateFailed' => 'アートワークの更新に失敗しました',
			'metadataEdit.noArtworkAvailable' => 'アートワークがありません',
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
			_ => null,
		};
	}
}
