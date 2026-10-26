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
	@override late final _Translations$cast$ja cast = _Translations$cast$ja._(_root);
	@override late final _Translations$automation$ja automation = _Translations$automation$ja._(_root);
	@override late final _Translations$notifications$ja notifications = _Translations$notifications$ja._(_root);
	@override late final _Translations$appIcon$ja appIcon = _Translations$appIcon$ja._(_root);
	@override late final _Translations$auth$ja auth = _Translations$auth$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
	@override late final _Translations$screens$ja screens = _Translations$screens$ja._(_root);
	@override late final _Translations$update$ja update = _Translations$update$ja._(_root);
	@override late final _Translations$appAccess$ja appAccess = _Translations$appAccess$ja._(_root);
	@override late final _Translations$settings$ja settings = _Translations$settings$ja._(_root);
	@override late final _Translations$themeEditor$ja themeEditor = _Translations$themeEditor$ja._(_root);
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
	@override late final _Translations$accountPreferences$ja accountPreferences = _Translations$accountPreferences$ja._(_root);
	@override late final _Translations$discover$ja discover = _Translations$discover$ja._(_root);
	@override late final _Translations$errors$ja errors = _Translations$errors$ja._(_root);
	@override late final _Translations$libraries$ja libraries = _Translations$libraries$ja._(_root);
	@override late final _Translations$about$ja about = _Translations$about$ja._(_root);
	@override late final _Translations$serverSelection$ja serverSelection = _Translations$serverSelection$ja._(_root);
	@override late final _Translations$hubDetail$ja hubDetail = _Translations$hubDetail$ja._(_root);
	@override late final _Translations$logs$ja logs = _Translations$logs$ja._(_root);
	@override late final _Translations$detail$ja detail = _Translations$detail$ja._(_root);
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
	@override late final _Translations$watchLink$ja watchLink = _Translations$watchLink$ja._(_root);
	@override late final _Translations$homeLayout$ja homeLayout = _Translations$homeLayout$ja._(_root);
	@override late final _Translations$platform$ja platform = _Translations$platform$ja._(_root);
	@override late final _Translations$fileSources$ja fileSources = _Translations$fileSources$ja._(_root);
	@override late final _Translations$lending$ja lending = _Translations$lending$ja._(_root);
	@override late final _Translations$audiobook$ja audiobook = _Translations$audiobook$ja._(_root);
}

// Path: app
class _Translations$app$ja extends Translations$app$en {
	_Translations$app$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$ja extends Translations$cast$en {
	_Translations$cast$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'デバイスに押し付ける';
	@override String get searching => 'キャストデバイスを探す...';
	@override String connectedTo({required Object device}) => '接続番号: ${device}';
	@override String get device => 'キャストデバイス';
	@override String get readyToCast => '投げる準備';
	@override String get subtitle => '字幕';
	@override String get serverNotAvailable => 'メディアサーバーは利用できません。';
	@override String get stopCasting => 'キャストをやめる';
	@override String get castToDevice => 'デバイスにキャスト';
	@override String get noEpisodeAvailable => '出演可能なエピソードはありません。';
	@override String get startFailed => 'サーバーをチェックして再度試してみる';
}

// Path: automation
class _Translations$automation$ja extends Translations$automation$en {
	_Translations$automation$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'コントロールする動画セッションはありません。';
	@override String get profileNotFound => 'その Plezy プロフィールは見つかりませんでした。';
}

// Path: notifications
class _Translations$notifications$ja extends Translations$notifications$en {
	_Translations$notifications$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => '新エピソード';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$ja extends Translations$appIcon$en {
	_Translations$appIcon$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'アプリアイコン';
	@override String get defaultIcon => 'デフォルト';
	@override String get current => '現在のアイコン';
	@override String get locked => '生涯アクセスが必要';
	@override String get lockedHint => '7日間の試用を開始するか、または代替アイコンを使用するために、PlezyNGを一生解除します。';
	@override String get changeFailed => 'アプリアイコンを変更できませんでした';
	@override String get launcherHint => 'Plezyを離れると、ホーム画面に新しいアイコンが表示されます。';
	@override String get tvLauncherHint => 'Plezyを離れると、新しいバナーが表示されます。Android TVでは、テレビを再起動するまで古いバナーが表示され続ける場合があります。';
	@override late final _Translations$appIcon$names$ja names = _Translations$appIcon$names$ja._(_root);
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
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Quick Connect を使う';
	@override String get quickConnectInstructions => 'JellyfinでQuick Connectを開き、このコードを入力してください。';
	@override String get quickConnectWaiting => '承認を待っています…';
	@override String get quickConnectCancel => 'キャンセル';
	@override String get quickConnectExpired => 'Quick Connectの有効期限が切れました。もう一度お試しください。';
	@override String get localDataRecoveryRequired => 'ローカルのサインイン情報と保留中の再生データを安全に復元できませんでした。もう一度サインインしてください。';
	@override String get pinCheckRejected => 'Plex PINの確認が拒否されました';
	@override String get connectToDirectPlex => '地元のサーバーに接続する Plex';
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
	@override String get options => 'オプション';
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
	@override late final _Translations$common$mediaKind$ja mediaKind = _Translations$common$mediaKind$ja._(_root);
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

// Path: appAccess
class _Translations$appAccess$ja extends Translations$appAccess$en {
	_Translations$appAccess$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'すべての機能を7日間無料で試してみてください。';
	@override String get description => 'PlezyNG のすべての機能を使える7日間の無料体験を開始できます。体験期間中の料金やサブスクリプションはありません。体験期間終了後は、ストアに表示される価格で一度購入すると、PlezyNG を無期限で利用できます。';
	@override String get trialEndedDescription => 'あなたの店の価格で1 つの購入で一生のための PlezyNG のすべての機能を解除します。';
	@override String get startTrial => '無料7日間の試験開始';
	@override String get trialActive => '7日間のフルフィードテストがアクティブです。';
	@override String get trialEnded => '7日間の試験が終わりました。';
	@override String get trialStartFailed => 'このデバイスで試用を保存できませんでしたので、また試してみてください。';
	@override String get lifetimeTitle => 'PlezyNG 終身無効';
	@override String get lifetimeBody => '感謝! あなたはすべてのPlezyNG機能に一生のアクセスがあります。';
	@override String get manageTitle => 'PlezyNG 生涯アクセス';
	@override String get manageDescription => '7日間無料で各機能を試してみて、その後、あなたの店の価格で1回の支払いで一生のすべてをオフにします。';
	@override String buy({required Object price}) => 'すべての機能を解除する ${price}';
	@override String get loadingPrice => 'ストアの価格...';
	@override String get retryPrice => '返品価格検索';
	@override String get restore => '生涯購入の復元';
	@override String get pending => '購入は支払いまたは承認を待っています. 店が完了した直後にライフタイムアクセスが開封されます。';
	@override String get storeUnavailable => '購入は利用できません. あなたが店にサインインされていることを確認し、このデバイスで購入が許可されています。';
	@override String get productNotFound => 'PlezyNG ライフタイム オフロックは、このストアではまだ利用できません。';
	@override String get productQueryFailed => 'ストア価格を負担することはできません. 接続をチェックして再度試してみてください。';
	@override String get purchaseFailed => '買い物は終わりませんでした!また試してみてください。';
	@override String get restoreFailed => '買い物を回復するために店に到達できなかったので、また試してみてください。';
	@override String get nothingToRestore => '購入番号 PlezyNG は、このストアのアカウントに検索されました。';
}

// Path: settings
class _Translations$settings$ja extends Translations$settings$en {
	_Translations$settings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get supportDeveloper => 'Plezyを支援';
	@override String get supportDeveloperDescription => '寄付で開発を支援';
	@override String get lifetimeAccess => 'PlezyNG 生涯アクセス';
	@override String get language => '言語';
	@override String get theme => 'テーマ';
	@override String get appearance => '外観';
	@override String get detailPage => '詳細ページ';
	@override String get themeSongsEnabled => 'テーマ曲を演奏';
	@override String get themeSongsEnabledDescription => 'メディアの詳細を見ながら、利用可能なテーマ曲をプレイします。';
	@override String get themeSongVolume => 'テーマ曲 ボリューム';
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
	@override String get emberTheme => '残り火';
	@override String get glacierTheme => '氷河';
	@override String get forestTheme => '森';
	@override String get plumTheme => 'プラム';
	@override String get paperTheme => 'ペーパー';
	@override String get libraryDensity => 'ライブラリの密度';
	@override String get displayScale => '表示スケール';
	@override String get compact => 'コンパクト';
	@override String get comfortable => 'ゆったり';
	@override String get gridSpacing => 'グリッド間隔';
	@override String get gridSpacingTight => '密';
	@override String get gridSpacingNormal => '標準';
	@override String get gridSpacingSpacious => 'ゆったり';
	@override String get tvCornerSpotlightBackdrop => '画面隅の注目コンテンツ背景';
	@override String get tvCornerSpotlightBackdropDescription => '画面全体ではなく、右上隅に注目コンテンツのアートワークを表示します';
	@override String get viewMode => '表示モード';
	@override String get gridView => 'グリッド';
	@override String get listView => 'リスト';
	@override String get showHeroSection => '注目コンテンツを表示';
	@override String get showHomeBackdrop => 'ホーム バックドロップ アートワーク';
	@override String get showHomeBackdropDescription => 'ホーム ラウンドの背後にある大きな芸術作品を表示する';
	@override String get contentScreensaverEnabled => 'コンテンツスクリーンセーバー';
	@override String get contentScreensaverEnabledDescription => 'アプリがアイドルになった後、全画面のアートワークを表示する';
	@override String get contentScreensaverDelay => 'スクリーンセーバーのスタート後';
	@override String get contentScreensaverLibraries => 'スクリーンサーバー図書館';
	@override String get contentScreensaverLibrariesDescription => 'スクリーンセーバーの画像に使うライブラリを選択します。何も選択しない場合は、すべてのライブラリの画像が使われます。';
	@override String get contentScreensaverAllLibraries => 'すべての図書館';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} 図書館 選択';
	@override String get contentScreensaverNoLibraries => '接続されたメディアライブラリは利用できません。';
	@override String get contentScreensaverDismissHint => 'ボタンを押すか、キャンセルするか';
	@override String get newEpisodeNotifications => '新エピソード通知';
	@override String get newEpisodeNotificationsDescription => 'ショーに新しいエピソードが追加されると警告します. チェックする Plezy が開いている間に。';
	@override String get continueWatchingRowSize => '続きを見る サイズ';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} カード';
	@override String get rowSizeCompact => 'コンパクト';
	@override String get rowSizeStandard => '標準';
	@override String get rowSizeLarge => '大';
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
	@override String get showWatchedIndicators => '視聴済みマークを表示';
	@override String get showWatchedIndicatorsDescription => '視聴済みの映画、番組、エピソードにチェックマークを表示します';
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
	@override String get playbackBuffer => '再生バッファー';
	@override String get playbackBufferAuto => '自動（推奨）';
	@override String get playbackBufferLarge => '大';
	@override String get playbackBufferExtraLarge => '特大';
	@override String get playbackBufferDescription => '不安定な接続に備えてより多くのバッファーを使用します。バッファーサイズによっても制限されます。';
	@override String get streamBufferSize => 'バッファーサイズ';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => '直播時にどれだけビデオをアップロードするか? トランスコードはサーバーのトランスコドバッファーで止まります。';
	@override String get streamBufferSizeExoNote => 'Playback Buffer を設定時に置き換え、アプリのメモリの半分にカップ';
	@override String get streamBufferMegabytes => 'メガバイト';
	@override String get defaultQualityTitle => 'デフォルト画質';
	@override String get cellularQualityTitle => 'モバイルデータ通信時のデフォルト画質';
	@override String get remoteQualityTitle => '遠隔ストリーミング品質';
	@override String get remoteQualitySameAsDefault => 'デフォルト品質と同じ';
	@override String get cellularQualitySameAsDefault => 'デフォルト画質と同じ';
	@override String get directPlayCoveredQuality => '小さい動画をオリジナル画質で再生';
	@override String get directPlayCoveredQualityDescription => '画質制限内の動画はトランスコードせずにダイレクト再生します';
	@override String get videoCodecs => 'ビデオコーデック';
	@override String get videoCodecsDescription => 'チェックを外したコーデックはサーバーがトランスコードします';
	@override String get videoCodecsAlwaysAccepted => '常に許可';
	@override String get musicQualityTitle => '音楽の音質';
	@override String get subtitleStyling => '字幕スタイル';
	@override String get subtitleStylingDescription => '字幕の外観をカスタマイズ';
	@override String get smallSkipDuration => '短いスキップ時間';
	@override String get largeSkipDuration => '長いスキップ時間';
	@override String get rewindOnResume => '再開時に巻き戻し';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} 秒',
	);
	@override String get defaultSleepTimer => 'デフォルトスリープタイマー';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} 分',
	);
	@override String get rememberTrackSelections => '番組/映画ごとにトラック選択を記憶';
	@override String get chooseTracksBeforePlayback => 'プレイバック前にオーディオとサブタイトルを選択する';
	@override String get chooseTracksBeforePlaybackDescription => '各ビデオが始まる前にソースオーディオとサブタイトルのトラックを選択します。';
	@override String get alwaysShowSubtitlesOnDevice => '常にこのデバイスにサブタイトルを表示する';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'サーバーがサブタイトルを選択していない場合は、ローカルにトラックを選択します. これはサーバーの好みを決して変更しません。';
	@override String get autoDownloadPreferredSubtitle => 'フラッシュが欠けている好みの言語のサブタイトル';
	@override String get autoDownloadPreferredSubtitleDescription => '地元でご好みの言語で利用可能なサブタイトルを選択します. 存在しない場合は、サーバーがサポートされているときに1つをタッチするようにしてください. 選択はこのデバイスに残ります。';
	@override String get rememberTrackSelectionsDescription => 'タイトルごとに音声と字幕の選択を記憶します';
	@override String get rememberTrackSelectionsBackendRule => 'Plexはファイルごとに選択をサーバーに保存します。Jellyfinはアカウントの「選択を記憶」も有効にします。Embyはサポートされていません';
	@override String get followServerTrackSelections => 'サーバーのエピソードごとのトラック選択を使用';
	@override String get followServerTrackSelectionsDescription => 'エピソード切り替え時に、現在の選択を引き継ぐ代わりにサーバーで選択された音声と字幕を適用します';
	@override String get resumeMusicOnLaunch => '音楽セッションを記憶';
	@override String get resumeMusicOnLaunchDescription => 'アプリ起動時に最後の曲を停止位置で一時停止のまま開きます';
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
	@override String get watchTogetherRelayDescription => '独自のリレーサーバーを設定しない限り、公開のOpen Watch Partyリレーサーバーを使用します';
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
	@override String get cloudBackup => 'クラウドバックアップ';
	@override String get cloudBackupDescription => '移行可能な設定をHTTPS経由でWebDAVの接続先にバックアップします。サーバー接続と認証情報はこのデバイスに残ります。';
	@override String get cloudBackupUrl => 'WebDAV JSON ファイル URL';
	@override String get cloudBackupUsername => 'ユーザー名';
	@override String get cloudBackupPassword => 'パスワード';
	@override String get cloudBackupSaved => 'クラウドバックアップ 目的地保存';
	@override String get cloudBackupNow => '復帰今';
	@override String get cloudBackupComplete => 'バックアップアップアップロード';
	@override String get cloudBackupRestore => 'バックアップ復元';
	@override String get cloudBackupRestoreConfirm => 'これは、このデバイス上の適合する携帯設定を置き換えるでしょう。';
	@override String get cloudBackupRestored => '設定は、Cloud Backup から復元';
	@override String get shortcutsReset => 'ショートカットをデフォルトにリセットしました';
	@override String get resetShortcutsConfirm => 'カスタムショートカットがデフォルトに置き換えられます。続行しますか？';
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
	@override String get autoPlayAndSkip => '自動再生とスキップ';
	@override String get autoPlayNextEpisode => '次のエピソードを自動再生';
	@override String get autoPlayNextEpisodeDescription => 'エピソードが終了すると、次のエピソードを自動的に再生します';
	@override String get shuffleStartsFromBeginning => 'シャッフルは最初から再生';
	@override String get shuffleStartsFromBeginningDescription => 'シャッフル時に各エピソードを再開位置ではなく最初から再生します';
	@override String get plexCinemaPreRoll => 'サーバー映画の入力';
	@override String get plexCinemaPreRollDescription => '映画が始まる前に、Plex プレロールまたは Jellyfin と Emby インタを設定してプレイします。';
	@override String get playNextCountdown => '次回再生のカウントダウン';
	@override String get playNextCountdownImmediate => 'すぐに再生';
	@override String get skipIntroMode => 'イントロをスキップ';
	@override String get skipIntroModeOffDescription => 'スキップボタンなしでイントロを通常どおり再生します';
	@override String get skipIntroModeButtonDescription => 'イントロ開始時にスキップボタンを表示します';
	@override String get skipIntroModeAutoDescription => '下記の遅延後にイントロを自動的にスキップします';
	@override String get skipCreditsMode => 'クレジットをスキップ';
	@override String get skipCreditsModeOffDescription => 'スキップボタンなしでクレジットを通常どおり再生します';
	@override String get skipCreditsModeButtonDescription => 'クレジット開始時にスキップボタンを表示します';
	@override String get skipCreditsModeAutoDescription => 'クレジットを自動的にスキップして次のエピソードを再生します';
	@override String get skipAdsMode => 'スキー広告';
	@override String get skipAdsModeOffDescription => '通常、スカイボタンなしで検出された広告を再生します。';
	@override String get skipAdsModeButtonDescription => 'スカイボタンを表示すると、Plex が広告を検出します。';
	@override String get skipAdsModeAutoDescription => '検出された広告を自動的に下の遅延後に削除する';
	@override String get musicPlayback => '音楽プレイバック';
	@override String get musicSweetFades => '甘いファド';
	@override String get musicSweetFadesDescription => '音楽がトラックエンドで、Plex が音量データを持っているとき、アルバムの再生は変わらない。';
	@override String get skipMarkerModeOff => 'オフ';
	@override String get skipMarkerModeButton => 'ボタンを表示';
	@override String get skipMarkerModeAuto => '自動';
	@override String get forceSkipMarkerFallback => 'フォールバックマーカーを強制';
	@override String get forceSkipMarkerFallbackDescription => 'Plexにマーカーがある場合でもチャプタータイトルのパターンを使用します';
	@override String get theIntroDbFallback => 'イントロDBをイントロファルバックとして使用する';
	@override String get theIntroDbFallbackDescription => 'コミュニティタイミングを使用する場合のみ、サーバーには入力マークがありません。';
	@override String get autoSkipDelay => '自動スキップの遅延';
	@override String autoSkipDelayDescription({required Object seconds}) => '自動スキップまで${seconds}秒待機';
	@override String get introPattern => 'イントロマーカーパターン';
	@override String get introPatternDescription => 'チャプタータイトルのイントロマーカーに一致する正規表現パターン';
	@override String get creditsPattern => 'クレジットマーカーパターン';
	@override String get creditsPatternDescription => 'チャプタータイトルのクレジットマーカーに一致する正規表現パターン';
	@override String get prerolls => 'プレロール';
	@override String get playPrerollsBeforeMovies => '映画の前にプレロールをプレイする';
	@override String get playPrerollsBeforeMoviesDescription => '各映画の前に下の選択からランダムなクリップをプレイします。';
	@override String get prerollLibrary => 'プリロル図書館';
	@override String get prerollLibraryNotSet => '未設定';
	@override String get prerollLibraryNoneFound => 'サーバーに図書館が見つかりません。';
	@override String get prerollSelection => '選ばれたプレロール';
	@override String get prerollSelectionPickLibraryFirst => '図書館を最初に選ぶ';
	@override String get prerollSelectionNoneSelected => '選ばれたプレロールはありません。';
	@override String prerollSelectionCount({required Object count}) => '${count}件選択';
	@override String get prerollItemPicker => '選び プレロール';
	@override String get prerollItemPickerLoadFailed => 'この図書館から物件をアップロードすることはできません。';
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
	@override String get autoDownloadContinueWatching => 'ダウンロード 続きを見る';
	@override String get autoDownloadContinueWatchingDescription => 'あなたの続きを見るシールドにアイテムをダウンロードし、シールドを離れた後にそれらを削除します。';
	@override String get downloadQuality => 'ダウンロード品質';
	@override String get downloadQualityDescription => 'Plexはダウンロードコードに変換されたコピーを準備します. JellyfinとEmbyはファイルのダウンロード中にトランスコードを変更します. 停止した転送は再起動する必要があります。';
	@override String get askDownloadQualityEachTime => '各ダウンロードの品質を選択';
	@override String get askDownloadQualityEachTimeDescription => '各ビデオダウンロードをチェックする前に品質ピッカーを表示する';
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
	@override String get companionRemoteServerStartFailed => 'コンパニオンリモートサーバーを開始できませんでした';
	@override String get companionRemoteServerStopFailed => 'コンパニオンリモートサーバーを停止できませんでした';
	@override String get autoPip => '自動ピクチャーインピクチャー';
	@override String get autoPipDescription => '再生中にアプリを離れると、自動的にピクチャーインピクチャーに切り替えます';
	@override String get matchContentFrameRate => 'コンテンツのフレームレートに合わせる';
	@override String get matchContentFrameRateDescription => '表示のリフレッシュレートを動画コンテンツに合わせます';
	@override String get matchContentResolution => 'コンテンツの解像度に合わせる';
	@override String get matchContentResolutionDescription => 'テレビ側でアップスケーリングを処理できるよう、ディスプレイを映像本来の解像度に切り替えます。再生中はメニューや字幕もアップスケールされます';
	@override String get matchRefreshRate => 'リフレッシュレートを合わせる';
	@override String get matchRefreshRateDescription => '全画面時に表示のリフレッシュレートを合わせます';
	@override String get matchDynamicRange => 'ダイナミックレンジを合わせる';
	@override String get matchDynamicRangeDescription => 'HDRコンテンツではHDRに切り替え、その後SDRに戻します';
	@override String get displaySwitchDelay => 'ディスプレイ切り替え遅延';
	@override String get tunneledPlayback => 'トンネル再生';
	@override String get tunneledPlaybackDescription => '動画トンネリングを使用します。HDR再生で画面が黒くなる場合や動きがカクつく場合は無効にしてください。';
	@override String get audioPassthrough => 'オーディオパススルー';
	@override String get audioPassthroughDescription => 'Dolby/DTS音声を再エンコードせずにレシーバーやテレビに送り、サラウンドを維持します。音が出ない場合は無効にしてください。';
	@override String get audioPassthroughDescriptionApple => 'Dolby Atmosを含むDolby Digital PlusにはApple標準のDolbyデコーダーを使用します。DTSとTrueHDは引き続きマルチチャンネルPCMで再生されます。音が出ない場合は無効にしてください。';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Dolby Atmosを含むDolby Digital PlusにはApple標準のDolbyデコーダーを使用します。iOS、iPadOS、tvOS 26以降では、TrueHD AtmosとDTS:Xが空間オーディオとして再生されます。その他のDTSとTrueHDのトラックはマルチチャンネルPCMで再生されます。音が出ない場合は無効にしてください。';
	@override String get audioPassthroughOverriddenByNormalization => 'ラウドネス正規化がオンの間はオフ';
	@override String get audioChannelLimit => '音声チャンネル';
	@override String get audioChannelLimitDescription => 'すべてのチャンネルを再生できないスピーカー、ヘッドホン、HDMI環境に合わせて、デコードした音声をダウンミックスします';
	@override String get audioChannelLimitOriginal => 'オリジナル';
	@override String get audioChannelLimitOriginalDescription => 'トラックのすべてのチャンネルを再生します';
	@override String get audioChannelLimitSurround51 => '最大5.1ch';
	@override String get audioChannelLimitSurround51Description => '5.1chのPCMにしか対応していないテレビやレシーバー向けに、7.1chを5.1chにダウンミックスします。パススルーには影響しません。';
	@override String get audioChannelLimitStereo => 'ステレオ';
	@override String get audioChannelLimitStereoDescription => 'ステレオスピーカーやヘッドホン向けに2チャンネルにダウンミックスします。パススルーはオフになります。';
	@override String get downmixCenterBoost => 'センターチャンネルブースト';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'ブースト (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'ダウンミックス時の音量正規化';
	@override String get audioDownmixNormalizeDescription => 'クリッピングを防ぐためにミックス音量を下げます。オフにすると元の音量を維持します（大音量シーンで歪む場合があります）。';
	@override String get dvConversionMode => 'Dolby Vision 変換';
	@override String get dvConversionModeDescription => 'Dolby Vision Profile 7 ファイルの処理方法を選択します。';
	@override String get dvConversionAuto => '自動';
	@override String get dvConversionNative => 'ネイティブ / 無効';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'デバイスの機能検出と通常のフォールバック動作を使用します';
	@override String get dvConversionNativeDescription => 'ネイティブ DV7 を強制し、DV 変換の再試行を抑制します';
	@override String get dvConversionDv81Description => 'Dolby Vision プロファイル 8.1 へのインライン RPU 変換を強制します';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision の RPU/EL レイヤーを削除し、通常の HEVC として扱います';
	@override String get disableDolbyVision => 'Dolby Vision を無効にする';
	@override String get disableDolbyVisionDescription => 'ファイルに HDR10 または HLG レイヤーがある場合は、Dolby Vision の代わりにそれを再生します';
	@override String get hdrSdrConversion => 'HDRからSDRへの変換';
	@override String get hdrSdrConversionDescription => 'ディスプレイがHDRを表示できないときに、HDR映像を何で変換するかを選択します。';
	@override String get hdrSdrConversionAuto => '自動';
	@override String get hdrSdrConversionAutoDescription => 'Android 9以降はデバイス、それより前のバージョンではプレーヤー';
	@override String get hdrSdrConversionDevice => 'デバイス';
	@override String get hdrSdrConversionDeviceDescription => 'デバイスの映像ハードウェアで変換します。最も高速ですが、色はデバイスによって異なります';
	@override String get hdrSdrConversionPlayer => 'プレーヤー';
	@override String get hdrSdrConversionPlayerDescription => 'プレーヤーで変換します。色は一定ですが、低価格なTVボックスでは4Kがカクつくことがあります';
	@override String get deinterlace => 'デインターレース';
	@override String get deinterlaceDescription => 'インターレース映像のくし型ノイズを除去します（mpvプレーヤーのみ）';
	@override String get deinterlaceOff => 'オフ';
	@override String get deinterlaceOffDescription => 'インターレース映像をデコードされたまま表示します';
	@override String get deinterlaceVideo => 'ビデオ';
	@override String get deinterlaceVideoDescription => '各フィールドを1つのフレームに変換します。スポーツ、ニュース、コンサートなど、テレビ用に撮影された映像向けです';
	@override String get deinterlaceFilm => 'フィルム';
	@override String get deinterlaceFilmDescription => 'NTSC DVDによくある、29.97fpsにテレシネされた映画やアニメの元のフレームを復元します。テレビ用に撮影された映像はカクつきます。ライブTVでは「ビデオ」を使用します';
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
	@override String get preferredServer => '優先サーバー';
	@override String get preferredServerDescription => 'このサーバーの結果を優先し、すべての接続されたサーバーを利用できるようにします。';
	@override String get preferredServerAutomatic => '自動';
	@override String get showExploreTab => '「探す」タブを表示';
	@override String get showExploreTabDescription => 'Plex Discoverと接続済みのトラッカーのコンテンツを「探す」タブに表示します';
	@override String get hideEmptyLibraries => '空っぽの図書館を隠す';
	@override String get hideEmptyLibrariesDescription => 'サーバーに報告された項目数をゼロからナビゲーションから削除する図書館。';
	@override String get liveTvDefaultFavorites => 'お気に入りチャンネルをデフォルトに';
	@override String get liveTvDefaultFavoritesDescription => 'ライブTVを開いたときにお気に入りチャンネルのみ表示';
	@override String get general => '一般';
	@override String get generalDescription => '言語、起動、ウィンドウの動作';
	@override String get languageAndRegion => '言語と地域';
	@override String get startup => '起動';
	@override String get display => 'ディスプレイ';
	@override String get libraryAndCards => 'ライブラリとカード';
	@override String get homeScreen => 'ホーム画面';
	@override String get navigation => 'ナビゲーション';
	@override String get window => 'ウィンドウ';
	@override String get liveTv => 'ライブTV';
	@override String get player => 'プレーヤー';
	@override String get videoAndDisplay => '映像とディスプレイ';
	@override String get audio => '音声';
	@override String get quality => '画質';
	@override String get subtitles => '字幕';
	@override String get seekAndTiming => 'シークとタイミング';
	@override String get behavior => '動作';
	@override String get gestures => 'ジェスチャー';
	@override String get gestureBrightnessSwipe => '明るさスワイプ';
	@override String get gestureBrightnessSwipeDescription => '左端を上下にスワイプして明るさを調整します';
	@override String get gestureVolumeSwipe => '音量スワイプ';
	@override String get gestureVolumeSwipeDescription => '右端を上下にスワイプして音量を調整します';
	@override String get gesturePinchToZoom => 'ピンチでズーム';
	@override String get gesturePinchToZoomDescription => '動画をピンチしてズームイン・アウト';
	@override String get gestureSeekSwipe => 'スイッチ検索';
	@override String get gestureSeekSwipeDescription => '左または右をスイッチする動画のどこでも検索する; リリースする ジャンプ';
	@override String get rememberBrightnessLevel => '明るさを記憶';
	@override String get rememberBrightnessLevelDescription => '前回スワイプで設定した明るさで再生を開始します';
	@override String get controls => 'コントロール';
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
	@override String get followSystem => 'システムに合わせる';
	@override String get followAppLanguage => '表示言語に合わせる';
	@override String get regionFormat => '地域別の書式';
	@override String get regionFormatDescription => '日付、数値、単位の表示形式を選択します。';
	@override String get metadataLanguage => 'メタデータの言語';
	@override String get metadataLanguageDescription => 'サーバーが対応している場合に、タイトルと説明に使用する言語です。音声と字幕の言語は別に設定します。';
	@override String get experimentalDolbyVision => '実験的なDolby Vision';
	@override String get experimentalDolbyVisionDescription => '次の再生で実験的なFELレンダラーを使用します。別途ビルドしたエンジンが必要です。';
	@override String get dvExperimentUnavailableDescription => 'この実験は現在Linuxでのみ利用できます。';
	@override String get dvCompatibilityFallback => '互換性フォールバック';
	@override String get dvCompatibilityFallbackDescription => '実験を開始できない場合は標準レンダラーを使用します。FELデータが失われる可能性があります。';
	@override String get dvExperimentDiagnostics => '動画実験のログ記録';
	@override String get dvExperimentDiagnosticsDescription => '次の再生でプレーヤーの詳細ログを有効にします。';
}

// Path: themeEditor
class _Translations$themeEditor$ja extends Translations$themeEditor$en {
	_Translations$themeEditor$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get builtIn => '標準';
	@override String get presets => 'プリセット';
	@override String get custom => 'カスタム';
	@override String get customEmpty => '未作成';
	@override String get editCustom => 'カスタムテーマを編集';
	@override String get editCustomDescription => 'すべての色を自分で選択';
	@override String get locked => '生涯アクセスが必要';
	@override String get savedLocked => '保存 - 生涯アクセスで利用可能';
	@override String get title => 'カスタムテーマ';
	@override String get startFrom => '元にするテーマ';
	@override String get startFromDescription => '別のテーマからすべての色をコピー';
	@override String get colors => '色';
	@override String get preview => 'プレビュー';
	@override late final _Translations$themeEditor$slots$ja slots = _Translations$themeEditor$slots$ja._(_root);
	@override String get opacity => '不透明度';
	@override String get hexHint => '#RRGGBB または #AARRGGBB';
	@override String get fromOtherThemes => '他のテーマから';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme}の${color}';
	@override late final _Translations$themeEditor$contrast$ja contrast = _Translations$themeEditor$contrast$ja._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1（推奨値の${minimum}:1未満）';
	@override String get discardTitle => '変更を破棄しますか？';
	@override String get discardMessage => '保存されていない色の変更は失われます。';
	@override String get discard => '破棄';
	@override String previewCardTitle({required Object number}) => 'エピソード${number}';
	@override String previewCardSubtitle({required Object minutes}) => '残り${minutes}分';
	@override String get previewSwitch => '自動再生';
	@override String get previewMutedText => '補助テキストはこのように表示されます';
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
	@override String get people => '人物';
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
		one: '含まれる${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のエピソードとそのファイルが削除されます。',
		other: '中の全${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}エピソードとそのファイルが削除されます。',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: 'このアイテムは${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個のファイルに保存されており、そのファイルが削除されます。',
		other: 'このアイテムは${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個のファイルにまたがって保存されており、すべて削除されます。',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '同じファイルに保存されている他の${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のエピソードも削除されます：',
		other: '同じファイルに保存されている他の${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}エピソードも削除されます：',
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
	@override String get red => '赤';
	@override String get green => '緑';
	@override String get blue => 'ブルー';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'アクセス性';
	@override String get summary => 'テキスト、対比、動き、コントロール';
	@override String get systemHint => 'デバイスのアクセス性設定は常に適用されます. これらのオプションは、PlezyNG 全体で調整を追加します。';
	@override String get readability => '読み方と視覚性';
	@override String get textSize => '追加テキストサイズ';
	@override String get preview => '次のストーリーを見つけて、自分のペースで読んで、聞き、観る。';
	@override String get boldText => 'ハードインターフェイス テキスト';
	@override String get highContrast => '高い対比';
	@override String get highContrastHint => '明るい背景でも暗い背景でも、文字や輪郭線、フォーカス表示を見やすくします。';
	@override String get interaction => '動きと相互作用';
	@override String get reduceMotion => '動きを減らす';
	@override String get reduceMotionHint => 'フォーカス表示、ページ切り替え、装飾効果の動きを止めます。';
	@override String get largeTargets => 'タッチターゲットの拡大';
	@override String get largeTargetsHint => '共通の操作ボタンの領域を広げ、タッチ操作や支援技術による操作をしやすくします。';
	@override String get navigationHint => 'TabとShift+Tabで操作項目を移動し、EnterまたはSpaceで実行、Escapeまたは戻るボタンで閉じます。本を開いている間は、拡大率や読書設定を変更できます。';
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
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} フレーム',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} フレーム',
	);
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
	@override String get trackSelectionTitle => 'プレイバック前にトラックを選択する';
	@override String get trackSelectionAuto => '自動選択';
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
	@override String get screenshotFailed => 'スクリーンショットを撮影できませんでした';
	@override String zoomPercent({required Object percent}) => 'ズーム ${percent}%';
	@override String volumePercent({required Object percent}) => '音量 ${percent}%';
	@override late final _Translations$videoControls$pipErrors$ja pipErrors = _Translations$videoControls$pipErrors$ja._(_root);
	@override String get chapters => 'チャプター';
	@override String get noChaptersAvailable => 'チャプターがありません';
	@override String get queue => 'キュー';
	@override String get noQueueItems => 'キューにアイテムがありません';
	@override String get noAudioDevicesAvailable => 'オーディオデバイスがありません';
	@override String get searchSubtitles => '字幕を検索';
	@override String get loadSubtitleFile => 'サブタイトルファイルをダウンロード';
	@override String get subtitleLoadFailed => 'サブタイトルファイルをダウンロードできなかった';
	@override String get language => '言語';
	@override String get noSubtitlesFound => '字幕が見つかりません';
	@override String get subtitleDownloaded => '字幕をダウンロードしました';
	@override String get subtitleDownloadedNotApplied => '字幕はダウンロードされましたが、選択できませんでした';
	@override String get subtitleDownloadFailed => '字幕のダウンロードに失敗しました';
	@override String get searchLanguages => '言語を検索…';
	@override String get skipIntro => 'イントロをスキップ';
	@override String get skipCredits => 'クレジットをスキップ';
	@override String get skipAds => 'スキー広告';
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
		one: '自動削除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ダウンロード',
		other: '視聴済みダウンロードを${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件自動削除しました',
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
	@override String playbackFailedDetail({required Object error}) => '再生を開始できませんでした: ${error}';
	@override String get audioOutputFailed => 'オーディオ出力が応答しなくなりました。テレビやレシーバーの音声接続を確認してください。他のアプリでも音が出ない場合は、デバイスを再起動してください。';
	@override String get mediaUnavailable => 'このコンテンツは利用できなくなりました。';
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
	@override String get playbackNotAllowedTitle => '再生が許可されていません';
	@override String get playbackNotAllowedBody => 'サーバーがこのアイテムのストリーミングを拒否しました（HTTP 403）。お使いのアカウントに再生の権限がないか、サーバーがローカルネットワーク内での再生のみを許可している可能性があります。';
	@override String get logsUploaded => 'ログをアップロードしました';
	@override String get logsUploadFailed => 'ログのアップロードに失敗しました';
	@override String get logId => 'ログID';
	@override String get burnedSubtitlesUseMenu => '字幕はこのストリームに焼き付けられています。字幕メニューから変更してください。';
	@override String get noVideoUrl => '利用可能な動画URLがありません';
	@override String get playbackNoMediaSources => 'サーバーから再生可能なメディアソースが返されませんでした';
	@override String get playbackDataNotPrepared => '再生データの準備が完了する前に再生が開始されました';
	@override String get streamSelectionUnavailable => 'このソースではストリームを選択できません';
	@override String get streamSelectionFailed => '選択したストリームを適用できませんでした';
	@override String get trackSelectionNotRemembered => 'このトラック選択は現在の再生にのみ適用されます。';
	@override String get serverUnavailableForProfile => '現在のプロフィールで利用可能なサーバーがありません';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ja extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'ブラウンフォックスが、狂犬を飛び越える。';
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
	@override String get useMargins => '余白を使用';
	@override String get useMarginsDescription => 'テキスト字幕を動画の外側の領域に表示できるようにします。スタイル付き字幕は元の配置を維持する場合があります。';
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
	@override String get lineHint => 'option=value';
	@override String get addLine => '行を追加';
	@override String get removeLine => '行を削除';
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
	@override String get signOutPlexDeleteDownloads => 'ダウンロードも削除';
	@override String get signOutPlexDeleteDownloadsDescription => '削除しない場合、ダウンロードはこのデバイスに残り、このアカウントに再度サインインすると再び利用できます。';
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
	@override String get copyAutomationLink => 'コピー Android 自動化リンク';
	@override String get copyAutomationLinkDescription => 'このプロフィールを選択する Android 意図または自動化から プロフィール PIN チェックはまだ適用されます。';
	@override String get automationLinkCopied => 'プロフィール自動化リンクコピー';
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
	@override String get borrowEmptySubtitle => 'まず、別のプロフィールをPlex、JellyfinまたはEmbyに接続してください。';
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
	@override String get settingsLocked => '設定はこのプロフィールに閉じ込められています。';
	@override String get unlockSettings => 'オフロック設定';
	@override String get showExploreForProfile => 'プロフィールを検索する';
	@override String get showExploreForProfileDescription => 'このプロフィールのナビゲーションから Explore を削除するためにオフにします。';
}

// Path: connections
class _Translations$connections$ja extends Translations$connections$en {
	_Translations$connections$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '接続';
	@override String get addConnection => '接続を追加';
	@override String get addConnectionSubtitleNoProfile => 'Plexでサインインするか、JellyfinまたはEmbyサーバーに接続';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}に追加：Plex、Jellyfin、Emby、または別のプロフィールの接続';
	@override String sessionExpiredOne({required Object name}) => '${name} のセッションの有効期限が切れました';
	@override String sessionExpiredMany({required Object count}) => '${count} 台のサーバーのセッションの有効期限が切れました';
	@override String accessDeniedOne({required Object name}) => '${name} がこのアカウントへのアクセスを拒否しました';
	@override String accessDeniedMany({required Object count}) => '${count} 台のサーバーがこのアカウントへのアクセスを拒否しました';
	@override String get signInAgain => '再度サインイン';
	@override String editMediaBrowserTitle({required Object product}) => '${product}接続を編集';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName}のURLを追加または削除します。Plezyは到達可能なURLのうち、レイテンシーが最も低いものを使用します。';
}

// Path: accountPreferences
class _Translations$accountPreferences$ja extends Translations$accountPreferences$en {
	_Translations$accountPreferences$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'アカウント設定';
	@override String hubSubtitleSingle({required Object account}) => '音声・字幕・ライブラリのオプションは${account}に保存されています';
	@override String hubSubtitleMultiple({required Object count}) => '音声・字幕・ライブラリのオプションは${count}個のアカウントに保存されています';
	@override String get pickAccount => '各アカウントに独自の設定が保存されています。編集するアカウントを選択してください。';
	@override String get storedOnAccount => 'これらのオプションはアカウント自体に保存されるため、サインインしているすべてのアプリ（他のデバイスのPlezyを含む）で使用されます。';
	@override String get noAccounts => '設定できるアカウントがありません';
	@override String get noAccountsHint => 'Plexにサインインするか、JellyfinまたはEmbyサーバーに接続すると、そのアカウントに保存された設定がここに表示されます。';
	@override String get unavailable => 'このアカウントにアクセスできません';
	@override String get loadFailed => 'この設定を読み込めませんでした';
	@override String get noPreference => '指定なし';
	@override String get notSet => '未設定';
	@override late final _Translations$accountPreferences$groups$ja groups = _Translations$accountPreferences$groups$ja._(_root);
	@override String get preferredAudioLanguage => '優先音声言語';
	@override String get autoSelectAudio => '言語で音声を選択';
	@override String get autoSelectAudioDescription => 'オフにすると、ファイルでデフォルトとマークされた音声トラックがそのまま使われます。';
	@override String get preferredSubtitleLanguage => '優先字幕言語';
	@override String get subtitleMode => '字幕の自動表示';
	@override late final _Translations$accountPreferences$subtitleModes$ja subtitleModes = _Translations$accountPreferences$subtitleModes$ja._(_root);
	@override String get subtitleAccessibility => 'SDH字幕';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$ja subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$ja._(_root);
	@override String get forcedSubtitles => '強制字幕';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$ja forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$ja._(_root);
	@override String get displayMissingEpisodes => '欠落エピソードを表示';
	@override String get displayMissingEpisodesDescription => 'サーバーが把握しているがファイルがないエピソードを一覧表示します。';
	@override String get hidePlayedInLatest => '「最新」の視聴済みアイテムを非表示';
	@override String get hidePlayedInLatestDescription => 'すでに視聴したアイテムは、サーバーの「最新」に表示されません。';
	@override String get displayCollectionsView => 'コレクションビューを表示';
	@override String get displayCollectionsViewDescription => 'ライブラリに加えて、サーバーのコレクションビューを表示します。';
	@override String get rewatchingInNextUp => '再視聴した番組を「次のエピソード」に残す';
	@override String get rewatchingInNextUpDescription => '番組を見終えた後に再び見始めると、「次のエピソード」は番組を外さずに再視聴に追従します。';
	@override String get watchedIndicator => '視聴済みマーク';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$ja watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$ja._(_root);
	@override String get mediaReviewsVisibility => '評価とレビュー';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$ja mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$ja._(_root);
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
	@override late final _Translations$discover$findNext$ja findNext = _Translations$discover$findNext$ja._(_root);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} タイトル',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}作品',
	);
	@override late final _Translations$discover$person$ja person = _Translations$discover$person$ja._(_root);
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
	@override String get reasonTimedOut => '接続がタイムアウトしました';
	@override String get reasonUnreachable => 'メディアサーバーに接続できませんでした';
	@override String get reasonRefused => 'メディアサーバーがリクエストを拒否しました';
	@override String get reasonNotFound => 'この項目はメディアサーバー上に存在しません';
	@override String get reasonServerError => 'メディアサーバーでエラーが発生しました';
	@override String get reasonCancelled => 'リクエストがキャンセルされました';
	@override String get reasonUnexpected => '予期しないエラーが発生しました';
}

// Path: libraries
class _Translations$libraries$ja extends Translations$libraries$en {
	_Translations$libraries$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'ランダム映画を演じる';
	@override String get randomPickFailed => 'この図書館からランダム映画を選ぶことはできません。';
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
	@override late final _Translations$libraries$advancedFilters$ja advancedFilters = _Translations$libraries$advancedFilters$ja._(_root);
	@override late final _Translations$libraries$selection$ja selection = _Translations$libraries$selection$ja._(_root);
}

// Path: about
class _Translations$about$ja extends Translations$about$en {
	_Translations$about$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'アプリについて';
	@override String get openSourceLicenses => 'オープンソースライセンス';
	@override String versionLabel({required Object version}) => 'バージョン ${version}';
	@override String get appDescription => 'Flutter製の美しいPlex・Jellyfin・Embyクライアント';
	@override String get viewLicensesDescription => 'サードパーティライブラリのライセンスを表示';
	@override String get privacyPolicy => 'プライバシーポリシー';
}

// Path: serverSelection
class _Translations$serverSelection$ja extends Translations$serverSelection$en {
	_Translations$serverSelection$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})のサーバーが見つかりません';
	@override String failedToLoadServers({required Object error}) => 'サーバーの読み込みに失敗しました: ${error}';
	@override String get noValidServers => 'このアカウントで利用可能なサーバーが見つかりませんでした';
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
	@override String get saveLogs => 'ファイルへのログを保存';
	@override String logsSaved({required Object path}) => 'ログを保存する ${path}';
	@override String get saveLogsFailed => 'ログファイルを保存できませんでした。';
}

// Path: detail
class _Translations$detail$ja extends Translations$detail$en {
	_Translations$detail$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => '${time}に終了';
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
	@override late final _Translations$explore$mdblistShelves$ja mdblistShelves = _Translations$explore$mdblistShelves$ja._(_root);
	@override String get title => '見つける';
	@override String get selectSource => 'ソースを選択';
	@override late final _Translations$explore$rows$ja rows = _Translations$explore$rows$ja._(_root);
	@override late final _Translations$explore$status$ja status = _Translations$explore$status$ja._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} エピソード',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}話',
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
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: 'サーバーをチェックできない ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}台のサーバーを確認できませんでした',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 結果',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件の結果',
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
	@override String get timelineLiveProgram => 'ライブプログラム(プレイバックはこのプログラムの外にある可能性があります)';
	@override String get timelineBuffer => 'バッファータイムライン';
	@override String get timelineUnavailable => 'タイムライン不利用';
	@override String get timelineEstimated => '評価プレイバック';
	@override String get timelinePending => '探し続ける';
	@override String get timelineStale => 'スケジュールが遅れる可能性';
	@override String get unknownHub => '不明';
	@override String get unknownError => '不明なエラー';
	@override String channelNumber({required Object number}) => 'チャンネル ${number}';
	@override String get unknownChannel => '不明なチャンネル';
	@override String get live => 'ライブ';
	@override String get premiereBadge => '新しい';
	@override String get reloadGuide => '番組表を再読み込み';
	@override String get searchGuide => '番組表を検索';
	@override String get searchHint => 'チャンネル・番組を検索';
	@override String searchNoResults({required Object query}) => '「${query}」に一致するものがありません';
	@override String get channelsSection => 'チャンネル';
	@override String get programsSection => '番組';
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
	@override String get guideReloadFailed => '番組表を再読み込みできませんでした';
	@override String get rulesProcessRequested => '録画ルールの再評価をリクエストしました';
	@override String get rulesProcessFailed => '録画ルールを再適用できませんでした';
	@override String get recordShow => '番組を録画';
	@override late final _Translations$liveTv$recordSettings$ja recordSettings = _Translations$liveTv$recordSettings$ja._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes}分後に開始';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product}から無効なライブTV再生データが返されました';
	@override String get failedToStartChannel => 'ライブチャンネルを開始できませんでした';
	@override String get failedToBuildStreamUrl => 'ストリームURLを生成できませんでした';
	@override String playbackStartFailed({required Object reason}) => 'チャンネルを再生できませんでした: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'チャンネルを切り替えられませんでした: ${reason}';
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
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}件',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} トラック',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}曲',
	);
	@override String get nowPlaying => '再生中';
	@override String playingFrom({required Object title}) => '${title}から再生';
	@override String get queue => '再生キュー';
	@override String get clearQueue => 'キューをクリア';
	@override String get lyrics => '歌詞';
	@override String get visualizer => 'ビジュアル';
	@override String get visualizerProfileLoading => 'トラック分析の読み方...';
	@override String get visualizerAmbientMotion => '環境運動';
	@override String get visualizerPlexLoudness => 'Plex 音量';
	@override String get visualizerPreviousPreset => '前の視覚スタイル';
	@override String get visualizerNextPreset => '次 次 視覚スタイル';
	@override String get visualizerPresetAurora => 'オーラ';
	@override String get visualizerPresetBloom => 'ブルーム';
	@override String get visualizerPresetOrbitals => 'オービタル';
	@override String get visualizerPresetPrism => 'プライズ';
	@override String get visualizerPresetTunnel => 'トンネル';
	@override String get visualizerPresetTrackMap => 'トラックマップ';
	@override String get noLyrics => '歌詞がありません';
	@override String get sleepTimer => 'スリープタイマー';
	@override String get sleepTimerEndOfTrack => '曲の終わり';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 分',
	);
	@override String get stopPlayback => '再生を停止';
	@override String get previousTrack => '前の曲';
	@override String get nextTrack => '次の曲';
	@override String get repeat => 'リピート';
	@override String get repeatAll => '全曲リピート';
	@override String get repeatOne => '1曲リピート';
	@override String get instantMixNoServer => 'インスタントミックスに利用できるサーバーがありません';
	@override String get instantMixFailed => 'インスタントミックスを読み込めませんでした';
	@override String get instantMixEmpty => 'インスタントミックスにトラックがありませんでした';
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
	@override String get createRoom => 'ルームを作成';
	@override String get creatingRoom => 'ルームを作成中…';
	@override String get joinRoom => 'ルームに参加';
	@override String get joiningRoom => 'ルームに参加中…';
	@override String get connecting => '接続中…';
	@override String get relayPublic => 'ルームは公開のOpen Watch Partyリレーサーバーを使用します。';
	@override String relayCustom({required Object url}) => 'ルームは${url}のリレーサーバーを使用します。';
	@override String get recentRooms => '最近のルーム';
	@override String get roomActions => 'ルームの操作';
	@override String get renameRoom => 'ルーム名を変更';
	@override String get removeRoom => '削除';
	@override String get enterRoomCode => 'ホストから共有された6文字のコードを入力してください。';
	@override String get roomCode => 'ルームコード';
	@override String get paste => '貼り付け';
	@override String get noCodeInClipboard => 'クリップボードにルームコードがありません';
	@override String get copyCode => 'コードをコピー';
	@override String get codeCopied => 'ルームコードをコピーしました';
	@override String get shareInvite => '招待を共有';
	@override String get inviteCopied => '招待をコピーしました。メッセージに貼り付けてください。';
	@override String inviteMessage({required Object code}) => 'Plezyの「一緒に見る」ルームに参加しませんか？「一緒に見る」を開いて「ルームに参加」を選び、${code}を入力してください。';
	@override String get openSessionControls => '「一緒に見る」セッションのコントロールを開く';
	@override String get reconnecting => '再接続中…';
	@override String get reconnectingDescription => '接続が切断されました。自動的にルームに再参加します。';
	@override String get connected => '接続済み';
	@override String get disconnected => '切断されました';
	@override String get youAreHost => 'あなたはホストです';
	@override String hostedBy({required Object name}) => 'ホスト: ${name}';
	@override String get hostControlsPlayback => 'ホストが再生を制御';
	@override String get anyoneCanControl => '全員が再生を制御可能';
	@override String get roomLocked => 'ルームはロック中';
	@override String get nowPlaying => '再生中';
	@override String get nothingPlaying => '再生中のコンテンツはありません';
	@override String get nothingPlayingHost => 'いずれかのライブラリから再生すると、ルームで共有されます。';
	@override String get nothingPlayingGuest => 'ホストが再生を始めると、ここに表示されます。';
	@override String get notShareable => 'この動画はカタログ情報と一致しないため、同じサーバーにアクセスできる人しか再生できません。';
	@override String get searching => 'ライブラリでこの動画を探しています…';
	@override String get yourCopy => 'あなたのコピー';
	@override String get sharingYourCopy => 'あなたのコピーを共有しています';
	@override String playingOtherLength({required Object difference}) => 'あなたのコピーを再生中（${difference}）';
	@override String get mismatchTitle => 'コピーの長さが異なります';
	@override String mismatchDescription({required Object difference}) => '最も近いコピーはルームの動画より${difference}です。別の編集版やバージョンの可能性があります。';
	@override String get playAnyway => 'このまま再生';
	@override String get chooseAnotherCopy => '別のコピーを選択';
	@override String get dontPlay => '再生しない';
	@override String get unavailableTitle => 'この動画がありません';
	@override String get unavailableDescription => 'Plezyはライブラリでこの動画を見つけられませんでした。自分でコピーを選ぶか、もう一度検索してください。';
	@override String get chooseCopy => 'コピーを選択';
	@override String get searchAgain => '再検索';
	@override String get noCandidates => 'ライブラリにコピーが見つかりません。';
	@override String get choiceFailed => 'このコピーをルームで再生できませんでした';
	@override String lengthLonger({required Object duration}) => '${duration}長い';
	@override String lengthShorter({required Object duration}) => '${duration}短い';
	@override String get lengthSame => '同じ長さ';
	@override String get lengthUnknown => '長さ不明';
	@override String get joinCurrentPlayback => '現在の再生に参加';
	@override String get joinCurrentPlaybackDescription => 'ホストが現在視聴中のコンテンツに戻る';
	@override String get stopMedia => '全員の動画を停止';
	@override String get syncOffset => '同期オフセット';
	@override String get syncOffsetDescription => '動画がルームより進んでいる、または遅れている場合にずらします。';
	@override String offsetHint({required Object difference}) => 'あなたのコピーはルームの動画より${difference}です。';
	@override String applyDifference({required Object offset}) => '${offset}を適用';
	@override String get offsetMinusSecond => '-1秒';
	@override String get offsetMinusTenth => '-100ms';
	@override String get offsetPlusTenth => '+100ms';
	@override String get offsetPlusSecond => '+1秒';
	@override String get participants => '参加者';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 参加者',
		other: '参加者${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}人',
	);
	@override String get hostBadge => 'ホスト';
	@override String nameYou({required Object name}) => '${name}（あなた）';
	@override String get playerIdle => '待機中';
	@override String get playerLoading => '読み込み中';
	@override String get playerReady => '準備完了';
	@override String get playerBuffering => 'バッファリング中';
	@override String get matchSearching => '検索中';
	@override String get matchMatched => '動画あり';
	@override String get matchMismatched => '長さが異なる';
	@override String get matchUnavailable => '動画なし';
	@override String participantOffset({required Object offset}) => 'オフセット ${offset}';
	@override String get makeHost => 'ホストにする';
	@override String get makeHostQuestion => 'ホストを移譲しますか？';
	@override String makeHostConfirm({required Object name}) => '${name}が再生を制御し、全員のセッションを主導します。';
	@override String get transfer => '移譲';
	@override String get removeParticipant => 'ルームから削除';
	@override String removeParticipantQuestion({required Object name}) => '${name}を削除しますか？';
	@override String removeParticipantConfirm({required Object name}) => '${name}をルームから退出させます。ルームをロックしない限り、コードを使って再度参加できます。';
	@override String get remove => '削除';
	@override String get roomSettings => 'ルーム設定';
	@override String get letEveryoneControl => '全員に再生の操作を許可';
	@override String get lockRoom => 'ルームをロック';
	@override String get lockRoomDescription => '新しい参加者は参加できなくなります';
	@override String get leaveRoom => 'ルームを退出';
	@override String get leaveRoomQuestion => 'ルームを退出しますか？';
	@override String get leaveRoomConfirm => 'ルームコードを使って再度参加できます。';
	@override String get leave => '退出';
	@override String get endRoom => 'ルームを終了';
	@override String get endRoomQuestion => 'ルームを終了しますか？';
	@override String get endRoomConfirm => '参加者全員のルームが終了します。';
	@override String get end => '終了';
	@override String get playBlockedTitle => '再生が開始されませんでした';
	@override String get playBlockedDescription => '再生を押して、ルームのみんなと一緒に視聴を始めてください。';
	@override late final _Translations$watchTogether$notices$ja notices = _Translations$watchTogether$notices$ja._(_root);
	@override late final _Translations$watchTogether$ended$ja ended = _Translations$watchTogether$ended$ja._(_root);
	@override late final _Translations$watchTogether$errors$ja errors = _Translations$watchTogether$errors$ja._(_root);
	@override String untitledEpisode({required Object number}) => 'エピソード${number}';
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
	@override String get storageFull => '空き容量を確保するため、ダウンロードを停止しました。空き容量を確保するか、別のダウンロード先を選んでから、もう一度お試しください。';
	@override String get storageUnavailable => '空き容量を確認できなかったため、ダウンロードを停止しました。ダウンロード先を確認してから、もう一度お試しください。';
	@override String episodesQueued({required Object count}) => '${count}エピソードをダウンロードキューに追加しました';
	@override String get downloadDeleted => 'ダウンロードを削除しました';
	@override String deleteConfirm({required Object title}) => 'このデバイスから「${title}」を削除しますか？';
	@override String get deleteCollectionDownloads => 'ダウンロードを削除';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '「${title}」のすべてのダウンロードをこのデバイスから削除しますか？';
	@override String get collectionDownloadsDeleted => 'ダウンロードを削除しました';
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
	@override String get retryAll => 'すべて再試行';
	@override String get retryFailed => '失敗したダウンロードを再試行';
	@override String get deleteAll => 'すべて削除';
	@override String get selectVersion => 'バージョンを選択';
	@override String get allEpisodes => 'すべてのエピソード';
	@override String get unwatchedOnly => '未視聴のみ';
	@override String nextNUnwatched({required Object count}) => '次の${count}件の未視聴';
	@override String get customAmount => '数を指定…';
	@override String get customAmountAny => '定量(毎回)';
	@override String get randomEpisodes => 'ランダムエピソード';
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
	@override String get syncNow => 'シンク今';
	@override String get downloadsUpToDate => 'ダウンロードは現在まで';
	@override String syncComplete({required Object queued, required Object removed}) => '合成完了 · ${queued} queued, ${removed} 削除';
	@override String get activeSyncRules => '同期ルール';
	@override String get reviewOrphanFiles => '記録のないダウンロードを確認';
	@override String get orphanReviewTitle => '記録のないダウンロードを確認';
	@override String get orphanReviewDescription => 'これらのタグ付きファイルは、PlezyNG が管理する既定のダウンロードフォルダー内にありますが、対応するダウンロード記録や実行中のタスクがありません。削除する前に一覧を確認してください。';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} 個のファイル · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count} 個のファイルを削除';
	@override String get orphanCleanupNone => '記録のないダウンロードファイルは見つかりませんでした';
	@override String get orphanCleanupFailed => 'PlezyNG は管理対象のダウンロードフォルダーを安全にスキャンできませんでした。ファイルは削除されていません。';
	@override String get orphanCleanupChanged => '確認中にダウンロード一覧が変更されました。整理する前にファイルをもう一度確認してください。';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count} 個の孤立ファイルを削除 · ${size} の空き容量を確保';
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
	@override String get syncRuleAccessDenied => 'アクセスが拒否されました';
	@override String get syncRuleNotAvailableForProfile => '現在のプロフィールでは利用できません';
	@override String get syncRuleUnknownServer => '不明なサーバー';
	@override String get syncRuleListCreated => '同期ルールを作成しました';
	@override late final _Translations$downloads$backgroundWarning$ja backgroundWarning = _Translations$downloads$backgroundWarning$ja._(_root);
	@override String get options => 'ダウンロードのオプション';
	@override late final _Translations$downloads$groupings$ja groupings = _Translations$downloads$groupings$ja._(_root);
	@override String get unknownLibrary => '不明なライブラリ';
	@override String get unknownShow => '不明な番組';
	@override String get unknownSeason => '不明なシーズン';
	@override String get unknownAlbum => '不明なアルバム';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total}完了';
	@override String storageUsed({required Object size}) => '使用済みのストレージ: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のダウンロード',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のダウンロード',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 表示',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 表示',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 映画',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 映画',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}枚のアルバム',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}枚のアルバム',
	);
	@override String get errorFileNotFound => 'ファイルが見つかりません（404）';
	@override String get errorDownloadNotAllowed => 'サーバーがダウンロードを許可していません（403）';
	@override String get errorDownloadFailed => 'ダウンロードに失敗しました';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'ダウンロードに失敗しました: ${reason}';
	@override String get convertingOnServer => 'サーバーに変換する...';
	@override String convertingOnServerPercent({required Object percent}) => 'サーバーに変換 · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'ダウンロードに失敗しました（HTTP ${status}）';
	@override String errorPostProcessing({required Object reason}) => '後処理に失敗しました: ${reason}';
	@override String get reasonFileNotSaved => 'このデバイスにファイルを保存できませんでした';
	@override String get reasonCannotResume => '途中までのダウンロードを再開できませんでした';
	@override String get reasonDeviceStorageFull => 'このデバイスのストレージが不足しています';
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
	@override String get audioEqualizer => '音声平等化';
	@override String get audioEqualizerDescription => 'このデバイスに5つの周波数帯を調整します. mpv で利用可能; アクティブな EQ はオーディオを解読し、パスチャードを無効にします。';
	@override String get audioEqualizerFlat => 'フラット';
	@override String get audioEqualizerActive => 'カスタム';
	@override String get audioEqualizerSaveFailed => 'オーディオエキサイティングの設定を保存することはできません。';
	@override String get backgroundVideoAudio => '背景動画オーディオ';
	@override String get backgroundVideoAudioDescription => 'プレイヤーを離れたときにビデオオーディオを再生し続ける; 返信するまで画像が隠されている. Android はメディア再生通知を使用します。';
	@override String get audioNormalization => 'ラウドネス正規化';
	@override String get audioNormalizationDisablesPassthrough => '音声をPCMにデコードします。オンの間はパススルーがオフになります';
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
	@override String get passthrough => 'パススルー';
	@override String get aspect => 'アスペクト';
	@override String get rotation => '回転';
	@override String get dvSource => 'DV ソース';
	@override String get dvPath => 'DV パス';
	@override String get dvRouteDecoder => 'Dolby Vision デコーダー';
	@override String get dvRouteDecoderP81 => 'Dolby Vision デコーダー（P7→8.1）';
	@override String get dvRouteBaseLayer => 'ベースレイヤー';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 ベースレイヤー';
	@override String get dvRouteBaseLayerHlg => 'HLG ベースレイヤー';
	@override String get dvRouteBaseLayerSdr => 'SDR ベースレイヤー';
	@override String get dvRouteReshaped => 'RPU リシェイプ（gpu-next）';
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
	@override String get playMethod => 'ゲーム方法';
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
	@override String get quickTag => 'クイックタグ…';
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
	@override String get noSignInMethods => 'この Seerr インスタンスには PlezyNG が対応しているサインイン方法がありません。';
	@override String get instance => 'インスタンス';
	@override String get disconnectConfirm => 'Seerr の接続を解除しますか？';
	@override String get disconnectConfirmBody => 'PlezyNG はこの Seerr インスタンスの情報を削除します。いつでも再接続できます。';
	@override String get request => 'リクエスト';
	@override String get request4k => '4K でリクエスト';
	@override String get seasons => 'シーズン';
	@override String get allSeasons => '全シーズン';
	@override String get advancedOptions => '詳細';
	@override String get destinationServer => '宛先サーバー';
	@override String get qualityProfile => '画質プロファイル';
	@override String get rootFolder => 'ルートフォルダ';
	@override String get languageProfile => '言語プロファイル';
	@override String get tags => 'タグ';
	@override String get noTags => 'タグなし';
	@override String defaultOption({required Object name}) => '${name}（デフォルト）';
	@override String get animeNote => 'このシリーズはアニメです。';
	@override String get requestSubmitted => 'リクエストを送信しました';
	@override String requestFailed({required Object error}) => 'リクエストに失敗しました: ${error}';
	@override String get requestsLoadFailed => 'リクエストオプションを読み込めませんでした';
	@override String get nothingToRequest => 'すべてすでに利用可能またはリクエスト済みです。';
	@override String get statusAvailable => '利用可能';
	@override String get statusPartiallyAvailable => '一部利用可能';
	@override String get statusRequested => 'リクエスト済み';
	@override String get statusProcessing => '処理中';
	@override String get statusBlocklisted => 'ブロックリスト登録済み';
	@override String couldNotReach({required Object url, required Object error}) => '${url}に接続できませんでした: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url}にSeerrインスタンスがありません（HTTP ${status}）';
	@override String get behindAuthProxy => 'Seerrではなく、認証が必要なリバースプロキシ（SSOまたはHTTP認証）が応答しました。Plezyはこれを通じてサインインできません。このアプリではSeerrの/api/v1パスをプロキシから除外するか、Seerrに直接到達するアドレスを使用してください。';
	@override String get invalidUrl => 'https://seerr.example.comのようなサーバーアドレスを入力してください';
	@override String get quickConnectUnsupported => 'このSeerrインスタンスはQuick Connectに対応していません。Seerr 3.4以降が必要です。';
	@override String get notInitialized => 'このSeerrインスタンスでは初回セットアップが完了していません';
	@override String get noPlexTokenForReauth => '再サインインに使用できるPlexトークンがありません';
	@override String get noStoredCredentials => '再サインインに使用できる保存済みの認証情報がありません';
	@override String get signInRejected => 'サインインが拒否されました';
	@override String get noSessionCookie => 'Seerrからセッションクッキーが発行されませんでした';
	@override String get freshCookieRejected => 'Seerrが新しいセッションクッキーを拒否しました';
	@override String get noUserInformation => 'Seerrからユーザー情報が返されませんでした';
	@override String get sessionRejectedAfterReauth => '再サインイン後にセッションが拒否されました';
	@override String get permissionDenied => 'Seerrがこの操作を拒否しました: アカウントに必要な権限がありません';
	@override String get permissionRevoked => 'これをリクエストする権限がなくなりました';
}

// Path: services
class _Translations$services$ja extends Translations$services$en {
	_Translations$services$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'サービス';
	@override String get hubSubtitle => '視聴の進捗を同期して、新しいタイトルをリクエストします。';
	@override String get integrations => 'インテグレーション';
	@override String get notConnected => '未接続';
	@override String connectedAs({required Object username}) => '@${username} として接続済み';
	@override String get scrobble => '進捗を自動で記録';
	@override String get scrobbleDescription => 'エピソードや映画を見終えたときにリストを更新します。';
	@override String disconnectConfirm({required Object service}) => '${service} の接続を解除しますか？';
	@override String disconnectConfirmBody({required Object service}) => 'Plezyは${service}の更新を停止します。いつでも再接続できます。';
	@override String connectFailed({required Object service}) => '${service} に接続できませんでした。もう一度お試しください。';
	@override late final _Translations$services$names$ja names = _Translations$services$names$ja._(_root);
	@override late final _Translations$services$simklReconnect$ja simklReconnect = _Translations$services$simklReconnect$ja._(_root);
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
	@override String get authResponseIncomplete => 'サーバーからのサインイン応答が不完全です';
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
	@override String get directPlexServerUrl => 'Plex サーバーの URL';
	@override String get directPlexServerUrlHelper => 'メディアサーバーの地元のIPとポートを入力する Plex メディアンサーバー。';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex トークン(オプション)';
	@override String get plexTokenHelper => 'Auth なしのアクセスがこのサーバーで許可されている場合に、空白を残します。';
	@override String get plexTokenRequired => '確認が必要です. Plex トークン(X-Plex-トークン)を入力してください。';
	@override String get connectDirectPlexCard => 'Plex メディアサーバー(直接/地元)';
	@override String get connectDirectPlexCardSubtitle => 'plex.tv アカウントなしで地元の IP または URL を使用して直接接続します。';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => '地元のIPまたはURLを使用して直接接続します. ${name} に接続します。';
	@override String get insecureTitle => '未暗号化の接続';
	@override String insecureDescription({required Object url}) => '${url} は HTTP を使用しています。ネットワーク上の第三者がパスワード、トークン、メディアを読み取ったり改ざんしたりする可能性があります。利用できる場合は HTTPS を使用してください。このネットワークを信頼し、リスクを受け入れる場合のみ続行してください。';
	@override String get allowHttp => 'HTTPを許可';
	@override String get httpsRequired => 'HTTPS を使用するか、暗号化されていない接続を明示的に許可するか。';
}

// Path: watchLink
class _Translations$watchLink$ja extends Translations$watchLink$en {
	_Translations$watchLink$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'このリンクのために Plex サーバーにアクセスできませんでした。';
	@override String get notFound => 'この番組または映画が Plex サーバーで見つかりませんでした。';
	@override String get ambiguous => 'このリンクは、複数のサーバーの項目と一致します. リンクにサーバーを追加します。';
	@override String get plexOnly => '視聴リンクは現在、サーバーのみをサポートしています Plex';
	@override String get unsupportedItem => '視聴リンクは、ショーや映画だけを開くことができます。';
	@override String get menuItem => '見るリンク';
	@override String get dialogTitle => 'リンクを見る';
	@override String get dialogShowHint => 'このリンクを開くと次のエピソードが再生されます. ショーをシュフルでプレイするために、最後に &mode=shuffle を追加します。';
	@override String get dialogMovieHint => 'このリンクを開くと映画が演奏されます。';
	@override String get copy => 'コピー';
	@override String get copied => 'リンクコピー';
}

// Path: homeLayout
class _Translations$homeLayout$ja extends Translations$homeLayout$en {
	_Translations$homeLayout$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'HOME レイアウト';
	@override String get resetToast => 'ホーム オリジナル Plezy ヒーロー レイアウトにリセット';
	@override String get resetHeroTitle => 'ヒーローのレイアウトをストックにリセットする Plezy?';
	@override String get resetHeroBody => '各行のヒーロー設定を切り離し、ホームの頂点に単一の回転バナーを持ち帰る、ヒーローの行が存在する前にと同じように。';
	@override String get removeRowTitle => 'ホーム ラウンドを削除する?';
	@override String removeRowBody({required Object title}) => '${title} は削除されます. これは無効にならない。';
	@override String get sync => 'シンク';
	@override String get syncAccountTitle => 'あなたのアカウント Plex と同期する';
	@override String get syncAccountOn => 'オン:このデバイスは、順序、順序の順序、ヒーロー、および自動スライドを他のデバイスと共有します。';
	@override String get syncAccountOff => 'オフ:このデバイスは独自のレイアウトを維持します。';
	@override String get syncNow => 'シンク今';
	@override String get plexHomeManager => 'Plex ホームマネージャー';
	@override String get managePlexRows => 'Plex 行を管理する Plezy';
	@override String get managePlexRowsDescription => 'ホーム 選択のラインを整理するためにオープン';
	@override String get organizeHomeRows => 'ホーム ラウンドの整理';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} ライン: 移動、 ヒーロー、 自動スライド、 削除';
	@override String organizeLibraryRows({required Object library}) => '組織 ${library} ライン';
	@override String organizeLibraryRowsDescription({required Object n}) => '続きを見る + ${n} 行: 移動, 図書館, ホーム, ヒーロー, 自動スライド';
	@override String get renderAsHero => 'ヒーローカードとしての出張';
	@override String get heroOnlySingleCollection => 'この行が単一のコレクションの実際のタイトルに解決する場合にのみ利用可能';
	@override String get hero => 'ヒーロー';
	@override String get autoSlide => '自動スライド';
	@override String get autoSlideDescription => 'ラウンド(PC)とdパッド(TV)は常に動作し、タイマーを再起動します。';
	@override String get autoSlideEditDescription => 'スライドは数秒ごとに自体でスライドします。 オフ: 矢をクリックする場合(PC)または遠隔(TV)の左/右を押す場合のみ動きます。';
	@override String get enableHeroFirst => '英雄を最初に';
	@override String get showOnHome => 'ホームスクリーンで表示';
	@override String get home => 'ホーム';
	@override String get removeFromHome => '家から取り除く';
	@override String get selectRowsFirst => 'まずは下のホームラインを選択します。';
	@override String plexManagedRows({required Object n}) => '${n} Plex 管理行';
	@override String get continueWatching => '視聴を続ける';
	@override String get continueWatchingLibraryDescription => 'この図書館のリサイクル・進歩の順番';
	@override String get continueWatchingHomeDescription => 'ホーム で表示される再生進歩の順番';
	@override String get nextUpHomeDescription => '次の未見のエピソードの順番がホームで別々に表示されます。';
	@override String get library => 'ライブラリ';
	@override String get showInRecommended => '図書館で紹介される';
	@override String get customPlexRow => '定制 Plex ライン';
	@override String get heroNeedsLibrary => '図書館をチェックするには、まずヒーローがどこかで表示する必要があります。';
	@override String get heroNeedsSurface => '図書館またはホームをチェックするには、まず、ヒーローがどこかで表示する必要があります。';
	@override String get removeHub => 'ハブを削除';
	@override String get noPlexRows => '番号 Plex 管理行がこの図書館に戻りました。';
	@override String get openDetails => 'オープン 詳細';
	@override String get heroCards => 'ヒーローカード';
	@override String get tapHeroCard => 'ヒーローカードを打ち出す';
	@override String get tvPlayFocus => 'テレビ: リモート: ハイライト Play ボタン';
	@override String get tvPlayFocusDescription => 'D-pad down は、次の行に移動する前に Play ボタンで停止します。';
	@override String get tvWrap => 'テレビ:ロップヒーローカード';
	@override String get tvWrapDescription => '最後のカードに直ぐに、最初のカードに戻ります。最後のカードの停止を除いて、最初の紙の左側は常にサイドバーに戻ります.';
	@override String get castOnHero => 'ヒーローバンダーのキャスト';
	@override String get castOnHeroDescription => 'ヒーローバナーの底に沿ってキャストを表示します タイトルと概要だけを残します。';
	@override String get customRows => '定義ラウンド';
	@override String get loading => 'ホーム レイアウト レイアー...';
	@override String get noCustomRows => 'まだカスタムライトなし';
	@override String get addRowHint => 'ホーム を追加して 1 つを作成します。';
	@override String get addHomeRow => 'HOME ローブを追加';
	@override String get addHomeRowDescription => 'カテゴリを選択し、新しい順位が自動的に組織に追加されます。';
	@override String get removeRow => 'ラウを取り除く';
	@override String get recentlyAdded => '最近追加されたコンテンツ';
	@override String get recentlyReleased => '最近リリース';
	@override String get movieCollections => '映画コレクション';
	@override String get showCollections => 'コレクション展示';
	@override String get rowTitle => 'ロータイトル';
	@override String get content => 'コンテンツ';
	@override String get showThisRowIn => 'この順番を表示する:';
	@override String get libraryRecommended => '図書館推奨';
	@override String get heroCard => 'ヒーローカード';
	@override String get heroCardDescription => 'ポスターシェルフの代わりに、単一の全幅のローテーションカードとして表示されます。';
	@override String get heroUnavailableDescription => 'この順番が単一のコレクションの実際のタイトルに解決する場合にのみ利用可能で、1 つ以上のコレクターが選択されると、単一のタイトルの回転はできません。';
	@override String get librariesSelection => '図書館(すべての図書館を含むためにチェックされていないすべてを残す)';
	@override String get librariesMergedDescription => 'ここでチェックされているすべての図書館は、この一行に合併しています。';
	@override String get movieCollectionsSelection => '映画コレクション(各選択された図書館にチェックされていないすべてを残す)';
	@override String get showCollectionsSelection => 'コレクションを表示する(各選択された図書館のすべての未チェックを残す)';
	@override String get collectionRowsDescription => 'もし1つのコレクションが合うなら、そのタイトルが順番に直接表示されます。もし1つ以上合うなら、1つのコレクトリが単一のポスターとして表示されます。';
	@override String get allCollections => 'すべてのコレクション';
	@override String get noRowsHere => 'まだ、ここに順番はない。';
	@override String get hideWatchedRows => '順番に隠された物件を';
	@override String get hideWatchedRowsDescription => '完全に監視されたタイトルはホームと図書館を離れ、推奨行を残します。';
	@override String get untitledCollection => '未名のコレクション';
	@override String get moveRowHint => 'Up/Down: 順番を移動する · Select: drop it here · Back: cancel';
	@override String get organizeRowsHint => '順位を選択する(または保持する) 順位を選択する:移動する · 左/右:順位オプション · 後退:完成';
	@override String get layoutNavDescription => '列、図書館、コレクションカテゴリを選択';
	@override String get editHomeRow => 'ホーム ラウ 編集';
	@override String get resetHeroButton => 'ヒーローのリセット レイアウト ストック Plezy';
	@override String get reorderingUnlocked => '再編 開封';
	@override String get reorderingLocked => '再編閉鎖';
	@override String get rowsCanBeDragged => '線は引き出すことができます - ロックをタップしてそれを防ぐために';
	@override String get tapLockToDrag => 'ロックを押してラインを引き出す';
	@override String customRowLabel({required Object title}) => '定員: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => '非表示';
	@override String get remove => '削除';
	@override String get libraryResumeRow => 'この図書館のリセットライン';
	@override String get pressAgainToDelete => '再度削除するために押す';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'で';
	@override String get resetHeroButtonDescription => '各行のヒーロー設定を切り離し、ヒーローラインが存在する前にあったように、上に単一の回転バナーを返します。';
}

// Path: platform
class _Translations$platform$ja extends Translations$platform$en {
	_Translations$platform$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG は、地元のネットワーク上のメディアサーバーおよび再生デバイスに接続します。';
	@override String get locationPermission => 'PlezyNGは、ローカルネットワークを検出してメディアサーバーに接続するためにiOSが必要とする場合、位置情報へのアクセスを使用します。';
	@override String get photoLibraryPermission => '写真ライブラリから、メディアのアートワークに使う画像を選択します。';
	@override String get cameraPermission => 'QRコードをスキャンしてCompanion Remoteをペアリングします。';
}

// Path: fileSources
class _Translations$fileSources$ja extends Translations$fileSources$en {
	_Translations$fileSources$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ファイルと本';
	@override String get subtitle => '読んで、聴いて、自分のファイルから見て';
	@override String get add => '源を追加';
	@override String get importFiles => 'ファイル輸入';
	@override String get localFiles => 'この装置で';
	@override String get source => '源泉';
	@override String get name => '名称';
	@override String get endpoint => 'サーバー URL';
	@override String get root => 'フォルダーまたはプレフィックス';
	@override String get username => 'ユーザー名';
	@override String get password => 'パスワード';
	@override String get token => 'API トークン';
	@override String get accessKey => 'アクセスキーID';
	@override String get secretKey => '秘密アクセスキー';
	@override String get sessionToken => 'セッション・トークン(オプション)';
	@override String get region => '地域';
	@override String get clientId => 'クライアントID';
	@override String get clientSecret => 'OAuth クライアント セキュリティ (Google デスクトップのみ)';
	@override String get allowHttp => '信頼できるネットワークで暗号化されていないHTTP接続を許可する';
	@override String get connect => '接続';
	@override String get cancel => 'キャンセル';
	@override String get save => '保存';
	@override String get close => '閉じる';
	@override String get removeSource => 'ソース 解約';
	@override String get disconnectMessage => 'このソースの接続を解除しますか？ダウンロード済みのファイルと読書・再生履歴は、このデバイスに残ります。';
	@override String get localFolder => 'フォルダーを選択';
	@override String get empty => 'まだ何もありません';
	@override String get emptyHint => 'ソースを追加したり、本、オーディオブック、音楽、またはビデオをインポートしたりします。';
	@override String get search => 'このフォルダーを検索';
	@override String get searchCached => '図書館を保存';
	@override String get refresh => '更新';
	@override String get loadMore => 'もっと充電';
	@override String get offline => 'オフライン利用';
	@override String get download => 'オフライン';
	@override String get removeDownload => 'オフラインコピーの削除';
	@override String get continueReading => '続きを読む';
	@override String get continueListening => '続き聴き方';
	@override String get continueWatching => '続きを見る';
	@override String get read => '読む';
	@override String get listen => '聴く';
	@override String get play => '再生';
	@override String get pause => '一時停止';
	@override String get stop => '停止';
	@override String get startOver => 'スタート トップ';
	@override String get finished => '再生終了';
	@override String get markFinished => 'マーク終了';
	@override String get markUnfinished => 'マーク 未完成';
	@override String get editions => '出版物とファイル';
	@override String get chapters => 'チャプター';
	@override String get bookmarks => 'ブックマークとノート';
	@override String get bookmark => 'ブックマークを追加';
	@override String get highlight => 'ハイライト';
	@override String get note => '注記';
	@override String get delete => '削除';
	@override String get export => '輸出ノート';
	@override String get exported => '輸出のノート';
	@override String get sync => 'シンク進歩';
	@override String get synced => '進歩合成';
	@override String get conflict => '別のデバイスは別の位置を持っています. どこで進むかを選択します。';
	@override String get useLocal => 'この装置を使用する';
	@override String get useRemote => '他のデバイスを使う';
	@override String get history => '位置歴史';
	@override String get groupAudio => 'ひとつのオーディオブックとして聴く';
	@override String get groupHint => 'このフォルダーで現在読み込まれている音声ファイルをまとめます。先にすべてのページを読み込んでください。';
	@override String get order => 'ファイル 注文';
	@override String get moveUp => '移動アップ';
	@override String get moveDown => 'ダウン移動';
	@override String get speed => 'プレイバックスピード';
	@override String get sleep => 'スリープタイマー';
	@override String get sleepOff => 'オフ';
	@override String get endChapter => '章の終わり';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} 分',
	);
	@override String get skipBack => 'スキーバック';
	@override String get skipForward => 'スキー前進';
	@override String get smartRewind => '休憩後のスマートな回復';
	@override String get playbackOptions => '聴くオプション';
	@override String remaining({required Object time}) => '${time} 残り';
	@override String get contents => 'コンテンツ';
	@override String get readerSettings => '読み設定';
	@override String get fontSize => 'テキストサイズ';
	@override String get lineHeight => 'スペースライン';
	@override String get margin => 'マルギン';
	@override String get font => 'タイプフェイス';
	@override String get serif => 'セリフ体';
	@override String get sans => 'サンセリフ体';
	@override String get mono => 'モノスペース';
	@override String get columns => 'コラム';
	@override String get scroll => '垂直にスクロール';
	@override String get justify => '両端揃え';
	@override String get readerTheme => 'ページの出演';
	@override String get appTheme => 'アプリテーマのフォロー';
	@override String get paper => 'ペーパー';
	@override String get sepia => 'セピア';
	@override String get night => '夜の';
	@override String get readAloud => 'このページを読み上げる';
	@override String get readAlong => '音声に合わせて読む';
	@override String get stopReading => '読み上げを停止';
	@override String get searchBook => '検索・本';
	@override String get noMatches => '試合なし';
	@override String get previousPage => '前ページ';
	@override String get nextPage => '次のページ';
	@override String page({required Object number}) => 'ページ ${number}';
	@override String get externalBlocked => 'リーダーでは、本の外部リンクは無効になっています。';
	@override String get loading => '開...';
	@override String get narrator => '講演者';
	@override String get audio => '音声';
	@override String get video => 'ビデオ';
	@override String get ebooks => 'エボブ';
	@override String get all => 'すべて';
	@override String get downloads => 'オフラインファイル';
	@override String get confirmDelete => '選択したオフラインコピーを削除しますか？読書・再生位置とメモは保持されます。';
	@override String get errorAuthentication => '再びこのソースを再接続するためにサインインします。';
	@override String get errorPermission => 'この情報源は、要求されたファイルへのアクセスを許可しませんでした。';
	@override String get errorUnavailable => 'ソースを利用できません。再試行するか、オフラインコピーを開いてください。';
	@override String get errorUnsupported => 'この形式または接続は、このデバイスではサポートされていません。ソースの設定ガイドを確認してください。';
	@override String get errorInvalidData => 'このファイルまたはサーバーの回答は安全に読み取れない。';
	@override String get errorCancelled => '作戦はキャンセルされました。';
	@override String get errorConflict => '別のセッションで読書・再生位置が変更されました。位置を選ぶには、アイテムを開き直してください。';
	@override String get signIn => 'サインイン';
	@override String get reconnect => '再接続';
	@override String get folderHelp => '空欄にするとソースのルートから開始します。S3のURLにはバケット名が含まれます。';
	@override String get preferences => '優先順位';
	@override String get timePosition => '位置';
	@override String get audioTrack => '音声トラック';
	@override String get subtitleTrack => 'トレック サブタイトル';
	@override String get none => '無';
	@override String get fullscreen => '全画面';
	@override String get syncLocation => 'プロセス シンク フォルダー(オプション)';
	@override String get syncLocationHint => 'PlezyNG 状態のための専用 WebDAV フォルダー 条件書きを使用します; メディアは変わらない。';
	@override String get audiobooks => 'オーディオブック';
	@override String get comics => '漫画';
	@override String get scan => '書籍とメディアのスキャン';
	@override String get browserReader => 'オープンリーダー';
	@override String get browserReaderHelp => 'ブラウザーでリーダーを開いています。読書位置やメモを保存するため、PlezyNGを開いたままにしてください。';
	@override String get on => 'で';
	@override String get advancedSetup => 'アプリ登録';
	@override String get microsoftSignIn => 'マイクロソフトとサインイン';
	@override String get zoomIn => 'ゾーム in';
	@override String get zoomOut => 'ゾーム出る';
	@override String get fitPage => 'フィットページ';
	@override String get fitWidth => '合計幅';
	@override String get actualSize => '現状サイズ';
	@override String get goToPage => 'ページへ行く';
	@override String get goToSection => '章へ行く';
	@override String pageRange({required Object count}) => '1 から ${count} までの番号を入力します。';
	@override String get pageLayout => 'ページレイアウト';
	@override String get automatic => '自動';
	@override String get singlePage => '単一ページ';
	@override String get twoPages => '2ページ';
	@override String get readingDirection => '読書方向';
	@override String get leftToRight => '左から右';
	@override String get rightToLeft => '右から左';
	@override String get letterSpacing => 'スペース 手紙';
	@override String get wordSpacing => 'スペース語';
	@override String get readerControlsHelp => 'ピンチ操作または拡大・縮小ボタンでページを拡大できます。ドラッグして表示位置を移動します。Ctrl/⌘と+または−で拡大率を調整し、Ctrl/⌘と0でリセットします。Page UpとPage Downでページをめくります。';
	@override String get imagePage => '漫画ページ';
	@override String get resetReader => '読み取りの好みを再設定';
	@override String get zoom => 'ズーム';
	@override String get useFiles => 'ファイルや本を使用する';
	@override String get cancelScan => 'スキャンキャン';
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$ja extends Translations$lending$en {
	_Translations$lending$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '公共図書館';
	@override String get add => '図書館を追加';
	@override String get other => 'もう一つの図書館';
	@override String get libraryName => '図書館名';
	@override String get libraryUrl => '図書館サイト';
	@override String get libraryUrlHint => '図書館のカタログまたはサインインページを使用します。';
	@override String get intro => '図書館から借りて、本をいつも身近に。';
	@override String get handoff => '図書館のサービスでサインインし、本を借りて安全に読めます。';
	@override String get openService => 'オープン図書館';
	@override String get findLibrary => '図書館を見つける';
	@override String get search => '書籍と著者を検索';
	@override String get catalogue => 'カタログ';
	@override String get loans => '貸し出し';
	@override String get holds => '予約';
	@override String get signIn => '図書館で登録する';
	@override String get waiting => 'ブラウザでサインインを終了し、ここに戻ります。';
	@override String get cancel => 'キャンセル';
	@override String get disconnect => '図書館削除';
	@override String get disconnectMessage => 'このプロフィールからこの図書館を削除しますか？貸出中の本と予約は図書館に残ります。';
	@override String get getBook => '書籍を取得';
	@override String get checkAvailability => '利用可能性チェック';
	@override String get available => '貸し出し利用可能';
	@override String get unavailable => '現在利用できない';
	@override String get borrow => '借りる';
	@override String get placeHold => '予約する';
	@override String get returnBook => '期限前に返却';
	@override String get cancelHold => '予約を取り消す';
	@override String get confirmBorrow => '図書館からこのタイトルを借りる?';
	@override String get confirmReturn => 'この本を今すぐ返却しますか？続きを利用するには、もう一度借りる必要がある場合があります。';
	@override String get confirmCancelHold => 'この本の予約を取り消しますか？';
	@override String get email => 'メール 通知';
	@override String due({required Object date}) => '返却期限：${date}';
	@override String queue({required Object position}) => 'ポジション ${position} ライン';
	@override String get empty => 'まだタイトルは無い。';
	@override String get openLibraryNote => 'Open Library のカタログを検索する. 読書および貸し出しのオプションは、各タイトルのページに表示されます。';
	@override String get more => 'もっと充電';
	@override String get gateway => '図書館登録サービス';
	@override String get gatewayHint => '図書館または管理者 PlezyNG によって提供されます。';
	@override String get advanced => '図書館統合';
	@override String get loadLibraries => '図書館を選択';
	@override String get expired => 'この本の貸出期間は終了しました。';
	@override String get updated => '図書館更新';
	@override String get continueService => 'サービスを継続';
	@override String get comingSoon => 'イン・アプリ・貸し出し · すぐに来る';
	@override String get comingSoonDescription => 'Libbyとの連携機能を準備中です。連携が完了するまでは、Libbyで図書館を利用できます。';
	@override String get suspendHold => '予約を一時停止';
	@override String get resumeHold => '予約を再開';
	@override String get suspendMessage => '順番を維持したまま、次の読者にこの本を貸し出しますか？予約は後で再開できます。';
	@override String get resumeMessage => '予約を再開して、次に利用可能な本の案内を図書館から受け取りますか？';
	@override String get editEmail => 'メール通知の変更';
}

// Path: audiobook
class _Translations$audiobook$ja extends Translations$audiobook$en {
	_Translations$audiobook$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => '読書・聴くシンク';
	@override String get syncHelp => 'あなたのデバイスを通じて読み込みポジション、聴くポジション、完成状態、ブックマーク、ノートを保持します。付属ストレージアカウントを選択し、それぞれのデバイスに同じ同期コードを使用します。';
	@override String get addSyncSource => 'Google ドライブ、OneDrive、Dropbox、WebDAV、または S3 をファイルと本に最初に追加します。';
	@override String get syncDestination => 'シンクストレージアカウント';
	@override String get syncFolder => 'シンクフォルダーまたはプレフィックス';
	@override String get syncFolderHelp => 'WebDAV ソース内の別々の既存のフォルダー、または専用の S3 プレフィックスを使用します。';
	@override String get syncCode => 'プライベートシンクコード';
	@override String get syncCodeHelp => '最初のデバイスでコードを作成し、そのコードを他のデバイスで入力します。プライベートコピーを保管します:それは暗号化状態の鍵です。';
	@override String get showCode => 'シンクコードを表示または隠す';
	@override String get newSyncCode => '新しいシンクコードを作成する';
	@override String get saveSync => '保存と同期';
	@override String get disableSync => 'このデバイスでSync をオフにする';
	@override String get syncSourceDisconnect => 'このソースを削除すると、ここで読み聞かせと聴く同期が停止されます。';
	@override String get syncReconnect => 'ストレージアカウント再接続';
	@override String lastSynced({required Object time}) => '最後に ${time} で同期';
	@override String get syncPrivacy => '暗号化された進歩およびノートのみが保存されます. オーディオおよび電子書籍ファイル、アカウントのトークンおよびパスワードはアップロードされません. Google ドライブおよび OneDrive はアプリストレージを使用します. Dropbox は PlezyNG Sync を使用します. 同期を有効にするには追加の書き込みアクセスが要求される可能性があります. 有効にしている間、この目的地は進歩同期を所有しています. サーバーの進歩は別々に残ります. 回転同期は地元の歴史と遠隔状態を維持します。';
	@override String get syncConflicts => '再開する場所を選択する';
	@override String get conflictHelp => 'これらの変更は独立して行われました. 保持するポジションまたはブックマークのバージョンを選択します. 遅いタイムストンプまたはより高い割合は自動的に勝てません。';
	@override String syncDevice({required Object device}) => 'デバイス ${device}';
	@override String get syncUnknownDevice => '未知の装置';
	@override String get deletedBookmark => '削除書籍';
	@override String get finished => '終了';
	@override String readingPosition({required Object percent}) => '読書 · ${percent}%';
	@override String get chapterTimeline => '第1章 進歩';
	@override String get bookTimeline => '全書進展';
	@override String bookRemaining({required Object time}) => 'この本に残る時間: ${time}';
	@override String chapterRemaining({required Object time}) => 'この章に残る時間: ${time}';
	@override String get unknownRemaining => '全時間利用可能 パーツがプレイされる場合';
	@override String get undoSeek => '最後の探求';
	@override String get customSpeed => 'Custom Playback スピード';
	@override String get speedHelp => '0.25×から4×までのスピードを選択します。';
	@override String get apply => '応募';
	@override String get customSleep => 'カスタム睡眠時間';
	@override String get sleepMinutes => '時間(1～1440分)';
	@override String sleepChapters({required Object count}) => '${count} 章の後停止';
	@override String get extendSleep => '追加5分';
	@override String sleepRemaining({required Object time}) => '睡眠タイマー: ${time}';
	@override String get useDefaults => 'これらの聴覚コントロールを新しい本に使用する';
	@override String get librarySort => '色の本';
	@override String get sortTitle => 'タイトル';
	@override String get sortAuthor => '著者';
	@override String get sortNarrator => '講演者';
	@override String get sortSeries => 'シリーズオーダー';
	@override String get sortRecent => '最近オープン';
	@override String get statusFilter => '読書状態';
	@override String get statusAll => 'すべての本';
	@override String get statusNew => '始まらない';
	@override String get statusProgress => '進歩中';
	@override String get statusFinished => '終了';
	@override String get goToTime => '時間へ行く';
	@override String get timeHelp => '時間:分:秒、または分:秒';
}

// Path: appIcon.names
class _Translations$appIcon$names$ja extends Translations$appIcon$names$en {
	_Translations$appIcon$names$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'ミッドナイト';
	@override String get ember => '残り火';
	@override String get paper => 'ペーパー';
	@override String get oled => 'OLED';
	@override String get line => 'ライン';
	@override String get ocean => 'オーシャン';
	@override String get ultraviolet => 'ウルトラバイオレット';
	@override String get matcha => '抹茶';
	@override String get sunset => 'サンセット';
	@override String get gold => 'ゴールド';
	@override String get titanium => 'チタニウム';
	@override String get glass => 'ガラス';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'シンセウェイブ';
	@override String get pixel => 'ピクセル';
	@override String get neon => 'ネオン';
	@override String get sticker => 'ステッカー';
	@override String get ticket => 'チケット';
	@override String get pop => 'ポップ';
	@override String get strata => '地層';
	@override String get facet => 'ファセット';
	@override String get tilde => 'チルダ';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ja extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

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
class _Translations$common$mediaKind$ja extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get movie => '映画';
	@override String get show => 'テレビ番組';
	@override String get season => 'シーズン';
	@override String get episode => 'エピソード';
	@override String get artist => 'アーティスト';
	@override String get album => 'アルバム';
	@override String get track => '曲';
	@override String get collection => 'コレクション';
	@override String get playlist => 'プレイリスト';
	@override String get clip => 'クリップ';
	@override String get photo => '写真';
	@override String get folder => 'フォルダ';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$ja extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get bg => '背景';
	@override String get surface => 'サーフェス';
	@override String get outline => '枠線';
	@override String get text => 'テキスト';
	@override String get textMuted => '補助テキスト';
	@override String get accent => 'アクセント';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$ja extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => '背景上のテキスト';
	@override String get textOnSurface => 'サーフェス上のテキスト';
	@override String get textMutedOnBg => '背景上の補助テキスト';
	@override String get textMutedOnSurface => 'サーフェス上の補助テキスト';
	@override String get accentOnBg => '背景上のアクセント';
	@override String get accentOnSurface => 'サーフェス上のアクセント';
	@override String get labelOnAccent => 'アクセント上のボタンラベル';
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
	@override String get subtitleDelayIncrease => '字幕を遅らせる';
	@override String get subtitleDelayDecrease => '字幕を早める';
	@override String get shaderToggle => 'シェーダー切替';
	@override String get skipMarker => 'イントロ/クレジットをスキップ';
	@override String get screenshot => 'スクリーンショットを撮る';
	@override String get framePrevious => '前 フレーム';
	@override String get frameNext => '次 フレーム';
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
	@override String get prepareFailed => 'ピクチャーインピクチャーを準備できませんでした';
	@override String unknown({required Object error}) => 'エラーが発生しました: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$ja extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => '音声と字幕';
	@override String get libraryDisplay => 'ライブラリ';
	@override String get personalMedia => '個人メディア';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$ja extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get none => '手動選択';
	@override String get noneDescription => '自動では字幕をオンにしません。';
	@override String get defaultMode => 'トラックのフラグに従う';
	@override String get defaultModeDescription => '各字幕トラックに保存されたデフォルトと強制のフラグを使用します。';
	@override String get always => '常に有効';
	@override String get alwaysDescription => '優先言語の字幕トラックがあれば、常にオンにします。';
	@override String get onlyForced => '強制字幕のみ';
	@override String get onlyForcedDescription => '強制とマークされたトラックのみ読み込みます。';
	@override String get smart => '外国語音声時に表示';
	@override String get smartDescription => '音声が別の言語の場合にのみ字幕をオンにします。';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$ja extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => '非SDH字幕を優先';
	@override String get preferSdh => 'SDH字幕を優先';
	@override String get onlySdh => 'SDH字幕のみ';
	@override String get onlyNonSdh => '非SDH字幕のみ';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$ja extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => '非強制字幕を優先';
	@override String get preferForced => '強制字幕を優先';
	@override String get onlyForced => '強制字幕のみ';
	@override String get onlyNonForced => '非強制字幕のみ';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$ja extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get none => 'しない';
	@override String get moviesAndShows => '映画とテレビ番組';
	@override String get movies => '映画のみ';
	@override String get shows => 'テレビ番組のみ';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$ja extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'ユーザーと批評家';
	@override String get usersOnly => 'ユーザーのみ';
	@override String get criticsOnly => '批評家のみ';
	@override String get nobody => '非表示';
}

// Path: discover.findNext
class _Translations$discover$findNext$ja extends Translations$discover$findNext$en {
	_Translations$discover$findNext$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '次を見つける';
	@override String get open => '次を見つける';
	@override String get anyTime => 'いつでも';
	@override String get timeAvailable => 'あなたはどのくらいの時間を持っていますか?';
	@override String get filters => '瞬間を選ぶ';
	@override String get watch => '見る';
	@override String get listen => '聴く';
	@override String get read => '読む';
	@override String finishable({required Object duration}) => '${duration} で終了';
	@override String aboutDuration({required Object duration}) => '${duration}について';
	@override String nextUnit({required Object duration}) => '次 次の投稿: ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} 総合';
	@override String get timingVaries => 'タイミングが変わる';
	@override String get notNow => 'いまではない';
	@override String get swipeHint => 'スイッチ、または下のボタンを使用します。';
	@override String get saved => '保存ピック';
	@override String savedCount({required Object count}) => 'トップページ > ${count}';
	@override String get undo => 'でしょ';
	@override String get details => '詳細';
	@override String get noPicks => 'まだ選べないもの';
	@override String get noPicksHint => '図書館に接続するか、メディアソースを追加してスタートします。';
	@override String get noMatches => 'この瞬間に合わないもの。';
	@override String get noMatchesHint => '別のフォーマットを試すか、自分に時間を与えるか。';
	@override String get allDone => 'みんな捕まえてる';
	@override String get allDoneHint => 'これらの選択肢を再度見るために新鮮なミックスを開始します。';
	@override String get refresh => 'もう一つのミックスを見つける';
	@override String sourceReason({required Object source}) => 'から ${source}';
	@override String libraryReason({required Object library}) => 'から ${library}';
	@override String get ownedReason => 'あなたの図書館から';
	@override String get liveNow => 'で今';
	@override String get watchLive => '見るライブ';
	@override String get filterAnything => '何でも';
	@override String get filterWatch => '見る';
	@override String get filterListen => '聴く';
	@override String get filterRead => '読む';
	@override String get twentyMinutes => '20分';
	@override String get fortyFiveMinutes => '45分';
	@override String get ninetyMinutes => '90分';
	@override String get apply => '応募';
	@override String get openFailed => 'この選択肢はもはや利用できません. 再度チェックするためにリフレッシュします。';
	@override String get changeFailed => '変更はできませんが、もう一度試してみてください。';
	@override String get savedLimit => '保存されたピックが満たされ、1つのピックを削除して別のピックを保存します。';
}

// Path: discover.person
class _Translations$discover$person$ja extends Translations$discover$person$en {
	_Translations$discover$person$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get born => '生年月日';
	@override String get died => '没年月日';
	@override String get birthplace => '出生地';
	@override String dateWithAge({required Object date, required Object age}) => '${date}（${age}歳）';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date}（${age}歳没）';
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
	@override String get filePath => 'ファイルパス';
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
	@override String get dateDownloaded => 'ダウンロード日';
	@override String get size => 'サイズ';
	@override String get library => 'ライブラリ';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$ja extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get include => '含める';
	@override String get exclude => '除外';
	@override String get any => '指定なし';
	@override String get yes => 'はい';
	@override String get no => 'いいえ';
	@override String not({required Object value}) => '${value}以外';
	@override String valueCount({required Object count}) => '${count}件選択';
	@override String valueCountExcluded({required Object count}) => '${count}件除外';
	@override String get searchValues => '値を検索';
	@override String get noValues => '値がありません';
	@override String get matchContains => '含む';
	@override String get matchNotContains => '含まない';
	@override String get matchIs => '一致する';
	@override String get matchIsNot => '一致しない';
	@override String get matchBeginsWith => '前方一致';
	@override String get matchEndsWith => '後方一致';
	@override String get textHint => 'テキストを入力';
	@override String get from => '下限';
	@override String get to => '上限';
	@override String range({required Object from, required Object to}) => '${from}〜${to}';
	@override String atLeast({required Object value}) => '${value}以上';
	@override String atMost({required Object value}) => '${value}以下';
	@override String dateLastDays({required Object count}) => '過去${count}日間';
	@override String get dateLastYear => '過去1年間';
	@override String dateOlderThanDays({required Object count}) => '${count}日以上前';
	@override String get dateOlderThanYear => '1年以上前';
}

// Path: libraries.selection
class _Translations$libraries$selection$ja extends Translations$libraries$selection$en {
	_Translations$libraries$selection$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get selectItems => '選択項目';
	@override String selectedCount({required Object count}) => '${count}件選択';
	@override String get actions => '選択行動';
	@override String get confirmDescendants => 'これは、選択されたショーやシーズンのすべてのエピソードを変更します。';
	@override String get confirmUnwatched => '選択したアイテムの再生状況もリセットされます。';
	@override String confirmCount({required Object count}) => '選ばれた項目: ${count}';
	@override String completed({required Object count}) => '更新項目: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => '更新 ${succeeded}; 失敗 ${failed}. 失敗した項目は選択されます。';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$ja extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get manage => '管理 シールド探検';
	@override String get manageDescription => 'あなたのアカウントからリストを選択し、整理します MDBList';
	@override String get description => 'MDBList アカウントから公開映画やテレビリストを選択します. MDBList にリストを作成またはコピーして更新します。';
	@override String get selected => '選ばれたシート';
	@override String get available => '利用可能なアカウントリスト';
	@override String get noLists => '公開映画やテレビリストが返ってこない リストを作成またはコピーする MDBList で、更新します。';
	@override String get displayName => 'シェルフ ディスプレイ名';
	@override String get nameHint => 'オリジナルリスト名を使用するために白いままにします。';
	@override String get add => 'シェルフを追加';
	@override String get save => 'シェルター保存';
	@override String moveUp({required Object title}) => '移動 ${title} アップ';
	@override String moveDown({required Object title}) => 'ダウンロード ${title}';
	@override String get unavailable => 'このリストは利用できません. 設定でそのシールを取り戻すか削除します。';
	@override String get rateLimited => '申請の制限はMDBList 達成されました 後で撤回してください。';
	@override String get loadFailed => '接続をチェックしてリトリを確認する';
	@override String get saveFailed => 'シェルフを保存できませんでした。もう一度お試しください。';
	@override String get accountChanged => 'アカウントまたはプロフィールが変更されました. これらの設定を再開します。';
	@override String get settingsUnreadable => '保存されたシートは読み取れないので、リストを再度選択して、これらの設定を置き換える。';
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} コメント',
		other: 'コメント ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件',
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
	@override String get actor => '俳優';
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
		one: 'ユーザー数: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ユーザー数',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}人のユーザーがおすすめ',
	);
	@override String recommendedBy({required Object who}) => '${who}がおすすめ';
	@override String favoritedBy({required Object who}) => '${who}がお気に入り登録';
	@override String unairedEpisodes({required Object n}) => '未放送 ${n}話';
	@override String recommendedByPercent({required Object percent}) => '視聴者の${percent}がおすすめ';
	@override String get relatedTitles => '関連作品';
	@override String get background => '背景';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$ja extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get startEarly => '早めに開始（秒）';
	@override String get endLate => '遅めに終了（秒）';
	@override String get newOnly => '新しいエピソードのみ';
	@override String get anyChannel => 'すべてのチャンネルで録画';
	@override String get anyTime => 'すべての時間帯で録画';
	@override String get skipInLibrary => 'ライブラリにあるエピソードをスキップ';
	@override String get keepUpTo => '保持するエピソード数';
	@override String get keepUpToHint => '0 ですべてのエピソードを保持';
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

// Path: watchTogether.notices
class _Translations$watchTogether$notices$ja extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name}が再生しました';
	@override String get playbackStarted => '再生が開始されました';
	@override String paused({required Object name}) => '${name}が一時停止しました';
	@override String get playbackPaused => '再生が一時停止されました';
	@override String jumpedTo({required Object name, required Object position}) => '${name}が${position}にジャンプしました';
	@override String roomJumpedTo({required Object position}) => '${position}にジャンプしました';
	@override String changedSpeed({required Object name, required Object speed}) => '${name}が速度を${speed}に設定しました';
	@override String speedChanged({required Object speed}) => '速度が${speed}に設定されました';
	@override String startedMedia({required Object name, required Object title}) => '${name}が${title}を再生しました';
	@override String mediaStarted({required Object title}) => '${title}を再生中';
	@override String stoppedMedia({required Object name}) => '${name}が動画を停止しました';
	@override String get mediaStopped => '動画が停止しました';
	@override String waitingFor({required Object name}) => '${name}を待っています…';
	@override String get waitingForSomeone => '他の参加者が追いつくのを待っています…';
	@override String get finished => '再生終了';
	@override String hostChangedTo({required Object name}) => '${name}がホストになりました';
	@override String get youAreNowHost => 'あなたがホストになりました';
	@override String joined({required Object name}) => '${name}が参加しました';
	@override String left({required Object name}) => '${name}が退出しました';
	@override String get controlRefused => '再生を操作できるのはホストのみです';
	@override String get searchFailed => '一部のサーバーでルームの動画を検索できませんでした';
	@override String get playBlocked => '再生を押して開始してください';
	@override String get shareFailed => 'この動画をルームと共有できませんでした';
	@override String get downloadNotShared => 'サーバーがオフラインの間、ダウンロードはルームと共有されません';
	@override String get openFailed => 'ルームの動画を開けませんでした';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$ja extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get ended => 'ホストがルームを終了しました';
	@override String get kicked => 'ルームから削除されました';
	@override String get expired => 'ルームの有効期限が切れました';
	@override String get replaced => '別のデバイスでこのルームに参加しました';
	@override String get lost => 'ルームとの接続が切れました';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$ja extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'ルームコードではありません。コードは0、1、I、L、Oを含まない6文字の英数字です。';
	@override String get roomNotFound => 'そのコードのルームはありません。終了した可能性があります。';
	@override String get roomFull => 'そのルームは満員です。';
	@override String get roomLocked => 'ホストがそのルームをロックしています。';
	@override String get relayFull => '「一緒に見る」は現在混み合っています。しばらくしてからもう一度お試しください。';
	@override String get unreachable => '「一緒に見る」のリレーサーバーに接続できませんでした。接続を確認してください。';
	@override String get rateLimited => '試行回数が多すぎます。しばらく待ってからもう一度お試しください。';
	@override String get clientBlocked => 'このバージョンのPlezyではリレーサーバーを使用できません。アプリをアップデートしてください。';
	@override String get forbidden => 'その操作はホストのみ可能です。';
	@override String get notInRoom => 'ルームに参加していません。';
	@override String get alreadyInRoom => 'すでにルームに参加しています。';
	@override String get resumeFailed => 'ルームに再参加できませんでした。';
	@override String get unsupported => 'リレーサーバーがこの操作に対応していません。';
	@override String get generic => '問題が発生しました。もう一度お試しください。';
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

// Path: downloads.groupings
class _Translations$downloads$groupings$ja extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get library => 'ライブラリ';
	@override String get collections => 'コレクション';
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
	@override String get manualAddressHint => '手動接続アドレス:';
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
	@override String get codeTitle => 'パイアリングコード';
	@override String get codeDescription => 'ホストデバイスで Companion Remote で表示されたコードを入力します. 両方のデバイスは、安全なカップリングをサポートするバージョンを使用する必要があります。';
	@override String get codeInvalid => 'ホストコードからすべての32文字と番号を入力します。';
	@override String get updateRequired => '両方のデバイスを安全なパリングをサポートするバージョンにアップグレードします。';
	@override String get hostDescription => 'このコードを各リモートで一度入力します. プライベートに保管してください: このプロフィールのコントロールを提供します。';
	@override String get resetCode => 'パイリングコードの再設定';
	@override String get resetDescription => 'すべてのリモートを切り離し、新しいコードを作成します。';
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

// Path: services.simklReconnect
class _Translations$services$simklReconnect$ja extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Simklに再接続';
	@override String get subtitle => 'Simklはこの接続で使用しているサインイン方法を廃止します。再接続するとsimkl.comが開き、Plezyを承認できます。Plezyがパスワードを知ることはありません。視聴履歴はSimklに残ります。';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$ja extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} で PlezyNG を有効化';
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
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'デバイスに押し付ける',
			'cast.searching' => 'キャストデバイスを探す...',
			'cast.connectedTo' => ({required Object device}) => '接続番号: ${device}',
			'cast.device' => 'キャストデバイス',
			'cast.readyToCast' => '投げる準備',
			'cast.subtitle' => '字幕',
			'cast.serverNotAvailable' => 'メディアサーバーは利用できません。',
			'cast.stopCasting' => 'キャストをやめる',
			'cast.castToDevice' => 'デバイスにキャスト',
			'cast.noEpisodeAvailable' => '出演可能なエピソードはありません。',
			'cast.startFailed' => 'サーバーをチェックして再度試してみる',
			'automation.noActivePlayback' => 'コントロールする動画セッションはありません。',
			'automation.profileNotFound' => 'その Plezy プロフィールは見つかりませんでした。',
			'notifications.newEpisodeTitle' => '新エピソード',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'アプリアイコン',
			'appIcon.defaultIcon' => 'デフォルト',
			'appIcon.current' => '現在のアイコン',
			'appIcon.locked' => '生涯アクセスが必要',
			'appIcon.lockedHint' => '7日間の試用を開始するか、または代替アイコンを使用するために、PlezyNGを一生解除します。',
			'appIcon.changeFailed' => 'アプリアイコンを変更できませんでした',
			'appIcon.launcherHint' => 'Plezyを離れると、ホーム画面に新しいアイコンが表示されます。',
			'appIcon.tvLauncherHint' => 'Plezyを離れると、新しいバナーが表示されます。Android TVでは、テレビを再起動するまで古いバナーが表示され続ける場合があります。',
			'appIcon.names.midnight' => 'ミッドナイト',
			'appIcon.names.ember' => '残り火',
			'appIcon.names.paper' => 'ペーパー',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'ライン',
			'appIcon.names.ocean' => 'オーシャン',
			'appIcon.names.ultraviolet' => 'ウルトラバイオレット',
			'appIcon.names.matcha' => '抹茶',
			'appIcon.names.sunset' => 'サンセット',
			'appIcon.names.gold' => 'ゴールド',
			'appIcon.names.titanium' => 'チタニウム',
			'appIcon.names.glass' => 'ガラス',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'シンセウェイブ',
			'appIcon.names.pixel' => 'ピクセル',
			'appIcon.names.neon' => 'ネオン',
			'appIcon.names.sticker' => 'ステッカー',
			'appIcon.names.ticket' => 'チケット',
			'appIcon.names.pop' => 'ポップ',
			'appIcon.names.strata' => '地層',
			'appIcon.names.facet' => 'ファセット',
			'appIcon.names.tilde' => 'チルダ',
			'auth.signInWithPlex' => 'Plexでサインイン',
			'auth.showQRCode' => 'QRコードを表示',
			'auth.authenticate' => '認証',
			'auth.authenticationTimeout' => '認証がタイムアウトしました。もう一度お試しください。',
			'auth.scanQRToSignIn' => 'このQRコードをスキャンしてサインイン',
			'auth.waitingForAuth' => '認証を待っています…\nブラウザでサインインしてください。',
			'auth.useBrowser' => 'ブラウザを使用',
			'auth.or' => 'または',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}に接続',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Quick Connect を使う',
			'auth.quickConnectInstructions' => 'JellyfinでQuick Connectを開き、このコードを入力してください。',
			'auth.quickConnectWaiting' => '承認を待っています…',
			'auth.quickConnectCancel' => 'キャンセル',
			'auth.quickConnectExpired' => 'Quick Connectの有効期限が切れました。もう一度お試しください。',
			'auth.localDataRecoveryRequired' => 'ローカルのサインイン情報と保留中の再生データを安全に復元できませんでした。もう一度サインインしてください。',
			'auth.pinCheckRejected' => 'Plex PINの確認が拒否されました',
			'auth.connectToDirectPlex' => '地元のサーバーに接続する Plex',
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
			'common.options' => 'オプション',
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
			'common.mediaKind.movie' => '映画',
			'common.mediaKind.show' => 'テレビ番組',
			'common.mediaKind.season' => 'シーズン',
			'common.mediaKind.episode' => 'エピソード',
			'common.mediaKind.artist' => 'アーティスト',
			'common.mediaKind.album' => 'アルバム',
			'common.mediaKind.track' => '曲',
			'common.mediaKind.collection' => 'コレクション',
			'common.mediaKind.playlist' => 'プレイリスト',
			'common.mediaKind.clip' => 'クリップ',
			'common.mediaKind.photo' => '写真',
			'common.mediaKind.folder' => 'フォルダ',
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
			'appAccess.title' => 'すべての機能を7日間無料で試してみてください。',
			'appAccess.description' => 'PlezyNG のすべての機能を使える7日間の無料体験を開始できます。体験期間中の料金やサブスクリプションはありません。体験期間終了後は、ストアに表示される価格で一度購入すると、PlezyNG を無期限で利用できます。',
			'appAccess.trialEndedDescription' => 'あなたの店の価格で1 つの購入で一生のための PlezyNG のすべての機能を解除します。',
			'appAccess.startTrial' => '無料7日間の試験開始',
			'appAccess.trialActive' => '7日間のフルフィードテストがアクティブです。',
			'appAccess.trialEnded' => '7日間の試験が終わりました。',
			'appAccess.trialStartFailed' => 'このデバイスで試用を保存できませんでしたので、また試してみてください。',
			'appAccess.lifetimeTitle' => 'PlezyNG 終身無効',
			'appAccess.lifetimeBody' => '感謝! あなたはすべてのPlezyNG機能に一生のアクセスがあります。',
			'appAccess.manageTitle' => 'PlezyNG 生涯アクセス',
			'appAccess.manageDescription' => '7日間無料で各機能を試してみて、その後、あなたの店の価格で1回の支払いで一生のすべてをオフにします。',
			'appAccess.buy' => ({required Object price}) => 'すべての機能を解除する ${price}',
			'appAccess.loadingPrice' => 'ストアの価格...',
			'appAccess.retryPrice' => '返品価格検索',
			'appAccess.restore' => '生涯購入の復元',
			'appAccess.pending' => '購入は支払いまたは承認を待っています. 店が完了した直後にライフタイムアクセスが開封されます。',
			'appAccess.storeUnavailable' => '購入は利用できません. あなたが店にサインインされていることを確認し、このデバイスで購入が許可されています。',
			'appAccess.productNotFound' => 'PlezyNG ライフタイム オフロックは、このストアではまだ利用できません。',
			'appAccess.productQueryFailed' => 'ストア価格を負担することはできません. 接続をチェックして再度試してみてください。',
			'appAccess.purchaseFailed' => '買い物は終わりませんでした!また試してみてください。',
			'appAccess.restoreFailed' => '買い物を回復するために店に到達できなかったので、また試してみてください。',
			'appAccess.nothingToRestore' => '購入番号 PlezyNG は、このストアのアカウントに検索されました。',
			'settings.title' => '設定',
			'settings.supportDeveloper' => 'Plezyを支援',
			'settings.supportDeveloperDescription' => '寄付で開発を支援',
			'settings.lifetimeAccess' => 'PlezyNG 生涯アクセス',
			'settings.language' => '言語',
			'settings.theme' => 'テーマ',
			'settings.appearance' => '外観',
			'settings.detailPage' => '詳細ページ',
			'settings.themeSongsEnabled' => 'テーマ曲を演奏',
			'settings.themeSongsEnabledDescription' => 'メディアの詳細を見ながら、利用可能なテーマ曲をプレイします。',
			'settings.themeSongVolume' => 'テーマ曲 ボリューム',
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
			'settings.emberTheme' => '残り火',
			'settings.glacierTheme' => '氷河',
			'settings.forestTheme' => '森',
			'settings.plumTheme' => 'プラム',
			'settings.paperTheme' => 'ペーパー',
			'settings.libraryDensity' => 'ライブラリの密度',
			'settings.displayScale' => '表示スケール',
			'settings.compact' => 'コンパクト',
			'settings.comfortable' => 'ゆったり',
			'settings.gridSpacing' => 'グリッド間隔',
			'settings.gridSpacingTight' => '密',
			'settings.gridSpacingNormal' => '標準',
			'settings.gridSpacingSpacious' => 'ゆったり',
			'settings.tvCornerSpotlightBackdrop' => '画面隅の注目コンテンツ背景',
			'settings.tvCornerSpotlightBackdropDescription' => '画面全体ではなく、右上隅に注目コンテンツのアートワークを表示します',
			'settings.viewMode' => '表示モード',
			'settings.gridView' => 'グリッド',
			'settings.listView' => 'リスト',
			'settings.showHeroSection' => '注目コンテンツを表示',
			'settings.showHomeBackdrop' => 'ホーム バックドロップ アートワーク',
			'settings.showHomeBackdropDescription' => 'ホーム ラウンドの背後にある大きな芸術作品を表示する',
			'settings.contentScreensaverEnabled' => 'コンテンツスクリーンセーバー',
			'settings.contentScreensaverEnabledDescription' => 'アプリがアイドルになった後、全画面のアートワークを表示する',
			'settings.contentScreensaverDelay' => 'スクリーンセーバーのスタート後',
			'settings.contentScreensaverLibraries' => 'スクリーンサーバー図書館',
			'settings.contentScreensaverLibrariesDescription' => 'スクリーンセーバーの画像に使うライブラリを選択します。何も選択しない場合は、すべてのライブラリの画像が使われます。',
			'settings.contentScreensaverAllLibraries' => 'すべての図書館',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} 図書館 選択',
			'settings.contentScreensaverNoLibraries' => '接続されたメディアライブラリは利用できません。',
			'settings.contentScreensaverDismissHint' => 'ボタンを押すか、キャンセルするか',
			'settings.newEpisodeNotifications' => '新エピソード通知',
			'settings.newEpisodeNotificationsDescription' => 'ショーに新しいエピソードが追加されると警告します. チェックする Plezy が開いている間に。',
			'settings.continueWatchingRowSize' => '続きを見る サイズ',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} カード',
			'settings.rowSizeCompact' => 'コンパクト',
			'settings.rowSizeStandard' => '標準',
			'settings.rowSizeLarge' => '大',
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
			'settings.showWatchedIndicators' => '視聴済みマークを表示',
			'settings.showWatchedIndicatorsDescription' => '視聴済みの映画、番組、エピソードにチェックマークを表示します',
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
			'settings.playbackBuffer' => '再生バッファー',
			'settings.playbackBufferAuto' => '自動（推奨）',
			'settings.playbackBufferLarge' => '大',
			'settings.playbackBufferExtraLarge' => '特大',
			'settings.playbackBufferDescription' => '不安定な接続に備えてより多くのバッファーを使用します。バッファーサイズによっても制限されます。',
			'settings.streamBufferSize' => 'バッファーサイズ',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => '直播時にどれだけビデオをアップロードするか? トランスコードはサーバーのトランスコドバッファーで止まります。',
			'settings.streamBufferSizeExoNote' => 'Playback Buffer を設定時に置き換え、アプリのメモリの半分にカップ',
			'settings.streamBufferMegabytes' => 'メガバイト',
			'settings.defaultQualityTitle' => 'デフォルト画質',
			'settings.cellularQualityTitle' => 'モバイルデータ通信時のデフォルト画質',
			'settings.remoteQualityTitle' => '遠隔ストリーミング品質',
			'settings.remoteQualitySameAsDefault' => 'デフォルト品質と同じ',
			'settings.cellularQualitySameAsDefault' => 'デフォルト画質と同じ',
			'settings.directPlayCoveredQuality' => '小さい動画をオリジナル画質で再生',
			'settings.directPlayCoveredQualityDescription' => '画質制限内の動画はトランスコードせずにダイレクト再生します',
			'settings.videoCodecs' => 'ビデオコーデック',
			'settings.videoCodecsDescription' => 'チェックを外したコーデックはサーバーがトランスコードします',
			'settings.videoCodecsAlwaysAccepted' => '常に許可',
			'settings.musicQualityTitle' => '音楽の音質',
			'settings.subtitleStyling' => '字幕スタイル',
			'settings.subtitleStylingDescription' => '字幕の外観をカスタマイズ',
			'settings.smallSkipDuration' => '短いスキップ時間',
			'settings.largeSkipDuration' => '長いスキップ時間',
			'settings.rewindOnResume' => '再開時に巻き戻し',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} 秒', ), 
			'settings.defaultSleepTimer' => 'デフォルトスリープタイマー',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} 分', ), 
			'settings.rememberTrackSelections' => '番組/映画ごとにトラック選択を記憶',
			'settings.chooseTracksBeforePlayback' => 'プレイバック前にオーディオとサブタイトルを選択する',
			'settings.chooseTracksBeforePlaybackDescription' => '各ビデオが始まる前にソースオーディオとサブタイトルのトラックを選択します。',
			'settings.alwaysShowSubtitlesOnDevice' => '常にこのデバイスにサブタイトルを表示する',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'サーバーがサブタイトルを選択していない場合は、ローカルにトラックを選択します. これはサーバーの好みを決して変更しません。',
			'settings.autoDownloadPreferredSubtitle' => 'フラッシュが欠けている好みの言語のサブタイトル',
			'settings.autoDownloadPreferredSubtitleDescription' => '地元でご好みの言語で利用可能なサブタイトルを選択します. 存在しない場合は、サーバーがサポートされているときに1つをタッチするようにしてください. 選択はこのデバイスに残ります。',
			'settings.rememberTrackSelectionsDescription' => 'タイトルごとに音声と字幕の選択を記憶します',
			'settings.rememberTrackSelectionsBackendRule' => 'Plexはファイルごとに選択をサーバーに保存します。Jellyfinはアカウントの「選択を記憶」も有効にします。Embyはサポートされていません',
			'settings.followServerTrackSelections' => 'サーバーのエピソードごとのトラック選択を使用',
			'settings.followServerTrackSelectionsDescription' => 'エピソード切り替え時に、現在の選択を引き継ぐ代わりにサーバーで選択された音声と字幕を適用します',
			'settings.resumeMusicOnLaunch' => '音楽セッションを記憶',
			'settings.resumeMusicOnLaunchDescription' => 'アプリ起動時に最後の曲を停止位置で一時停止のまま開きます',
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
			'settings.watchTogetherRelayDescription' => '独自のリレーサーバーを設定しない限り、公開のOpen Watch Partyリレーサーバーを使用します',
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
			'settings.cloudBackup' => 'クラウドバックアップ',
			'settings.cloudBackupDescription' => '移行可能な設定をHTTPS経由でWebDAVの接続先にバックアップします。サーバー接続と認証情報はこのデバイスに残ります。',
			'settings.cloudBackupUrl' => 'WebDAV JSON ファイル URL',
			'settings.cloudBackupUsername' => 'ユーザー名',
			'settings.cloudBackupPassword' => 'パスワード',
			'settings.cloudBackupSaved' => 'クラウドバックアップ 目的地保存',
			'settings.cloudBackupNow' => '復帰今',
			'settings.cloudBackupComplete' => 'バックアップアップアップロード',
			'settings.cloudBackupRestore' => 'バックアップ復元',
			'settings.cloudBackupRestoreConfirm' => 'これは、このデバイス上の適合する携帯設定を置き換えるでしょう。',
			'settings.cloudBackupRestored' => '設定は、Cloud Backup から復元',
			'settings.shortcutsReset' => 'ショートカットをデフォルトにリセットしました',
			'settings.resetShortcutsConfirm' => 'カスタムショートカットがデフォルトに置き換えられます。続行しますか？',
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
			'settings.autoPlayAndSkip' => '自動再生とスキップ',
			'settings.autoPlayNextEpisode' => '次のエピソードを自動再生',
			'settings.autoPlayNextEpisodeDescription' => 'エピソードが終了すると、次のエピソードを自動的に再生します',
			'settings.shuffleStartsFromBeginning' => 'シャッフルは最初から再生',
			'settings.shuffleStartsFromBeginningDescription' => 'シャッフル時に各エピソードを再開位置ではなく最初から再生します',
			'settings.plexCinemaPreRoll' => 'サーバー映画の入力',
			'settings.plexCinemaPreRollDescription' => '映画が始まる前に、Plex プレロールまたは Jellyfin と Emby インタを設定してプレイします。',
			'settings.playNextCountdown' => '次回再生のカウントダウン',
			'settings.playNextCountdownImmediate' => 'すぐに再生',
			'settings.skipIntroMode' => 'イントロをスキップ',
			'settings.skipIntroModeOffDescription' => 'スキップボタンなしでイントロを通常どおり再生します',
			'settings.skipIntroModeButtonDescription' => 'イントロ開始時にスキップボタンを表示します',
			'settings.skipIntroModeAutoDescription' => '下記の遅延後にイントロを自動的にスキップします',
			'settings.skipCreditsMode' => 'クレジットをスキップ',
			'settings.skipCreditsModeOffDescription' => 'スキップボタンなしでクレジットを通常どおり再生します',
			'settings.skipCreditsModeButtonDescription' => 'クレジット開始時にスキップボタンを表示します',
			'settings.skipCreditsModeAutoDescription' => 'クレジットを自動的にスキップして次のエピソードを再生します',
			'settings.skipAdsMode' => 'スキー広告',
			'settings.skipAdsModeOffDescription' => '通常、スカイボタンなしで検出された広告を再生します。',
			'settings.skipAdsModeButtonDescription' => 'スカイボタンを表示すると、Plex が広告を検出します。',
			'settings.skipAdsModeAutoDescription' => '検出された広告を自動的に下の遅延後に削除する',
			'settings.musicPlayback' => '音楽プレイバック',
			'settings.musicSweetFades' => '甘いファド',
			'settings.musicSweetFadesDescription' => '音楽がトラックエンドで、Plex が音量データを持っているとき、アルバムの再生は変わらない。',
			'settings.skipMarkerModeOff' => 'オフ',
			'settings.skipMarkerModeButton' => 'ボタンを表示',
			'settings.skipMarkerModeAuto' => '自動',
			'settings.forceSkipMarkerFallback' => 'フォールバックマーカーを強制',
			'settings.forceSkipMarkerFallbackDescription' => 'Plexにマーカーがある場合でもチャプタータイトルのパターンを使用します',
			'settings.theIntroDbFallback' => 'イントロDBをイントロファルバックとして使用する',
			'settings.theIntroDbFallbackDescription' => 'コミュニティタイミングを使用する場合のみ、サーバーには入力マークがありません。',
			'settings.autoSkipDelay' => '自動スキップの遅延',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自動スキップまで${seconds}秒待機',
			'settings.introPattern' => 'イントロマーカーパターン',
			'settings.introPatternDescription' => 'チャプタータイトルのイントロマーカーに一致する正規表現パターン',
			'settings.creditsPattern' => 'クレジットマーカーパターン',
			'settings.creditsPatternDescription' => 'チャプタータイトルのクレジットマーカーに一致する正規表現パターン',
			'settings.prerolls' => 'プレロール',
			'settings.playPrerollsBeforeMovies' => '映画の前にプレロールをプレイする',
			'settings.playPrerollsBeforeMoviesDescription' => '各映画の前に下の選択からランダムなクリップをプレイします。',
			'settings.prerollLibrary' => 'プリロル図書館',
			'settings.prerollLibraryNotSet' => '未設定',
			'settings.prerollLibraryNoneFound' => 'サーバーに図書館が見つかりません。',
			'settings.prerollSelection' => '選ばれたプレロール',
			'settings.prerollSelectionPickLibraryFirst' => '図書館を最初に選ぶ',
			'settings.prerollSelectionNoneSelected' => '選ばれたプレロールはありません。',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count}件選択',
			'settings.prerollItemPicker' => '選び プレロール',
			'settings.prerollItemPickerLoadFailed' => 'この図書館から物件をアップロードすることはできません。',
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
			'settings.autoDownloadContinueWatching' => 'ダウンロード 続きを見る',
			'settings.autoDownloadContinueWatchingDescription' => 'あなたの続きを見るシールドにアイテムをダウンロードし、シールドを離れた後にそれらを削除します。',
			'settings.downloadQuality' => 'ダウンロード品質',
			'settings.downloadQualityDescription' => 'Plexはダウンロードコードに変換されたコピーを準備します. JellyfinとEmbyはファイルのダウンロード中にトランスコードを変更します. 停止した転送は再起動する必要があります。',
			'settings.askDownloadQualityEachTime' => '各ダウンロードの品質を選択',
			'settings.askDownloadQualityEachTimeDescription' => '各ビデオダウンロードをチェックする前に品質ピッカーを表示する',
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
			'settings.companionRemoteServerStartFailed' => 'コンパニオンリモートサーバーを開始できませんでした',
			'settings.companionRemoteServerStopFailed' => 'コンパニオンリモートサーバーを停止できませんでした',
			'settings.autoPip' => '自動ピクチャーインピクチャー',
			'settings.autoPipDescription' => '再生中にアプリを離れると、自動的にピクチャーインピクチャーに切り替えます',
			'settings.matchContentFrameRate' => 'コンテンツのフレームレートに合わせる',
			'settings.matchContentFrameRateDescription' => '表示のリフレッシュレートを動画コンテンツに合わせます',
			'settings.matchContentResolution' => 'コンテンツの解像度に合わせる',
			'settings.matchContentResolutionDescription' => 'テレビ側でアップスケーリングを処理できるよう、ディスプレイを映像本来の解像度に切り替えます。再生中はメニューや字幕もアップスケールされます',
			'settings.matchRefreshRate' => 'リフレッシュレートを合わせる',
			'settings.matchRefreshRateDescription' => '全画面時に表示のリフレッシュレートを合わせます',
			'settings.matchDynamicRange' => 'ダイナミックレンジを合わせる',
			'settings.matchDynamicRangeDescription' => 'HDRコンテンツではHDRに切り替え、その後SDRに戻します',
			'settings.displaySwitchDelay' => 'ディスプレイ切り替え遅延',
			'settings.tunneledPlayback' => 'トンネル再生',
			'settings.tunneledPlaybackDescription' => '動画トンネリングを使用します。HDR再生で画面が黒くなる場合や動きがカクつく場合は無効にしてください。',
			'settings.audioPassthrough' => 'オーディオパススルー',
			'settings.audioPassthroughDescription' => 'Dolby/DTS音声を再エンコードせずにレシーバーやテレビに送り、サラウンドを維持します。音が出ない場合は無効にしてください。',
			'settings.audioPassthroughDescriptionApple' => 'Dolby Atmosを含むDolby Digital PlusにはApple標準のDolbyデコーダーを使用します。DTSとTrueHDは引き続きマルチチャンネルPCMで再生されます。音が出ない場合は無効にしてください。',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Dolby Atmosを含むDolby Digital PlusにはApple標準のDolbyデコーダーを使用します。iOS、iPadOS、tvOS 26以降では、TrueHD AtmosとDTS:Xが空間オーディオとして再生されます。その他のDTSとTrueHDのトラックはマルチチャンネルPCMで再生されます。音が出ない場合は無効にしてください。',
			'settings.audioPassthroughOverriddenByNormalization' => 'ラウドネス正規化がオンの間はオフ',
			'settings.audioChannelLimit' => '音声チャンネル',
			'settings.audioChannelLimitDescription' => 'すべてのチャンネルを再生できないスピーカー、ヘッドホン、HDMI環境に合わせて、デコードした音声をダウンミックスします',
			'settings.audioChannelLimitOriginal' => 'オリジナル',
			'settings.audioChannelLimitOriginalDescription' => 'トラックのすべてのチャンネルを再生します',
			'settings.audioChannelLimitSurround51' => '最大5.1ch',
			'settings.audioChannelLimitSurround51Description' => '5.1chのPCMにしか対応していないテレビやレシーバー向けに、7.1chを5.1chにダウンミックスします。パススルーには影響しません。',
			'settings.audioChannelLimitStereo' => 'ステレオ',
			'settings.audioChannelLimitStereoDescription' => 'ステレオスピーカーやヘッドホン向けに2チャンネルにダウンミックスします。パススルーはオフになります。',
			'settings.downmixCenterBoost' => 'センターチャンネルブースト',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'ブースト (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'ダウンミックス時の音量正規化',
			'settings.audioDownmixNormalizeDescription' => 'クリッピングを防ぐためにミックス音量を下げます。オフにすると元の音量を維持します（大音量シーンで歪む場合があります）。',
			'settings.dvConversionMode' => 'Dolby Vision 変換',
			'settings.dvConversionModeDescription' => 'Dolby Vision Profile 7 ファイルの処理方法を選択します。',
			'settings.dvConversionAuto' => '自動',
			'settings.dvConversionNative' => 'ネイティブ / 無効',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'デバイスの機能検出と通常のフォールバック動作を使用します',
			'settings.dvConversionNativeDescription' => 'ネイティブ DV7 を強制し、DV 変換の再試行を抑制します',
			'settings.dvConversionDv81Description' => 'Dolby Vision プロファイル 8.1 へのインライン RPU 変換を強制します',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision の RPU/EL レイヤーを削除し、通常の HEVC として扱います',
			'settings.disableDolbyVision' => 'Dolby Vision を無効にする',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'ファイルに HDR10 または HLG レイヤーがある場合は、Dolby Vision の代わりにそれを再生します',
			'settings.hdrSdrConversion' => 'HDRからSDRへの変換',
			'settings.hdrSdrConversionDescription' => 'ディスプレイがHDRを表示できないときに、HDR映像を何で変換するかを選択します。',
			'settings.hdrSdrConversionAuto' => '自動',
			'settings.hdrSdrConversionAutoDescription' => 'Android 9以降はデバイス、それより前のバージョンではプレーヤー',
			'settings.hdrSdrConversionDevice' => 'デバイス',
			'settings.hdrSdrConversionDeviceDescription' => 'デバイスの映像ハードウェアで変換します。最も高速ですが、色はデバイスによって異なります',
			'settings.hdrSdrConversionPlayer' => 'プレーヤー',
			'settings.hdrSdrConversionPlayerDescription' => 'プレーヤーで変換します。色は一定ですが、低価格なTVボックスでは4Kがカクつくことがあります',
			'settings.deinterlace' => 'デインターレース',
			'settings.deinterlaceDescription' => 'インターレース映像のくし型ノイズを除去します（mpvプレーヤーのみ）',
			'settings.deinterlaceOff' => 'オフ',
			'settings.deinterlaceOffDescription' => 'インターレース映像をデコードされたまま表示します',
			'settings.deinterlaceVideo' => 'ビデオ',
			'settings.deinterlaceVideoDescription' => '各フィールドを1つのフレームに変換します。スポーツ、ニュース、コンサートなど、テレビ用に撮影された映像向けです',
			'settings.deinterlaceFilm' => 'フィルム',
			'settings.deinterlaceFilmDescription' => 'NTSC DVDによくある、29.97fpsにテレシネされた映画やアニメの元のフレームを復元します。テレビ用に撮影された映像はカクつきます。ライブTVでは「ビデオ」を使用します',
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
			'settings.preferredServer' => '優先サーバー',
			'settings.preferredServerDescription' => 'このサーバーの結果を優先し、すべての接続されたサーバーを利用できるようにします。',
			'settings.preferredServerAutomatic' => '自動',
			'settings.showExploreTab' => '「探す」タブを表示',
			'settings.showExploreTabDescription' => 'Plex Discoverと接続済みのトラッカーのコンテンツを「探す」タブに表示します',
			'settings.hideEmptyLibraries' => '空っぽの図書館を隠す',
			'settings.hideEmptyLibrariesDescription' => 'サーバーに報告された項目数をゼロからナビゲーションから削除する図書館。',
			'settings.liveTvDefaultFavorites' => 'お気に入りチャンネルをデフォルトに',
			'settings.liveTvDefaultFavoritesDescription' => 'ライブTVを開いたときにお気に入りチャンネルのみ表示',
			'settings.general' => '一般',
			'settings.generalDescription' => '言語、起動、ウィンドウの動作',
			'settings.languageAndRegion' => '言語と地域',
			'settings.startup' => '起動',
			'settings.display' => 'ディスプレイ',
			'settings.libraryAndCards' => 'ライブラリとカード',
			'settings.homeScreen' => 'ホーム画面',
			'settings.navigation' => 'ナビゲーション',
			'settings.window' => 'ウィンドウ',
			'settings.liveTv' => 'ライブTV',
			'settings.player' => 'プレーヤー',
			'settings.videoAndDisplay' => '映像とディスプレイ',
			'settings.audio' => '音声',
			'settings.quality' => '画質',
			'settings.subtitles' => '字幕',
			'settings.seekAndTiming' => 'シークとタイミング',
			'settings.behavior' => '動作',
			'settings.gestures' => 'ジェスチャー',
			'settings.gestureBrightnessSwipe' => '明るさスワイプ',
			'settings.gestureBrightnessSwipeDescription' => '左端を上下にスワイプして明るさを調整します',
			'settings.gestureVolumeSwipe' => '音量スワイプ',
			'settings.gestureVolumeSwipeDescription' => '右端を上下にスワイプして音量を調整します',
			'settings.gesturePinchToZoom' => 'ピンチでズーム',
			'settings.gesturePinchToZoomDescription' => '動画をピンチしてズームイン・アウト',
			'settings.gestureSeekSwipe' => 'スイッチ検索',
			'settings.gestureSeekSwipeDescription' => '左または右をスイッチする動画のどこでも検索する; リリースする ジャンプ',
			'settings.rememberBrightnessLevel' => '明るさを記憶',
			'settings.rememberBrightnessLevelDescription' => '前回スワイプで設定した明るさで再生を開始します',
			'settings.controls' => 'コントロール',
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
			'settings.followSystem' => 'システムに合わせる',
			'settings.followAppLanguage' => '表示言語に合わせる',
			'settings.regionFormat' => '地域別の書式',
			'settings.regionFormatDescription' => '日付、数値、単位の表示形式を選択します。',
			'settings.metadataLanguage' => 'メタデータの言語',
			'settings.metadataLanguageDescription' => 'サーバーが対応している場合に、タイトルと説明に使用する言語です。音声と字幕の言語は別に設定します。',
			'settings.experimentalDolbyVision' => '実験的なDolby Vision',
			'settings.experimentalDolbyVisionDescription' => '次の再生で実験的なFELレンダラーを使用します。別途ビルドしたエンジンが必要です。',
			'settings.dvExperimentUnavailableDescription' => 'この実験は現在Linuxでのみ利用できます。',
			'settings.dvCompatibilityFallback' => '互換性フォールバック',
			'settings.dvCompatibilityFallbackDescription' => '実験を開始できない場合は標準レンダラーを使用します。FELデータが失われる可能性があります。',
			'settings.dvExperimentDiagnostics' => '動画実験のログ記録',
			'settings.dvExperimentDiagnosticsDescription' => '次の再生でプレーヤーの詳細ログを有効にします。',
			'themeEditor.builtIn' => '標準',
			'themeEditor.presets' => 'プリセット',
			'themeEditor.custom' => 'カスタム',
			'themeEditor.customEmpty' => '未作成',
			'themeEditor.editCustom' => 'カスタムテーマを編集',
			'themeEditor.editCustomDescription' => 'すべての色を自分で選択',
			'themeEditor.locked' => '生涯アクセスが必要',
			'themeEditor.savedLocked' => '保存 - 生涯アクセスで利用可能',
			'themeEditor.title' => 'カスタムテーマ',
			'themeEditor.startFrom' => '元にするテーマ',
			'themeEditor.startFromDescription' => '別のテーマからすべての色をコピー',
			'themeEditor.colors' => '色',
			'themeEditor.preview' => 'プレビュー',
			'themeEditor.slots.bg' => '背景',
			'themeEditor.slots.surface' => 'サーフェス',
			'themeEditor.slots.outline' => '枠線',
			'themeEditor.slots.text' => 'テキスト',
			'themeEditor.slots.textMuted' => '補助テキスト',
			'themeEditor.slots.accent' => 'アクセント',
			'themeEditor.opacity' => '不透明度',
			'themeEditor.hexHint' => '#RRGGBB または #AARRGGBB',
			'themeEditor.fromOtherThemes' => '他のテーマから',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme}の${color}',
			'themeEditor.contrast.textOnBg' => '背景上のテキスト',
			'themeEditor.contrast.textOnSurface' => 'サーフェス上のテキスト',
			'themeEditor.contrast.textMutedOnBg' => '背景上の補助テキスト',
			'themeEditor.contrast.textMutedOnSurface' => 'サーフェス上の補助テキスト',
			'themeEditor.contrast.accentOnBg' => '背景上のアクセント',
			'themeEditor.contrast.accentOnSurface' => 'サーフェス上のアクセント',
			'themeEditor.contrast.labelOnAccent' => 'アクセント上のボタンラベル',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1（推奨値の${minimum}:1未満）',
			'themeEditor.discardTitle' => '変更を破棄しますか？',
			'themeEditor.discardMessage' => '保存されていない色の変更は失われます。',
			'themeEditor.discard' => '破棄',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'エピソード${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '残り${minutes}分',
			'themeEditor.previewSwitch' => '自動再生',
			'themeEditor.previewMutedText' => '補助テキストはこのように表示されます',
			'search.hint' => '映画、番組、音楽を検索…',
			'search.tryDifferentTerm' => '別の検索語をお試しください',
			'search.searchYourMedia' => 'メディアを検索',
			'search.enterTitleActorOrKeyword' => 'タイトル、俳優、またはキーワードを入力',
			'search.people' => '人物',
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
			'hotkeys.actions.subtitleDelayIncrease' => '字幕を遅らせる',
			'hotkeys.actions.subtitleDelayDecrease' => '字幕を早める',
			'hotkeys.actions.shaderToggle' => 'シェーダー切替',
			'hotkeys.actions.skipMarker' => 'イントロ/クレジットをスキップ',
			'hotkeys.actions.screenshot' => 'スクリーンショットを撮る',
			'hotkeys.actions.framePrevious' => '前 フレーム',
			'hotkeys.actions.frameNext' => '次 フレーム',
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
			'mediaMenu.deleteShowConfirm' => '番組を削除',
			'mediaMenu.deleteMovieConfirm' => '映画を削除',
			'mediaMenu.deleteAnyway' => 'それでも削除',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'サーバーから「${title}」を完全に削除しますか？',
			'mediaMenu.deleteMultipleWarning' => 'すべてのエピソードとそのファイルが含まれます。',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '含まれる${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のエピソードとそのファイルが削除されます。', other: '中の全${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}エピソードとそのファイルが削除されます。', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: 'このアイテムは${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個のファイルに保存されており、そのファイルが削除されます。', other: 'このアイテムは${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個のファイルにまたがって保存されており、すべて削除されます。', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '同じファイルに保存されている他の${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のエピソードも削除されます：', other: '同じファイルに保存されている他の${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}エピソードも削除されます：', ), 
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
			'accessibility.red' => '赤',
			'accessibility.green' => '緑',
			'accessibility.blue' => 'ブルー',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'アクセス性',
			'accessibility.summary' => 'テキスト、対比、動き、コントロール',
			'accessibility.systemHint' => 'デバイスのアクセス性設定は常に適用されます. これらのオプションは、PlezyNG 全体で調整を追加します。',
			'accessibility.readability' => '読み方と視覚性',
			'accessibility.textSize' => '追加テキストサイズ',
			'accessibility.preview' => '次のストーリーを見つけて、自分のペースで読んで、聞き、観る。',
			'accessibility.boldText' => 'ハードインターフェイス テキスト',
			'accessibility.highContrast' => '高い対比',
			'accessibility.highContrastHint' => '明るい背景でも暗い背景でも、文字や輪郭線、フォーカス表示を見やすくします。',
			'accessibility.interaction' => '動きと相互作用',
			'accessibility.reduceMotion' => '動きを減らす',
			'accessibility.reduceMotionHint' => 'フォーカス表示、ページ切り替え、装飾効果の動きを止めます。',
			'accessibility.largeTargets' => 'タッチターゲットの拡大',
			'accessibility.largeTargetsHint' => '共通の操作ボタンの領域を広げ、タッチ操作や支援技術による操作をしやすくします。',
			'accessibility.navigationHint' => 'TabとShift+Tabで操作項目を移動し、EnterまたはSpaceで実行、Escapeまたは戻るボタンで閉じます。本を開いている間は、拡大率や読書設定を変更できます。',
			'tooltips.shufflePlay' => 'シャッフル再生',
			'tooltips.playTrailer' => '予告編を再生',
			'tooltips.markAsWatched' => '視聴済みにする',
			'tooltips.markAsUnwatched' => '未視聴にする',
			'audioTracks.track' => ({required Object n}) => '音声トラック${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} フレーム', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} フレーム', ), 
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
			'videoControls.trackSelectionTitle' => 'プレイバック前にトラックを選択する',
			'videoControls.trackSelectionAuto' => '自動選択',
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
			'videoControls.screenshotFailed' => 'スクリーンショットを撮影できませんでした',
			'videoControls.zoomPercent' => ({required Object percent}) => 'ズーム ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => '音量 ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0以降が必要です',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0以降が必要です',
			'videoControls.pipErrors.permissionDisabled' => 'ピクチャーインピクチャーが無効です。システム設定で有効にしてください。',
			'videoControls.pipErrors.notSupported' => 'デバイスはピクチャーインピクチャーモードをサポートしていません',
			'videoControls.pipErrors.voSwitchFailed' => 'ピクチャーインピクチャーの映像出力切替に失敗しました',
			'videoControls.pipErrors.failed' => 'ピクチャーインピクチャーの開始に失敗しました',
			'videoControls.pipErrors.prepareFailed' => 'ピクチャーインピクチャーを準備できませんでした',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'エラーが発生しました: ${error}',
			'videoControls.chapters' => 'チャプター',
			'videoControls.noChaptersAvailable' => 'チャプターがありません',
			'videoControls.queue' => 'キュー',
			'videoControls.noQueueItems' => 'キューにアイテムがありません',
			'videoControls.noAudioDevicesAvailable' => 'オーディオデバイスがありません',
			'videoControls.searchSubtitles' => '字幕を検索',
			'videoControls.loadSubtitleFile' => 'サブタイトルファイルをダウンロード',
			'videoControls.subtitleLoadFailed' => 'サブタイトルファイルをダウンロードできなかった',
			'videoControls.language' => '言語',
			'videoControls.noSubtitlesFound' => '字幕が見つかりません',
			'videoControls.subtitleDownloaded' => '字幕をダウンロードしました',
			'videoControls.subtitleDownloadedNotApplied' => '字幕はダウンロードされましたが、選択できませんでした',
			'videoControls.subtitleDownloadFailed' => '字幕のダウンロードに失敗しました',
			'videoControls.searchLanguages' => '言語を検索…',
			'videoControls.skipIntro' => 'イントロをスキップ',
			'videoControls.skipCredits' => 'クレジットをスキップ',
			'videoControls.skipAds' => 'スキー広告',
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
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '自動削除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ダウンロード', other: '視聴済みダウンロードを${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件自動削除しました', ), 
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
			'messages.playbackFailedDetail' => ({required Object error}) => '再生を開始できませんでした: ${error}',
			'messages.audioOutputFailed' => 'オーディオ出力が応答しなくなりました。テレビやレシーバーの音声接続を確認してください。他のアプリでも音が出ない場合は、デバイスを再起動してください。',
			'messages.mediaUnavailable' => 'このコンテンツは利用できなくなりました。',
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
			_ => null,
		} ?? switch (path) {
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
			'messages.playbackNotAllowedTitle' => '再生が許可されていません',
			'messages.playbackNotAllowedBody' => 'サーバーがこのアイテムのストリーミングを拒否しました（HTTP 403）。お使いのアカウントに再生の権限がないか、サーバーがローカルネットワーク内での再生のみを許可している可能性があります。',
			'messages.logsUploaded' => 'ログをアップロードしました',
			'messages.logsUploadFailed' => 'ログのアップロードに失敗しました',
			'messages.logId' => 'ログID',
			'messages.burnedSubtitlesUseMenu' => '字幕はこのストリームに焼き付けられています。字幕メニューから変更してください。',
			'messages.noVideoUrl' => '利用可能な動画URLがありません',
			'messages.playbackNoMediaSources' => 'サーバーから再生可能なメディアソースが返されませんでした',
			'messages.playbackDataNotPrepared' => '再生データの準備が完了する前に再生が開始されました',
			'messages.streamSelectionUnavailable' => 'このソースではストリームを選択できません',
			'messages.streamSelectionFailed' => '選択したストリームを適用できませんでした',
			'messages.trackSelectionNotRemembered' => 'このトラック選択は現在の再生にのみ適用されます。',
			'messages.serverUnavailableForProfile' => '現在のプロフィールで利用可能なサーバーがありません',
			'subtitlingStyling.previewSample' => 'ブラウンフォックスが、狂犬を飛び越える。',
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
			'subtitlingStyling.useMargins' => '余白を使用',
			'subtitlingStyling.useMarginsDescription' => 'テキスト字幕を動画の外側の領域に表示できるようにします。スタイル付き字幕は元の配置を維持する場合があります。',
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
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => '行を追加',
			'mpvConfig.removeLine' => '行を削除',
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
			'profiles.signOutPlexDeleteDownloads' => 'ダウンロードも削除',
			'profiles.signOutPlexDeleteDownloadsDescription' => '削除しない場合、ダウンロードはこのデバイスに残り、このアカウントに再度サインインすると再び利用できます。',
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
			'profiles.copyAutomationLink' => 'コピー Android 自動化リンク',
			'profiles.copyAutomationLinkDescription' => 'このプロフィールを選択する Android 意図または自動化から プロフィール PIN チェックはまだ適用されます。',
			'profiles.automationLinkCopied' => 'プロフィール自動化リンクコピー',
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
			'profiles.borrowEmptySubtitle' => 'まず、別のプロフィールをPlex、JellyfinまたはEmbyに接続してください。',
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
			'profiles.settingsLocked' => '設定はこのプロフィールに閉じ込められています。',
			'profiles.unlockSettings' => 'オフロック設定',
			'profiles.showExploreForProfile' => 'プロフィールを検索する',
			'profiles.showExploreForProfileDescription' => 'このプロフィールのナビゲーションから Explore を削除するためにオフにします。',
			'connections.sectionTitle' => '接続',
			'connections.addConnection' => '接続を追加',
			'connections.addConnectionSubtitleNoProfile' => 'Plexでサインインするか、JellyfinまたはEmbyサーバーに接続',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}に追加：Plex、Jellyfin、Emby、または別のプロフィールの接続',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} のセッションの有効期限が切れました',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 台のサーバーのセッションの有効期限が切れました',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} がこのアカウントへのアクセスを拒否しました',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} 台のサーバーがこのアカウントへのアクセスを拒否しました',
			'connections.signInAgain' => '再度サインイン',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product}接続を編集',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName}のURLを追加または削除します。Plezyは到達可能なURLのうち、レイテンシーが最も低いものを使用します。',
			'accountPreferences.sectionTitle' => 'アカウント設定',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '音声・字幕・ライブラリのオプションは${account}に保存されています',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '音声・字幕・ライブラリのオプションは${count}個のアカウントに保存されています',
			'accountPreferences.pickAccount' => '各アカウントに独自の設定が保存されています。編集するアカウントを選択してください。',
			'accountPreferences.storedOnAccount' => 'これらのオプションはアカウント自体に保存されるため、サインインしているすべてのアプリ（他のデバイスのPlezyを含む）で使用されます。',
			'accountPreferences.noAccounts' => '設定できるアカウントがありません',
			'accountPreferences.noAccountsHint' => 'Plexにサインインするか、JellyfinまたはEmbyサーバーに接続すると、そのアカウントに保存された設定がここに表示されます。',
			'accountPreferences.unavailable' => 'このアカウントにアクセスできません',
			'accountPreferences.loadFailed' => 'この設定を読み込めませんでした',
			'accountPreferences.noPreference' => '指定なし',
			'accountPreferences.notSet' => '未設定',
			'accountPreferences.groups.audioAndSubtitles' => '音声と字幕',
			'accountPreferences.groups.libraryDisplay' => 'ライブラリ',
			'accountPreferences.groups.personalMedia' => '個人メディア',
			'accountPreferences.preferredAudioLanguage' => '優先音声言語',
			'accountPreferences.autoSelectAudio' => '言語で音声を選択',
			'accountPreferences.autoSelectAudioDescription' => 'オフにすると、ファイルでデフォルトとマークされた音声トラックがそのまま使われます。',
			'accountPreferences.preferredSubtitleLanguage' => '優先字幕言語',
			'accountPreferences.subtitleMode' => '字幕の自動表示',
			'accountPreferences.subtitleModes.none' => '手動選択',
			'accountPreferences.subtitleModes.noneDescription' => '自動では字幕をオンにしません。',
			'accountPreferences.subtitleModes.defaultMode' => 'トラックのフラグに従う',
			'accountPreferences.subtitleModes.defaultModeDescription' => '各字幕トラックに保存されたデフォルトと強制のフラグを使用します。',
			'accountPreferences.subtitleModes.always' => '常に有効',
			'accountPreferences.subtitleModes.alwaysDescription' => '優先言語の字幕トラックがあれば、常にオンにします。',
			'accountPreferences.subtitleModes.onlyForced' => '強制字幕のみ',
			'accountPreferences.subtitleModes.onlyForcedDescription' => '強制とマークされたトラックのみ読み込みます。',
			'accountPreferences.subtitleModes.smart' => '外国語音声時に表示',
			'accountPreferences.subtitleModes.smartDescription' => '音声が別の言語の場合にのみ字幕をオンにします。',
			'accountPreferences.subtitleAccessibility' => 'SDH字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => '非SDH字幕を優先',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH字幕を優先',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'SDH字幕のみ',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => '非SDH字幕のみ',
			'accountPreferences.forcedSubtitles' => '強制字幕',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => '非強制字幕を優先',
			'accountPreferences.forcedSubtitleOptions.preferForced' => '強制字幕を優先',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => '強制字幕のみ',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => '非強制字幕のみ',
			'accountPreferences.displayMissingEpisodes' => '欠落エピソードを表示',
			'accountPreferences.displayMissingEpisodesDescription' => 'サーバーが把握しているがファイルがないエピソードを一覧表示します。',
			'accountPreferences.hidePlayedInLatest' => '「最新」の視聴済みアイテムを非表示',
			'accountPreferences.hidePlayedInLatestDescription' => 'すでに視聴したアイテムは、サーバーの「最新」に表示されません。',
			'accountPreferences.displayCollectionsView' => 'コレクションビューを表示',
			'accountPreferences.displayCollectionsViewDescription' => 'ライブラリに加えて、サーバーのコレクションビューを表示します。',
			'accountPreferences.rewatchingInNextUp' => '再視聴した番組を「次のエピソード」に残す',
			'accountPreferences.rewatchingInNextUpDescription' => '番組を見終えた後に再び見始めると、「次のエピソード」は番組を外さずに再視聴に追従します。',
			'accountPreferences.watchedIndicator' => '視聴済みマーク',
			'accountPreferences.watchedIndicatorOptions.none' => 'しない',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => '映画とテレビ番組',
			'accountPreferences.watchedIndicatorOptions.movies' => '映画のみ',
			'accountPreferences.watchedIndicatorOptions.shows' => 'テレビ番組のみ',
			'accountPreferences.mediaReviewsVisibility' => '評価とレビュー',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'ユーザーと批評家',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'ユーザーのみ',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => '批評家のみ',
			'accountPreferences.mediaReviewsOptions.nobody' => '非表示',
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
			'discover.findNext.title' => '次を見つける',
			'discover.findNext.open' => '次を見つける',
			'discover.findNext.anyTime' => 'いつでも',
			'discover.findNext.timeAvailable' => 'あなたはどのくらいの時間を持っていますか?',
			'discover.findNext.filters' => '瞬間を選ぶ',
			'discover.findNext.watch' => '見る',
			'discover.findNext.listen' => '聴く',
			'discover.findNext.read' => '読む',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration} で終了',
			'discover.findNext.aboutDuration' => ({required Object duration}) => '${duration}について',
			'discover.findNext.nextUnit' => ({required Object duration}) => '次 次の投稿: ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} 総合',
			'discover.findNext.timingVaries' => 'タイミングが変わる',
			'discover.findNext.notNow' => 'いまではない',
			'discover.findNext.swipeHint' => 'スイッチ、または下のボタンを使用します。',
			'discover.findNext.saved' => '保存ピック',
			'discover.findNext.savedCount' => ({required Object count}) => 'トップページ > ${count}',
			'discover.findNext.undo' => 'でしょ',
			'discover.findNext.details' => '詳細',
			'discover.findNext.noPicks' => 'まだ選べないもの',
			'discover.findNext.noPicksHint' => '図書館に接続するか、メディアソースを追加してスタートします。',
			'discover.findNext.noMatches' => 'この瞬間に合わないもの。',
			'discover.findNext.noMatchesHint' => '別のフォーマットを試すか、自分に時間を与えるか。',
			'discover.findNext.allDone' => 'みんな捕まえてる',
			'discover.findNext.allDoneHint' => 'これらの選択肢を再度見るために新鮮なミックスを開始します。',
			'discover.findNext.refresh' => 'もう一つのミックスを見つける',
			'discover.findNext.sourceReason' => ({required Object source}) => 'から ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'から ${library}',
			'discover.findNext.ownedReason' => 'あなたの図書館から',
			'discover.findNext.liveNow' => 'で今',
			'discover.findNext.watchLive' => '見るライブ',
			'discover.findNext.filterAnything' => '何でも',
			'discover.findNext.filterWatch' => '見る',
			'discover.findNext.filterListen' => '聴く',
			'discover.findNext.filterRead' => '読む',
			'discover.findNext.twentyMinutes' => '20分',
			'discover.findNext.fortyFiveMinutes' => '45分',
			'discover.findNext.ninetyMinutes' => '90分',
			'discover.findNext.apply' => '応募',
			'discover.findNext.openFailed' => 'この選択肢はもはや利用できません. 再度チェックするためにリフレッシュします。',
			'discover.findNext.changeFailed' => '変更はできませんが、もう一度試してみてください。',
			'discover.findNext.savedLimit' => '保存されたピックが満たされ、1つのピックを削除して別のピックを保存します。',
			'discover.extras' => '予告編とエクストラ',
			'discover.studio' => 'スタジオ',
			'discover.rating' => '評価',
			'discover.director' => '監督',
			'discover.directors' => '監督',
			'discover.movie' => '映画',
			'discover.tvShow' => 'テレビ番組',
			'discover.minutesLeft' => ({required Object minutes}) => '残り${minutes}分',
			'discover.moreLikeThis' => '似ている作品',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} タイトル', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}作品', ), 
			'discover.person.born' => '生年月日',
			'discover.person.died' => '没年月日',
			'discover.person.birthplace' => '出生地',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date}（${age}歳）',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date}（${age}歳没）',
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
			'errors.reasonTimedOut' => '接続がタイムアウトしました',
			'errors.reasonUnreachable' => 'メディアサーバーに接続できませんでした',
			'errors.reasonRefused' => 'メディアサーバーがリクエストを拒否しました',
			'errors.reasonNotFound' => 'この項目はメディアサーバー上に存在しません',
			'errors.reasonServerError' => 'メディアサーバーでエラーが発生しました',
			'errors.reasonCancelled' => 'リクエストがキャンセルされました',
			'errors.reasonUnexpected' => '予期しないエラーが発生しました',
			'libraries.playRandomMovie' => 'ランダム映画を演じる',
			'libraries.randomPickFailed' => 'この図書館からランダム映画を選ぶことはできません。',
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
			'libraries.filterCategories.filePath' => 'ファイルパス',
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
			'libraries.sortLabels.dateDownloaded' => 'ダウンロード日',
			'libraries.sortLabels.size' => 'サイズ',
			'libraries.sortLabels.library' => 'ライブラリ',
			'libraries.advancedFilters.include' => '含める',
			'libraries.advancedFilters.exclude' => '除外',
			'libraries.advancedFilters.any' => '指定なし',
			'libraries.advancedFilters.yes' => 'はい',
			'libraries.advancedFilters.no' => 'いいえ',
			'libraries.advancedFilters.not' => ({required Object value}) => '${value}以外',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count}件選択',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count}件除外',
			'libraries.advancedFilters.searchValues' => '値を検索',
			'libraries.advancedFilters.noValues' => '値がありません',
			'libraries.advancedFilters.matchContains' => '含む',
			'libraries.advancedFilters.matchNotContains' => '含まない',
			'libraries.advancedFilters.matchIs' => '一致する',
			'libraries.advancedFilters.matchIsNot' => '一致しない',
			'libraries.advancedFilters.matchBeginsWith' => '前方一致',
			'libraries.advancedFilters.matchEndsWith' => '後方一致',
			'libraries.advancedFilters.textHint' => 'テキストを入力',
			'libraries.advancedFilters.from' => '下限',
			'libraries.advancedFilters.to' => '上限',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from}〜${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value}以上',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value}以下',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '過去${count}日間',
			'libraries.advancedFilters.dateLastYear' => '過去1年間',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '${count}日以上前',
			'libraries.advancedFilters.dateOlderThanYear' => '1年以上前',
			'libraries.selection.selectItems' => '選択項目',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count}件選択',
			'libraries.selection.actions' => '選択行動',
			'libraries.selection.confirmDescendants' => 'これは、選択されたショーやシーズンのすべてのエピソードを変更します。',
			'libraries.selection.confirmUnwatched' => '選択したアイテムの再生状況もリセットされます。',
			'libraries.selection.confirmCount' => ({required Object count}) => '選ばれた項目: ${count}',
			'libraries.selection.completed' => ({required Object count}) => '更新項目: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => '更新 ${succeeded}; 失敗 ${failed}. 失敗した項目は選択されます。',
			'about.title' => 'アプリについて',
			'about.openSourceLicenses' => 'オープンソースライセンス',
			'about.versionLabel' => ({required Object version}) => 'バージョン ${version}',
			'about.appDescription' => 'Flutter製の美しいPlex・Jellyfin・Embyクライアント',
			'about.viewLicensesDescription' => 'サードパーティライブラリのライセンスを表示',
			'about.privacyPolicy' => 'プライバシーポリシー',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email})のサーバーが見つかりません',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'サーバーの読み込みに失敗しました: ${error}',
			'serverSelection.noValidServers' => 'このアカウントで利用可能なサーバーが見つかりませんでした',
			'hubDetail.title' => 'タイトル',
			'hubDetail.releaseYear' => '公開年',
			'hubDetail.dateAdded' => '追加日',
			'hubDetail.rating' => '評価',
			'hubDetail.noItemsFound' => 'アイテムが見つかりません',
			'logs.clearLogs' => 'ログをクリア',
			'logs.copyLogs' => 'ログをコピー',
			'logs.uploadLogs' => 'ログをアップロード',
			'logs.saveLogs' => 'ファイルへのログを保存',
			'logs.logsSaved' => ({required Object path}) => 'ログを保存する ${path}',
			'logs.saveLogsFailed' => 'ログファイルを保存できませんでした。',
			'detail.endsAt' => ({required Object time}) => '${time}に終了',
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
			'explore.mdblistShelves.manage' => '管理 シールド探検',
			'explore.mdblistShelves.manageDescription' => 'あなたのアカウントからリストを選択し、整理します MDBList',
			'explore.mdblistShelves.description' => 'MDBList アカウントから公開映画やテレビリストを選択します. MDBList にリストを作成またはコピーして更新します。',
			'explore.mdblistShelves.selected' => '選ばれたシート',
			'explore.mdblistShelves.available' => '利用可能なアカウントリスト',
			'explore.mdblistShelves.noLists' => '公開映画やテレビリストが返ってこない リストを作成またはコピーする MDBList で、更新します。',
			'explore.mdblistShelves.displayName' => 'シェルフ ディスプレイ名',
			'explore.mdblistShelves.nameHint' => 'オリジナルリスト名を使用するために白いままにします。',
			'explore.mdblistShelves.add' => 'シェルフを追加',
			'explore.mdblistShelves.save' => 'シェルター保存',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '移動 ${title} アップ',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'ダウンロード ${title}',
			'explore.mdblistShelves.unavailable' => 'このリストは利用できません. 設定でそのシールを取り戻すか削除します。',
			'explore.mdblistShelves.rateLimited' => '申請の制限はMDBList 達成されました 後で撤回してください。',
			'explore.mdblistShelves.loadFailed' => '接続をチェックしてリトリを確認する',
			'explore.mdblistShelves.saveFailed' => 'シェルフを保存できませんでした。もう一度お試しください。',
			'explore.mdblistShelves.accountChanged' => 'アカウントまたはプロフィールが変更されました. これらの設定を再開します。',
			'explore.mdblistShelves.settingsUnreadable' => '保存されたシートは読み取れないので、リストを再度選択して、これらの設定を置き換える。',
			'explore.title' => '見つける',
			'explore.selectSource' => 'ソースを選択',
			'explore.rows.watchlist' => 'ウォッチリスト',
			'explore.rows.recommendedMovies' => 'おすすめの映画',
			_ => null,
		} ?? switch (path) {
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} エピソード', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}話', ), 
			'explore.cast' => 'キャスト',
			'explore.characters' => 'キャラクター',
			'explore.addToWatchlist' => 'ウォッチリストに追加',
			'explore.removeFromWatchlist' => 'ウォッチリストから削除',
			'explore.addedToWatchlist' => 'ウォッチリストに追加しました',
			'explore.removedFromWatchlist' => 'ウォッチリストから削除しました',
			'explore.watchlistUpdateFailed' => 'ウォッチリストを更新できませんでした',
			'explore.watchlistNoMatch' => 'このアイテムに一致するウォッチリスト項目が見つかりませんでした',
			'explore.notInLibrary' => 'ライブラリにありません',
			'explore.inTheseLibraries' => 'これらのライブラリにあります',
			'explore.checkingLibrary' => 'ライブラリを確認中…',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: 'サーバーをチェックできない ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}台のサーバーを確認できませんでした', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} コメント', other: 'コメント ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件', ), 
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
			'explore.creditRole.actor' => '俳優',
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: 'ユーザー数: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ユーザー数', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}人のユーザーがおすすめ', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who}がおすすめ',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who}がお気に入り登録',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '未放送 ${n}話',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '視聴者の${percent}がおすすめ',
			'explore.detail.relatedTitles' => '関連作品',
			'explore.detail.background' => '背景',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 結果', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件の結果', ), 
			'liveTv.title' => 'ライブTV',
			'liveTv.guide' => '番組表',
			'liveTv.noChannels' => 'チャンネルがありません',
			'liveTv.noDvr' => 'どのサーバーにもDVRが設定されていません',
			'liveTv.serverUnavailable' => 'ライブTVサーバーを利用できません。',
			'liveTv.serverNotConnected' => 'ライブTVサーバーに接続されていません。',
			'liveTv.noPrograms' => '番組データがありません',
			'liveTv.liveStreamFailed' => 'ライブストリームに失敗しました',
			'liveTv.unknownProgram' => '不明な番組',
			'liveTv.timelineLiveProgram' => 'ライブプログラム(プレイバックはこのプログラムの外にある可能性があります)',
			'liveTv.timelineBuffer' => 'バッファータイムライン',
			'liveTv.timelineUnavailable' => 'タイムライン不利用',
			'liveTv.timelineEstimated' => '評価プレイバック',
			'liveTv.timelinePending' => '探し続ける',
			'liveTv.timelineStale' => 'スケジュールが遅れる可能性',
			'liveTv.unknownHub' => '不明',
			'liveTv.unknownError' => '不明なエラー',
			'liveTv.channelNumber' => ({required Object number}) => 'チャンネル ${number}',
			'liveTv.unknownChannel' => '不明なチャンネル',
			'liveTv.live' => 'ライブ',
			'liveTv.premiereBadge' => '新しい',
			'liveTv.reloadGuide' => '番組表を再読み込み',
			'liveTv.searchGuide' => '番組表を検索',
			'liveTv.searchHint' => 'チャンネル・番組を検索',
			'liveTv.searchNoResults' => ({required Object query}) => '「${query}」に一致するものがありません',
			'liveTv.channelsSection' => 'チャンネル',
			'liveTv.programsSection' => '番組',
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
			'liveTv.guideReloadFailed' => '番組表を再読み込みできませんでした',
			'liveTv.rulesProcessRequested' => '録画ルールの再評価をリクエストしました',
			'liveTv.rulesProcessFailed' => '録画ルールを再適用できませんでした',
			'liveTv.recordShow' => '番組を録画',
			'liveTv.recordSettings.startEarly' => '早めに開始（秒）',
			'liveTv.recordSettings.endLate' => '遅めに終了（秒）',
			'liveTv.recordSettings.newOnly' => '新しいエピソードのみ',
			'liveTv.recordSettings.anyChannel' => 'すべてのチャンネルで録画',
			'liveTv.recordSettings.anyTime' => 'すべての時間帯で録画',
			'liveTv.recordSettings.skipInLibrary' => 'ライブラリにあるエピソードをスキップ',
			'liveTv.recordSettings.keepUpTo' => '保持するエピソード数',
			'liveTv.recordSettings.keepUpToHint' => '0 ですべてのエピソードを保持',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes}分後に開始',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product}から無効なライブTV再生データが返されました',
			'liveTv.failedToStartChannel' => 'ライブチャンネルを開始できませんでした',
			'liveTv.failedToBuildStreamUrl' => 'ストリームURLを生成できませんでした',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'チャンネルを再生できませんでした: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'チャンネルを切り替えられませんでした: ${reason}',
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
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}件', ), 
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} トラック', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}曲', ), 
			'music.nowPlaying' => '再生中',
			'music.playingFrom' => ({required Object title}) => '${title}から再生',
			'music.queue' => '再生キュー',
			'music.clearQueue' => 'キューをクリア',
			'music.lyrics' => '歌詞',
			'music.visualizer' => 'ビジュアル',
			'music.visualizerProfileLoading' => 'トラック分析の読み方...',
			'music.visualizerAmbientMotion' => '環境運動',
			'music.visualizerPlexLoudness' => 'Plex 音量',
			'music.visualizerPreviousPreset' => '前の視覚スタイル',
			'music.visualizerNextPreset' => '次 次 視覚スタイル',
			'music.visualizerPresetAurora' => 'オーラ',
			'music.visualizerPresetBloom' => 'ブルーム',
			'music.visualizerPresetOrbitals' => 'オービタル',
			'music.visualizerPresetPrism' => 'プライズ',
			'music.visualizerPresetTunnel' => 'トンネル',
			'music.visualizerPresetTrackMap' => 'トラックマップ',
			'music.noLyrics' => '歌詞がありません',
			'music.sleepTimer' => 'スリープタイマー',
			'music.sleepTimerEndOfTrack' => '曲の終わり',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 分', ), 
			'music.stopPlayback' => '再生を停止',
			'music.previousTrack' => '前の曲',
			'music.nextTrack' => '次の曲',
			'music.repeat' => 'リピート',
			'music.repeatAll' => '全曲リピート',
			'music.repeatOne' => '1曲リピート',
			'music.instantMixNoServer' => 'インスタントミックスに利用できるサーバーがありません',
			'music.instantMixFailed' => 'インスタントミックスを読み込めませんでした',
			'music.instantMixEmpty' => 'インスタントミックスにトラックがありませんでした',
			'music.noAudioUrl' => ({required Object track}) => '${track}で利用可能な音声URLがありません',
			'music.discography.singlesAndEps' => 'シングル・EP',
			'music.discography.live' => 'ライブ',
			'music.discography.compilations' => 'コンピレーション',
			'watchTogether.title' => '一緒に見る',
			'watchTogether.description' => '友達や家族と同期してコンテンツを視聴',
			'watchTogether.createRoom' => 'ルームを作成',
			'watchTogether.creatingRoom' => 'ルームを作成中…',
			'watchTogether.joinRoom' => 'ルームに参加',
			'watchTogether.joiningRoom' => 'ルームに参加中…',
			'watchTogether.connecting' => '接続中…',
			'watchTogether.relayPublic' => 'ルームは公開のOpen Watch Partyリレーサーバーを使用します。',
			'watchTogether.relayCustom' => ({required Object url}) => 'ルームは${url}のリレーサーバーを使用します。',
			'watchTogether.recentRooms' => '最近のルーム',
			'watchTogether.roomActions' => 'ルームの操作',
			'watchTogether.renameRoom' => 'ルーム名を変更',
			'watchTogether.removeRoom' => '削除',
			'watchTogether.enterRoomCode' => 'ホストから共有された6文字のコードを入力してください。',
			'watchTogether.roomCode' => 'ルームコード',
			'watchTogether.paste' => '貼り付け',
			'watchTogether.noCodeInClipboard' => 'クリップボードにルームコードがありません',
			'watchTogether.copyCode' => 'コードをコピー',
			'watchTogether.codeCopied' => 'ルームコードをコピーしました',
			'watchTogether.shareInvite' => '招待を共有',
			'watchTogether.inviteCopied' => '招待をコピーしました。メッセージに貼り付けてください。',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Plezyの「一緒に見る」ルームに参加しませんか？「一緒に見る」を開いて「ルームに参加」を選び、${code}を入力してください。',
			'watchTogether.openSessionControls' => '「一緒に見る」セッションのコントロールを開く',
			'watchTogether.reconnecting' => '再接続中…',
			'watchTogether.reconnectingDescription' => '接続が切断されました。自動的にルームに再参加します。',
			'watchTogether.connected' => '接続済み',
			'watchTogether.disconnected' => '切断されました',
			'watchTogether.youAreHost' => 'あなたはホストです',
			'watchTogether.hostedBy' => ({required Object name}) => 'ホスト: ${name}',
			'watchTogether.hostControlsPlayback' => 'ホストが再生を制御',
			'watchTogether.anyoneCanControl' => '全員が再生を制御可能',
			'watchTogether.roomLocked' => 'ルームはロック中',
			'watchTogether.nowPlaying' => '再生中',
			'watchTogether.nothingPlaying' => '再生中のコンテンツはありません',
			'watchTogether.nothingPlayingHost' => 'いずれかのライブラリから再生すると、ルームで共有されます。',
			'watchTogether.nothingPlayingGuest' => 'ホストが再生を始めると、ここに表示されます。',
			'watchTogether.notShareable' => 'この動画はカタログ情報と一致しないため、同じサーバーにアクセスできる人しか再生できません。',
			'watchTogether.searching' => 'ライブラリでこの動画を探しています…',
			'watchTogether.yourCopy' => 'あなたのコピー',
			'watchTogether.sharingYourCopy' => 'あなたのコピーを共有しています',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'あなたのコピーを再生中（${difference}）',
			'watchTogether.mismatchTitle' => 'コピーの長さが異なります',
			'watchTogether.mismatchDescription' => ({required Object difference}) => '最も近いコピーはルームの動画より${difference}です。別の編集版やバージョンの可能性があります。',
			'watchTogether.playAnyway' => 'このまま再生',
			'watchTogether.chooseAnotherCopy' => '別のコピーを選択',
			'watchTogether.dontPlay' => '再生しない',
			'watchTogether.unavailableTitle' => 'この動画がありません',
			'watchTogether.unavailableDescription' => 'Plezyはライブラリでこの動画を見つけられませんでした。自分でコピーを選ぶか、もう一度検索してください。',
			'watchTogether.chooseCopy' => 'コピーを選択',
			'watchTogether.searchAgain' => '再検索',
			'watchTogether.noCandidates' => 'ライブラリにコピーが見つかりません。',
			'watchTogether.choiceFailed' => 'このコピーをルームで再生できませんでした',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration}長い',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration}短い',
			'watchTogether.lengthSame' => '同じ長さ',
			'watchTogether.lengthUnknown' => '長さ不明',
			'watchTogether.joinCurrentPlayback' => '現在の再生に参加',
			'watchTogether.joinCurrentPlaybackDescription' => 'ホストが現在視聴中のコンテンツに戻る',
			'watchTogether.stopMedia' => '全員の動画を停止',
			'watchTogether.syncOffset' => '同期オフセット',
			'watchTogether.syncOffsetDescription' => '動画がルームより進んでいる、または遅れている場合にずらします。',
			'watchTogether.offsetHint' => ({required Object difference}) => 'あなたのコピーはルームの動画より${difference}です。',
			'watchTogether.applyDifference' => ({required Object offset}) => '${offset}を適用',
			'watchTogether.offsetMinusSecond' => '-1秒',
			'watchTogether.offsetMinusTenth' => '-100ms',
			'watchTogether.offsetPlusTenth' => '+100ms',
			'watchTogether.offsetPlusSecond' => '+1秒',
			'watchTogether.participants' => '参加者',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 参加者', other: '参加者${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}人', ), 
			'watchTogether.hostBadge' => 'ホスト',
			'watchTogether.nameYou' => ({required Object name}) => '${name}（あなた）',
			'watchTogether.playerIdle' => '待機中',
			'watchTogether.playerLoading' => '読み込み中',
			'watchTogether.playerReady' => '準備完了',
			'watchTogether.playerBuffering' => 'バッファリング中',
			'watchTogether.matchSearching' => '検索中',
			'watchTogether.matchMatched' => '動画あり',
			'watchTogether.matchMismatched' => '長さが異なる',
			'watchTogether.matchUnavailable' => '動画なし',
			'watchTogether.participantOffset' => ({required Object offset}) => 'オフセット ${offset}',
			'watchTogether.makeHost' => 'ホストにする',
			'watchTogether.makeHostQuestion' => 'ホストを移譲しますか？',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name}が再生を制御し、全員のセッションを主導します。',
			'watchTogether.transfer' => '移譲',
			'watchTogether.removeParticipant' => 'ルームから削除',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name}を削除しますか？',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name}をルームから退出させます。ルームをロックしない限り、コードを使って再度参加できます。',
			'watchTogether.remove' => '削除',
			'watchTogether.roomSettings' => 'ルーム設定',
			'watchTogether.letEveryoneControl' => '全員に再生の操作を許可',
			'watchTogether.lockRoom' => 'ルームをロック',
			'watchTogether.lockRoomDescription' => '新しい参加者は参加できなくなります',
			'watchTogether.leaveRoom' => 'ルームを退出',
			'watchTogether.leaveRoomQuestion' => 'ルームを退出しますか？',
			'watchTogether.leaveRoomConfirm' => 'ルームコードを使って再度参加できます。',
			'watchTogether.leave' => '退出',
			'watchTogether.endRoom' => 'ルームを終了',
			'watchTogether.endRoomQuestion' => 'ルームを終了しますか？',
			'watchTogether.endRoomConfirm' => '参加者全員のルームが終了します。',
			'watchTogether.end' => '終了',
			'watchTogether.playBlockedTitle' => '再生が開始されませんでした',
			'watchTogether.playBlockedDescription' => '再生を押して、ルームのみんなと一緒に視聴を始めてください。',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name}が再生しました',
			'watchTogether.notices.playbackStarted' => '再生が開始されました',
			'watchTogether.notices.paused' => ({required Object name}) => '${name}が一時停止しました',
			'watchTogether.notices.playbackPaused' => '再生が一時停止されました',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name}が${position}にジャンプしました',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '${position}にジャンプしました',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name}が速度を${speed}に設定しました',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => '速度が${speed}に設定されました',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name}が${title}を再生しました',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => '${title}を再生中',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name}が動画を停止しました',
			'watchTogether.notices.mediaStopped' => '動画が停止しました',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '${name}を待っています…',
			'watchTogether.notices.waitingForSomeone' => '他の参加者が追いつくのを待っています…',
			'watchTogether.notices.finished' => '再生終了',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name}がホストになりました',
			'watchTogether.notices.youAreNowHost' => 'あなたがホストになりました',
			'watchTogether.notices.joined' => ({required Object name}) => '${name}が参加しました',
			'watchTogether.notices.left' => ({required Object name}) => '${name}が退出しました',
			'watchTogether.notices.controlRefused' => '再生を操作できるのはホストのみです',
			'watchTogether.notices.searchFailed' => '一部のサーバーでルームの動画を検索できませんでした',
			'watchTogether.notices.playBlocked' => '再生を押して開始してください',
			'watchTogether.notices.shareFailed' => 'この動画をルームと共有できませんでした',
			'watchTogether.notices.downloadNotShared' => 'サーバーがオフラインの間、ダウンロードはルームと共有されません',
			'watchTogether.notices.openFailed' => 'ルームの動画を開けませんでした',
			'watchTogether.ended.ended' => 'ホストがルームを終了しました',
			'watchTogether.ended.kicked' => 'ルームから削除されました',
			'watchTogether.ended.expired' => 'ルームの有効期限が切れました',
			'watchTogether.ended.replaced' => '別のデバイスでこのルームに参加しました',
			'watchTogether.ended.lost' => 'ルームとの接続が切れました',
			'watchTogether.errors.invalidCode' => 'ルームコードではありません。コードは0、1、I、L、Oを含まない6文字の英数字です。',
			'watchTogether.errors.roomNotFound' => 'そのコードのルームはありません。終了した可能性があります。',
			'watchTogether.errors.roomFull' => 'そのルームは満員です。',
			'watchTogether.errors.roomLocked' => 'ホストがそのルームをロックしています。',
			'watchTogether.errors.relayFull' => '「一緒に見る」は現在混み合っています。しばらくしてからもう一度お試しください。',
			'watchTogether.errors.unreachable' => '「一緒に見る」のリレーサーバーに接続できませんでした。接続を確認してください。',
			'watchTogether.errors.rateLimited' => '試行回数が多すぎます。しばらく待ってからもう一度お試しください。',
			'watchTogether.errors.clientBlocked' => 'このバージョンのPlezyではリレーサーバーを使用できません。アプリをアップデートしてください。',
			'watchTogether.errors.forbidden' => 'その操作はホストのみ可能です。',
			'watchTogether.errors.notInRoom' => 'ルームに参加していません。',
			'watchTogether.errors.alreadyInRoom' => 'すでにルームに参加しています。',
			'watchTogether.errors.resumeFailed' => 'ルームに再参加できませんでした。',
			'watchTogether.errors.unsupported' => 'リレーサーバーがこの操作に対応していません。',
			'watchTogether.errors.generic' => '問題が発生しました。もう一度お試しください。',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'エピソード${number}',
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
			'downloads.storageFull' => '空き容量を確保するため、ダウンロードを停止しました。空き容量を確保するか、別のダウンロード先を選んでから、もう一度お試しください。',
			'downloads.storageUnavailable' => '空き容量を確認できなかったため、ダウンロードを停止しました。ダウンロード先を確認してから、もう一度お試しください。',
			'downloads.episodesQueued' => ({required Object count}) => '${count}エピソードをダウンロードキューに追加しました',
			'downloads.downloadDeleted' => 'ダウンロードを削除しました',
			'downloads.deleteConfirm' => ({required Object title}) => 'このデバイスから「${title}」を削除しますか？',
			'downloads.deleteCollectionDownloads' => 'ダウンロードを削除',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '「${title}」のすべてのダウンロードをこのデバイスから削除しますか？',
			'downloads.collectionDownloadsDeleted' => 'ダウンロードを削除しました',
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
			'downloads.retryAll' => 'すべて再試行',
			_ => null,
		} ?? switch (path) {
			'downloads.retryFailed' => '失敗したダウンロードを再試行',
			'downloads.deleteAll' => 'すべて削除',
			'downloads.selectVersion' => 'バージョンを選択',
			'downloads.allEpisodes' => 'すべてのエピソード',
			'downloads.unwatchedOnly' => '未視聴のみ',
			'downloads.nextNUnwatched' => ({required Object count}) => '次の${count}件の未視聴',
			'downloads.customAmount' => '数を指定…',
			'downloads.customAmountAny' => '定量(毎回)',
			'downloads.randomEpisodes' => 'ランダムエピソード',
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
			'downloads.syncNow' => 'シンク今',
			'downloads.downloadsUpToDate' => 'ダウンロードは現在まで',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => '合成完了 · ${queued} queued, ${removed} 削除',
			'downloads.activeSyncRules' => '同期ルール',
			'downloads.reviewOrphanFiles' => '記録のないダウンロードを確認',
			'downloads.orphanReviewTitle' => '記録のないダウンロードを確認',
			'downloads.orphanReviewDescription' => 'これらのタグ付きファイルは、PlezyNG が管理する既定のダウンロードフォルダー内にありますが、対応するダウンロード記録や実行中のタスクがありません。削除する前に一覧を確認してください。',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} 個のファイル · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count} 個のファイルを削除',
			'downloads.orphanCleanupNone' => '記録のないダウンロードファイルは見つかりませんでした',
			'downloads.orphanCleanupFailed' => 'PlezyNG は管理対象のダウンロードフォルダーを安全にスキャンできませんでした。ファイルは削除されていません。',
			'downloads.orphanCleanupChanged' => '確認中にダウンロード一覧が変更されました。整理する前にファイルをもう一度確認してください。',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count} 個の孤立ファイルを削除 · ${size} の空き容量を確保',
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
			'downloads.syncRuleAccessDenied' => 'アクセスが拒否されました',
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
			'downloads.options' => 'ダウンロードのオプション',
			'downloads.groupings.library' => 'ライブラリ',
			'downloads.groupings.collections' => 'コレクション',
			'downloads.unknownLibrary' => '不明なライブラリ',
			'downloads.unknownShow' => '不明な番組',
			'downloads.unknownSeason' => '不明なシーズン',
			'downloads.unknownAlbum' => '不明なアルバム',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total}完了',
			'downloads.storageUsed' => ({required Object size}) => '使用済みのストレージ: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のダウンロード', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}件のダウンロード', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 表示', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 表示', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 映画', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 映画', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}枚のアルバム', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}枚のアルバム', ), 
			'downloads.errorFileNotFound' => 'ファイルが見つかりません（404）',
			'downloads.errorDownloadNotAllowed' => 'サーバーがダウンロードを許可していません（403）',
			'downloads.errorDownloadFailed' => 'ダウンロードに失敗しました',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'ダウンロードに失敗しました: ${reason}',
			'downloads.convertingOnServer' => 'サーバーに変換する...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'サーバーに変換 · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'ダウンロードに失敗しました（HTTP ${status}）',
			'downloads.errorPostProcessing' => ({required Object reason}) => '後処理に失敗しました: ${reason}',
			'downloads.reasonFileNotSaved' => 'このデバイスにファイルを保存できませんでした',
			'downloads.reasonCannotResume' => '途中までのダウンロードを再開できませんでした',
			'downloads.reasonDeviceStorageFull' => 'このデバイスのストレージが不足しています',
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
			'companionRemote.session.manualAddressHint' => '手動接続アドレス:',
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
			'companionRemote.pairing.codeTitle' => 'パイアリングコード',
			'companionRemote.pairing.codeDescription' => 'ホストデバイスで Companion Remote で表示されたコードを入力します. 両方のデバイスは、安全なカップリングをサポートするバージョンを使用する必要があります。',
			'companionRemote.pairing.codeInvalid' => 'ホストコードからすべての32文字と番号を入力します。',
			'companionRemote.pairing.updateRequired' => '両方のデバイスを安全なパリングをサポートするバージョンにアップグレードします。',
			'companionRemote.pairing.hostDescription' => 'このコードを各リモートで一度入力します. プライベートに保管してください: このプロフィールのコントロールを提供します。',
			'companionRemote.pairing.resetCode' => 'パイリングコードの再設定',
			'companionRemote.pairing.resetDescription' => 'すべてのリモートを切り離し、新しいコードを作成します。',
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
			'videoSettings.audioEqualizer' => '音声平等化',
			'videoSettings.audioEqualizerDescription' => 'このデバイスに5つの周波数帯を調整します. mpv で利用可能; アクティブな EQ はオーディオを解読し、パスチャードを無効にします。',
			'videoSettings.audioEqualizerFlat' => 'フラット',
			'videoSettings.audioEqualizerActive' => 'カスタム',
			'videoSettings.audioEqualizerSaveFailed' => 'オーディオエキサイティングの設定を保存することはできません。',
			'videoSettings.backgroundVideoAudio' => '背景動画オーディオ',
			'videoSettings.backgroundVideoAudioDescription' => 'プレイヤーを離れたときにビデオオーディオを再生し続ける; 返信するまで画像が隠されている. Android はメディア再生通知を使用します。',
			'videoSettings.audioNormalization' => 'ラウドネス正規化',
			'videoSettings.audioNormalizationDisablesPassthrough' => '音声をPCMにデコードします。オンの間はパススルーがオフになります',
			'performanceOverlay.color' => '色',
			'performanceOverlay.performance' => 'パフォーマンス',
			'performanceOverlay.buffer' => 'バッファ',
			'performanceOverlay.app' => 'アプリ',
			'performanceOverlay.decoder' => 'デコーダー',
			'performanceOverlay.rawDecoder' => 'Raw デコーダー',
			'performanceOverlay.tunneling' => 'トンネリング',
			'performanceOverlay.passthrough' => 'パススルー',
			'performanceOverlay.aspect' => 'アスペクト',
			'performanceOverlay.rotation' => '回転',
			'performanceOverlay.dvSource' => 'DV ソース',
			'performanceOverlay.dvPath' => 'DV パス',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision デコーダー',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision デコーダー（P7→8.1）',
			'performanceOverlay.dvRouteBaseLayer' => 'ベースレイヤー',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 ベースレイヤー',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG ベースレイヤー',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR ベースレイヤー',
			'performanceOverlay.dvRouteReshaped' => 'RPU リシェイプ（gpu-next）',
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
			'performanceOverlay.playMethod' => 'ゲーム方法',
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
			'metadataEdit.quickTag' => 'クイックタグ…',
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
			'seerr.noSignInMethods' => 'この Seerr インスタンスには PlezyNG が対応しているサインイン方法がありません。',
			'seerr.instance' => 'インスタンス',
			'seerr.disconnectConfirm' => 'Seerr の接続を解除しますか？',
			'seerr.disconnectConfirmBody' => 'PlezyNG はこの Seerr インスタンスの情報を削除します。いつでも再接続できます。',
			'seerr.request' => 'リクエスト',
			'seerr.request4k' => '4K でリクエスト',
			'seerr.seasons' => 'シーズン',
			'seerr.allSeasons' => '全シーズン',
			'seerr.advancedOptions' => '詳細',
			'seerr.destinationServer' => '宛先サーバー',
			'seerr.qualityProfile' => '画質プロファイル',
			'seerr.rootFolder' => 'ルートフォルダ',
			'seerr.languageProfile' => '言語プロファイル',
			'seerr.tags' => 'タグ',
			'seerr.noTags' => 'タグなし',
			'seerr.defaultOption' => ({required Object name}) => '${name}（デフォルト）',
			'seerr.animeNote' => 'このシリーズはアニメです。',
			'seerr.requestSubmitted' => 'リクエストを送信しました',
			'seerr.requestFailed' => ({required Object error}) => 'リクエストに失敗しました: ${error}',
			'seerr.requestsLoadFailed' => 'リクエストオプションを読み込めませんでした',
			'seerr.nothingToRequest' => 'すべてすでに利用可能またはリクエスト済みです。',
			'seerr.statusAvailable' => '利用可能',
			'seerr.statusPartiallyAvailable' => '一部利用可能',
			'seerr.statusRequested' => 'リクエスト済み',
			'seerr.statusProcessing' => '処理中',
			'seerr.statusBlocklisted' => 'ブロックリスト登録済み',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url}に接続できませんでした: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url}にSeerrインスタンスがありません（HTTP ${status}）',
			'seerr.behindAuthProxy' => 'Seerrではなく、認証が必要なリバースプロキシ（SSOまたはHTTP認証）が応答しました。Plezyはこれを通じてサインインできません。このアプリではSeerrの/api/v1パスをプロキシから除外するか、Seerrに直接到達するアドレスを使用してください。',
			'seerr.invalidUrl' => 'https://seerr.example.comのようなサーバーアドレスを入力してください',
			'seerr.quickConnectUnsupported' => 'このSeerrインスタンスはQuick Connectに対応していません。Seerr 3.4以降が必要です。',
			'seerr.notInitialized' => 'このSeerrインスタンスでは初回セットアップが完了していません',
			'seerr.noPlexTokenForReauth' => '再サインインに使用できるPlexトークンがありません',
			'seerr.noStoredCredentials' => '再サインインに使用できる保存済みの認証情報がありません',
			'seerr.signInRejected' => 'サインインが拒否されました',
			'seerr.noSessionCookie' => 'Seerrからセッションクッキーが発行されませんでした',
			'seerr.freshCookieRejected' => 'Seerrが新しいセッションクッキーを拒否しました',
			'seerr.noUserInformation' => 'Seerrからユーザー情報が返されませんでした',
			'seerr.sessionRejectedAfterReauth' => '再サインイン後にセッションが拒否されました',
			'seerr.permissionDenied' => 'Seerrがこの操作を拒否しました: アカウントに必要な権限がありません',
			'seerr.permissionRevoked' => 'これをリクエストする権限がなくなりました',
			'services.title' => 'サービス',
			'services.hubSubtitle' => '視聴の進捗を同期して、新しいタイトルをリクエストします。',
			'services.integrations' => 'インテグレーション',
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
			'services.simklReconnect.title' => 'Simklに再接続',
			'services.simklReconnect.subtitle' => 'Simklはこの接続で使用しているサインイン方法を廃止します。再接続するとsimkl.comが開き、Plezyを承認できます。Plezyがパスワードを知ることはありません。視聴履歴はSimklに残ります。',
			'services.deviceCode.title' => ({required Object service}) => '${service} で PlezyNG を有効化',
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
			_ => null,
		} ?? switch (path) {
			'addServer.borrowFromAnotherProfile' => '別のプロフィールの接続を利用',
			'addServer.borrowFromAnotherProfileSubtitle' => '別のプロフィールの接続を再利用します。PINで保護されたプロフィールにはPINが必要です。',
			'addServer.invalidCredentials' => 'ユーザー名またはパスワードが正しくありません',
			'addServer.authResponseNotJson' => '認証レスポンスが有効なJSONではありません',
			'addServer.authResponseIncomplete' => 'サーバーからのサインイン応答が不完全です',
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
			'addServer.directPlexServerUrl' => 'Plex サーバーの URL',
			'addServer.directPlexServerUrlHelper' => 'メディアサーバーの地元のIPとポートを入力する Plex メディアンサーバー。',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex トークン(オプション)',
			'addServer.plexTokenHelper' => 'Auth なしのアクセスがこのサーバーで許可されている場合に、空白を残します。',
			'addServer.plexTokenRequired' => '確認が必要です. Plex トークン(X-Plex-トークン)を入力してください。',
			'addServer.connectDirectPlexCard' => 'Plex メディアサーバー(直接/地元)',
			'addServer.connectDirectPlexCardSubtitle' => 'plex.tv アカウントなしで地元の IP または URL を使用して直接接続します。',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => '地元のIPまたはURLを使用して直接接続します. ${name} に接続します。',
			'addServer.insecureTitle' => '未暗号化の接続',
			'addServer.insecureDescription' => ({required Object url}) => '${url} は HTTP を使用しています。ネットワーク上の第三者がパスワード、トークン、メディアを読み取ったり改ざんしたりする可能性があります。利用できる場合は HTTPS を使用してください。このネットワークを信頼し、リスクを受け入れる場合のみ続行してください。',
			'addServer.allowHttp' => 'HTTPを許可',
			'addServer.httpsRequired' => 'HTTPS を使用するか、暗号化されていない接続を明示的に許可するか。',
			'watchLink.serverUnavailable' => 'このリンクのために Plex サーバーにアクセスできませんでした。',
			'watchLink.notFound' => 'この番組または映画が Plex サーバーで見つかりませんでした。',
			'watchLink.ambiguous' => 'このリンクは、複数のサーバーの項目と一致します. リンクにサーバーを追加します。',
			'watchLink.plexOnly' => '視聴リンクは現在、サーバーのみをサポートしています Plex',
			'watchLink.unsupportedItem' => '視聴リンクは、ショーや映画だけを開くことができます。',
			'watchLink.menuItem' => '見るリンク',
			'watchLink.dialogTitle' => 'リンクを見る',
			'watchLink.dialogShowHint' => 'このリンクを開くと次のエピソードが再生されます. ショーをシュフルでプレイするために、最後に &mode=shuffle を追加します。',
			'watchLink.dialogMovieHint' => 'このリンクを開くと映画が演奏されます。',
			'watchLink.copy' => 'コピー',
			'watchLink.copied' => 'リンクコピー',
			'homeLayout.title' => 'HOME レイアウト',
			'homeLayout.resetToast' => 'ホーム オリジナル Plezy ヒーロー レイアウトにリセット',
			'homeLayout.resetHeroTitle' => 'ヒーローのレイアウトをストックにリセットする Plezy?',
			'homeLayout.resetHeroBody' => '各行のヒーロー設定を切り離し、ホームの頂点に単一の回転バナーを持ち帰る、ヒーローの行が存在する前にと同じように。',
			'homeLayout.removeRowTitle' => 'ホーム ラウンドを削除する?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} は削除されます. これは無効にならない。',
			'homeLayout.sync' => 'シンク',
			'homeLayout.syncAccountTitle' => 'あなたのアカウント Plex と同期する',
			'homeLayout.syncAccountOn' => 'オン:このデバイスは、順序、順序の順序、ヒーロー、および自動スライドを他のデバイスと共有します。',
			'homeLayout.syncAccountOff' => 'オフ:このデバイスは独自のレイアウトを維持します。',
			'homeLayout.syncNow' => 'シンク今',
			'homeLayout.plexHomeManager' => 'Plex ホームマネージャー',
			'homeLayout.managePlexRows' => 'Plex 行を管理する Plezy',
			'homeLayout.managePlexRowsDescription' => 'ホーム 選択のラインを整理するためにオープン',
			'homeLayout.organizeHomeRows' => 'ホーム ラウンドの整理',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} ライン: 移動、 ヒーロー、 自動スライド、 削除',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '組織 ${library} ライン',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => '続きを見る + ${n} 行: 移動, 図書館, ホーム, ヒーロー, 自動スライド',
			'homeLayout.renderAsHero' => 'ヒーローカードとしての出張',
			'homeLayout.heroOnlySingleCollection' => 'この行が単一のコレクションの実際のタイトルに解決する場合にのみ利用可能',
			'homeLayout.hero' => 'ヒーロー',
			'homeLayout.autoSlide' => '自動スライド',
			'homeLayout.autoSlideDescription' => 'ラウンド(PC)とdパッド(TV)は常に動作し、タイマーを再起動します。',
			'homeLayout.autoSlideEditDescription' => 'スライドは数秒ごとに自体でスライドします。 オフ: 矢をクリックする場合(PC)または遠隔(TV)の左/右を押す場合のみ動きます。',
			'homeLayout.enableHeroFirst' => '英雄を最初に',
			'homeLayout.showOnHome' => 'ホームスクリーンで表示',
			'homeLayout.home' => 'ホーム',
			'homeLayout.removeFromHome' => '家から取り除く',
			'homeLayout.selectRowsFirst' => 'まずは下のホームラインを選択します。',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex 管理行',
			'homeLayout.continueWatching' => '視聴を続ける',
			'homeLayout.continueWatchingLibraryDescription' => 'この図書館のリサイクル・進歩の順番',
			'homeLayout.continueWatchingHomeDescription' => 'ホーム で表示される再生進歩の順番',
			'homeLayout.nextUpHomeDescription' => '次の未見のエピソードの順番がホームで別々に表示されます。',
			'homeLayout.library' => 'ライブラリ',
			'homeLayout.showInRecommended' => '図書館で紹介される',
			'homeLayout.customPlexRow' => '定制 Plex ライン',
			'homeLayout.heroNeedsLibrary' => '図書館をチェックするには、まずヒーローがどこかで表示する必要があります。',
			'homeLayout.heroNeedsSurface' => '図書館またはホームをチェックするには、まず、ヒーローがどこかで表示する必要があります。',
			'homeLayout.removeHub' => 'ハブを削除',
			'homeLayout.noPlexRows' => '番号 Plex 管理行がこの図書館に戻りました。',
			'homeLayout.openDetails' => 'オープン 詳細',
			'homeLayout.heroCards' => 'ヒーローカード',
			'homeLayout.tapHeroCard' => 'ヒーローカードを打ち出す',
			'homeLayout.tvPlayFocus' => 'テレビ: リモート: ハイライト Play ボタン',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down は、次の行に移動する前に Play ボタンで停止します。',
			'homeLayout.tvWrap' => 'テレビ:ロップヒーローカード',
			'homeLayout.tvWrapDescription' => '最後のカードに直ぐに、最初のカードに戻ります。最後のカードの停止を除いて、最初の紙の左側は常にサイドバーに戻ります.',
			'homeLayout.castOnHero' => 'ヒーローバンダーのキャスト',
			'homeLayout.castOnHeroDescription' => 'ヒーローバナーの底に沿ってキャストを表示します タイトルと概要だけを残します。',
			'homeLayout.customRows' => '定義ラウンド',
			'homeLayout.loading' => 'ホーム レイアウト レイアー...',
			'homeLayout.noCustomRows' => 'まだカスタムライトなし',
			'homeLayout.addRowHint' => 'ホーム を追加して 1 つを作成します。',
			'homeLayout.addHomeRow' => 'HOME ローブを追加',
			'homeLayout.addHomeRowDescription' => 'カテゴリを選択し、新しい順位が自動的に組織に追加されます。',
			'homeLayout.removeRow' => 'ラウを取り除く',
			'homeLayout.recentlyAdded' => '最近追加されたコンテンツ',
			'homeLayout.recentlyReleased' => '最近リリース',
			'homeLayout.movieCollections' => '映画コレクション',
			'homeLayout.showCollections' => 'コレクション展示',
			'homeLayout.rowTitle' => 'ロータイトル',
			'homeLayout.content' => 'コンテンツ',
			'homeLayout.showThisRowIn' => 'この順番を表示する:',
			'homeLayout.libraryRecommended' => '図書館推奨',
			'homeLayout.heroCard' => 'ヒーローカード',
			'homeLayout.heroCardDescription' => 'ポスターシェルフの代わりに、単一の全幅のローテーションカードとして表示されます。',
			'homeLayout.heroUnavailableDescription' => 'この順番が単一のコレクションの実際のタイトルに解決する場合にのみ利用可能で、1 つ以上のコレクターが選択されると、単一のタイトルの回転はできません。',
			'homeLayout.librariesSelection' => '図書館(すべての図書館を含むためにチェックされていないすべてを残す)',
			'homeLayout.librariesMergedDescription' => 'ここでチェックされているすべての図書館は、この一行に合併しています。',
			'homeLayout.movieCollectionsSelection' => '映画コレクション(各選択された図書館にチェックされていないすべてを残す)',
			'homeLayout.showCollectionsSelection' => 'コレクションを表示する(各選択された図書館のすべての未チェックを残す)',
			'homeLayout.collectionRowsDescription' => 'もし1つのコレクションが合うなら、そのタイトルが順番に直接表示されます。もし1つ以上合うなら、1つのコレクトリが単一のポスターとして表示されます。',
			'homeLayout.allCollections' => 'すべてのコレクション',
			'homeLayout.noRowsHere' => 'まだ、ここに順番はない。',
			'homeLayout.hideWatchedRows' => '順番に隠された物件を',
			'homeLayout.hideWatchedRowsDescription' => '完全に監視されたタイトルはホームと図書館を離れ、推奨行を残します。',
			'homeLayout.untitledCollection' => '未名のコレクション',
			'homeLayout.moveRowHint' => 'Up/Down: 順番を移動する · Select: drop it here · Back: cancel',
			'homeLayout.organizeRowsHint' => '順位を選択する(または保持する) 順位を選択する:移動する · 左/右:順位オプション · 後退:完成',
			'homeLayout.layoutNavDescription' => '列、図書館、コレクションカテゴリを選択',
			'homeLayout.editHomeRow' => 'ホーム ラウ 編集',
			'homeLayout.resetHeroButton' => 'ヒーローのリセット レイアウト ストック Plezy',
			'homeLayout.reorderingUnlocked' => '再編 開封',
			'homeLayout.reorderingLocked' => '再編閉鎖',
			'homeLayout.rowsCanBeDragged' => '線は引き出すことができます - ロックをタップしてそれを防ぐために',
			'homeLayout.tapLockToDrag' => 'ロックを押してラインを引き出す',
			'homeLayout.customRowLabel' => ({required Object title}) => '定員: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => '非表示',
			'homeLayout.remove' => '削除',
			'homeLayout.libraryResumeRow' => 'この図書館のリセットライン',
			'homeLayout.pressAgainToDelete' => '再度削除するために押す',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'で',
			'homeLayout.resetHeroButtonDescription' => '各行のヒーロー設定を切り離し、ヒーローラインが存在する前にあったように、上に単一の回転バナーを返します。',
			'platform.localNetworkPermission' => 'PlezyNG は、地元のネットワーク上のメディアサーバーおよび再生デバイスに接続します。',
			'platform.locationPermission' => 'PlezyNGは、ローカルネットワークを検出してメディアサーバーに接続するためにiOSが必要とする場合、位置情報へのアクセスを使用します。',
			'platform.photoLibraryPermission' => '写真ライブラリから、メディアのアートワークに使う画像を選択します。',
			'platform.cameraPermission' => 'QRコードをスキャンしてCompanion Remoteをペアリングします。',
			'fileSources.title' => 'ファイルと本',
			'fileSources.subtitle' => '読んで、聴いて、自分のファイルから見て',
			'fileSources.add' => '源を追加',
			'fileSources.importFiles' => 'ファイル輸入',
			'fileSources.localFiles' => 'この装置で',
			'fileSources.source' => '源泉',
			'fileSources.name' => '名称',
			'fileSources.endpoint' => 'サーバー URL',
			'fileSources.root' => 'フォルダーまたはプレフィックス',
			'fileSources.username' => 'ユーザー名',
			'fileSources.password' => 'パスワード',
			'fileSources.token' => 'API トークン',
			'fileSources.accessKey' => 'アクセスキーID',
			'fileSources.secretKey' => '秘密アクセスキー',
			'fileSources.sessionToken' => 'セッション・トークン(オプション)',
			'fileSources.region' => '地域',
			'fileSources.clientId' => 'クライアントID',
			'fileSources.clientSecret' => 'OAuth クライアント セキュリティ (Google デスクトップのみ)',
			'fileSources.allowHttp' => '信頼できるネットワークで暗号化されていないHTTP接続を許可する',
			'fileSources.connect' => '接続',
			'fileSources.cancel' => 'キャンセル',
			'fileSources.save' => '保存',
			'fileSources.close' => '閉じる',
			'fileSources.removeSource' => 'ソース 解約',
			'fileSources.disconnectMessage' => 'このソースの接続を解除しますか？ダウンロード済みのファイルと読書・再生履歴は、このデバイスに残ります。',
			'fileSources.localFolder' => 'フォルダーを選択',
			'fileSources.empty' => 'まだ何もありません',
			'fileSources.emptyHint' => 'ソースを追加したり、本、オーディオブック、音楽、またはビデオをインポートしたりします。',
			'fileSources.search' => 'このフォルダーを検索',
			'fileSources.searchCached' => '図書館を保存',
			'fileSources.refresh' => '更新',
			'fileSources.loadMore' => 'もっと充電',
			'fileSources.offline' => 'オフライン利用',
			'fileSources.download' => 'オフライン',
			'fileSources.removeDownload' => 'オフラインコピーの削除',
			'fileSources.continueReading' => '続きを読む',
			'fileSources.continueListening' => '続き聴き方',
			'fileSources.continueWatching' => '続きを見る',
			'fileSources.read' => '読む',
			'fileSources.listen' => '聴く',
			'fileSources.play' => '再生',
			'fileSources.pause' => '一時停止',
			'fileSources.stop' => '停止',
			'fileSources.startOver' => 'スタート トップ',
			'fileSources.finished' => '再生終了',
			'fileSources.markFinished' => 'マーク終了',
			'fileSources.markUnfinished' => 'マーク 未完成',
			'fileSources.editions' => '出版物とファイル',
			'fileSources.chapters' => 'チャプター',
			'fileSources.bookmarks' => 'ブックマークとノート',
			'fileSources.bookmark' => 'ブックマークを追加',
			'fileSources.highlight' => 'ハイライト',
			'fileSources.note' => '注記',
			'fileSources.delete' => '削除',
			'fileSources.export' => '輸出ノート',
			'fileSources.exported' => '輸出のノート',
			'fileSources.sync' => 'シンク進歩',
			'fileSources.synced' => '進歩合成',
			'fileSources.conflict' => '別のデバイスは別の位置を持っています. どこで進むかを選択します。',
			'fileSources.useLocal' => 'この装置を使用する',
			'fileSources.useRemote' => '他のデバイスを使う',
			'fileSources.history' => '位置歴史',
			'fileSources.groupAudio' => 'ひとつのオーディオブックとして聴く',
			'fileSources.groupHint' => 'このフォルダーで現在読み込まれている音声ファイルをまとめます。先にすべてのページを読み込んでください。',
			'fileSources.order' => 'ファイル 注文',
			'fileSources.moveUp' => '移動アップ',
			'fileSources.moveDown' => 'ダウン移動',
			'fileSources.speed' => 'プレイバックスピード',
			'fileSources.sleep' => 'スリープタイマー',
			'fileSources.sleepOff' => 'オフ',
			'fileSources.endChapter' => '章の終わり',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} 分', ), 
			'fileSources.skipBack' => 'スキーバック',
			'fileSources.skipForward' => 'スキー前進',
			'fileSources.smartRewind' => '休憩後のスマートな回復',
			'fileSources.playbackOptions' => '聴くオプション',
			'fileSources.remaining' => ({required Object time}) => '${time} 残り',
			'fileSources.contents' => 'コンテンツ',
			'fileSources.readerSettings' => '読み設定',
			'fileSources.fontSize' => 'テキストサイズ',
			'fileSources.lineHeight' => 'スペースライン',
			'fileSources.margin' => 'マルギン',
			'fileSources.font' => 'タイプフェイス',
			'fileSources.serif' => 'セリフ体',
			'fileSources.sans' => 'サンセリフ体',
			'fileSources.mono' => 'モノスペース',
			'fileSources.columns' => 'コラム',
			'fileSources.scroll' => '垂直にスクロール',
			'fileSources.justify' => '両端揃え',
			'fileSources.readerTheme' => 'ページの出演',
			'fileSources.appTheme' => 'アプリテーマのフォロー',
			'fileSources.paper' => 'ペーパー',
			'fileSources.sepia' => 'セピア',
			'fileSources.night' => '夜の',
			'fileSources.readAloud' => 'このページを読み上げる',
			'fileSources.readAlong' => '音声に合わせて読む',
			'fileSources.stopReading' => '読み上げを停止',
			'fileSources.searchBook' => '検索・本',
			'fileSources.noMatches' => '試合なし',
			'fileSources.previousPage' => '前ページ',
			'fileSources.nextPage' => '次のページ',
			'fileSources.page' => ({required Object number}) => 'ページ ${number}',
			'fileSources.externalBlocked' => 'リーダーでは、本の外部リンクは無効になっています。',
			'fileSources.loading' => '開...',
			'fileSources.narrator' => '講演者',
			'fileSources.audio' => '音声',
			'fileSources.video' => 'ビデオ',
			'fileSources.ebooks' => 'エボブ',
			'fileSources.all' => 'すべて',
			'fileSources.downloads' => 'オフラインファイル',
			'fileSources.confirmDelete' => '選択したオフラインコピーを削除しますか？読書・再生位置とメモは保持されます。',
			'fileSources.errorAuthentication' => '再びこのソースを再接続するためにサインインします。',
			'fileSources.errorPermission' => 'この情報源は、要求されたファイルへのアクセスを許可しませんでした。',
			'fileSources.errorUnavailable' => 'ソースを利用できません。再試行するか、オフラインコピーを開いてください。',
			'fileSources.errorUnsupported' => 'この形式または接続は、このデバイスではサポートされていません。ソースの設定ガイドを確認してください。',
			'fileSources.errorInvalidData' => 'このファイルまたはサーバーの回答は安全に読み取れない。',
			'fileSources.errorCancelled' => '作戦はキャンセルされました。',
			'fileSources.errorConflict' => '別のセッションで読書・再生位置が変更されました。位置を選ぶには、アイテムを開き直してください。',
			'fileSources.signIn' => 'サインイン',
			'fileSources.reconnect' => '再接続',
			'fileSources.folderHelp' => '空欄にするとソースのルートから開始します。S3のURLにはバケット名が含まれます。',
			'fileSources.preferences' => '優先順位',
			'fileSources.timePosition' => '位置',
			'fileSources.audioTrack' => '音声トラック',
			'fileSources.subtitleTrack' => 'トレック サブタイトル',
			'fileSources.none' => '無',
			'fileSources.fullscreen' => '全画面',
			'fileSources.syncLocation' => 'プロセス シンク フォルダー(オプション)',
			'fileSources.syncLocationHint' => 'PlezyNG 状態のための専用 WebDAV フォルダー 条件書きを使用します; メディアは変わらない。',
			'fileSources.audiobooks' => 'オーディオブック',
			'fileSources.comics' => '漫画',
			'fileSources.scan' => '書籍とメディアのスキャン',
			'fileSources.browserReader' => 'オープンリーダー',
			'fileSources.browserReaderHelp' => 'ブラウザーでリーダーを開いています。読書位置やメモを保存するため、PlezyNGを開いたままにしてください。',
			'fileSources.on' => 'で',
			'fileSources.advancedSetup' => 'アプリ登録',
			'fileSources.microsoftSignIn' => 'マイクロソフトとサインイン',
			'fileSources.zoomIn' => 'ゾーム in',
			'fileSources.zoomOut' => 'ゾーム出る',
			'fileSources.fitPage' => 'フィットページ',
			'fileSources.fitWidth' => '合計幅',
			'fileSources.actualSize' => '現状サイズ',
			'fileSources.goToPage' => 'ページへ行く',
			'fileSources.goToSection' => '章へ行く',
			'fileSources.pageRange' => ({required Object count}) => '1 から ${count} までの番号を入力します。',
			'fileSources.pageLayout' => 'ページレイアウト',
			'fileSources.automatic' => '自動',
			'fileSources.singlePage' => '単一ページ',
			'fileSources.twoPages' => '2ページ',
			'fileSources.readingDirection' => '読書方向',
			'fileSources.leftToRight' => '左から右',
			'fileSources.rightToLeft' => '右から左',
			'fileSources.letterSpacing' => 'スペース 手紙',
			'fileSources.wordSpacing' => 'スペース語',
			'fileSources.readerControlsHelp' => 'ピンチ操作または拡大・縮小ボタンでページを拡大できます。ドラッグして表示位置を移動します。Ctrl/⌘と+または−で拡大率を調整し、Ctrl/⌘と0でリセットします。Page UpとPage Downでページをめくります。',
			'fileSources.imagePage' => '漫画ページ',
			'fileSources.resetReader' => '読み取りの好みを再設定',
			'fileSources.zoom' => 'ズーム',
			'fileSources.useFiles' => 'ファイルや本を使用する',
			'fileSources.cancelScan' => 'スキャンキャン',
			'fileSources.googleDrive' => 'Google Drive',
			'lending.title' => '公共図書館',
			'lending.add' => '図書館を追加',
			'lending.other' => 'もう一つの図書館',
			'lending.libraryName' => '図書館名',
			'lending.libraryUrl' => '図書館サイト',
			'lending.libraryUrlHint' => '図書館のカタログまたはサインインページを使用します。',
			'lending.intro' => '図書館から借りて、本をいつも身近に。',
			'lending.handoff' => '図書館のサービスでサインインし、本を借りて安全に読めます。',
			'lending.openService' => 'オープン図書館',
			'lending.findLibrary' => '図書館を見つける',
			'lending.search' => '書籍と著者を検索',
			'lending.catalogue' => 'カタログ',
			'lending.loans' => '貸し出し',
			'lending.holds' => '予約',
			'lending.signIn' => '図書館で登録する',
			'lending.waiting' => 'ブラウザでサインインを終了し、ここに戻ります。',
			'lending.cancel' => 'キャンセル',
			'lending.disconnect' => '図書館削除',
			'lending.disconnectMessage' => 'このプロフィールからこの図書館を削除しますか？貸出中の本と予約は図書館に残ります。',
			'lending.getBook' => '書籍を取得',
			'lending.checkAvailability' => '利用可能性チェック',
			'lending.available' => '貸し出し利用可能',
			'lending.unavailable' => '現在利用できない',
			'lending.borrow' => '借りる',
			'lending.placeHold' => '予約する',
			'lending.returnBook' => '期限前に返却',
			'lending.cancelHold' => '予約を取り消す',
			'lending.confirmBorrow' => '図書館からこのタイトルを借りる?',
			'lending.confirmReturn' => 'この本を今すぐ返却しますか？続きを利用するには、もう一度借りる必要がある場合があります。',
			'lending.confirmCancelHold' => 'この本の予約を取り消しますか？',
			'lending.email' => 'メール 通知',
			'lending.due' => ({required Object date}) => '返却期限：${date}',
			'lending.queue' => ({required Object position}) => 'ポジション ${position} ライン',
			'lending.empty' => 'まだタイトルは無い。',
			'lending.openLibraryNote' => 'Open Library のカタログを検索する. 読書および貸し出しのオプションは、各タイトルのページに表示されます。',
			'lending.more' => 'もっと充電',
			'lending.gateway' => '図書館登録サービス',
			'lending.gatewayHint' => '図書館または管理者 PlezyNG によって提供されます。',
			'lending.advanced' => '図書館統合',
			'lending.loadLibraries' => '図書館を選択',
			'lending.expired' => 'この本の貸出期間は終了しました。',
			'lending.updated' => '図書館更新',
			'lending.continueService' => 'サービスを継続',
			'lending.comingSoon' => 'イン・アプリ・貸し出し · すぐに来る',
			'lending.comingSoonDescription' => 'Libbyとの連携機能を準備中です。連携が完了するまでは、Libbyで図書館を利用できます。',
			'lending.suspendHold' => '予約を一時停止',
			'lending.resumeHold' => '予約を再開',
			'lending.suspendMessage' => '順番を維持したまま、次の読者にこの本を貸し出しますか？予約は後で再開できます。',
			'lending.resumeMessage' => '予約を再開して、次に利用可能な本の案内を図書館から受け取りますか？',
			'lending.editEmail' => 'メール通知の変更',
			'audiobook.syncTitle' => '読書・聴くシンク',
			'audiobook.syncHelp' => 'あなたのデバイスを通じて読み込みポジション、聴くポジション、完成状態、ブックマーク、ノートを保持します。付属ストレージアカウントを選択し、それぞれのデバイスに同じ同期コードを使用します。',
			'audiobook.addSyncSource' => 'Google ドライブ、OneDrive、Dropbox、WebDAV、または S3 をファイルと本に最初に追加します。',
			'audiobook.syncDestination' => 'シンクストレージアカウント',
			'audiobook.syncFolder' => 'シンクフォルダーまたはプレフィックス',
			'audiobook.syncFolderHelp' => 'WebDAV ソース内の別々の既存のフォルダー、または専用の S3 プレフィックスを使用します。',
			'audiobook.syncCode' => 'プライベートシンクコード',
			'audiobook.syncCodeHelp' => '最初のデバイスでコードを作成し、そのコードを他のデバイスで入力します。プライベートコピーを保管します:それは暗号化状態の鍵です。',
			'audiobook.showCode' => 'シンクコードを表示または隠す',
			'audiobook.newSyncCode' => '新しいシンクコードを作成する',
			'audiobook.saveSync' => '保存と同期',
			'audiobook.disableSync' => 'このデバイスでSync をオフにする',
			'audiobook.syncSourceDisconnect' => 'このソースを削除すると、ここで読み聞かせと聴く同期が停止されます。',
			'audiobook.syncReconnect' => 'ストレージアカウント再接続',
			'audiobook.lastSynced' => ({required Object time}) => '最後に ${time} で同期',
			'audiobook.syncPrivacy' => '暗号化された進歩およびノートのみが保存されます. オーディオおよび電子書籍ファイル、アカウントのトークンおよびパスワードはアップロードされません. Google ドライブおよび OneDrive はアプリストレージを使用します. Dropbox は PlezyNG Sync を使用します. 同期を有効にするには追加の書き込みアクセスが要求される可能性があります. 有効にしている間、この目的地は進歩同期を所有しています. サーバーの進歩は別々に残ります. 回転同期は地元の歴史と遠隔状態を維持します。',
			'audiobook.syncConflicts' => '再開する場所を選択する',
			'audiobook.conflictHelp' => 'これらの変更は独立して行われました. 保持するポジションまたはブックマークのバージョンを選択します. 遅いタイムストンプまたはより高い割合は自動的に勝てません。',
			'audiobook.syncDevice' => ({required Object device}) => 'デバイス ${device}',
			'audiobook.syncUnknownDevice' => '未知の装置',
			'audiobook.deletedBookmark' => '削除書籍',
			'audiobook.finished' => '終了',
			'audiobook.readingPosition' => ({required Object percent}) => '読書 · ${percent}%',
			'audiobook.chapterTimeline' => '第1章 進歩',
			'audiobook.bookTimeline' => '全書進展',
			'audiobook.bookRemaining' => ({required Object time}) => 'この本に残る時間: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'この章に残る時間: ${time}',
			'audiobook.unknownRemaining' => '全時間利用可能 パーツがプレイされる場合',
			'audiobook.undoSeek' => '最後の探求',
			'audiobook.customSpeed' => 'Custom Playback スピード',
			'audiobook.speedHelp' => '0.25×から4×までのスピードを選択します。',
			'audiobook.apply' => '応募',
			'audiobook.customSleep' => 'カスタム睡眠時間',
			'audiobook.sleepMinutes' => '時間(1～1440分)',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} 章の後停止',
			'audiobook.extendSleep' => '追加5分',
			'audiobook.sleepRemaining' => ({required Object time}) => '睡眠タイマー: ${time}',
			'audiobook.useDefaults' => 'これらの聴覚コントロールを新しい本に使用する',
			'audiobook.librarySort' => '色の本',
			'audiobook.sortTitle' => 'タイトル',
			'audiobook.sortAuthor' => '著者',
			'audiobook.sortNarrator' => '講演者',
			'audiobook.sortSeries' => 'シリーズオーダー',
			'audiobook.sortRecent' => '最近オープン',
			'audiobook.statusFilter' => '読書状態',
			'audiobook.statusAll' => 'すべての本',
			'audiobook.statusNew' => '始まらない',
			'audiobook.statusProgress' => '進歩中',
			'audiobook.statusFinished' => '終了',
			'audiobook.goToTime' => '時間へ行く',
			'audiobook.timeHelp' => '時間:分:秒、または分:秒',
			_ => null,
		};
	}
}
