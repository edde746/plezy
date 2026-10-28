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
class TranslationsKo extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsKo({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ko>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsKo _root = this; // ignore: unused_field

	@override 
	TranslationsKo $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsKo(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ko app = _Translations$app$ko._(_root);
	@override late final _Translations$appIcon$ko appIcon = _Translations$appIcon$ko._(_root);
	@override late final _Translations$auth$ko auth = _Translations$auth$ko._(_root);
	@override late final _Translations$common$ko common = _Translations$common$ko._(_root);
	@override late final _Translations$screens$ko screens = _Translations$screens$ko._(_root);
	@override late final _Translations$update$ko update = _Translations$update$ko._(_root);
	@override late final _Translations$settings$ko settings = _Translations$settings$ko._(_root);
	@override late final _Translations$themeEditor$ko themeEditor = _Translations$themeEditor$ko._(_root);
	@override late final _Translations$search$ko search = _Translations$search$ko._(_root);
	@override late final _Translations$hotkeys$ko hotkeys = _Translations$hotkeys$ko._(_root);
	@override late final _Translations$fileInfo$ko fileInfo = _Translations$fileInfo$ko._(_root);
	@override late final _Translations$mediaMenu$ko mediaMenu = _Translations$mediaMenu$ko._(_root);
	@override late final _Translations$rateSheet$ko rateSheet = _Translations$rateSheet$ko._(_root);
	@override late final _Translations$accessibility$ko accessibility = _Translations$accessibility$ko._(_root);
	@override late final _Translations$tooltips$ko tooltips = _Translations$tooltips$ko._(_root);
	@override late final _Translations$audioTracks$ko audioTracks = _Translations$audioTracks$ko._(_root);
	@override late final _Translations$videoControls$ko videoControls = _Translations$videoControls$ko._(_root);
	@override late final _Translations$messages$ko messages = _Translations$messages$ko._(_root);
	@override late final _Translations$subtitlingStyling$ko subtitlingStyling = _Translations$subtitlingStyling$ko._(_root);
	@override late final _Translations$mpvConfig$ko mpvConfig = _Translations$mpvConfig$ko._(_root);
	@override late final _Translations$dialog$ko dialog = _Translations$dialog$ko._(_root);
	@override late final _Translations$profiles$ko profiles = _Translations$profiles$ko._(_root);
	@override late final _Translations$connections$ko connections = _Translations$connections$ko._(_root);
	@override late final _Translations$accountPreferences$ko accountPreferences = _Translations$accountPreferences$ko._(_root);
	@override late final _Translations$discover$ko discover = _Translations$discover$ko._(_root);
	@override late final _Translations$errors$ko errors = _Translations$errors$ko._(_root);
	@override late final _Translations$libraries$ko libraries = _Translations$libraries$ko._(_root);
	@override late final _Translations$about$ko about = _Translations$about$ko._(_root);
	@override late final _Translations$serverSelection$ko serverSelection = _Translations$serverSelection$ko._(_root);
	@override late final _Translations$hubDetail$ko hubDetail = _Translations$hubDetail$ko._(_root);
	@override late final _Translations$logs$ko logs = _Translations$logs$ko._(_root);
	@override late final _Translations$startup$ko startup = _Translations$startup$ko._(_root);
	@override late final _Translations$licenses$ko licenses = _Translations$licenses$ko._(_root);
	@override late final _Translations$navigation$ko navigation = _Translations$navigation$ko._(_root);
	@override late final _Translations$explore$ko explore = _Translations$explore$ko._(_root);
	@override late final _Translations$liveTv$ko liveTv = _Translations$liveTv$ko._(_root);
	@override late final _Translations$collections$ko collections = _Translations$collections$ko._(_root);
	@override late final _Translations$playlists$ko playlists = _Translations$playlists$ko._(_root);
	@override late final _Translations$music$ko music = _Translations$music$ko._(_root);
	@override late final _Translations$watchTogether$ko watchTogether = _Translations$watchTogether$ko._(_root);
	@override late final _Translations$downloads$ko downloads = _Translations$downloads$ko._(_root);
	@override late final _Translations$shaders$ko shaders = _Translations$shaders$ko._(_root);
	@override late final _Translations$companionRemote$ko companionRemote = _Translations$companionRemote$ko._(_root);
	@override late final _Translations$videoSettings$ko videoSettings = _Translations$videoSettings$ko._(_root);
	@override late final _Translations$performanceOverlay$ko performanceOverlay = _Translations$performanceOverlay$ko._(_root);
	@override late final _Translations$externalPlayer$ko externalPlayer = _Translations$externalPlayer$ko._(_root);
	@override late final _Translations$metadataEdit$ko metadataEdit = _Translations$metadataEdit$ko._(_root);
	@override late final _Translations$matchScreen$ko matchScreen = _Translations$matchScreen$ko._(_root);
	@override late final _Translations$serverTasks$ko serverTasks = _Translations$serverTasks$ko._(_root);
	@override late final _Translations$trakt$ko trakt = _Translations$trakt$ko._(_root);
	@override late final _Translations$seerr$ko seerr = _Translations$seerr$ko._(_root);
	@override late final _Translations$services$ko services = _Translations$services$ko._(_root);
	@override late final _Translations$addServer$ko addServer = _Translations$addServer$ko._(_root);
	@override late final _Translations$cast$ko cast = _Translations$cast$ko._(_root);
	@override late final _Translations$automation$ko automation = _Translations$automation$ko._(_root);
	@override late final _Translations$notifications$ko notifications = _Translations$notifications$ko._(_root);
	@override late final _Translations$appAccess$ko appAccess = _Translations$appAccess$ko._(_root);
	@override late final _Translations$detail$ko detail = _Translations$detail$ko._(_root);
	@override late final _Translations$watchLink$ko watchLink = _Translations$watchLink$ko._(_root);
	@override late final _Translations$homeLayout$ko homeLayout = _Translations$homeLayout$ko._(_root);
	@override late final _Translations$platform$ko platform = _Translations$platform$ko._(_root);
	@override late final _Translations$universalMedia$ko universalMedia = _Translations$universalMedia$ko._(_root);
	@override late final _Translations$fileSources$ko fileSources = _Translations$fileSources$ko._(_root);
	@override late final _Translations$lending$ko lending = _Translations$lending$ko._(_root);
	@override late final _Translations$audiobook$ko audiobook = _Translations$audiobook$ko._(_root);
	@override late final _Translations$sourceSetup$ko sourceSetup = _Translations$sourceSetup$ko._(_root);
	@override late final _Translations$comics$ko comics = _Translations$comics$ko._(_root);
	@override late final _Translations$games$ko games = _Translations$games$ko._(_root);
	@override late final _Translations$deepLinks$ko deepLinks = _Translations$deepLinks$ko._(_root);
}

// Path: app
class _Translations$app$ko extends Translations$app$en {
	_Translations$app$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$ko extends Translations$appIcon$en {
	_Translations$appIcon$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '앱 아이콘';
	@override String get defaultIcon => '기본';
	@override String get current => '현재 아이콘';
	@override String get locked => '인생 접근이 필요합니다';
	@override String get lockedHint => '7일간의 시험을 시작하거나 PlezyNG을 잠그거나 대체 아이콘을 사용하십시오.';
	@override String get changeFailed => '앱 아이콘을 변경하지 못했습니다';
	@override String get launcherHint => 'Plezy를 나가면 홈 화면에 새 아이콘이 표시됩니다.';
	@override String get tvLauncherHint => 'Plezy를 나가면 새 배너가 표시됩니다. Android TV에서는 TV를 다시 시작할 때까지 이전 배너가 계속 표시될 수 있습니다.';
	@override late final _Translations$appIcon$names$ko names = _Translations$appIcon$names$ko._(_root);
	@override String get description => '장치 시작자에 의해 표시된 아이콘을 선택합니다.예비 보기에서는 각 옵션이 어떻게 보이는지 보여줍니다.';
}

// Path: auth
class _Translations$auth$ko extends Translations$auth$en {
	_Translations$auth$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex 계정으로 로그인';
	@override String get showQRCode => 'QR 코드 표시';
	@override String get authenticate => '인증';
	@override String get authenticationTimeout => '인증 시간이 초과되었습니다. 다시 시도해 주세요.';
	@override String get scanQRToSignIn => '로그인하려면 이 QR 코드를 스캔하세요';
	@override String get waitingForAuth => '인증 대기 중...\n브라우저에서 로그인하세요.';
	@override String get useBrowser => '브라우저 사용';
	@override String get or => '또는';
	@override String connectToMediaBrowser({required Object product}) => '${product}에 연결';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Quick Connect 사용';
	@override String get quickConnectInstructions => 'Jellyfin에서 Quick Connect를 열고 이 코드를 입력하세요.';
	@override String get quickConnectWaiting => '승인 대기 중…';
	@override String get quickConnectCancel => '취소';
	@override String get quickConnectExpired => 'Quick Connect가 만료되었습니다. 다시 시도하세요.';
	@override String get localDataRecoveryRequired => 'Plezy에서 로컬 로그인 정보와 대기 중인 재생 데이터를 안전하게 복구하지 못했습니다. 다시 로그인해 주세요.';
	@override String get pinCheckRejected => 'Plex PIN 확인이 거부되었습니다';
	@override String get connectToDirectPlex => '지역 서버 Plex에 연결';
}

// Path: common
class _Translations$common$ko extends Translations$common$en {
	_Translations$common$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get cancel => '취소';
	@override String get save => '저장';
	@override String get close => '닫기';
	@override String get closeMiniPlayer => '미니 플레이어 근처';
	@override String get closeWorkspaceWindow => '가까운 창문';
	@override String get returnToFullView => '완전한 시야로 돌아가기';
	@override String get manageMediaSessions => '미디어 세션 관리';
	@override String get hideMediaSessions => '미디어 세션 숨기기';
	@override String get mediaSessions => '미디어 세션';
	@override String get mediaSessionsHint => '파크는 창을 숨기지만 열려 있습니다. 반환은 완전한 전망으로 열립니다; 가까운 끝은 그것입니다.';
	@override String get sessionInWorkspace => '워크샵에서';
	@override String get sessionParked => '주차';
	@override String get sessionFullscreen => '전체 스크린';
	@override String get switchToNextWindow => '다음 창으로 전환';
	@override String get moveWindow => '움직이는 창문';
	@override String get finishMovingWindow => '움직이는 창을 마무리';
	@override String get moveWindowHint => '긴 밀어 넣고 창을 끌어서 이동합니다.이 컨트롤은 또한 열쇠 움직임을 허용합니다.';
	@override String get movingWindowHelp => '끌기 이동 · 끌 키 조정 · 입력 저장 · 탈출 취소';
	@override String get resizeWindow => '윈도우 재설정';
	@override String get resizeWindowHint => '이 손잡이를 끌거나 창을 재구성하기 위해 총 열쇠를 사용하십시오.';
	@override String get workspaceWindowHint => '움직임 컨트롤 또는 긴 압축을 사용 하 여 이동 하 고 끌어.';
	@override String get workspacePaneHint => '이 패널을 선택하여 초점을 맞추십시오.전체 스크린 컨트롤을 사용하여 확장합니다.';
	@override String workspaceWindowLabel({required Object title}) => '세션 창: ${title}';
	@override String get workspaceTitleHint => '초점을 선택합니다. 이동하려면 제목 바를 끌어; 확장하기 위해 전체 스크린 버튼을 사용합니다.';
	@override String get moveToSessionTray => '세션 트레이로 이동';
	@override String get moveToSessionTrayHint => '이 세션은 창을 표시하지 않고 사용할 수 있습니다.';
	@override String get closeSessionHint => '이 창을 닫고 세션이 끝납니다.';
	@override String get sideBySideLayout => '스위치 - Side-by-side layout';
	@override String get floatingWindows => '윈도우를 흐르는 스위치';
	@override String get clear => '지우기';
	@override String get reset => '초기화';
	@override String get later => '나중에';
	@override String get submit => '제출';
	@override String get confirm => '확인';
	@override String get retry => '재시도';
	@override String get logout => '로그아웃';
	@override String get unknown => '알 수 없는';
	@override String get refresh => '새로고침';
	@override String get yes => '예';
	@override String get no => '아니오';
	@override String get delete => '삭제';
	@override String get edit => '편집';
	@override String get shuffle => '무작위 재생';
	@override String get addTo => '추가하기...';
	@override String get createNew => '새로 만들기';
	@override String get connect => '연결';
	@override String get disconnect => '연결 해제';
	@override String get play => '재생';
	@override String get pause => '일시정지';
	@override String get resume => '재개';
	@override String get error => '오류';
	@override String get search => '검색';
	@override String get home => '홈';
	@override String get back => '뒤로';
	@override String get settings => '설정';
	@override String get mute => '음소거';
	@override String get ok => '확인';
	@override String get off => '꺼짐';
	@override String get options => '옵션';
	@override String seasonNumber({required Object number}) => '시즌 ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => '${number}화 - ${title}';
	@override String chapterNumber({required Object number}) => '챕터 ${number}';
	@override String get reconnect => '다시 연결';
	@override String get viewAll => '모두 보기';
	@override String get checkingNetwork => '네트워크 확인 중...';
	@override String get loadingServers => '서버 로딩 중...';
	@override String get connectingToServers => '서버 연결 중...';
	@override String get startingOfflineMode => '오프라인 모드 시작 중...';
	@override String get loading => '로딩 중...';
	@override String get fullscreen => '전체 화면';
	@override String get exitFullscreen => '전체 화면 종료';
	@override String get pressBackAgainToExit => '한 번 더 누르면 종료됩니다';
	@override late final _Translations$common$ratingSource$ko ratingSource = _Translations$common$ratingSource$ko._(_root);
	@override String get notAvailable => 'N/A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$ko mediaKind = _Translations$common$mediaKind$ko._(_root);
}

// Path: screens
class _Translations$screens$ko extends Translations$screens$en {
	_Translations$screens$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get licenses => '라이선스';
	@override String get switchProfile => '프로필 전환';
	@override String get subtitleStyling => '자막 스타일 설정';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => '로그';
}

// Path: update
class _Translations$update$ko extends Translations$update$en {
	_Translations$update$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get available => '업데이트 있음';
	@override String versionAvailable({required Object version}) => '${version} 버전을 사용할 수 있습니다';
	@override String currentVersion({required Object version}) => '현재 버전: ${version}';
	@override String get skipVersion => '이 버전 건너뛰기';
	@override String get viewRelease => '릴리스 정보 보기';
	@override String get latestVersion => '최신 버전을 사용 중입니다';
	@override String get checkFailed => '업데이트 확인 실패';
}

// Path: settings
class _Translations$settings$ko extends Translations$settings$en {
	_Translations$settings$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '설정';
	@override String get supportDeveloper => 'PlezyNG 후원하기';
	@override String get supportDeveloperDescription => '기부로 개발을 지원하세요';
	@override String get lifetimeAccess => 'PlezyNG 평생 액세스';
	@override String get language => '언어';
	@override String get theme => '테마';
	@override String get appearance => '디자인';
	@override String get detailPage => '자세한 페이지';
	@override String get themeSongsEnabled => '주제 노래를 연주';
	@override String get themeSongsEnabledDescription => '미디어 세부 사항을 볼 때 사용 가능한 테마 노래를 재생합니다.';
	@override String get themeSongVolume => '노래의 곡 Volume';
	@override String get videoPlayback => '비디오 재생';
	@override String get videoPlaybackDescription => '재생 동작 설정';
	@override String get advanced => '고급';
	@override String get episodePosterMode => '에피소드 포스터 스타일';
	@override String get seriesPoster => '시리즈 포스터';
	@override String get seasonPoster => '시즌 포스터';
	@override String get episodeThumbnail => '썸네일';
	@override String get showHeroSectionDescription => '홈 화면에 주요 콘텐츠 캐러셀(슬라이드) 표시';
	@override String get secondsLabel => '초';
	@override String get minutesLabel => '분';
	@override String get secondsShort => '초';
	@override String get minutesShort => '분';
	@override String durationHint({required Object min, required Object max}) => '기간 입력 (${min}-${max})';
	@override String get systemTheme => '시스템';
	@override String get lightTheme => '라이트';
	@override String get darkTheme => '다크';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => '불씨';
	@override String get glacierTheme => '빙하';
	@override String get forestTheme => '숲';
	@override String get plumTheme => '자두';
	@override String get paperTheme => '종이';
	@override String get libraryDensity => '라이브러리 표시 밀도';
	@override String get displayScale => '표시 배율';
	@override String get compact => '조밀하게';
	@override String get comfortable => '여유롭게';
	@override String get gridSpacing => '그리드 간격';
	@override String get gridSpacingTight => '조밀하게';
	@override String get gridSpacingNormal => '보통';
	@override String get gridSpacingSpacious => '여유롭게';
	@override String get tvCornerSpotlightBackdrop => '모서리 스포트라이트 배경';
	@override String get tvCornerSpotlightBackdropDescription => '화면 전체를 채우는 대신 오른쪽 상단에 스포트라이트 아트워크를 표시합니다';
	@override String get viewMode => '보기 모드';
	@override String get gridView => '그리드 보기';
	@override String get listView => '목록 보기';
	@override String get showHeroSection => '주요 추천 영역 표시';
	@override String get showHomeBackdrop => 'Home Backdrop 예술 작품 보기';
	@override String get showHomeBackdropDescription => '큰 예술 작품을 보여주고, 가정 라인 뒤에';
	@override String get contentScreensaverEnabled => '콘텐츠 스크린 스토어';
	@override String get contentScreensaverEnabledDescription => '앱이 아이돌이 된 후에 전체 스크린 아트워크를 표시합니다.';
	@override String get contentScreensaverDelay => '스크린 스토어를 시작한 후';
	@override String get contentScreensaverLibraries => '스크린 스토어 도서관';
	@override String get contentScreensaverLibrariesDescription => '화면 보호기 이미지에 사용할 라이브러리를 선택하세요. 아무것도 선택하지 않으면 모든 라이브러리의 이미지가 사용됩니다.';
	@override String get contentScreensaverAllLibraries => '모든 도서관';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} 선택된 도서관';
	@override String get contentScreensaverNoLibraries => '연결된 미디어 도서관은 없습니다.';
	@override String get contentScreensaverDismissHint => '버튼을 누르거나 삭제를 눌러';
	@override String get newEpisodeNotifications => '새로운 에피소드 알림';
	@override String get newEpisodeNotificationsDescription => '새 에피소드가 쇼에 추가되면 경고를 받으십시오. Plezy이 열려있는 동안 확인합니다.';
	@override String get continueWatchingRowSize => '계속해서 롤 크기를 보세요.';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} 카드';
	@override String get rowSizeCompact => '조밀하게';
	@override String get rowSizeStandard => '표준';
	@override String get rowSizeLarge => '대형';
	@override String get continueWatchingAction => '계속 보기 동작';
	@override String get continueWatchingPlay => '재생';
	@override String get continueWatchingDetails => '상세 정보 열기';
	@override String get episodeAction => '에피소드 동작';
	@override String get episodePlay => '재생';
	@override String get episodeDetails => '상세 정보 열기';
	@override String get useGlobalHubs => '홈 레이아웃 사용';
	@override String get useGlobalHubsDescription => '통합 홈 허브를 표시합니다. 끄면 라이브러리 추천을 사용합니다.';
	@override String get showServerNameOnHubs => '허브에 서버 이름 표시';
	@override String get showServerNameOnHubsDescription => '허브 제목에 항상 서버 이름을 표시합니다.';
	@override String get groupLibrariesByServer => '서버별로 라이브러리 그룹화';
	@override String get groupLibrariesByServerDescription => '사이드바 라이브러리를 미디어 서버별로 그룹화합니다.';
	@override String get alwaysKeepSidebarOpen => '사이드바 항상 열어두기';
	@override String get alwaysKeepSidebarOpenDescription => '사이드바가 확장된 상태로 유지되고 콘텐츠 영역이 맞춰집니다';
	@override String get showUnwatchedCount => '미시청 수 표시';
	@override String get showUnwatchedCountDescription => '시리즈 및 시즌에 미시청 에피소드 수 표시';
	@override String get showWatchedIndicators => '시청 표시 보이기';
	@override String get showWatchedIndicatorsDescription => '시청한 영화, 프로그램, 에피소드에 체크 표시를 표시합니다';
	@override String get showEpisodeNumberOnCards => '카드에 에피소드 번호 표시';
	@override String get showEpisodeNumberOnCardsDescription => '에피소드 카드에 시즌 및 에피소드 번호 표시';
	@override String get showSeasonPostersOnTabs => '탭에 시즌 포스터 표시';
	@override String get showSeasonPostersOnTabsDescription => '각 시즌 포스터를 탭 위에 표시';
	@override String get tvFullCardLayout => '전체 TV 카드';
	@override String get tvFullCardLayoutDescription => 'TV 카드에 이미지만 표시하고 배우 이름을 오버레이로 표시';
	@override String get focusGlow => '포커스 글로우';
	@override String get focusGlowDescription => '포커스된 카드 주위에 은은한 빛 효과를 표시';
	@override String get visualEffects => '시각 효과';
	@override String get visualEffectsAuto => '자동';
	@override String get visualEffectsAutoDescription => '저전력 기기에서 효과를 자동으로 줄입니다';
	@override String get visualEffectsFull => '전체';
	@override String get visualEffectsReduced => '축소';
	@override String get visualEffectsReducedDescription => '애니메이션을 줄이고 아트워크 해상도를 낮춥니다';
	@override String get hideSpoilers => '미시청 에피소드 스포일러 숨기기';
	@override String get hideSpoilersDescription => '시청하지 않은 에피소드의 썸네일과 설명을 흐리게 처리';
	@override String get playerBackend => '플레이어 백엔드';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => '하드웨어 디코딩';
	@override String get hardwareDecodingDescription => '가능한 경우 하드웨어 가속을 사용합니다';
	@override String get playbackBuffer => '재생 버퍼';
	@override String get playbackBufferAuto => '자동 (권장)';
	@override String get playbackBufferLarge => '대형';
	@override String get playbackBufferExtraLarge => '초대형';
	@override String get playbackBufferDescription => '불안정한 연결에 대비해 더 많은 버퍼를 사용합니다. 버퍼 크기에 의해서도 제한됩니다.';
	@override String get streamBufferSize => '부퍼 크기';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => '얼마나 많은 비디오를 직접 재생할 때 앞으로 충전해야 하는지.Transcodes는 서버의 자체 transcode 버퍼에서 멈추게 됩니다. 0 = 자동';
	@override String get streamBufferSizeExoNote => '설정할 때 Playback Buffer를 대체하고, 앱의 메모리 한도 절반에 캡처';
	@override String get streamBufferMegabytes => '메가바이트';
	@override String get defaultQualityTitle => '기본 화질';
	@override String get cellularQualityTitle => '셀룰러에서 기본 화질';
	@override String get remoteQualityTitle => '원격 스트리밍 품질';
	@override String get remoteQualitySameAsDefault => '기본 품질과 동일한';
	@override String get cellularQualitySameAsDefault => '기본 화질과 동일';
	@override String get directPlayCoveredQuality => '작은 동영상을 원본 화질로 재생';
	@override String get directPlayCoveredQualityDescription => '화질 제한 내의 동영상은 트랜스코딩하지 않고 Direct Play합니다';
	@override String get videoCodecs => '비디오 코덱';
	@override String get videoCodecsDescription => '선택 해제한 코덱은 서버가 트랜스코딩합니다';
	@override String get videoCodecsAlwaysAccepted => '항상 허용';
	@override String get musicQualityTitle => '음악 음질';
	@override String get subtitleStyling => '자막 스타일';
	@override String get subtitleStylingDescription => '자막 모양을 사용자 지정합니다';
	@override String get smallSkipDuration => '짧은 건너뛰기 시간';
	@override String get largeSkipDuration => '긴 건너뛰기 시간';
	@override String get rewindOnResume => '재개 시 되감기';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)}초',
	);
	@override String get defaultSleepTimer => '기본 취침 타이머';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)}분',
	);
	@override String get rememberTrackSelections => '시리즈/영화별 트랙 선택 기억';
	@override String get chooseTracksBeforePlayback => '재생 전에 오디오 및 하위 제목을 선택합니다.';
	@override String get chooseTracksBeforePlaybackDescription => '각 비디오가 시작되기 전에 소스 오디오 및 하위 제목 트랙을 선택합니다.';
	@override String get alwaysShowSubtitlesOnDevice => '항상 이 장치에 서브 타이틀을 표시합니다.';
	@override String get alwaysShowSubtitlesOnDeviceDescription => '서버가 선택된 하위 제목이 없으면 로컬로 트랙을 선택합니다.이것은 서버의 선호도를 결코 변경하지 않습니다.';
	@override String get autoDownloadPreferredSubtitle => '페치가 좋아하는 언어 서브 타이틀을 놓치고 있다.';
	@override String get autoDownloadPreferredSubtitleDescription => '좋아하는 언어로 사용할 수 있는 하위 제목을 현지적으로 선택합니다.이 언어가 존재하지 않는 경우, 지원되는 경우 서버에 하나를 캡처하도록 요청합니다.';
	@override String get rememberTrackSelectionsDescription => '작품별 오디오 및 자막 선택 기억';
	@override String get rememberTrackSelectionsBackendRule => 'Plex는 파일별로 각 선택을 서버에 저장합니다. Jellyfin은 계정의 선택 기억도 활성화합니다. Emby는 지원되지 않습니다';
	@override String get followServerTrackSelections => '서버의 에피소드별 트랙 선택 사용';
	@override String get followServerTrackSelectionsDescription => '에피소드 전환 시 현재 선택을 유지하는 대신 서버에서 선택된 오디오와 자막을 적용합니다';
	@override String get resumeMusicOnLaunch => '음악 세션 기억';
	@override String get resumeMusicOnLaunchDescription => '앱 시작 시 마지막 곡을 멈춘 위치에서 일시정지 상태로 엽니다';
	@override String get showChapterMarkersOnTimeline => '탐색 막대에 챕터 마커 표시';
	@override String get showChapterMarkersOnTimelineDescription => '챕터 경계에서 탐색 막대 구분';
	@override String get specialsOrdering => '에피소드 순서로 스페셜 표시';
	@override String get specialsOrderingDescription => '시리즈 시청 순서에서 스페셜이 재생되는 위치';
	@override String get specialsOrderingServer => '서버 순서 따르기';
	@override String get specialsOrderingAirDate => '방영일 순서로 삽입';
	@override String get specialsOrderingLast => '일반 시즌 뒤';
	@override String get clickVideoTogglesPlayback => '동영상 클릭으로 재생/일시정지 전환';
	@override String get clickVideoTogglesPlaybackDescription => '컨트롤을 표시하는 대신 동영상을 클릭하여 재생하거나 일시정지합니다.';
	@override String get videoPlayerControls => '비디오 플레이어 컨트롤';
	@override String get keyboardShortcuts => '키보드 단축키';
	@override String get keyboardShortcutsDescription => '키보드 단축키를 사용자 지정합니다';
	@override String get videoPlayerNavigation => '비디오 플레이어 탐색';
	@override String get videoPlayerNavigationDescription => '방향 키로 비디오 플레이어 컨트롤을 탐색합니다';
	@override String get watchTogetherRelay => '함께 보기 릴레이';
	@override String get watchTogetherRelayDescription => '직접 설정하지 않으면 공개 Open Watch Party 릴레이를 사용합니다';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => '올바른 HTTP 또는 HTTPS 릴레이 기본 URL을 입력하세요.';
	@override String get crashReporting => '충돌 보고';
	@override String get crashReportingDescription => '앱 개선을 위해 충돌 보고서 전송';
	@override String get debugLogging => '디버그 로깅';
	@override String get debugLoggingDescription => '문제 해결을 위해 상세 로깅 활성화';
	@override String get viewLogs => '로그 보기';
	@override String get viewLogsDescription => '애플리케이션 로그 확인';
	@override String get clearImageCache => '이미지 캐시 지우기';
	@override String get clearImageCacheDescription => '캐시된 아트워크와 썸네일을 지웁니다. 다시 다운로드할 때까지 이미지가 느리게 로드될 수 있습니다.';
	@override String get clearImageCacheSuccess => '이미지 캐시를 성공적으로 지웠습니다';
	@override String get resetSettings => '설정 재설정';
	@override String get resetSettingsDescription => '기본 설정으로 복원합니다. 되돌릴 수 없습니다.';
	@override String get resetSettingsSuccess => '설정 재설정 성공';
	@override String get backup => '백업';
	@override String get exportSettings => '설정 내보내기';
	@override String get exportSettingsDescription => '기본 설정을 파일로 저장';
	@override String get exportSettingsSuccess => '설정 내보내기 완료';
	@override String get importSettings => '설정 가져오기';
	@override String get importSettingsDescription => '파일에서 기본 설정 복원';
	@override String get importSettingsConfirm => '현재 설정을 대체합니다. 계속하시겠습니까?';
	@override String get importSettingsSuccess => '설정 가져오기 완료';
	@override String get importSettingsInvalidFile => '유효한 PlezyNG 설정 내보내기 파일이 아닙니다';
	@override String get importSettingsNoUser => '설정을 가져오기 전에 로그인하세요';
	@override String get cloudBackup => '클라우드 백업';
	@override String get cloudBackupDescription => '이동 가능한 설정을 HTTPS를 통해 WebDAV 주소에 백업합니다. 서버 연결 및 로그인 정보는 이 기기에 유지됩니다.';
	@override String get cloudBackupUrl => 'WebDAV JSON 파일 URL';
	@override String get cloudBackupUsername => '사용자 이름';
	@override String get cloudBackupPassword => '비밀번호';
	@override String get cloudBackupSaved => '구름 백업 목적지 저장';
	@override String get cloudBackupNow => '지금 다시 올라';
	@override String get cloudBackupComplete => '설정 백업 업로드';
	@override String get cloudBackupRestore => 'Backup 복구';
	@override String get cloudBackupRestoreConfirm => '이 장치에서 해당 휴대용 설정을 대체합니다.';
	@override String get cloudBackupRestored => 'Cloud Backup에서 복구된 설정';
	@override String get shortcutsReset => '단축키가 기본값으로 재설정되었습니다';
	@override String get resetShortcutsConfirm => '사용자 지정 단축키가 기본값으로 대체됩니다. 계속하시겠습니까?';
	@override String get about => '정보';
	@override String get aboutDescription => '앱 정보 및 라이선스';
	@override String get updates => '업데이트';
	@override String get updateAvailable => '사용 가능한 업데이트 있음';
	@override String get checkForUpdates => '업데이트 확인';
	@override String get autoCheckUpdatesOnStartup => '시작 시 자동으로 업데이트 확인';
	@override String get autoCheckUpdatesOnStartupDescription => '실행 시 업데이트가 있으면 알림';
	@override String get validationErrorEnterNumber => '유효한 숫자를 입력하세요';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '기간은 ${min}과 ${max} ${unit} 사이여야 합니다';
	@override String shortcutAlreadyAssigned({required Object action}) => '단축키가 이미 ${action}에 할당되었습니다';
	@override String shortcutUpdated({required Object action}) => '${action} 단축키가 업데이트되었습니다';
	@override String get saveFailed => '변경 사항을 저장하지 못했습니다. 다시 시도하세요.';
	@override String get autoPlayAndSkip => '자동 재생 및 건너뛰기';
	@override String get autoPlayNextEpisode => '다음 에피소드 자동 재생';
	@override String get autoPlayNextEpisodeDescription => '에피소드가 끝나면 다음 에피소드를 자동으로 재생';
	@override String get shuffleStartsFromBeginning => '무작위 재생 시 처음부터 시작';
	@override String get shuffleStartsFromBeginningDescription => '무작위 재생 시 이어보기 대신 각 에피소드를 처음부터 재생합니다';
	@override String get plexCinemaPreRoll => '서버 영화관 인트로스 사용';
	@override String get plexCinemaPreRollDescription => '영화가 시작되기 전에 Plex 사전 롤 또는 Jellyfin 및 Emby 입력을 구성합니다.';
	@override String get playNextCountdown => '다음 재생 카운트다운';
	@override String get playNextCountdownImmediate => '즉시 재생';
	@override String get skipIntroMode => '인트로 건너뛰기';
	@override String get skipIntroModeOffDescription => '건너뛰기 버튼 없이 인트로를 정상적으로 재생합니다';
	@override String get skipIntroModeButtonDescription => '인트로가 시작되면 건너뛰기 버튼을 표시합니다';
	@override String get skipIntroModeAutoDescription => '아래 지연 시간 후 인트로를 자동으로 건너뜁니다';
	@override String get skipCreditsMode => '크레딧 건너뛰기';
	@override String get skipCreditsModeOffDescription => '건너뛰기 버튼 없이 크레딧을 정상적으로 재생합니다';
	@override String get skipCreditsModeButtonDescription => '크레딧이 시작되면 건너뛰기 버튼을 표시합니다';
	@override String get skipCreditsModeAutoDescription => '크레딧을 자동으로 건너뛰고 다음 에피소드를 재생합니다';
	@override String get skipAdsMode => '스키 광고';
	@override String get skipAdsModeOffDescription => '스키 버튼 없이 일반적으로 발견된 광고를 재생합니다.';
	@override String get skipAdsModeButtonDescription => 'Plex 광고를 발견할 때 스키 버튼을 표시합니다.';
	@override String get skipAdsModeAutoDescription => '아래의 지연 후에 자동으로 발견된 광고를 삭제합니다.';
	@override String get musicPlayback => '음악 플레이백';
	@override String get musicSweetFades => '달콤한 파드';
	@override String get musicSweetFadesDescription => 'Plex이 음성 데이터를 가지고 있는 경우 트랙 옆에 음악을 녹음합니다.앨범 재생은 변하지 않습니다.';
	@override String get skipMarkerModeOff => '끄기';
	@override String get skipMarkerModeButton => '버튼 표시';
	@override String get skipMarkerModeAuto => '자동';
	@override String get forceSkipMarkerFallback => '대체 마커 강제 사용';
	@override String get forceSkipMarkerFallbackDescription => 'Plex에 마커가 있어도 챕터 제목 패턴 사용';
	@override String get theIntroDbFallback => 'IntroDB를 Intro Fallback로 사용하십시오.';
	@override String get theIntroDbFallbackDescription => '커뮤니티 타이밍을 사용하면 서버에 입력 표시가 없을 때만 사용합니다.';
	@override String get autoSkipDelay => '자동 건너뛰기 지연';
	@override String autoSkipDelayDescription({required Object seconds}) => '자동으로 건너뛰기 전 ${seconds}초 대기';
	@override String get introPattern => '인트로 마커 패턴';
	@override String get introPatternDescription => '챕터 제목에서 인트로 마커를 인식하는 정규식 패턴';
	@override String get creditsPattern => '크레딧 마커 패턴';
	@override String get creditsPatternDescription => '챕터 제목에서 크레딧 마커를 인식하는 정규식 패턴';
	@override String get prerolls => '프레로스';
	@override String get playPrerollsBeforeMovies => '영화 전에 프레롤을 재생합니다.';
	@override String get playPrerollsBeforeMoviesDescription => '각 영화 전에 아래의 선택에서 우연한 클립을 재생합니다.';
	@override String get prerollLibrary => '프레롤 도서관';
	@override String get prerollLibraryNotSet => '설정되지 않음';
	@override String get prerollLibraryNoneFound => '서버에 도서관이 없습니다.';
	@override String get prerollSelection => '선택된 선구자';
	@override String get prerollSelectionPickLibraryFirst => '먼저 도서관을 선택하세요.';
	@override String get prerollSelectionNoneSelected => '선택된 선구자 없음';
	@override String prerollSelectionCount({required Object count}) => '${count}개 선택됨';
	@override String get prerollItemPicker => '선호자 선택';
	@override String get prerollItemPickerLoadFailed => '이 도서관에서 항목을 충전할 수는 없었습니다.';
	@override String get invalidRegex => '잘못된 정규식';
	@override String get regex => '정규식';
	@override String get downloads => '다운로드';
	@override String get downloadLocationDescription => '다운로드 콘텐츠 저장 위치 선택';
	@override String get downloadLocationDefault => '기본값 (앱 저장소)';
	@override String get downloadLocationCustom => '사용자 지정 위치';
	@override String get selectFolder => '폴더 선택';
	@override String get resetToDefault => '기본값으로 재설정';
	@override String currentPath({required Object path}) => '현재: ${path}';
	@override String get downloadLocationChanged => '다운로드 위치가 변경되었습니다';
	@override String get downloadLocationReset => '다운로드 위치가 기본값으로 재설정되었습니다';
	@override String get downloadLocationInvalid => '선택한 폴더에 쓰기 권한이 없습니다';
	@override String get downloadLocationPickerUnavailable => '이 기기에서는 폴더를 선택할 수 없습니다';
	@override String get downloadOnWifiOnly => 'Wi-Fi 연결 시에만 다운로드';
	@override String get downloadOnWifiOnlyDescription => '셀룰러 데이터 사용 중에는 다운로드하지 않습니다';
	@override String get autoRemoveWatchedDownloads => '시청한 다운로드 항목 자동 삭제';
	@override String get autoRemoveWatchedDownloadsDescription => '시청한 다운로드 항목을 자동으로 삭제합니다';
	@override String get autoDownloadContinueWatching => '자동 다운로드 계속 보기';
	@override String get autoDownloadContinueWatchingDescription => '계속 보면서 셰일에 항목을 다운로드하고 그들이 셰일을 떠나면 그들을 제거합니다.';
	@override String get downloadQuality => '다운로드 품질';
	@override String get downloadQualityDescription => 'Plex은 다운로드 쿼드에 변환 된 복사본을 준비합니다. Jellyfin 및 Emby는 파일 다운로드 중 트랜스코드; 중단 된 전송은 다시 시작해야 할 수 있습니다.';
	@override String get askDownloadQualityEachTime => '각 다운로드에 대한 품질 선택';
	@override String get askDownloadQualityEachTimeDescription => '각 동영상 다운로드를 대기열에 추가하기 전에 화질 선택 화면 표시';
	@override String get cellularDownloadBlocked => '셀룰러에서는 다운로드가 차단됩니다. Wi-Fi를 사용하거나 설정을 변경하세요.';
	@override String get maxVolume => '최대 볼륨';
	@override String get maxVolumeDescription => '음량이 작은 콘텐츠를 위해 100% 이상의 볼륨을 허용합니다';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord에서 시청 중인 콘텐츠 표시';
	@override String get services => '서비스';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr 등 연결';
	@override String get manageLibrariesDescription => '라이브러리 순서를 변경하거나 숨깁니다';
	@override String get companionRemoteServer => '컴패니언 리모트 서버';
	@override String get companionRemoteServerDescription => '네트워크의 모바일 기기가 이 앱을 제어할 수 있도록 허용';
	@override String get companionRemoteServerStartFailed => '컴패니언 리모트 서버를 시작할 수 없습니다';
	@override String get companionRemoteServerStopFailed => '컴패니언 리모트 서버를 중지할 수 없습니다';
	@override String get autoPip => '자동 PIP 모드';
	@override String get autoPipDescription => '재생 중 앱을 떠나면 자동으로 화면 속 화면 모드로 전환합니다';
	@override String get matchContentFrameRate => '콘텐츠 프레임 레이트 맞춤';
	@override String get matchContentFrameRateDescription => '디스플레이 새로 고침 빈도를 동영상 콘텐츠에 맞춤';
	@override String get matchContentResolution => '콘텐츠 해상도에 맞추기';
	@override String get matchContentResolutionDescription => 'TV가 업스케일링을 처리하도록 디스플레이를 영상 본래 해상도로 전환합니다. 재생 중에는 메뉴와 자막도 함께 업스케일됩니다';
	@override String get matchRefreshRate => '주사율 맞춤';
	@override String get matchRefreshRateDescription => '전체 화면에서 디스플레이 새로 고침 빈도 맞춤';
	@override String get matchDynamicRange => '다이나믹 레인지 맞춤';
	@override String get matchDynamicRangeDescription => 'HDR 콘텐츠에서는 HDR로 전환한 뒤 SDR로 되돌림';
	@override String get displaySwitchDelay => '디스플레이 전환 지연';
	@override String get tunneledPlayback => '터널 재생';
	@override String get tunneledPlaybackDescription => '비디오 터널링을 사용합니다. HDR 재생 시 검은 화면이 보이거나 움직임이 끊기면 비활성화하세요.';
	@override String get audioPassthrough => '오디오 패스스루';
	@override String get audioPassthroughDescription => 'Dolby/DTS 오디오를 재인코딩 없이 리시버나 TV로 전송하여 서라운드 사운드를 유지합니다. 소리가 나지 않으면 비활성화하세요.';
	@override String get audioPassthroughDescriptionApple => 'Dolby Digital Plus(Atmos 포함)에 Apple의 기본 Dolby 디코더를 사용합니다. DTS와 TrueHD는 계속 멀티채널 PCM으로 재생됩니다. 소리가 나지 않으면 비활성화하세요.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Dolby Digital Plus(Atmos 포함)에 Apple의 기본 Dolby 디코더를 사용합니다. iOS, iPadOS, tvOS 26 이상에서는 TrueHD Atmos와 DTS:X가 공간 오디오로 재생됩니다. 그 밖의 DTS 및 TrueHD 트랙은 멀티채널 PCM으로 재생됩니다. 소리가 나지 않으면 비활성화하세요.';
	@override String get audioPassthroughOverriddenByNormalization => '음량 정규화가 켜져 있는 동안 꺼짐';
	@override String get audioChannelLimit => '오디오 채널';
	@override String get audioChannelLimitDescription => '모든 채널을 재생할 수 없는 스피커, 헤드폰 또는 HDMI 환경에 맞게 디코딩된 오디오를 다운믹스합니다';
	@override String get audioChannelLimitOriginal => '원본';
	@override String get audioChannelLimitOriginalDescription => '트랙의 모든 채널을 재생합니다';
	@override String get audioChannelLimitSurround51 => '최대 5.1';
	@override String get audioChannelLimitSurround51Description => '5.1 PCM만 지원하는 TV와 리시버를 위해 7.1을 5.1로 다운믹스합니다. 패스스루에는 영향을 주지 않습니다.';
	@override String get audioChannelLimitStereo => '스테레오';
	@override String get audioChannelLimitStereoDescription => '스테레오 스피커나 헤드폰에 맞게 2채널로 다운믹스합니다. 패스스루가 꺼집니다.';
	@override String get downmixCenterBoost => '센터 채널 부스트';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '부스트 (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '다운믹스 시 음량 정규화';
	@override String get audioDownmixNormalizeDescription => '클리핑을 방지하기 위해 믹스 음량을 낮춥니다. 원래 음량을 유지하려면 끄세요(큰 소리 장면에서 왜곡될 수 있음).';
	@override String get dvConversionMode => 'Dolby Vision 변환';
	@override String get dvConversionModeDescription => 'Dolby Vision Profile 7 파일을 처리하는 방식을 선택합니다.';
	@override String get dvConversionAuto => '자동';
	@override String get dvConversionNative => '네이티브 / 비활성화';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '기기 기능 감지와 일반 폴백 동작을 사용합니다';
	@override String get dvConversionNativeDescription => '네이티브 DV7을 강제하고 DV 변환 재시도를 억제합니다';
	@override String get dvConversionDv81Description => 'Dolby Vision 프로필 8.1로 인라인 RPU 변환을 강제합니다';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision RPU/EL 레이어를 제거하고 일반 HEVC로 제공합니다';
	@override String get experimentalDolbyVision => '실험적 Dolby Vision';
	@override String get experimentalDolbyVisionDescription => '다음 재생에서 실험적 FEL 렌더러를 사용합니다. 별도로 빌드한 엔진이 필요합니다.';
	@override String get dvExperimentUnavailableDescription => '이 실험은 현재 Linux에서만 사용할 수 있습니다.';
	@override String get dvCompatibilityFallback => '호환성 대체 모드';
	@override String get dvCompatibilityFallbackDescription => '실험을 시작할 수 없으면 기본 렌더러를 사용합니다. FEL 데이터가 손실될 수 있습니다.';
	@override String get dvExperimentDiagnostics => '비디오 실험 로그';
	@override String get dvExperimentDiagnosticsDescription => '다음 재생에서 상세 플레이어 로그를 활성화합니다.';
	@override String get disableDolbyVision => 'Dolby Vision 끄기';
	@override String get disableDolbyVisionDescription => '파일에 HDR10 또는 HLG 레이어가 있으면 Dolby Vision 대신 해당 레이어를 재생합니다';
	@override String get hdrSdrConversion => 'HDR을 SDR로 변환';
	@override String get hdrSdrConversionDescription => '디스플레이가 HDR을 표시할 수 없을 때 HDR 동영상을 무엇으로 변환할지 선택합니다.';
	@override String get hdrSdrConversionAuto => '자동';
	@override String get hdrSdrConversionAutoDescription => 'Android 9 이상에서는 기기, 이전 버전에서는 플레이어';
	@override String get hdrSdrConversionDevice => '기기';
	@override String get hdrSdrConversionDeviceDescription => '기기의 비디오 하드웨어가 변환합니다. 가장 빠르지만 색상은 기기에 따라 다릅니다';
	@override String get hdrSdrConversionPlayer => '플레이어';
	@override String get hdrSdrConversionPlayerDescription => '플레이어가 변환합니다. 색상은 일정하지만 저사양 TV 박스에서는 4K가 끊길 수 있습니다';
	@override String get deinterlace => '디인터레이싱';
	@override String get deinterlaceDescription => '인터레이스 비디오의 빗살 무늬 아티팩트를 제거합니다 (mpv 플레이어만 해당)';
	@override String get deinterlaceOff => '끄기';
	@override String get deinterlaceOffDescription => '인터레이스 비디오를 디코딩된 그대로 표시합니다';
	@override String get deinterlaceVideo => '비디오';
	@override String get deinterlaceVideoDescription => '각 필드를 완전한 프레임으로 변환합니다. 스포츠, 뉴스, 콘서트처럼 TV용으로 촬영된 영상에 적합합니다';
	@override String get deinterlaceFilm => '필름';
	@override String get deinterlaceFilmDescription => 'NTSC DVD에서 흔한, 29.97fps로 텔레시네된 영화와 애니메이션의 원본 프레임을 복원합니다. TV용으로 촬영된 영상은 끊겨 보입니다. 라이브 TV에는 비디오 모드가 사용됩니다';
	@override String get requireProfileSelectionOnOpen => '앱 실행 시 프로필 선택';
	@override String get requireProfileSelectionOnOpenDescription => '앱을 열 때마다 프로필 선택 화면을 표시합니다';
	@override String get forceTvMode => 'TV 모드 강제 사용';
	@override String get forceTvModeDescription => 'TV 레이아웃을 강제합니다. 자동 감지되지 않는 기기용입니다. 재시작이 필요합니다.';
	@override String get startInFullscreen => '전체 화면으로 시작';
	@override String get startInFullscreenDescription => '실행 시 Plezy를 전체 화면 모드로 엽니다';
	@override String get exitFullscreenOnPlayerClose => '플레이어를 닫을 때 전체 화면 종료';
	@override String get exitFullscreenOnPlayerCloseDescription => '비디오 플레이어를 닫을 때 자동으로 전체 화면을 종료합니다';
	@override String get autoHidePerformanceOverlay => '성능 오버레이 자동 숨기기';
	@override String get autoHidePerformanceOverlayDescription => '재생 컨트롤과 함께 성능 오버레이를 페이드 처리';
	@override String get showNavBarLabels => '내비게이션 바 라벨 표시';
	@override String get showNavBarLabelsDescription => '내비게이션 바 아이콘 아래에 텍스트 라벨을 표시합니다';
	@override String get startupSection => '시작 섹션';
	@override String get preferredServer => '선호하는 서버';
	@override String get preferredServerDescription => '이 서버의 결과를 우선시하고 모든 연결된 서버를 사용할 수 있도록 유지합니다.';
	@override String get preferredServerAutomatic => '자동';
	@override String get showExploreTab => '둘러보기 탭 표시';
	@override String get showExploreTabDescription => 'Plex Discover와 연결된 트래커의 콘텐츠가 포함된 둘러보기 탭을 표시합니다';
	@override String get hideEmptyLibraries => '빈 도서관을 숨기기';
	@override String get hideEmptyLibrariesDescription => '서버에 의해 보고된 항목의 0을 가진 도서관을 탐색에서 제거합니다.';
	@override String get liveTvDefaultFavorites => '즐겨찾기 채널 기본 설정';
	@override String get liveTvDefaultFavoritesDescription => '라이브 TV를 열 때 즐겨찾기 채널만 표시';
	@override String get general => '일반';
	@override String get generalDescription => '언어, 시작 및 창 동작';
	@override String get languageAndRegion => '언어 및 지역';
	@override String get startup => '시작';
	@override String get display => '디스플레이';
	@override String get libraryAndCards => '라이브러리 및 카드';
	@override String get homeScreen => '홈 화면';
	@override String get navigation => '탐색';
	@override String get window => '창';
	@override String get liveTv => '라이브 TV';
	@override String get player => '플레이어';
	@override String get videoAndDisplay => '비디오 및 디스플레이';
	@override String get audio => '오디오';
	@override String get quality => '화질';
	@override String get subtitles => '자막';
	@override String get seekAndTiming => '탐색 및 타이밍';
	@override String get behavior => '동작';
	@override String get gestures => '제스처';
	@override String get gestureBrightnessSwipe => '밝기 스와이프';
	@override String get gestureBrightnessSwipeDescription => '왼쪽 가장자리에서 위아래로 스와이프하여 밝기를 조절합니다';
	@override String get gestureVolumeSwipe => '볼륨 스와이프';
	@override String get gestureVolumeSwipeDescription => '오른쪽 가장자리에서 위아래로 스와이프하여 볼륨을 조절합니다';
	@override String get gesturePinchToZoom => '핀치 줌';
	@override String get gesturePinchToZoomDescription => '비디오에서 핀치하여 확대하거나 축소합니다';
	@override String get gestureSeekSwipe => '스위프 검색';
	@override String get gestureSeekSwipeDescription => '검색하는 비디오의 왼쪽 또는 오른쪽으로 스위치; 던지기 위해 릴리스';
	@override String get rememberBrightnessLevel => '밝기 수준 기억';
	@override String get rememberBrightnessLevelDescription => '마지막으로 스와이프하여 설정한 밝기로 재생을 시작합니다';
	@override String get controls => '컨트롤';
	@override String get rememberPlayerChanges => '플레이어 변경 사항 기억';
	@override String get rememberPlayerChangesDescription => '재생 중 변경한 사항을 저장하고 다시 적용할 위치';
	@override String get scopePlaybackSpeed => '재생 속도';
	@override String get scopeShaderPreset => '셰이더 프리셋';
	@override String get scopeAspectRatio => '화면 비율';
	@override String get scopeSyncOffsets => '오디오 및 자막 동기화';
	@override String get playerScopeOff => '저장하지 않음';
	@override String get playerScopeGlobal => '모든 곳';
	@override String get playerScopeLibrary => '라이브러리별';
	@override String get playerScopeTitle => '시리즈 또는 영화별';
	@override String get exportDialogTitle => 'PlezyNG 설정 내보내기';
	@override String get followSystem => '시스템 설정 따르기';
	@override String get followAppLanguage => '인터페이스 언어와 동일하게';
	@override String get regionFormat => '지역별 표시 형식';
	@override String get regionFormatDescription => '날짜, 숫자, 측정 단위의 표시 형식을 선택하세요.';
	@override String get metadataLanguage => '메타데이터 언어';
	@override String get metadataLanguageDescription => '서버가 지원하는 경우 제목과 설명에 사용할 언어입니다. 오디오와 자막 언어는 별도로 설정합니다.';
	@override String get enterFullscreenOnPlaybackStart => '플레이백이 시작되면 전체 스크린을 입력합니다.';
	@override String get enterFullscreenOnPlaybackStartDescription => '플레이백이 시작되면 풀 스크린으로 데스크톱 비디오를 열어보세요.';
	@override String get extendVideoIntoDisplayCutout => '비디오를 디스플레이 Cutout로 확장';
	@override String get extendVideoIntoDisplayCutoutDescription => '전체 스크린 비디오를 안드로이드 휴대폰에서 카메라 절단을 사용하십시오.';
	@override String get languageDescription => 'PlezyNG 컨트롤 및 메시지에 사용되는 언어를 선택하십시오.Follow system tracks your device language.';
	@override String get themeDescription => '앱 전체에 걸쳐 사용되는 색상과 대조를 선택합니다.';
	@override String get libraryDensityDescription => '각 라인에 얼마나 많은 도서관 카드가 적합한지 변경합니다.';
	@override String get displayScaleDescription => '이 차 디스플레이에 있는 인터페이스를 다시 만들고 장치 전체 텍스트 크기를 변경하지 않습니다.';
	@override String get themeSongVolumeDescription => '다른 오디오와 비교하여 테마 노래의 볼륨을 설정합니다.';
	@override String get viewModeDescription => '도서관 항목이 네트워크에 포스터 또는 컴팩트 목록으로 표시되는지 여부를 선택합니다.';
	@override String get gridViewDescription => '도서관 항목을 포스터의 줄과 열로 배열하십시오.';
	@override String get listViewDescription => '수직 목록에서 도서관 항목을 표시하여 항목 당 더 많은 텍스트를 제공합니다.';
	@override String get gridSpacingDescription => '도서관 네트워크에서 포스터 사이의 격차를 설정합니다.';
	@override String get gridSpacingTightDescription => '더 작은 격차로 화면 위에 더 많은 포스터를 적합합니다.';
	@override String get gridSpacingNormalDescription => '포스터 사이의 표준 간격을 사용하십시오.';
	@override String get gridSpacingSpaciousDescription => '더 많은 분리를 위해 포스터 사이에 더 큰 격차를 추가합니다.';
	@override String get episodePosterModeDescription => '에피소드 카드에 어떤 예술 작품이 나타나는지 선택합니다.';
	@override String get seriesPosterDescription => '각 에피소드에 대한 쇼 시리즈 포스터를 사용하십시오.';
	@override String get seasonPosterDescription => '사용할 때 각 에피소드에 대한 시즌 포스터를 사용하십시오.';
	@override String get episodeThumbnailDescription => '사용할 때 에피소드에서 프레임을 사용하십시오.';
	@override String get continueWatchingActionDescription => '계속 시청 카드를 활성화할 때 무슨 일이 일어나는지 선택합니다.';
	@override String get continueWatchingPlayDescription => '즉시 영화 또는 에피소드를 시작합니다.';
	@override String get continueWatchingDetailsDescription => '제목 페이지를 먼저 열어서 세부 사항을 검토하고 행동을 선택할 수 있습니다.';
	@override String get episodeActionDescription => '에피소드 카드를 활성화할 때 무슨 일이 일어나는지 선택합니다.';
	@override String get episodePlayDescription => '즉시 에피소드를 시작합니다.';
	@override String get episodeDetailsDescription => 'Playback 전에 에피소드 페이지를 열어보세요.';
	@override String get contentScreensaverDelayDescription => '예술 작품을 보여주기 전에 PlezyNG가 입력없이 얼마나 오래 기다리는지 선택하십시오.';
	@override String get continueWatchingRowSizeDescription => '계속 관찰 라인에서 카드가 얼마나 큰지 선택하십시오.';
	@override String get rowSizeCompactDescription => '더 작은 카드를 표시하여 더 많은 항목이 라인에 맞게됩니다.';
	@override String get rowSizeStandardDescription => '표준 카드 크기를 사용하십시오.';
	@override String get rowSizeLargeDescription => '더 큰 카드와 더 많은 예술 작품 세부 사항을 표시합니다.';
	@override String get visualEffectsDescription => '이 장치에 대한 애니메이션 및 예술 효과 예산을 선택합니다.';
	@override String get visualEffectsFullDescription => '모든 장치에 완전한 애니메이션 및 예술 작품 효과를 사용하십시오.';
	@override String get startupSectionDescription => 'PlezyNG 시작할 때 어떤 섹션이 열리는지 선택합니다.';
	@override late final _Translations$settings$startupSectionOptions$ko startupSectionOptions = _Translations$settings$startupSectionOptions$ko._(_root);
	@override String get smallSkipDurationDescription => '짧은 뒤쪽으로 이동하는 거리를 설정하고 앞으로 컨트롤을 찾습니다.';
	@override String get largeSkipDurationDescription => '긴 뒤쪽으로 움직이는 거리를 설정하고 앞으로 통제를 찾습니다.';
	@override String get rewindOnResumeDescription => '비디오를 다시 재생할 때 이 금액으로 재생을 이동합니다.';
	@override String get defaultSleepTimerDescription => '잠자리 타이머를 시작할 때 사용되는 초기 기간을 설정합니다.';
	@override String get playNextCountdownDescription => '다음 에피소드를 시작하기 전에 이것을 오랫동안 기다리십시오. 즉시 시작하려면 0으로 설정합니다.';
	@override String get autoSkipDelaySettingDescription => '입력, 크레딧 또는 광고가 자동으로 스파이를 설정할 때 적용됩니다.';
	@override String get downmixCenterBoostDescription => '중앙 채널에서 대화를 높이면 주변 오디오가 스테레오로 혼합됩니다.';
	@override String get displaySwitchDelayDescription => '디스플레이 모드를 변경하기 전에 TV 또는 수신기가 이전 스위치를 완료 할 수 있도록 기다리십시오.';
	@override String get playerBackendDescription => '어떤 재생 엔진이 이 장치에서 비디오를 해독하고 회전하는지 선택합니다.';
	@override String get exoPlayerDescription => '안드로이드의 원주민 Media3 기반 플레이어와 지원되는 하드웨어 경로를 사용하십시오.';
	@override String get mpvDescription => 'MPV를 사용하여 추가 재생, 하위 제목 및 비디오 처리 컨트롤을 표시합니다.';
	@override String get scopeOffDescription => '현재 플레이백 세션에 대한 변경 사항만 유지합니다.';
	@override String get scopeGlobalDescription => '각 도서관 및 제목에 대해 동일한 가치를 다시 사용합니다.';
	@override String get scopeLibraryDescription => '각 도서관에 대한 별도의 가치를 기억하십시오.';
	@override String get scopeTitleDescription => '각 쇼 또는 영화에 대해 별도의 값을 기억하십시오.';
	@override String get specialsOrderingServerDescription => '미디어 서버에 의해 제공되는 에피소드 주문을 유지합니다.';
	@override String get specialsOrderingAirDateDescription => '그들의 날짜에 따라 정기적 인 에피소드 중 특별한 장소.';
	@override String get specialsOrderingLastDescription => '각각의 특별한 장소는 정규 시즌 후에 배치합니다.';
	@override String get skipIntroModeDescription => '입력 마커가 정상적으로 재생하는지, 스키 버튼을 표시하거나 자동으로 스키를 선택합니다.';
	@override String get skipCreditsModeDescription => '크레딧이 정상적으로 재생되는지, 스키 버튼을 표시하거나 자동으로 스키를 선택합니다.';
	@override String get skipAdsModeDescription => '발견된 광고가 정상적으로 재생되는지, 스키 버튼을 표시하거나 자동으로 스키를 선택합니다.';
	@override String get playbackBufferAutoDescription => '활성 플레이어가 정상 버퍼 크기를 선택하도록 허용합니다.';
	@override String get playbackBufferLargeDescription => '재생 전에 더 많은 미디어를 준비하십시오; 이것은 더 많은 메모리를 사용합니다.';
	@override String get playbackBufferExtraLargeDescription => '가장 큰 읽기 넓은 버퍼를 유지하십시오; 이것은 대부분의 메모리를 사용합니다.';
	@override String get defaultQualityDescription => '기본 비디오 해상도를 설정하고 서버가 트랜스코드하는 스트림에 대한 지붕을 비트레이션합니다.';
	@override String get cellularQualityDescription => '장치가 셀룰러만 연결을 사용하는 경우 기본 품질을 초과합니다.';
	@override String get remoteQualityDescription => '원격 연결을 통해 서버에 연결할 때 기본 품질을 초과합니다.';
	@override String get qualityPresetOriginalDescription => '서버가 그것을 트랜스코드하도록 요청하지 않고 사용할 수있는 품질에서 소스를 재생합니다.';
	@override String get qualityPresetTranscodeOptionDescription => '위에서 표시된 해상도와 비트라이트를 사용하여 서버에 변환 된 스트림을 요청하십시오.';
	@override String get qualityPresetSameAsDefaultDescription => '기본 품질에서 선택한 품질을 사용합니다.';
	@override String get musicQualityDescription => '서버에서 요청한 최대 오디오 비트 속도를 설정; 원본은 소스 스트림을 유지합니다.';
	@override String get musicQualityOriginalDescription => '비트라이트 카프 트랜스코드 없이 소스 오디오를 재생합니다.';
	@override String get musicQualityTranscodeOptionDescription => '위에서 표시된 비트 속도 근처에 서버 트랜스코드를 요청하십시오; 실제 출력은 다를 수 있습니다.';
	@override String get maxVolumeInputLabel => '최대 수량 ( % )';
	@override String get checkForUpdatesDescription => '이제 PlezyNG의 새 버전이 사용할 수 있는지 확인하십시오.';
	@override String get appearanceDescription => '앱 테마를 선택하고 도서관 카드, 홈 라인 및 네비게이션을 조정합니다.';
	@override String get prerollLibraryDescription => '영화 프리 롤로 사용할 수있는 클립을 포함하는 도서관을 선택합니다.';
	@override String get prerollSelectionDescription => '선택한 도서관에서 어떤 클립이 영화 전에 재생할 수 있는지 선택합니다.';
	@override String get contentScreensaverDelayOptionDescription => '스크린 저장 예술 작품을 보여주기 전에 입력없이 많은 분을 기다리십시오.';
	@override String get videoCodecOptionDescription => '이 코덱을 지원할 때 직접 재생할 수 있습니다.Unchecked codecs are transcoded by the media server.';
}

// Path: themeEditor
class _Translations$themeEditor$ko extends Translations$themeEditor$en {
	_Translations$themeEditor$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get builtIn => '기본 제공';
	@override String get presets => '프리셋';
	@override String get custom => '사용자 지정';
	@override String get customEmpty => '아직 만들지 않음';
	@override String get editCustom => '사용자 지정 테마 편집';
	@override String get editCustomDescription => '모든 색상을 직접 선택';
	@override String get locked => '인생 접근이 필요합니다';
	@override String get savedLocked => '저장 - 평생 접근을 통해 사용할 수 있습니다';
	@override String get title => '사용자 지정 테마';
	@override String get startFrom => '기반 테마';
	@override String get startFromDescription => '다른 테마의 모든 색상을 복사합니다';
	@override String get colors => '색상';
	@override String get preview => '미리보기';
	@override late final _Translations$themeEditor$slots$ko slots = _Translations$themeEditor$slots$ko._(_root);
	@override String get opacity => '불투명도';
	@override String get hexHint => '#RRGGBB 또는 #AARRGGBB';
	@override String get fromOtherThemes => '다른 테마에서';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$ko contrast = _Translations$themeEditor$contrast$ko._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, 권장 기준 ${minimum}:1 미만';
	@override String get discardTitle => '변경 사항을 버리시겠습니까?';
	@override String get discardMessage => '저장하지 않은 색상 변경 사항이 사라집니다.';
	@override String get discard => '버리기';
	@override String previewCardTitle({required Object number}) => '${number}화';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes}분 남음';
	@override String get previewSwitch => '자동 재생';
	@override String get previewMutedText => '보조 텍스트는 이렇게 표시됩니다';
	@override String get themeSystemDescription => '장치의 모습을 추적하고 빛과 어둠 사이를 자동으로 전환합니다.';
	@override String get themeLightDescription => '어두운 텍스트와 함께 밝은 배경을 사용하십시오.';
	@override String get themeDarkDescription => '밝은 텍스트를 가진 어두운 배경을 사용하십시오.';
	@override String get themeOledDescription => 'OLED 스크린에 빛을 줄이는 가까운 검은 표면을 사용하십시오.';
	@override String get themeEmberDescription => '따뜻한 빨간색과 암버 액센트 색상을 사용하십시오.';
	@override String get themeGlacierDescription => '차가운 파란색 액센트 색상을 사용하십시오.';
	@override String get themeForestDescription => '녹색과 자연적인 강조 색상을 사용하십시오.';
	@override String get themePlumDescription => '바이올렛과 플루미 액센트 색상을 사용합니다.';
	@override String get themePaperDescription => '따뜻한 종이와 같은 표면과 잉크 영감을받은 색상을 사용하십시오.';
	@override String get themeCustomDescription => '사용자 지정 테마 편집기에서 만든 색상 패널을 사용하십시오.';
	@override String get editorDescription => '팔레트 색상을 선택하고, 그것의 색깔, 만족도, 밝기 또는 오파시티를 조정하고, 예비 보기 업데이트를 보시기 전에 저장할 수 있습니다.';
}

// Path: search
class _Translations$search$ko extends Translations$search$en {
	_Translations$search$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get hint => '영화, 시리즈, 음악 등을 검색하세요...';
	@override String get tryDifferentTerm => '다른 검색어를 시도해 보세요';
	@override String get searchYourMedia => '미디어 검색';
	@override String get enterTitleActorOrKeyword => '제목, 배우 또는 키워드를 입력하세요';
	@override String get people => '인물';
}

// Path: hotkeys
class _Translations$hotkeys$ko extends Translations$hotkeys$en {
	_Translations$hotkeys$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName}에 대한 단축키 설정';
	@override String get clearShortcut => '단축키 삭제';
	@override String get noShortcutSet => '설정된 단축키 없음';
	@override String get currentShortcut => '현재 단축키:';
	@override String get pressToRecord => '단축키를 기록하려면 선택';
	@override String get recordingShortcut => '지금 단축키를 누르세요';
	@override late final _Translations$hotkeys$actions$ko actions = _Translations$hotkeys$actions$ko._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$ko extends Translations$fileInfo$en {
	_Translations$fileInfo$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '파일 정보';
	@override String get overview => '개요';
	@override String get video => '비디오';
	@override String get audio => '오디오';
	@override String get subtitles => '자막';
	@override String get images => '내장 이미지';
	@override String get dataStreams => '데이터 스트림';
	@override String get lyrics => '가사';
	@override String get file => '파일';
	@override String get attachments => '첨부 파일';
	@override String get delivery => '재생 방식';
	@override String versionCounter({required Object index, required Object count}) => '버전 ${index} / ${count}';
	@override String fileCounter({required Object index, required Object count}) => '파일 ${index} / ${count}';
	@override String get noStreams => '서버에서 이 파일에 대한 스트림 정보를 보고하지 않았습니다.';
	@override String get copyPath => '경로 복사';
	@override String get pathCopied => '파일 경로가 복사되었습니다';
	@override String get codec => '코덱';
	@override String get codecTag => '코덱 태그';
	@override String get resolution => '해상도';
	@override String get codedResolution => '코딩 해상도';
	@override String get bitrate => '비트레이트';
	@override String get frameRate => '프레임 속도';
	@override String get rotation => '회전';
	@override String get comment => '주석';
	@override String get audioDescription => '오디오 설명';
	@override String get headerCompression => '헤더 압축';
	@override String get sidecarFile => '사이드카 파일';
	@override String get transportTimestamp => '전송 타임스탬프';
	@override String get displayOffset => '표시 오프셋';
	@override String get previewFailureCode => '미리보기 오류 코드';
	@override String get previewRetries => '미리보기 재시도 횟수';
	@override String get aspectRatio => '종횡비';
	@override String get pixelAspectRatio => '픽셀 종횡비';
	@override String get profile => '프로파일';
	@override String get level => '레벨';
	@override String get bitDepth => '비트 심도';
	@override String get pixelFormat => '픽셀 포맷';
	@override String get colorSpace => '색 공간';
	@override String get colorRange => '색 범위';
	@override String get colorPrimaries => '색 원색';
	@override String get colorTransfer => '색상 전송';
	@override String get chromaSubsampling => '색차 서브샘플링';
	@override String get chromaLocation => '크로마 위치';
	@override String get scanType => '주사 방식';
	@override String get interlaced => '비월 주사';
	@override String get anamorphic => '아나모픽';
	@override String get referenceFrames => '참조 프레임';
	@override String get dynamicRange => '동적 범위';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision 레벨';
	@override String get dolbyVisionVersion => 'Dolby Vision 버전';
	@override String get dolbyVisionLayers => 'Dolby Vision 레이어';
	@override String get baseLayerCompatibility => '베이스 레이어 호환성';
	@override String get avcBitstream => 'AVC 비트스트림';
	@override String get nalLengthSize => 'NAL 길이 크기';
	@override String get scalingMatrix => '사용자 지정 스케일링 매트릭스';
	@override String get streamIdentifier => '스트림 식별자';
	@override String get streamIndex => '스트림 인덱스';
	@override String get streamId => '스트림 ID';
	@override String get language => '언어';
	@override String get languageCode => '언어 코드';
	@override String get streamTitle => '트랙 제목';
	@override String get channels => '채널';
	@override String get sampleRate => '샘플 레이트';
	@override String get spatialAudio => '공간 오디오';
	@override String get textBased => '텍스트 기반';
	@override String get subtitleFormat => '사이드카 포맷';
	@override String get provider => '제공자';
	@override String get matchScore => '일치 점수';
	@override String get externalDelivery => '별도 제공 가능';
	@override String get sidecarPath => '사이드카 경로';
	@override String get sourceStream => '복사 출처';
	@override String get temporary => '임시';
	@override String get timeBase => '시간 기준';
	@override String get overallBitrate => '전체 비트레이트';
	@override String get path => '경로';
	@override String get fileName => '파일 이름';
	@override String get size => '크기';
	@override String get totalSize => '총 크기';
	@override String get container => '컨테이너';
	@override String get duration => '재생 시간';
	@override String get previewThumbnails => '미리보기 썸네일';
	@override String get previewIndex => '미리보기 인덱스';
	@override String get packetLength => '패킷 길이';
	@override String get filePresent => '파일 있음';
	@override String get fileReadable => '서버에서 읽기 가능';
	@override String get streamPath => '스트림 경로';
	@override String get optimizedForStreaming => '스트리밍 최적화';
	@override String get has64bitOffsets => '64비트 오프셋';
	@override String get protocol => '프로토콜';
	@override String get mediaType => '미디어 유형';
	@override String get sourceKind => '소스 종류';
	@override String get optimizedVersion => '최적화 버전';
	@override String get optimizationTarget => '최적화 대상';
	@override String get deletedAt => '삭제됨';
	@override String get remoteSource => '원격 소스';
	@override String get infiniteStream => '무한 스트림';
	@override String get directPlay => 'Direct Play';
	@override String get directStream => 'Direct Stream';
	@override String get transcoding => '트랜스코딩';
	@override String get etag => 'ETag';
	@override String get versionId => '버전 ID';
	@override String get fileId => '파일 ID';
	@override String get defaultAudioTrack => '기본 오디오 트랙';
	@override String get defaultSubtitleTrack => '기본 자막 트랙';
	@override String get subtitlesOff => '꺼짐';
	@override String get flagDefault => '기본';
	@override String get flagForced => '강제';
	@override String get flagSelected => '선택됨';
	@override String get flagExternal => '외부';
	@override String get flagHearingImpaired => '청각 장애인용';
	@override String get flagDub => '더빙';
	@override String get flagOriginal => '원본';
	@override String get channelsMono => '모노';
	@override String dolbyVisionProfile({required Object profile}) => '프로파일 ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$ko extends Translations$mediaMenu$en {
	_Translations$mediaMenu$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '시청 완료로 표시';
	@override String get markAsUnwatched => '미시청으로 표시';
	@override String get removeFromContinueWatching => '계속 보기에서 제거';
	@override String get viewDetails => '상세 정보 보기';
	@override String get goToSeries => '시리즈로 이동';
	@override String get shufflePlay => '무작위 재생';
	@override String get shuffleNotAvailableOffline => '오프라인에서는 무작위 재생을 사용할 수 없습니다';
	@override String get fileInfo => '파일 정보';
	@override String get deleteEpisodeFromServer => '서버에서 에피소드 삭제';
	@override String get deleteSeasonFromServer => '서버에서 시즌 삭제';
	@override String get deleteShowFromServer => '서버에서 프로그램 삭제';
	@override String get deleteMovieFromServer => '서버에서 영화 삭제';
	@override String get deleteEpisodeTitle => '이 에피소드를 삭제할까요?';
	@override String get deleteSeasonTitle => '이 시즌을 삭제할까요?';
	@override String get deleteShowTitle => '이 프로그램을 삭제할까요?';
	@override String get deleteMovieTitle => '이 영화를 삭제할까요?';
	@override String get deleteEpisodeConfirm => '에피소드 삭제';
	@override String get deleteSeasonConfirm => '시즌 삭제';
	@override String get deleteShowConfirm => '프로그램 삭제';
	@override String get deleteMovieConfirm => '영화 삭제';
	@override String get deleteAnyway => '그래도 삭제';
	@override String confirmDeleteTarget({required Object title}) => '서버에서 ${title}을(를) 영구 삭제할까요?';
	@override String get deleteMultipleWarning => '모든 에피소드와 파일이 포함됩니다.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '포함된 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개와 해당 파일이 삭제됩니다.',
		other: '포함된 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개와 해당 파일이 모두 삭제됩니다.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '이 항목은 파일 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개에 저장되어 있으며, 해당 파일이 삭제됩니다.',
		other: '이 항목은 파일 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개에 걸쳐 저장되어 있으며, 모든 파일이 삭제됩니다.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '같은 파일에 저장된 다른 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개도 함께 삭제됩니다:',
		other: '같은 파일에 저장된 다른 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개도 함께 삭제됩니다:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy가 어떤 파일이 삭제될지 확인하지 못해 위 항목보다 더 많은 파일이 삭제될 수 있습니다. 취소하고 다시 시도하거나 그래도 삭제하세요.';
	@override String get deleteScopeUnverifiedNoFileInfo => '서버가 이 항목의 파일 정보를 제공하지 않아 Plezy가 어떤 파일이 삭제될지 확인할 수 없습니다. 위 항목보다 더 많은 파일이 삭제될 수 있습니다.';
	@override String get mediaDeletedSuccessfully => '미디어 항목이 성공적으로 삭제되었습니다';
	@override String get mediaFailedToDelete => '미디어 항목 삭제 실패';
	@override String get rate => '평가';
	@override String get playFromBeginning => '처음부터 재생';
	@override String get playVersion => '버전 재생...';
}

// Path: rateSheet
class _Translations$rateSheet$ko extends Translations$rateSheet$en {
	_Translations$rateSheet$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '평가';
	@override String get server => '서버';
	@override String get favorite => '즐겨찾기';
	@override String get favorited => '즐겨찾기됨';
	@override String get saved => '저장됨';
	@override String get notAvailable => '일치 항목 없음';
	@override String get noConnectedServices => '평가하려면 설정에서 서비스를 연결하세요.';
}

// Path: accessibility
class _Translations$accessibility$ko extends Translations$accessibility$en {
	_Translations$accessibility$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 영화';
	@override String mediaCardShow({required Object title}) => '${title}, TV 프로그램';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '시청 완료';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent}% 시청 완료';
	@override String get mediaCardUnwatched => '미시청';
	@override String get tapToPlay => '탭하여 재생';
	@override String get decrease => '낮추기';
	@override String get increase => '높이기';
	@override String decreaseValue({required Object label}) => '${label} 낮추기';
	@override String increaseValue({required Object label}) => '${label} 높이기';
	@override String get hue => '색조';
	@override String get saturation => '채도';
	@override String get brightness => '밝기';
	@override String get hexColor => '16진수 색상';
	@override String get expandText => '텍스트 펼치기';
	@override String get collapseText => '텍스트 접기';
	@override String get alphabetNavigation => '알파벳 탐색';
	@override String get alphabetScrollHint => '위아래로 스와이프하여 글자별로 이동';
	@override String rowColumnPosition({required Object rowCount, required Object row, required Object columnCount, required Object column}) => '${rowCount}행 중 ${row}행, ${columnCount}열 중 ${column}열';
	@override String rowPosition({required Object rowCount, required Object row}) => '${rowCount}행 중 ${row}행';
	@override String get autoScrollPlay => '자동 스크롤 재생';
	@override String get autoScrollPause => '자동 스크롤 일시정지';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => '빨간색';
	@override String get green => '녹색';
	@override String get blue => '블루';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => '접근성';
	@override String get summary => '텍스트, 대조, 움직임 및 컨트롤';
	@override String get systemHint => '장치의 접근성 설정은 항상 적용됩니다.이 옵션은 PlezyNG에 걸쳐 조정이 추가됩니다.';
	@override String get readability => '읽기 및 시야';
	@override String get textSize => '추가 텍스트 크기';
	@override String get preview => '다음 이야기를 찾아보세요.읽고, 듣고, 자신의 속도로 보세요.';
	@override String get boldText => '용감한 인터페이스 텍스트';
	@override String get highContrast => '높은 대조';
	@override String get highContrastHint => '밝거나 어두운 배경에서 텍스트, 윤곽선 및 포커스 표시를 더 선명하게 보여줍니다.';
	@override String get interaction => '운동과 상호 작용';
	@override String get reduceMotion => '움직임을 줄이기';
	@override String get reduceMotionHint => '포커스 표시, 페이지 전환 및 장식 효과의 움직임을 멈춥니다.';
	@override String get largeTargets => '더 큰 터치 목표';
	@override String get largeTargetsHint => '공통 컨트롤의 영역을 넓혀 터치와 보조 기술을 통한 탐색을 쉽게 합니다.';
	@override String get navigationHint => 'Tab과 Shift+Tab으로 컨트롤 사이를 이동하고, Enter 또는 Space로 실행하고, Escape 또는 뒤로 버튼으로 닫으세요. 책을 열면 확대/축소와 읽기 설정을 사용할 수 있습니다.';
	@override String get textSizeDescription => 'PlezyNG에서 스케일 인터페이스 텍스트는 장치의 시스템 텍스트 크기 설정 외에도.';
	@override String get boldTextHint => '인터페이스 라벨과 메시지에 더 무거운 무게를 사용하여 구별하기 쉽습니다.';
}

// Path: tooltips
class _Translations$tooltips$ko extends Translations$tooltips$en {
	_Translations$tooltips$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '무작위 재생';
	@override String get playTrailer => '예고편 재생';
	@override String get markAsWatched => '시청 완료로 표시';
	@override String get markAsUnwatched => '미시청으로 표시';
}

// Path: audioTracks
class _Translations$audioTracks$ko extends Translations$audioTracks$en {
	_Translations$audioTracks$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => '오디오 트랙 ${n}';
}

// Path: videoControls
class _Translations$videoControls$ko extends Translations$videoControls$en {
	_Translations$videoControls$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '오디오';
	@override String get subtitlesLabel => '자막';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => '레터박스 모드';
	@override String get fillScreen => '화면 채우기';
	@override String get stretch => '확장';
	@override String get lockRotation => '회전 잠금';
	@override String get unlockRotation => '회전 잠금 해제';
	@override String get timerActive => '타이머 활성화됨';
	@override String playbackWillPauseIn({required Object duration}) => '${duration} 후 재생이 일시정지됩니다';
	@override String get sleepTimerEndOfVideo => '현재 비디오의 끝';
	@override String get sleepTimerStopAtHeader => '정지 시점';
	@override String get sleepTimerDurationHeader => '타이머';
	@override String get playbackWillPauseAtEnd => '재생이 이 비디오의 끝에서 일시 중지됩니다';
	@override String get stillWatching => '아직 시청 중이신가요?';
	@override String pausingIn({required Object seconds}) => '${seconds}초 후 일시 정지';
	@override String get continueWatching => '계속';
	@override String get autoPlayNext => '다음 자동 재생';
	@override String get playNext => '다음 재생';
	@override String get playButton => '재생';
	@override String get pauseButton => '일시정지';
	@override String get playbackPaused => '일시정지됨';
	@override String get playbackResumed => '재생 중';
	@override String get loadingVideo => '동영상 로딩 중...';
	@override String get showPlaybackControls => '재생 컨트롤 표시';
	@override String get hidePlaybackControls => '재생 컨트롤 숨기기';
	@override String seekBackwardButton({required Object seconds}) => '${seconds}초 뒤로 이동';
	@override String seekForwardButton({required Object seconds}) => '${seconds}초 앞으로 이동';
	@override String get previousButton => '이전 에피소드';
	@override String get nextButton => '다음 에피소드';
	@override String get previousChapterButton => '이전 챕터';
	@override String get nextChapterButton => '다음 챕터';
	@override String get muteButton => '음소거';
	@override String get unmuteButton => '음소거 해제';
	@override String get settingsButton => '재생 설정';
	@override String get tracksButton => '오디오 및 자막';
	@override String get chaptersButton => '챕터';
	@override String get segmentLoopHelp => '이 재생 중에 섹션을 움직이십시오.A를 설정하고 나중에 B를 타임 라인에 설정합니다.';
	@override String get setLoopStart => '세트 루프 시작 (A)';
	@override String get setLoopEnd => '세트 루프 끝 (B)';
	@override String get clearSegmentLoop => '분명한 세그먼트 루프';
	@override String get setLoopStartFirst => '롤 시작 (A) 전에 끝 (B)을 설정합니다.';
	@override String get loopEndAfterStart => '롤 끝은 시작보다 나중에 있어야합니다.';
	@override String get segmentLoopUnavailable => '세그먼트 루핑은 이 플레이백을 위해 사용할 수 없습니다.';
	@override String get loopPointNotSet => '설정하지 않는';
	@override String get bookmarksHelp => '책표는 이 장치에 저장됩니다.이 시간에 가기 위해 하나를 선택합니다.';
	@override String get bookmarksButton => '책표';
	@override String get chaptersAndBookmarks => '장 및 책표';
	@override String get segmentLoop => '세그먼트 루프';
	@override String get addBookmark => 'Bookmark 추가하기';
	@override String get bookmarkName => 'Bookmark 이름';
	@override String get bookmarkNameHint => '예를 들어, 개방 장면';
	@override String bookmarkDefaultName({required Object n}) => '책표 ${n}';
	@override String get bookmarkNameRequired => '이 책자에 대한 이름을 입력합니다.';
	@override String get deleteBookmark => 'Bookmark 삭제';
	@override String get bookmarkLimitReached => '이 항목은 이미 100 개의 책표를 가지고 있습니다.';
	@override String get bookmarkUnavailable => '이 책을 저장하거나 제거할 수는 없습니다.';
	@override String get bookmarkSaved => '도서관이 저장되었습니다.';
	@override String get bookmarkDeleted => 'Bookmark 삭제됨';
	@override String loopPointSet({required Object point, required Object time}) => '로프 포인트 ${point} 세트 에 ${time}그리고';
	@override String get noChaptersOrBookmarks => '장이나 책표가 없습니다.';
	@override String get versionQualityButton => '버전 및 화질';
	@override String get versionColumnHeader => '버전';
	@override String get qualityColumnHeader => '화질';
	@override String get qualityOriginal => '원본';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => '트랜스코딩을 사용할 수 없음 — 원본 화질로 재생';
	@override String get subtitleUnavailableFallback => '선택한 자막을 불러올 수 없어 자막 없이 재생을 계속합니다';
	@override String get pipButton => '픽처 인 픽처 모드';
	@override String get aspectRatioButton => '화면비율';
	@override String get ambientLighting => '주변 조명';
	@override String get fullscreenButton => '전체 화면';
	@override String get exitFullscreenButton => '전체 화면 종료';
	@override String get alwaysOnTopButton => '창 최상위 고정';
	@override String get rotationLockButton => '회전 잠금';
	@override String get lockScreen => '화면 잠금';
	@override String get screenLockButton => '화면 잠금';
	@override String get timelineSlider => '타임라인';
	@override String get volumeSlider => '볼륨 조절';
	@override String endsAt({required Object time}) => '${time}에 종료';
	@override String get pipActive => '화면 속 화면으로 재생 중';
	@override String get pipFailed => '화면 속 화면 모드를 시작할 수 없습니다';
	@override String get screenshotSaved => '스크린샷 저장됨';
	@override String get screenshotFailed => '스크린샷을 찍지 못했습니다';
	@override String zoomPercent({required Object percent}) => '확대/축소 ${percent}%';
	@override String volumePercent({required Object percent}) => '볼륨 ${percent}%';
	@override late final _Translations$videoControls$pipErrors$ko pipErrors = _Translations$videoControls$pipErrors$ko._(_root);
	@override String get chapters => '챕터';
	@override String get noChaptersAvailable => '사용 가능한 챕터가 없습니다';
	@override String get queue => '재생 대기열';
	@override String get noQueueItems => '대기열에 항목이 없습니다';
	@override String get noAudioDevicesAvailable => '사용 가능한 오디오 기기가 없습니다';
	@override String get searchSubtitles => '자막 검색';
	@override String get language => '언어';
	@override String get noSubtitlesFound => '자막을 찾을 수 없습니다';
	@override String get subtitleDownloaded => '자막이 다운로드되었습니다';
	@override String get subtitleDownloadedNotApplied => '자막을 다운로드했지만 선택할 수 없습니다';
	@override String get subtitleDownloadFailed => '자막 다운로드에 실패했습니다';
	@override String get searchLanguages => '언어 검색...';
	@override String get skipIntro => '인트로 건너뛰기';
	@override String get skipCredits => '크레딧 건너뛰기';
	@override String get nextEpisode => '다음 에피소드';
	@override String subtitleTrack({required Object n}) => '트랙 ${n}';
	@override String subtitleFile({required Object name}) => '자막 ${name}';
	@override String forcedTrack({required Object label}) => '${label} (강제)';
	@override String get osdSubtitlesOff => '자막: 꺼짐';
	@override String osdSubtitles({required Object track}) => '자막: ${track}';
	@override String osdAudio({required Object track}) => '오디오: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 프레임',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 프레임',
	);
	@override String get trackSelectionTitle => '플레이백 전에 트랙을 선택합니다.';
	@override String get trackSelectionAuto => '자동 선택';
	@override String get openMiniPlayer => '오픈 미니 플레이어';
	@override String get returnToFullPlayer => '완전한 플레이어로 돌아가기';
	@override String get loadSubtitleFile => 'Subtitle 파일을 다운로드합니다.';
	@override String get subtitleLoadFailed => 'Subtitle 파일을 다운로드하지 못했습니다.';
	@override String get skipAds => '스키 광고';
	@override String get tapToUnlock => '잠금을 해제하려면 탭하세요';
	@override String get tapAgainToUnlock => '잠금을 해제하려면 다시 탭하세요';
}

// Path: messages
class _Translations$messages$ko extends Translations$messages$en {
	_Translations$messages$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '시청 완료로 표시됨';
	@override String get markedAsUnwatched => '미시청으로 표시됨';
	@override String get markedAsWatchedOffline => '시청 완료로 표시됨 (연결 시 동기화됨)';
	@override String get markedAsUnwatchedOffline => '미시청으로 표시됨 (연결 시 동기화됨)';
	@override String autoRemovedWatchedDownload({required Object title}) => '자동 삭제됨: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '자동 삭제 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 다운로드 보기',
		other: '시청한 다운로드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개를 자동 삭제했습니다',
	);
	@override String get removedFromContinueWatching => '계속 시청 목록에서 제거됨';
	@override String errorLoading({required Object error}) => '오류: ${error}';
	@override String get searchPartialResults => '일부 미디어 서버를 검색하지 못했습니다. 사용 가능한 결과만 표시합니다.';
	@override String get streamInterrupted => '스트림이 중단되었습니다. 재생을 누르거나 탐색하여 다시 시도하세요.';
	@override String get liveStreamInterrupted => '라이브 스트림이 중단되었습니다. 재생을 눌러 다시 시도하세요.';
	@override String get fileInfoNotAvailable => '파일 정보가 없습니다';
	@override String get playbackAuthenticationRequired => '이 항목을 재생하려면 미디어 서버에 다시 로그인하세요.';
	@override String get playbackServerUnavailable => '미디어 서버를 사용할 수 없습니다. 나중에 다시 시도하세요.';
	@override String get playbackDataInvalid => '서버에서 잘못된 재생 정보를 반환했습니다.';
	@override String get playbackCancelled => '재생이 취소되었습니다.';
	@override String get playbackFailed => '재생을 시작할 수 없습니다.';
	@override String playbackFailedDetail({required Object error}) => '재생을 시작할 수 없습니다: ${error}';
	@override String get audioOutputFailed => '오디오 출력이 응답하지 않습니다. TV 또는 리시버의 오디오 연결을 확인하세요. 다른 앱에서도 소리가 나지 않으면 기기를 재시작하세요.';
	@override String get mediaUnavailable => '이 콘텐츠는 더 이상 사용할 수 없습니다.';
	@override String errorLoadingFileInfo({required Object error}) => '파일 정보 로딩 중 오류: ${error}';
	@override String get errorLoadingSeries => '시리즈 로딩 중 오류';
	@override String get musicNotSupported => '음악 재생 미지원';
	@override String get noDescriptionAvailable => '설명이 없습니다';
	@override String get noProfilesAvailable => '사용 가능한 프로필이 없습니다';
	@override String get contactAdminForProfiles => '프로필을 추가하려면 서버 관리자에게 문의하세요';
	@override String get unableToDetermineLibrarySection => '이 항목의 라이브러리 섹션을 확인할 수 없습니다';
	@override String get logsCleared => '로그가 삭제되었습니다';
	@override String get logsCopied => '로그가 클립보드에 복사되었습니다';
	@override String get noLogsAvailable => '사용 가능한 로그가 없습니다';
	@override String libraryScanning({required Object title}) => '"${title}"을(를) 스캔 중입니다...';
	@override String libraryScanStarted({required Object title}) => '"${title}" 미디어 라이브러리 스캔 시작';
	@override String libraryScanFailed({required Object error}) => '미디어 라이브러리 스캔 실패: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" 메타데이터 새로고침 중...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" 메타데이터 새로고침 시작됨';
	@override String metadataRefreshFailed({required Object error}) => '메타데이터 새로고침 실패: ${error}';
	@override String get logoutConfirm => '로그아웃하시겠습니까?';
	@override String get noSeasonsFound => '시즌을 찾을 수 없음';
	@override String get seasonsLoadFailed => '시즌을 불러오지 못했습니다';
	@override String get noEpisodesFound => '시즌 1에서 에피소드를 찾을 수 없습니다';
	@override String get noEpisodesFoundGeneral => '에피소드를 찾을 수 없습니다';
	@override String get episodesLoadFailed => '에피소드를 불러오지 못했습니다';
	@override String get noResultsFound => '결과를 찾을 수 없습니다';
	@override String sleepTimerSet({required Object label}) => '취침 타이머가 ${label}(으)로 설정되었습니다';
	@override String get noItemsAvailable => '사용 가능한 항목이 없습니다';
	@override String get failedToCreatePlayQueueNoItems => '재생 대기열을 만들지 못했습니다 — 항목이 없습니다';
	@override String failedPlayback({required Object action, required Object error}) => '${action}을(를) 수행할 수 없습니다: ${error}';
	@override String get switchingToCompatiblePlayer => '호환되는 플레이어로 전환 중...';
	@override String get serverLimitTitle => '재생 실패';
	@override String get serverLimitBody => '서버 오류(HTTP 500). 대역폭/트랜스코딩 제한으로 세션이 거부된 것 같습니다. 소유자에게 조정을 요청하세요.';
	@override String get mediaUnreadableTitle => '파일을 사용할 수 없음';
	@override String get mediaUnreadableBody => '서버에서 이 항목을 찾았지만 파일을 읽을 수 없습니다(HTTP 404). 파일이 이동되거나 삭제되었거나 저장소가 오프라인 상태일 수 있습니다. 서버 관리자에게 파일 확인과 라이브러리 재스캔을 요청하세요.';
	@override String get serverBusyTitle => '스트림을 사용할 수 없음';
	@override String get serverBusyBody => '서버에서 이 파일의 스트리밍을 계속 거부했습니다(HTTP 503). 서버가 다시 시작 중이거나 사용량이 많을 수 있으며, 파일이 저장된 저장소가 오프라인일 수도 있습니다. 잠시 후 다시 시도하세요. 문제가 계속되면 서버 소유자에게 서버와 파일 저장소를 확인해 달라고 요청하세요.';
	@override String get playbackNotAllowedTitle => '재생이 허용되지 않음';
	@override String get playbackNotAllowedBody => '서버에서 이 항목의 스트리밍을 거부했습니다(HTTP 403). 계정에 재생 권한이 없거나 서버가 로컬 네트워크에서만 재생을 허용할 수 있습니다.';
	@override String get logsUploaded => '로그 업로드 완료';
	@override String get logsUploadFailed => '로그 업로드 실패';
	@override String get logId => '로그 ID';
	@override String get burnedSubtitlesUseMenu => '자막이 이 스트림에 입혀져 있습니다. 자막 메뉴에서 변경하세요.';
	@override String get noVideoUrl => '사용 가능한 비디오 URL이 없습니다';
	@override String get playbackNoMediaSources => '서버에서 재생 가능한 미디어 소스를 반환하지 않았습니다';
	@override String get playbackDataNotPrepared => '재생 데이터가 준비되기 전에 재생이 시작되었습니다';
	@override String get streamSelectionUnavailable => '이 소스에서는 스트림을 선택할 수 없습니다';
	@override String get streamSelectionFailed => '선택한 스트림을 적용할 수 없습니다';
	@override String get trackSelectionNotRemembered => '이 트랙 선택은 현재 재생에만 적용됩니다.';
	@override String get serverUnavailableForProfile => '활성 프로필에 사용할 수 있는 서버가 없습니다';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ko extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get previewSample => '빠른 갈색 엉덩이가 멍청한 개를 뛰어 넘는다.';
	@override String get text => '텍스트';
	@override String get border => '테두리';
	@override String get background => '배경';
	@override String get fontSize => '글자 크기';
	@override String get textColor => '텍스트 색상';
	@override String get borderSize => '테두리 크기';
	@override String get borderColor => '테두리 색상';
	@override String get backgroundOpacity => '배경 불투명도';
	@override String get backgroundColor => '배경색';
	@override String get position => '위치';
	@override String get assOverride => 'ASS 오버라이드';
	@override String get overrideScale => '크기 조정';
	@override String get overrideForce => '강제 적용';
	@override String get overrideStrip => '스타일 제거';
	@override String get positionTop => '위';
	@override String get positionBottom => '아래';
	@override String get useMargins => '여백 사용';
	@override String get useMarginsDescription => '텍스트 자막을 비디오 바깥 영역에 표시할 수 있습니다. 스타일이 적용된 자막은 원래 위치를 유지할 수 있습니다.';
	@override String get anchorToScreen => '화면에 고정';
	@override String get anchorToScreenDescription => '와이드스크린 비디오 아래의 검은 여백에 텍스트 자막을 표시합니다';
	@override String get bold => '굵게';
	@override String get italic => '기울임꼴';
	@override String get renderResolution => '렌더링 해상도';
	@override String get renderResolutionScreen => '화면 해상도';
	@override String get renderResolutionVideo => '영상 해상도';
	@override String get fontSizeDescription => '이 장치에 서브 텍스트 크기를 설정합니다.';
	@override String get textColorDescription => 'Subtitle 텍스트에 사용되는 색상을 선택합니다.';
	@override String get borderSizeDescription => 'Subtitle 텍스트 주위에 출력의 두께를 설정합니다.';
	@override String get borderColorDescription => '서브 타이틀에 사용되는 색상을 선택합니다.';
	@override String get backgroundColorDescription => '서브 타이틀 텍스트 뒤에 있는 색상을 선택합니다.';
	@override String get backgroundOpacityDescription => '서브 타이틀 배경이 얼마나 투명한지 설정하십시오: 0%는 명확하고 100%는 견고합니다.';
	@override String get positionDescription => '0 %는 비디오의 상단이며 100 %는 바닥입니다.';
	@override String get assOverrideDescription => '플레이어가 ASS 하위 제목에 삽입 된 스타일링을 추적, 조정, 교체 또는 제거하는지 여부를 선택합니다.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$ko assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$ko._(_root);
	@override String get renderResolutionDescription => '이미지와 ASS 서브 타이틀을 라스테리화하는 데 사용되는 해상도를 선택합니다.더 낮은 안드로이드 스케일은 rendering 작업을 줄일 수 있지만 더 부드럽게 보입니다.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$ko renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$ko._(_root);
	@override String get boldDescription => '더 무거운 무게로 서브 타이틀 텍스트를 그리십시오.';
	@override String get italicDescription => '이탈리아어로 발음한 Subtitle 텍스트';
}

// Path: mpvConfig
class _Translations$mpvConfig$ko extends Translations$mpvConfig$en {
	_Translations$mpvConfig$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => '고급 비디오 플레이어 설정';
	@override String get presets => '프리셋';
	@override String get noPresets => '저장된 프리셋이 없습니다';
	@override String get saveAsPreset => '프리셋으로 저장...';
	@override String get presetName => '프리셋 이름';
	@override String get presetNameHint => '이 프리셋의 이름을 입력하세요';
	@override String get loadPreset => '불러오기';
	@override String get deletePreset => '삭제';
	@override String get presetSaved => '프리셋이 저장되었습니다';
	@override String get presetLoaded => '프리셋을 불러왔습니다';
	@override String get presetDeleted => '프리셋이 삭제되었습니다';
	@override String get confirmDeletePreset => '이 프리셋을 삭제하시겠습니까?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => '줄 추가';
	@override String get removeLine => '줄 제거';
	@override String get embeddedVoHint => 'Linux에서는 vo, gpu-context, gpu-api가 무시됩니다. 내장 동영상은 항상 비디오 평면에서 vo=libmpv로 렌더링되며, gpu-next(ArtCNN 같은 컴퓨트 셰이더에 필요)는 내장 방식으로 실행할 수 없습니다.';
}

// Path: dialog
class _Translations$dialog$ko extends Translations$dialog$en {
	_Translations$dialog$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '작업 확인';
}

// Path: profiles
class _Translations$profiles$ko extends Translations$profiles$en {
	_Translations$profiles$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG 프로필 추가';
	@override String get switchingProfile => '프로필 전환 중…';
	@override String get deleteThisProfileTitle => '이 프로필을 삭제하시겠습니까?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName}을(를) 제거합니다. 연결에는 영향이 없습니다.';
	@override String get active => '활성';
	@override String get manage => '관리';
	@override String get delete => '삭제';
	@override String get signOut => '로그아웃';
	@override String get signOutPlexTitle => 'Plex에서 로그아웃하시겠습니까?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} 및 모든 Plex Home 사용자를 제거할까요? 언제든 다시 로그인할 수 있습니다.';
	@override String get signOutPlexDeleteDownloads => '다운로드도 삭제';
	@override String get signOutPlexDeleteDownloadsDescription => '삭제하지 않으면 다운로드가 이 기기에 남아 있다가 이 계정에 다시 로그인하면 다시 표시됩니다.';
	@override String get signedOutPlex => 'Plex에서 로그아웃되었습니다.';
	@override String get signOutFailed => '로그아웃에 실패했습니다.';
	@override String get sectionTitle => '프로필';
	@override String get summarySingle => '관리되는 사용자와 로컬 ID를 혼합하려면 프로필을 추가하세요';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count}개 프로필 · 활성: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count}개 프로필';
	@override String get removeConnectionTitle => '연결을 제거하시겠습니까?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName}의 ${connectionLabel} 접근 권한을 제거합니다. 다른 프로필에는 유지됩니다.';
	@override String get deleteProfileTitle => '프로필을 삭제하시겠습니까?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} 및 해당 연결을 제거합니다. 서버는 계속 사용할 수 있습니다.';
	@override String get profileNameLabel => '프로필 이름';
	@override String get pinProtectionLabel => 'PIN 보호';
	@override String get copyAutomationLink => '복사 Android 자동화 링크';
	@override String get copyAutomationLinkDescription => '이 프로필을 Android 의도 또는 자동화에서 선택합니다. 프로필 PIN 검사는 여전히 적용됩니다.';
	@override String get automationLinkCopied => '프로필 자동화 링크 복사.';
	@override String get pinManagedByPlex => 'PIN은 Plex에서 관리됩니다. plex.tv에서 편집하세요.';
	@override String get noPinSetEditOnPlex => '설정된 PIN이 없습니다. 요구하려면 plex.tv에서 Home 사용자를 편집하세요.';
	@override String get setPin => 'PIN 설정';
	@override String get setPinTitle => 'PIN 설정';
	@override String get confirmPinTitle => 'PIN 확인';
	@override String get pinSet => 'PIN 설정됨';
	@override String get changePin => '변경';
	@override String get removePin => '제거';
	@override String get connectionsLabel => '연결';
	@override String get add => '추가';
	@override String get deleteProfileButton => '프로필 삭제';
	@override String get noConnectionsHint => '연결이 없습니다 — 이 프로필을 사용하려면 하나 추가하세요.';
	@override String get noConnections => '연결 없음';
	@override String get plexHomeAccount => 'Plex Home 계정';
	@override String plexAccountChip({required Object account}) => 'Plex 계정: ${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} 계정의 ${user}';
	@override String get connectionDefault => '기본값';
	@override String connectionAs({required Object displayName}) => '${displayName}(으)로';
	@override String get makeDefault => '기본값으로 설정';
	@override String get removeConnection => '제거';
	@override String get profileRenamed => '프로필 이름이 변경되었습니다.';
	@override String borrowAddTo({required Object displayName}) => '${displayName}에 추가';
	@override String get borrowExplain => '다른 프로필의 연결을 빌립니다. PIN으로 보호된 프로필에는 PIN이 필요합니다.';
	@override String get borrowEmpty => '아직 빌릴 것이 없습니다.';
	@override String get borrowEmptySubtitle => '먼저 다른 프로필에 Plex, Jellyfin 또는 Emby를 연결하세요.';
	@override String get borrowLoadFailed => '사용 가능한 연결을 불러오지 못했습니다. 다시 시도하세요.';
	@override String borrowFromProfile({required Object displayName}) => '${displayName}에서';
	@override String get borrowConnectionBorrowed => '연결을 빌렸습니다.';
	@override String get borrowFailed => '연결을 빌리지 못했습니다.';
	@override String get incorrectPin => 'PIN이 올바르지 않습니다.';
	@override String get incorrectPinTryAgain => 'PIN이 올바르지 않습니다. 다시 시도하세요.';
	@override String get sourceProfileMissingParentAccount => '원본 프로필에 상위 계정이 없습니다.';
	@override String get failedToLoadHomeUsers => 'Plex Home 사용자를 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.';
	@override String get failedToVerifyPin => 'PIN을 확인하지 못했습니다.';
	@override String get newProfile => '새 프로필';
	@override String get profileNameHint => '예: 손님, 어린이, 가족실';
	@override String get pinProtectionOptional => 'PIN 보호 (선택 사항)';
	@override String get pinExplain => '프로필 전환에는 4자리 PIN이 필요합니다.';
	@override String get continueButton => '계속';
	@override String get pinsDontMatch => 'PIN이 일치하지 않습니다';
	@override String get tokenIdentityMismatch => 'Plex 프로필 토큰이 예상과 다른 서버로 확인되었습니다';
	@override String get settingsLocked => '이 프로필에 대한 설정이 잠겨 있습니다.';
	@override String get unlockSettings => '닫기 설정';
	@override String get showExploreForProfile => '이 프로필을 위한 탐색을 보여주기';
	@override String get showExploreForProfileDescription => '이 프로필의 항해에서 Explore를 제거하기 위해 끄십시오.';
}

// Path: connections
class _Translations$connections$ko extends Translations$connections$en {
	_Translations$connections$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '연결';
	@override String get addConnection => '연결 추가';
	@override String get addConnectionSubtitleNoProfile => 'Plex로 로그인하거나 Jellyfin 또는 Emby 서버에 연결';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}에 추가: Plex, Jellyfin, Emby 또는 다른 프로필 연결';
	@override String sessionExpiredOne({required Object name}) => '${name}의 세션이 만료되었습니다';
	@override String sessionExpiredMany({required Object count}) => '${count}개 서버의 세션이 만료되었습니다';
	@override String accessDeniedOne({required Object name}) => '${name}에서 이 계정의 접근을 거부했습니다';
	@override String accessDeniedMany({required Object count}) => '${count}개 서버에서 이 계정의 접근을 거부했습니다';
	@override String get signInAgain => '다시 로그인';
	@override String editMediaBrowserTitle({required Object product}) => '${product} 연결 편집';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName}의 URL을 추가하거나 제거하세요. Plezy는 연결 가능한 URL 중 지연 시간이 가장 낮은 URL을 사용합니다.';
}

// Path: accountPreferences
class _Translations$accountPreferences$ko extends Translations$accountPreferences$en {
	_Translations$accountPreferences$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '계정 기본 설정';
	@override String hubSubtitleSingle({required Object account}) => '${account}에 저장된 오디오, 자막 및 라이브러리 옵션';
	@override String hubSubtitleMultiple({required Object count}) => '${count}개 계정에 저장된 오디오, 자막 및 라이브러리 옵션';
	@override String get pickAccount => '각 계정은 고유한 기본 설정을 저장합니다. 편집할 계정을 선택하세요.';
	@override String get storedOnAccount => '이 옵션은 계정 자체에 저장되므로 해당 계정으로 로그인한 모든 앱에서 사용됩니다 — 다른 기기의 Plezy를 포함합니다.';
	@override String get noAccounts => '구성할 계정이 없습니다';
	@override String get noAccountsHint => 'Plex에 로그인하거나 Jellyfin 또는 Emby 서버에 연결하면 해당 계정에 저장된 기본 설정이 여기에 표시됩니다.';
	@override String get unavailable => '이 계정에 연결할 수 없습니다';
	@override String get loadFailed => '이 기본 설정을 불러올 수 없습니다';
	@override String get noPreference => '기본 설정 없음';
	@override String get notSet => '설정되지 않음';
	@override late final _Translations$accountPreferences$groups$ko groups = _Translations$accountPreferences$groups$ko._(_root);
	@override String get preferredAudioLanguage => '선호 오디오 언어';
	@override String get autoSelectAudio => '언어별로 오디오 선택';
	@override String get autoSelectAudioDescription => '끄면 파일이 기본으로 표시한 오디오 트랙을 유지합니다.';
	@override String get preferredSubtitleLanguage => '선호 자막 언어';
	@override String get subtitleMode => '자막 자동 켜기';
	@override late final _Translations$accountPreferences$subtitleModes$ko subtitleModes = _Translations$accountPreferences$subtitleModes$ko._(_root);
	@override String get subtitleAccessibility => 'SDH 자막';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$ko subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$ko._(_root);
	@override String get forcedSubtitles => '강제 자막';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$ko forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$ko._(_root);
	@override String get displayMissingEpisodes => '누락된 에피소드 표시';
	@override String get displayMissingEpisodesDescription => '서버가 알고 있지만 파일이 없는 에피소드를 나열합니다.';
	@override String get hidePlayedInLatest => '최신 항목에서 시청한 항목 숨기기';
	@override String get hidePlayedInLatestDescription => '이미 시청한 항목은 서버의 최신 행에서 제외합니다.';
	@override String get displayCollectionsView => '컬렉션 보기 표시';
	@override String get displayCollectionsViewDescription => '라이브러리와 함께 서버의 컬렉션 보기를 제공합니다.';
	@override String get rewatchingInNextUp => '재시청한 프로그램을 다음 에피소드에 유지';
	@override String get rewatchingInNextUpDescription => '프로그램을 끝까지 본 뒤 다시 시작하면, 목록에서 제거하는 대신 다음 에피소드가 재시청을 따라갑니다.';
	@override String get watchedIndicator => '시청 표시';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$ko watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$ko._(_root);
	@override String get mediaReviewsVisibility => '평점 및 리뷰';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$ko mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$ko._(_root);
	@override String get preferredAudioLanguageDescription => '서버 또는 플레이어가 자동으로 트랙을 선택할 때이 언어로 오디오 트래크를 선호합니다.';
	@override String get preferredSubtitleLanguageDescription => '자막이 자동으로 선택되면 이 언어에서 자막을 추적하는 것을 선호합니다.';
	@override String get subtitleAccessibilityDescription => '자동 하위 제목 선택 중에 SDH 캡션이 선호되거나 요구되는지 여부를 선택합니다.';
	@override String get forcedSubtitleDescription => '자동 선택 중에 강제 서브 타이틀 트랙이 선호되거나 요구되는지 여부를 선택합니다.';
	@override String get watchedIndicatorDescription => '어떤 미디어 유형이 서버 인터페이스에서 관찰된 체크 마크를 받는지 선택합니다.';
	@override String get mediaReviewsVisibilityDescription => '서버가 미디어 페이지에 표시하는 관객과 비판적 평가를 선택합니다.';
	@override String get subtitleModeDescription => '이 서버 계정에서 하위 제목이 자동으로 켜질 때를 선택합니다.';
	@override String get hubDescription => '이러한 선호도는 미디어 서버 계정에 저장되며 다른 고객에게도 적용될 수 있습니다.';
}

// Path: discover
class _Translations$discover$ko extends Translations$discover$en {
	_Translations$discover$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '둘러보기';
	@override String get noContentAvailable => '사용 가능한 콘텐츠가 없습니다';
	@override String get addMediaToLibraries => '미디어 라이브러리에 미디어를 추가해 주세요';
	@override String get continueWatching => '계속 시청';
	@override String continueWatchingIn({required Object library}) => '${library}에서 계속 시청';
	@override String get nextUp => '다음 에피소드';
	@override String nextUpIn({required Object library}) => '${library}의 다음 에피소드';
	@override String get recentlyAdded => '최근에 추가됨';
	@override String recentlyAddedIn({required Object library}) => '${library}에 최근에 추가됨';
	@override String latestAlbumsIn({required Object library}) => '${library}의 최신 앨범';
	@override String recentlyPlayedIn({required Object library}) => '${library}에서 최근 재생';
	@override String mostPlayedIn({required Object library}) => '${library}에서 가장 많이 재생';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => '개요';
	@override String get cast => '출연진';
	@override late final _Translations$discover$findNext$ko findNext = _Translations$discover$findNext$ko._(_root);
	@override String get extras => '예고편 및 부가영상';
	@override String get studio => '제작사';
	@override String get rating => '연령 등급';
	@override String get director => '감독';
	@override String get directors => '감독';
	@override String get movie => '영화';
	@override String get tvShow => 'TV 시리즈';
	@override String minutesLeft({required Object minutes}) => '${minutes}분 남음';
	@override String get moreLikeThis => '비슷한 콘텐츠';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 제목',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 타이틀',
	);
	@override late final _Translations$discover$person$ko person = _Translations$discover$person$ko._(_root);
}

// Path: errors
class _Translations$errors$ko extends Translations$errors$en {
	_Translations$errors$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '검색 실패: ${error}';
	@override String get searchUnavailable => '검색이 어떤 미디어 서버에도 연결할 수 없습니다.';
	@override String connectionTimeout({required Object context}) => '${context} 로드 중 연결 시간 초과';
	@override String get connectionFailed => '미디어 서버에 연결할 수 없습니다';
	@override String unableToLoad({required Object context}) => '${context}을(를) 불러올 수 없습니다. 다시 시도하세요.';
	@override String get noClientAvailable => '사용 가능한 클라이언트가 없습니다';
	@override String get pleaseEnterToken => '토큰을 입력해 주세요';
	@override String get invalidToken => '토큰이 유효하지 않습니다';
	@override String failedToVerifyToken({required Object error}) => '토큰을 확인할 수 없습니다: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName}으로 전환할 수 없습니다';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName}을(를) 삭제할 수 없습니다';
	@override String get failedToRate => '평점을 업데이트하지 못했습니다';
	@override String get reasonTimedOut => '연결 시간이 초과되었습니다';
	@override String get reasonUnreachable => '서버에 연결할 수 없습니다';
	@override String get reasonRefused => '서버가 요청을 거부했습니다';
	@override String get reasonNotFound => '항목이 더 이상 서버에 없습니다';
	@override String get reasonServerError => '서버에서 오류가 보고되었습니다';
	@override String get reasonCancelled => '요청이 취소되었습니다';
	@override String get reasonUnexpected => '예기치 않은 오류가 발생했습니다';
}

// Path: libraries
class _Translations$libraries$ko extends Translations$libraries$en {
	_Translations$libraries$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => '우연한 영화를 재생합니다.';
	@override String get randomPickFailed => '이 도서관에서 우연한 영화를 선택할 수 없습니다.';
	@override String get title => '미디어 라이브러리';
	@override String get fallbackTitle => '라이브러리';
	@override String get scanLibraryFiles => '미디어 라이브러리 파일 스캔';
	@override String get scanLibrary => '미디어 라이브러리 스캔';
	@override String get analyze => '분석';
	@override String get analyzeLibrary => '미디어 라이브러리 분석';
	@override String get refreshMetadata => '메타데이터 새로 고침';
	@override String get emptyTrash => '휴지통 비우기';
	@override String emptyingTrash({required Object title}) => '「${title}」의 휴지통을 비우고 있습니다...';
	@override String trashEmptied({required Object title}) => '「${title}」의 휴지통을 비웠습니다';
	@override String failedToEmptyTrash({required Object error}) => '휴지통 비우기 실패: ${error}';
	@override String analyzing({required Object title}) => '"${title}" 분석 중...';
	@override String analysisStarted({required Object title}) => '"${title}" 분석 시작됨';
	@override String failedToAnalyze({required Object error}) => '미디어 라이브러리 분석 실패: ${error}';
	@override String get noLibrariesFound => '미디어 라이브러리 없음';
	@override String get allLibrariesHidden => '모든 라이브러리가 숨겨졌습니다';
	@override String hiddenLibrariesCount({required Object count}) => '숨겨진 라이브러리 (${count})';
	@override String get thisLibraryIsEmpty => '이 미디어 라이브러리는 비어 있습니다';
	@override String get noItemsMatchFilters => '활성화된 필터와 일치하는 항목이 없습니다';
	@override String get resetFilters => '필터 초기화';
	@override String get all => '전체';
	@override String get clearAll => '모두 삭제';
	@override String scanLibraryConfirm({required Object title}) => '「${title}」을(를) 스캔하시겠습니까?';
	@override String analyzeLibraryConfirm({required Object title}) => '「${title}」을(를) 분석하시겠습니까?';
	@override String refreshMetadataConfirm({required Object title}) => '「${title}」의 메타데이터를 새로고침하시겠습니까?';
	@override String emptyTrashConfirm({required Object title}) => '${title}의 휴지통을 비우시겠습니까?';
	@override String get manageLibraries => '미디어 라이브러리 관리';
	@override String get sort => '정렬';
	@override String get sortBy => '정렬 기준';
	@override String get filters => '필터';
	@override String get confirmActionMessage => '이 작업을 실행하시겠습니까?';
	@override String get showLibrary => '미디어 라이브러리 표시';
	@override String get hideLibrary => '미디어 라이브러리 숨기기';
	@override String get libraryOptions => '미디어 라이브러리 옵션';
	@override String get content => '미디어 라이브러리 콘텐츠';
	@override String get selectLibrary => '미디어 라이브러리 선택';
	@override String filtersWithCount({required Object count}) => '필터 (${count})';
	@override String get noRecommendations => '추천 없음';
	@override String get noCollections => '이 미디어 라이브러리에는 컬렉션이 없습니다';
	@override String get noFoldersFound => '폴더를 찾을 수 없습니다';
	@override String get folders => '폴더';
	@override late final _Translations$libraries$tabs$ko tabs = _Translations$libraries$tabs$ko._(_root);
	@override late final _Translations$libraries$groupings$ko groupings = _Translations$libraries$groupings$ko._(_root);
	@override late final _Translations$libraries$filterCategories$ko filterCategories = _Translations$libraries$filterCategories$ko._(_root);
	@override late final _Translations$libraries$sortLabels$ko sortLabels = _Translations$libraries$sortLabels$ko._(_root);
	@override late final _Translations$libraries$advancedFilters$ko advancedFilters = _Translations$libraries$advancedFilters$ko._(_root);
	@override late final _Translations$libraries$selection$ko selection = _Translations$libraries$selection$ko._(_root);
}

// Path: about
class _Translations$about$ko extends Translations$about$en {
	_Translations$about$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '소개';
	@override String get openSourceLicenses => '오픈소스 라이선스';
	@override String versionLabel({required Object version}) => '버전 ${version}';
	@override String get appDescription => 'Flutter로 만든 아름다운 Plex, Jellyfin 및 Emby 클라이언트';
	@override String get viewLicensesDescription => '타사 라이브러리 라이선스 보기';
	@override String get privacyPolicy => '개인정보 처리방침';
}

// Path: serverSelection
class _Translations$serverSelection$ko extends Translations$serverSelection$en {
	_Translations$serverSelection$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})의 서버를 찾을 수 없습니다.';
	@override String failedToLoadServers({required Object error}) => '서버를 로드할 수 없습니다: ${error}';
	@override String get noValidServers => '이 계정에서 사용할 수 있는 서버를 찾지 못했습니다';
}

// Path: hubDetail
class _Translations$hubDetail$ko extends Translations$hubDetail$en {
	_Translations$hubDetail$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '제목';
	@override String get releaseYear => '출시 연도';
	@override String get dateAdded => '추가 날짜';
	@override String get rating => '평점';
	@override String get noItemsFound => '항목이 없습니다';
}

// Path: logs
class _Translations$logs$ko extends Translations$logs$en {
	_Translations$logs$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '로그 지우기';
	@override String get copyLogs => '로그 복사';
	@override String get uploadLogs => '로그 업로드';
	@override String get saveLogs => '파일에 로그를 저장';
	@override String logsSaved({required Object path}) => '기록을 저장할 수 있습니다 ${path}';
	@override String get saveLogsFailed => '로그 파일을 저장할 수 없었습니다.';
}

// Path: startup
class _Translations$startup$ko extends Translations$startup$en {
	_Translations$startup$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy를 시작하지 못했습니다';
	@override String get failedBody => '시작 중 문제가 발생했습니다. 아래 세부 정보에서 실패 원인을 확인할 수 있습니다.';
	@override String get failedBodyRepairable => 'Plezy의 저장된 설정 파일이 손상되어 Plezy를 시작하려면 먼저 파일을 다시 만들어야 합니다. 재시도해도 해결되지 않습니다 — 저장소 복구를 선택하세요.';
	@override String get phaseLabel => '단계';
	@override String get showDetails => '세부 정보 표시';
	@override String get hideDetails => '세부 정보 숨기기';
	@override String get copyDetails => '세부 정보 복사';
	@override String get detailsCopied => '세부 정보가 클립보드에 복사되었습니다';
	@override String get uploadDetails => '세부 정보 업로드';
	@override String get repairStorage => '저장소 복구';
	@override String get repairTitle => '저장된 데이터를 복구할까요?';
	@override String get repairBodyCommon => 'Plezy의 설정 파일이 손상되어 읽을 수 없습니다. 복구하면 모든 설정이 기본값으로 재설정됩니다.';
	@override String get repairBodyOneCredential => '저장된 로그인 정보 하나가 손상되어 읽을 수 없습니다. 복구하면 해당 로그인 정보만 제거되며 다른 설정은 그대로 유지됩니다.';
	@override String get repairBodySignInsKept => '서버와 프로필은 로그인 상태가 유지됩니다.';
	@override String get repairBodySignInsLost => '저장된 로그인 정보를 보호하는 키를 이 파일에서 복구할 수 없어 모든 서버와 프로필에 다시 로그인해야 합니다. 미디어 서버의 데이터에는 영향이 없습니다.';
	@override String get repairBodySessionsUncertain => '트래커(MAL, AniList, Simkl, Trakt)와 Seerr는 별도로 저장되며 유지 여부가 확실하지 않습니다. Plezy가 유지된 항목을 정확히 알려줄 것입니다.';
	@override String get repairConfirm => '복구';
	@override String get repairSucceeded => '저장소가 복구되었습니다';
	@override String get repairNeedsRestart => '저장소가 복구되었습니다 — 재시작 필요';
	@override String get restartRequiredBody => '데이터가 복구되었지만 Plezy는 이를 사용하려면 새로 시작해야 합니다. Plezy를 종료한 후 다시 열어주세요.';
	@override String get quitPlezy => 'PlezyNG 종료';
	@override String get repairFailed => '복구 실패';
	@override String get repairKeptSignIns => '서버와 프로필이 계속 로그인 상태입니다.';
	@override String get repairLostSignIns => '저장된 로그인 정보를 보호하는 키를 복구할 수 없었습니다. 모든 서버와 프로필에 다시 로그인해야 합니다.';
	@override String get repairLostSessions => '트래커 또는 Seerr 연결이 하나 이상 끊어져 다시 연결해야 합니다.';
	@override String get backupTitle => '손상된 파일의 복사본이 보관되었습니다';
	@override String get backupWarning => '로그인 자격 증명이 포함되어 있습니다. 업로드하거나 공유하지 마세요.';
	@override String get deleteBackup => '복사본 삭제';
	@override String get backupDeleted => '복사본이 삭제되었습니다.';
	@override String get previousFailureTitle => '지난번에 Plezy를 시작하지 못했습니다';
}

// Path: licenses
class _Translations$licenses$ko extends Translations$licenses$en {
	_Translations$licenses$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '관련 소프트웨어 패키지';
	@override String get license => '라이선스';
	@override String licenseNumber({required Object number}) => '라이선스 ${number}';
	@override String licensesCount({required Object count}) => '${count}개의 라이선스';
}

// Path: navigation
class _Translations$navigation$ko extends Translations$navigation$en {
	_Translations$navigation$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get libraries => '미디어 라이브러리';
	@override String get downloads => '다운로드';
	@override String get liveTv => '실시간 TV';
	@override String get explore => '탐색';
}

// Path: explore
class _Translations$explore$ko extends Translations$explore$en {
	_Translations$explore$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$ko mdblistShelves = _Translations$explore$mdblistShelves$ko._(_root);
	@override String get title => '탐색';
	@override String get selectSource => '소스 선택';
	@override late final _Translations$explore$rows$ko rows = _Translations$explore$rows$ko._(_root);
	@override late final _Translations$explore$status$ko status = _Translations$explore$status$ko._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 에피소드',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}화',
	);
	@override String get cast => '출연진';
	@override String get characters => '캐릭터';
	@override String get addToWatchlist => '관심 목록에 추가';
	@override String get removeFromWatchlist => '관심 목록에서 제거';
	@override String get addedToWatchlist => '관심 목록에 추가했습니다';
	@override String get removedFromWatchlist => '관심 목록에서 삭제했습니다';
	@override String get watchlistUpdateFailed => '관심 목록을 업데이트하지 못했습니다';
	@override String get watchlistNoMatch => '이 항목을 관심 목록과 연결할 수 없습니다';
	@override String get notInLibrary => '라이브러리에 없음';
	@override String get inTheseLibraries => '이 라이브러리에 있음';
	@override String get checkingLibrary => '라이브러리 확인 중...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 서버를 확인할 수 없음',
		other: '서버 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개를 확인할 수 없습니다',
	);
	@override String get emptyTitle => '아직 아무것도 없습니다';
	@override String emptyMessage({required Object source}) => '${source}에 콘텐츠가 추가되면 여기에 표시됩니다.';
	@override String searchHint({required Object source}) => '${source}에서 검색';
	@override String searchEmpty({required Object query}) => '「${query}」에 대한 결과가 없습니다';
	@override String searchPrompt({required Object source}) => '${source}에서 영화와 TV 프로그램을 검색하세요.';
	@override String get searchFailed => '검색에 실패했습니다. 연결을 확인하고 다시 시도하세요.';
	@override late final _Translations$explore$badge$ko badge = _Translations$explore$badge$ko._(_root);
	@override late final _Translations$explore$stats$ko stats = _Translations$explore$stats$ko._(_root);
	@override late final _Translations$explore$season$ko season = _Translations$explore$season$ko._(_root);
	@override late final _Translations$explore$format$ko format = _Translations$explore$format$ko._(_root);
	@override late final _Translations$explore$sourceMaterial$ko sourceMaterial = _Translations$explore$sourceMaterial$ko._(_root);
	@override late final _Translations$explore$creditRole$ko creditRole = _Translations$explore$creditRole$ko._(_root);
	@override late final _Translations$explore$relation$ko relation = _Translations$explore$relation$ko._(_root);
	@override String broadcast({required Object day, required Object time}) => '${day} ${time} 방영';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '${day} ${time} ${timezone} 방영';
	@override late final _Translations$explore$detail$ko detail = _Translations$explore$detail$ko._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 결과',
		other: '결과 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개',
	);
}

// Path: liveTv
class _Translations$liveTv$ko extends Translations$liveTv$en {
	_Translations$liveTv$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '실시간 TV';
	@override String get guide => '편성표';
	@override String get noChannels => '사용 가능한 채널이 없습니다';
	@override String get noDvr => '서버에 DVR이 구성되어 있지 않습니다';
	@override String get serverUnavailable => '라이브 TV 서버를 사용할 수 없습니다.';
	@override String get serverNotConnected => '라이브 TV 서버에 연결되어 있지 않습니다.';
	@override String get noPrograms => '프로그램 데이터가 없습니다';
	@override String get liveStreamFailed => '라이브 스트림 실패';
	@override String get unknownProgram => '알 수 없는 프로그램';
	@override String get timelineLiveProgram => '라이브 프로그램 (플레이백은 이 프로그램 이외의 프로그램이 될 수 있습니다)';
	@override String get timelineBuffer => '버퍼 타임 라인';
	@override String get timelineUnavailable => '시간표가 불가능';
	@override String get timelineEstimated => '값진 플레이백';
	@override String get timelinePending => '재생 위치 이동 대기 중';
	@override String get timelineStale => '일정은 과장될 수 있습니다.';
	@override String get unknownHub => '알 수 없음';
	@override String get unknownError => '알 수 없는 오류';
	@override String channelNumber({required Object number}) => '채널 ${number}';
	@override String get unknownChannel => '알 수 없는 채널';
	@override String get live => '실시간';
	@override String get premiereBadge => '새로운';
	@override String get reloadGuide => '편성표 새로고침';
	@override String get searchGuide => '편성표 검색';
	@override String get searchHint => '채널 및 프로그램 검색';
	@override String searchNoResults({required Object query}) => '「${query}」와(과) 일치하는 항목이 없습니다';
	@override String get channelsSection => '채널';
	@override String get programsSection => '프로그램';
	@override String get now => '지금';
	@override String get today => '오늘';
	@override String get tomorrow => '내일';
	@override String get midnight => '자정';
	@override String get overnight => '심야';
	@override String get morning => '아침';
	@override String get daytime => '낮';
	@override String get evening => '저녁';
	@override String get lateNight => '심야 방송';
	@override String get whatsOn => '지금 방송 중';
	@override String get watchChannel => '채널 시청';
	@override String get favorites => '즐겨찾기';
	@override String get reorderFavorites => '즐겨찾기 순서 변경';
	@override String get noFavoriteChannels => '즐겨찾기 채널 없음';
	@override String get noFavoriteChannelsHint => '모든 채널을 표시한 다음 채널을 길게 눌러 즐겨찾기에 추가하세요.';
	@override String get showAllChannels => '모든 채널 표시';
	@override String get favoritesLoadFailed => '즐겨찾기를 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.';
	@override String get favoritesUpdateFailed => '즐겨찾기를 업데이트할 수 없습니다. 연결을 확인하고 다시 시도하세요.';
	@override String get joinSession => '진행 중인 세션 참여';
	@override String watchFromStart({required Object minutes}) => '처음부터 시청 (${minutes}분 전 시작)';
	@override String get watchLive => '실시간 시청';
	@override String get goToLive => '실시간으로 이동';
	@override String get record => '녹화';
	@override String get recordEpisode => '에피소드 녹화';
	@override String get recordSeries => '시리즈 녹화';
	@override String get recordOptions => '녹화 옵션';
	@override String get saveTo => '저장 위치';
	@override String get recordings => '녹화';
	@override String get scheduledRecordings => '예약됨';
	@override String get recordingRules => '녹화 규칙';
	@override String get noScheduledRecordings => '예약된 녹화 없음';
	@override String get manageRecording => '녹화 관리';
	@override String get cancelRecording => '녹화 취소';
	@override String get cancelRecordingTitle => '이 녹화를 취소할까요?';
	@override String cancelRecordingMessage({required Object title}) => '${title}이(가) 더 이상 녹화되지 않습니다.';
	@override String get deleteRule => '규칙 삭제';
	@override String get deleteRuleTitle => '녹화 규칙을 삭제할까요?';
	@override String deleteRuleMessage({required Object title}) => '${title}의 향후 에피소드는 녹화되지 않습니다.';
	@override String get recordingScheduled => '녹화 예약됨';
	@override String get alreadyScheduled => '이 프로그램은 이미 예약되어 있습니다';
	@override String get dvrAdminRequired => 'DVR 설정은 관리자 계정이 필요합니다';
	@override String get recordingFailed => '녹화를 예약할 수 없습니다';
	@override String get recordingTargetMissing => '녹화 라이브러리를 확인할 수 없습니다';
	@override String get recordNotAvailable => '이 프로그램은 녹화할 수 없습니다';
	@override String get recordingCancelled => '녹화 취소됨';
	@override String get recordingRuleDeleted => '녹화 규칙 삭제됨';
	@override String get processRecordingRules => '규칙 재평가';
	@override String get recordingInProgress => '녹화 중';
	@override String recordingsCount({required Object count}) => '${count}개 예약됨';
	@override String get editRule => '규칙 편집';
	@override String get editRuleAction => '편집';
	@override String get recordingRuleUpdated => '녹화 규칙 업데이트됨';
	@override String get guideReloadRequested => '가이드 새로고침 요청됨';
	@override String get guideReloadFailed => '편성표를 새로고침할 수 없습니다';
	@override String get rulesProcessRequested => '규칙 재평가 요청됨';
	@override String get rulesProcessFailed => '녹화 규칙을 다시 적용할 수 없습니다';
	@override String get recordShow => '프로그램 녹화';
	@override late final _Translations$liveTv$recordSettings$ko recordSettings = _Translations$liveTv$recordSettings$ko._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes}분 후 시작';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product}에서 잘못된 실시간 TV 재생 데이터를 반환했습니다';
	@override String get failedToStartChannel => '실시간 채널을 시작할 수 없습니다';
	@override String get failedToBuildStreamUrl => '스트림 URL을 생성할 수 없습니다';
	@override String playbackStartFailed({required Object reason}) => '채널을 시작하지 못했습니다: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => '채널을 전환하지 못했습니다: ${reason}';
}

// Path: collections
class _Translations$collections$ko extends Translations$collections$en {
	_Translations$collections$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '컬렉션';
	@override String get collection => '컬렉션';
	@override String get empty => '컬렉션이 비어 있습니다';
	@override String get deleteCollection => '컬렉션 삭제';
	@override String deleteConfirm({required Object title}) => '"${title}"을(를) 삭제할까요? 되돌릴 수 없습니다.';
	@override String get deleted => '컬렉션 삭제됨';
	@override String get deleteFailed => '컬렉션 삭제 실패';
	@override String deleteFailedWithError({required Object error}) => '컬렉션 삭제 실패: ${error}';
	@override String get selectCollection => '컬렉션 선택';
	@override String get collectionName => '컬렉션 이름';
	@override String get enterCollectionName => '컬렉션 이름 입력';
	@override String get addedToCollection => '컬렉션에 추가됨';
	@override String get errorAddingToCollection => '컬렉션에 추가 실패';
	@override String get created => '컬렉션 생성됨';
	@override String get removeFromCollection => '컬렉션에서 제거';
	@override String removeFromCollectionConfirm({required Object title}) => '${title}을(를) 이 컬렉션에서 제거하시겠습니까?';
	@override String get removedFromCollection => '컬렉션에서 제거됨';
	@override String get removeFromCollectionFailed => '컬렉션에서 제거 실패';
	@override String removeFromCollectionError({required Object error}) => '컬렉션에서 제거 중 오류 발생: ${error}';
	@override String get searchCollections => '컬렉션 검색...';
}

// Path: playlists
class _Translations$playlists$ko extends Translations$playlists$en {
	_Translations$playlists$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '플레이리스트';
	@override String get playlist => '재생 목록';
	@override String get noPlaylists => '재생 목록을 찾을 수 없습니다';
	@override String get create => '재생 목록 생성';
	@override String get playlistName => '재생 목록 이름';
	@override String get enterPlaylistName => '재생 목록 이름 입력';
	@override String get delete => '재생 목록 삭제';
	@override String get removeItem => '재생 목록에서 항목 제거';
	@override String get smartPlaylist => '스마트 재생 목록';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}개 항목',
	);
	@override String get emptyPlaylist => '이 재생 목록은 비어 있습니다';
	@override String get deleteConfirm => '재생 목록을 삭제하시겠습니까?';
	@override String deleteMessage({required Object name}) => '"${name}"을(를) 삭제하시겠습니까?';
	@override String get created => '재생 목록이 생성되었습니다';
	@override String get deleted => '재생 목록이 삭제되었습니다';
	@override String get itemAdded => '재생 목록에 추가되었습니다';
	@override String get itemRemoved => '재생 목록에서 제거됨';
	@override String get selectPlaylist => '재생 목록 선택';
	@override String get searchPlaylists => '재생 목록 검색...';
	@override String get errorCreating => '재생 목록 생성 실패';
	@override String get errorDeleting => '재생 목록 삭제 실패';
	@override String get errorLoading => '재생 목록 로드 실패';
	@override String get errorAdding => '재생 목록에 추가 실패';
	@override String get errorReordering => '재생 목록 항목 재정렬 실패';
	@override String get errorRemoving => '재생 목록에서 제거 실패';
}

// Path: music
class _Translations$music$ko extends Translations$music$en {
	_Translations$music$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => '앨범으로 이동';
	@override String get goToArtist => '아티스트로 이동';
	@override String get instantMix => '인스턴트 믹스';
	@override String get playNext => '다음에 재생';
	@override String get addToQueue => '대기열에 추가';
	@override String discNumber({required Object n}) => '디스크 ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 트랙',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}곡',
	);
	@override String get nowPlaying => '재생 중';
	@override String playingFrom({required Object title}) => '${title}에서 재생 중';
	@override String get queue => '재생 대기열';
	@override String get clearQueue => '대기열 비우기';
	@override String get lyrics => '가사';
	@override String get visualizer => '시각화';
	@override String get visualizerProfileLoading => '트랙 분석을 읽고...';
	@override String get visualizerAmbientMotion => '환경 운동';
	@override String get visualizerPlexLoudness => 'Plex 소음';
	@override String get visualizerPreviousPreset => '이전 시각적 스타일';
	@override String get visualizerNextPreset => '다음 시각적 스타일';
	@override String get visualizerPresetAurora => '오로라';
	@override String get visualizerPresetBloom => '블루';
	@override String get visualizerPresetOrbitals => '궤도';
	@override String get visualizerPresetPrism => '프리스마스';
	@override String get visualizerPresetTunnel => '터널';
	@override String get visualizerPresetTrackMap => '트랙지도';
	@override String get noLyrics => '가사 없음';
	@override String get sleepTimer => '취침 타이머';
	@override String get sleepTimerEndOfTrack => '곡 종료 시';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}분',
	);
	@override String get stopPlayback => '재생 중지';
	@override String get previousTrack => '이전 곡';
	@override String get nextTrack => '다음 곡';
	@override String get repeat => '반복';
	@override String get repeatAll => '전체 반복';
	@override String get repeatOne => '한 곡 반복';
	@override String get instantMixNoServer => '즉석 믹스에 사용할 수 있는 서버가 없습니다';
	@override String get instantMixFailed => '인스턴트 믹스를 불러오지 못했습니다';
	@override String get instantMixEmpty => '인스턴트 믹스에 트랙이 없습니다';
	@override String noAudioUrl({required Object track}) => '${track}에 사용할 수 있는 오디오 URL이 없습니다';
	@override late final _Translations$music$discography$ko discography = _Translations$music$discography$ko._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$ko extends Translations$watchTogether$en {
	_Translations$watchTogether$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '함께 보기';
	@override String get description => '친구 및 가족과 콘텐츠를 동시에 시청하세요';
	@override String get createRoom => '방 만들기';
	@override String get creatingRoom => '방 만드는 중...';
	@override String get joinRoom => '방 참여';
	@override String get joiningRoom => '방에 참여하는 중...';
	@override String get connecting => '연결 중...';
	@override String get relayPublic => '방은 공개 Open Watch Party 릴레이를 사용합니다.';
	@override String relayCustom({required Object url}) => '방은 ${url}에 있는 내 릴레이를 사용합니다.';
	@override String get recentRooms => '최근 참여한 방';
	@override String get roomActions => '방 작업';
	@override String get renameRoom => '방 이름 변경';
	@override String get removeRoom => '제거';
	@override String get enterRoomCode => '호스트에게 받은 6자리 코드를 입력하세요.';
	@override String get roomCode => '방 코드';
	@override String get paste => '붙여넣기';
	@override String get noCodeInClipboard => '클립보드에 방 코드가 없습니다';
	@override String get copyCode => '코드 복사';
	@override String get codeCopied => '방 코드가 복사되었습니다';
	@override String get shareInvite => '초대 공유';
	@override String get inviteCopied => '초대 메시지가 복사되었습니다. 메시지에 붙여넣으세요.';
	@override String inviteMessage({required Object code}) => 'PlezyNG 함께 보기 방에 초대합니다. \'함께 보기\'를 열고 \'방 참여\'를 선택한 다음 ${code} 코드를 입력하세요.';
	@override String get openSessionControls => '함께 보기 세션 제어 열기';
	@override String get reconnecting => '재연결 중...';
	@override String get reconnectingDescription => '연결이 끊어졌습니다. 자동으로 방에 다시 참여합니다.';
	@override String get connected => '연결됨';
	@override String get disconnected => '연결 끊김';
	@override String get youAreHost => '호스트입니다';
	@override String hostedBy({required Object name}) => '호스트: ${name}';
	@override String get hostControlsPlayback => '호스트 재생 제어';
	@override String get anyoneCanControl => '누구나 재생 제어 가능';
	@override String get roomLocked => '방 잠김';
	@override String get nowPlaying => '지금 재생 중';
	@override String get nothingPlaying => '재생 중인 항목 없음';
	@override String get nothingPlayingHost => '라이브러리에서 아무 콘텐츠나 재생하면 방에 공유됩니다.';
	@override String get nothingPlayingGuest => '호스트가 콘텐츠를 재생하면 여기에서 열립니다.';
	@override String get notShareable => '이 비디오는 카탈로그와 일치하는 항목이 없어 같은 서버에 접근할 수 있는 사람만 재생할 수 있습니다.';
	@override String get searching => '라이브러리에서 이 비디오를 찾는 중...';
	@override String get yourCopy => '내 사본';
	@override String get sharingYourCopy => '내 사본을 공유하는 중';
	@override String playingOtherLength({required Object difference}) => '내 사본 재생 중(${difference})';
	@override String get mismatchTitle => '내 사본의 길이가 다릅니다';
	@override String mismatchDescription({required Object difference}) => '가장 근접한 내 사본이 방의 비디오와 길이가 다릅니다(${difference}). 다른 편집본이나 버전일 수 있습니다.';
	@override String get playAnyway => '그래도 재생';
	@override String get chooseAnotherCopy => '다른 사본 선택';
	@override String get dontPlay => '재생 안 함';
	@override String get unavailableTitle => '이 비디오가 없습니다';
	@override String get unavailableDescription => 'Plezy가 라이브러리에서 이 비디오를 찾지 못했습니다. 직접 사본을 선택하거나 다시 검색하세요.';
	@override String get chooseCopy => '사본 선택';
	@override String get searchAgain => '다시 검색';
	@override String get noCandidates => '라이브러리에서 사본을 찾을 수 없습니다.';
	@override String get choiceFailed => '방에서 이 사본을 재생할 수 없습니다';
	@override String lengthLonger({required Object duration}) => '${duration} 더 김';
	@override String lengthShorter({required Object duration}) => '${duration} 더 짧음';
	@override String get lengthSame => '길이 같음';
	@override String get lengthUnknown => '길이 알 수 없음';
	@override String get joinCurrentPlayback => '현재 재생 참여';
	@override String get joinCurrentPlaybackDescription => '호스트가 현재 시청 중인 콘텐츠로 이동합니다';
	@override String get stopMedia => '모든 참가자의 비디오 중지';
	@override String get syncOffset => '동기화 오프셋';
	@override String get syncOffsetDescription => '비디오가 방보다 앞서거나 뒤처지면 시간을 조정하세요.';
	@override String offsetHint({required Object difference}) => '내 사본이 방의 비디오와 길이가 다릅니다(${difference}).';
	@override String applyDifference({required Object offset}) => '${offset} 적용';
	@override String get offsetMinusSecond => '-1초';
	@override String get offsetMinusTenth => '-100ms';
	@override String get offsetPlusTenth => '+100ms';
	@override String get offsetPlusSecond => '+1초';
	@override String get participants => '참가자';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 참가자',
		other: '참가자 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}명',
	);
	@override String get hostBadge => '호스트';
	@override String nameYou({required Object name}) => '${name}(나)';
	@override String get playerIdle => '대기 중';
	@override String get playerLoading => '로딩 중';
	@override String get playerReady => '준비됨';
	@override String get playerBuffering => '버퍼링 중';
	@override String get matchSearching => '찾는 중';
	@override String get matchMatched => '비디오 있음';
	@override String get matchMismatched => '길이 다름';
	@override String get matchUnavailable => '비디오 없음';
	@override String participantOffset({required Object offset}) => '오프셋 ${offset}';
	@override String get makeHost => '호스트로 지정';
	@override String get makeHostQuestion => '호스트를 이전하시겠습니까?';
	@override String makeHostConfirm({required Object name}) => '${name}님이 재생을 제어하고 모든 참가자의 세션을 이끕니다.';
	@override String get transfer => '이전';
	@override String get removeParticipant => '방에서 내보내기';
	@override String removeParticipantQuestion({required Object name}) => '${name}님을 내보내시겠습니까?';
	@override String removeParticipantConfirm({required Object name}) => '${name}님이 방에서 나가게 됩니다. 방을 잠그지 않으면 코드로 다시 참여할 수 있습니다.';
	@override String get remove => '내보내기';
	@override String get roomSettings => '방 설정';
	@override String get letEveryoneControl => '모든 참가자에게 재생 제어 허용';
	@override String get lockRoom => '방 잠그기';
	@override String get lockRoomDescription => '새 참가자가 참여할 수 없습니다';
	@override String get leaveRoom => '방 나가기';
	@override String get leaveRoomQuestion => '방에서 나가시겠습니까?';
	@override String get leaveRoomConfirm => '방 코드로 다시 참여할 수 있습니다.';
	@override String get leave => '나가기';
	@override String get endRoom => '방 종료';
	@override String get endRoomQuestion => '방을 종료하시겠습니까?';
	@override String get endRoomConfirm => '모든 참가자에게 방이 종료됩니다.';
	@override String get end => '종료';
	@override String get playBlockedTitle => '재생이 시작되지 않았습니다';
	@override String get playBlockedDescription => '재생을 눌러 방 참가자들과 함께 시청을 시작하세요.';
	@override late final _Translations$watchTogether$notices$ko notices = _Translations$watchTogether$notices$ko._(_root);
	@override late final _Translations$watchTogether$ended$ko ended = _Translations$watchTogether$ended$ko._(_root);
	@override late final _Translations$watchTogether$errors$ko errors = _Translations$watchTogether$errors$ko._(_root);
	@override String untitledEpisode({required Object number}) => '${number}화';
}

// Path: downloads
class _Translations$downloads$ko extends Translations$downloads$en {
	_Translations$downloads$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '다운로드';
	@override String get manage => '관리';
	@override String get tvShows => 'TV 프로그램';
	@override String get movies => '영화';
	@override String get music => '음악';
	@override String tracksQueued({required Object count}) => '${count}곡 다운로드 대기 중';
	@override String get noDownloads => '다운로드 없음';
	@override String get noDownloadsDescription => '다운로드한 콘텐츠는 오프라인 시청을 위해 여기에 표시됩니다';
	@override String get downloadNow => '다운로드';
	@override String get deleteDownload => '다운로드 삭제';
	@override String get retryDownload => '다운로드 재시도';
	@override String get downloadQueued => '다운로드 대기 중';
	@override String get downloadResumed => '다운로드를 재개했습니다';
	@override String get serverErrorBitrate => '서버 오류: 파일이 원격 비트레이트 제한을 초과할 수 있습니다';
	@override String get storageFull => '사용 가능한 저장 공간을 보호하기 위해 다운로드를 중지했습니다. 공간을 확보하거나 다른 다운로드 위치를 선택한 후 다시 시도하세요.';
	@override String get storageUnavailable => '사용 가능한 저장 공간을 확인할 수 없어 다운로드를 중지했습니다. 다운로드 위치를 확인한 후 다시 시도하세요.';
	@override String episodesQueued({required Object count}) => '에피소드 ${count}개가 다운로드 대기열에 추가되었습니다';
	@override String get downloadDeleted => '다운로드 삭제됨';
	@override String deleteConfirm({required Object title}) => '이 기기에서 "${title}"을(를) 삭제할까요?';
	@override String get deleteCollectionDownloads => '다운로드 삭제';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '이 기기에서 "${title}"의 모든 다운로드를 삭제할까요?';
	@override String get collectionDownloadsDeleted => '다운로드 삭제됨';
	@override String get cancelledDownloadTitle => '취소된 다운로드';
	@override String get cancelledDownloadMessage => '이 다운로드가 취소되었습니다. 어떻게 하시겠습니까?';
	@override String get allEpisodesAlreadyDownloaded => '모든 에피소드가 이미 다운로드되었습니다';
	@override String get resumeDownload => '다운로드 재개';
	@override String get cancelledDownload => '취소된 다운로드';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} 동기화 중)';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} 다운로드됨 — 클릭하여 완료';
	@override String get partialDownloadClickToComplete => '부분 다운로드됨 — 클릭하여 완료';
	@override String get deleting => '삭제 중...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})';
	@override String get queuedTooltip => '대기 중';
	@override String queuedFilesTooltip({required Object files}) => '대기 중: ${files}';
	@override String get downloadingTooltip => '다운로드 중...';
	@override String downloadingFilesTooltip({required Object files}) => '${files} 다운로드 중';
	@override String get noDownloadsTree => '다운로드 없음';
	@override String get pauseAll => '모두 일시정지';
	@override String get resumeAll => '모두 재개';
	@override String get retryAll => '모두 재시도';
	@override String get retryFailed => '실패한 다운로드 재시도';
	@override String get deleteAll => '모두 삭제';
	@override String get selectVersion => '버전 선택';
	@override String get allEpisodes => '모든 에피소드';
	@override String get unwatchedOnly => '시청하지 않은 것만';
	@override String nextNUnwatched({required Object count}) => '다음 ${count}개 미시청';
	@override String get customAmount => '직접 입력...';
	@override String get customAmountAny => '각각의 수량(일반적으로)';
	@override String get randomEpisodes => '우연한 사건';
	@override String get includeSpecials => '스페셜 포함';
	@override String get howManyEpisodes => '몇 개의 에피소드?';
	@override String get invalidEpisodeCount => '올바른 에피소드 수를 입력하세요.';
	@override String get keepSynced => '동기화 유지';
	@override String get downloadOnce => '한 번만 다운로드';
	@override String keepNUnwatched({required Object count}) => '미시청 ${count}개 유지';
	@override String get editSyncRule => '동기화 규칙 편집';
	@override String get removeSyncRule => '동기화 규칙 제거';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" 동기화를 중단하시겠습니까? 다운로드된 에피소드는 유지됩니다.';
	@override String removeListSyncRuleConfirm({required Object title}) => '"${title}" 동기화를 중지할까요?';
	@override String get deleteSyncRuleDownloads => '연결된 다운로드도 삭제';
	@override String get deleteSyncRuleDownloadsDescription => '다른 동기화 규칙이나 프로필에서 사용하는 다운로드는 유지됩니다.';
	@override String syncRuleCreated({required Object count}) => '동기화 규칙 생성됨 — 미시청 에피소드 ${count}개 유지';
	@override String get syncRuleUpdated => '동기화 규칙 업데이트됨';
	@override String get syncRuleRemoved => '동기화 규칙 제거됨';
	@override String get syncRuleAndDownloadsRemoved => '동기화 규칙과 연결된 다운로드가 삭제되었습니다';
	@override String get syncRuleCleanupBusy => '동기화 규칙이 현재 업데이트 중입니다. 잠시 후 다시 시도하세요.';
	@override String get syncRuleCleanupUnavailable => '연결된 다운로드를 안전하게 확인할 수 없습니다. 서버에 다시 연결한 후 시도하거나, 다운로드를 삭제하지 않고 규칙만 제거하세요.';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title}의 새 에피소드 ${count}개 동기화됨';
	@override String get syncNow => '지금 시너먼트';
	@override String get downloadsUpToDate => '다운로드는 현재까지 진행되고 있습니다.';
	@override String syncComplete({required Object queued, required Object removed}) => '동기화 완료 · ${queued} queued, ${removed} 제거';
	@override String get activeSyncRules => '동기화 규칙';
	@override String get reviewOrphanFiles => '기록이 없는 다운로드 검토';
	@override String get orphanReviewTitle => '기록이 없는 다운로드 검토';
	@override String get orphanReviewDescription => '이 태그가 지정된 파일은 PlezyNG가 관리하는 기본 다운로드 폴더에 있지만, 일치하는 다운로드 기록이나 활성 작업이 없습니다. 삭제하기 전에 목록을 확인하세요.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count}개 파일 · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count}개 파일 삭제';
	@override String get orphanCleanupNone => '기록이 없는 다운로드 파일을 찾지 못했습니다';
	@override String get orphanCleanupFailed => 'PlezyNG에서 관리되는 다운로드 폴더를 안전하게 검색할 수 없습니다. 파일은 삭제되지 않았습니다.';
	@override String get orphanCleanupChanged => '검토 중 다운로드 목록이 변경되었습니다. 정리하기 전에 파일을 다시 확인하세요.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count}개 기록 없는 파일 삭제됨 · ${size} 확보';
	@override String get noSyncRules => '동기화 규칙 없음';
	@override String get manageSyncRule => '동기화 관리';
	@override String get editEpisodeCount => '에피소드 수';
	@override String get editSyncFilter => '동기화 필터';
	@override String get syncAllItems => '모든 항목 동기화 중';
	@override String get syncUnwatchedItems => '시청하지 않은 항목 동기화 중';
	@override String syncRuleServerContext({required Object server, required Object status}) => '서버: ${server} • ${status}';
	@override String get syncRuleAvailable => '사용 가능';
	@override String get syncRuleOffline => '오프라인';
	@override String get syncRuleSignInRequired => '로그인 필요';
	@override String get syncRuleAccessDenied => '접근 거부됨';
	@override String get syncRuleNotAvailableForProfile => '현재 프로필에서 사용할 수 없음';
	@override String get syncRuleUnknownServer => '알 수 없는 서버';
	@override String get syncRuleListCreated => '동기화 규칙이 생성되었습니다';
	@override late final _Translations$downloads$backgroundWarning$ko backgroundWarning = _Translations$downloads$backgroundWarning$ko._(_root);
	@override String get options => '다운로드 옵션';
	@override late final _Translations$downloads$groupings$ko groupings = _Translations$downloads$groupings$ko._(_root);
	@override String get unknownLibrary => '알 수 없는 라이브러리';
	@override String get unknownShow => '알 수 없는 프로그램';
	@override String get unknownSeason => '알 수 없는 시즌';
	@override String get unknownAlbum => '알 수 없는 앨범';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} 완료';
	@override String storageUsed({required Object size}) => '사용된 저장소: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 다운로드',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 다운로드',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 쇼',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 표시',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 영화',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 영화',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 앨범',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 앨범',
	);
	@override String get errorFileNotFound => '파일을 찾을 수 없음(404)';
	@override String get errorDownloadNotAllowed => '서버에서 다운로드를 허용하지 않음(403)';
	@override String get errorDownloadFailed => '다운로드 실패';
	@override String errorDownloadFailedWithReason({required Object reason}) => '다운로드 실패: ${reason}';
	@override String get convertingOnServer => '서버로 변환하는 ...';
	@override String convertingOnServerPercent({required Object percent}) => '서버로 변환 · ${percent}%';
	@override String errorHttpStatus({required Object status}) => '다운로드 실패(HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => '후처리 실패: ${reason}';
	@override String get reasonFileNotSaved => '이 기기에 파일을 저장할 수 없습니다';
	@override String get reasonCannotResume => '일부만 받은 다운로드를 이어서 받을 수 없습니다';
	@override String get reasonDeviceStorageFull => '이 기기의 저장 공간이 부족합니다';
	@override String get notificationDownloading => '다운로드 중...';
	@override String get notificationComplete => '다운로드 완료';
	@override String get notificationPaused => '다운로드 일시 중지';
}

// Path: shaders
class _Translations$shaders$ko extends Translations$shaders$en {
	_Translations$shaders$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '셰이더';
	@override String get noShaderDescription => '비디오 향상 없음';
	@override String get nvscalerDescription => '더 선명한 비디오를 위한 NVIDIA 이미지 스케일링';
	@override String get artcnnVariantNeutral => '중립';
	@override String get artcnnVariantDenoise => '노이즈 제거';
	@override String get artcnnVariantDenoiseSharpen => '노이즈 제거 + 선명화';
	@override String get qualityFast => '빠름';
	@override String get qualityHQ => '고품질';
	@override String get mode => '모드';
	@override String get importShader => '셰이더 가져오기';
	@override String get customShaderDescription => '사용자 정의 GLSL 셰이더';
	@override String get shaderImported => '셰이더를 가져왔습니다';
	@override String get shaderImportFailed => '셰이더 가져오기 실패';
	@override String get deleteShader => '셰이더 삭제';
	@override String deleteShaderConfirm({required Object name}) => '"${name}"을(를) 삭제하시겠습니까?';
}

// Path: companionRemote
class _Translations$companionRemote$ko extends Translations$companionRemote$en {
	_Translations$companionRemote$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '컴패니언 리모컨';
	@override String connectedTo({required Object name}) => '${name}에 연결됨';
	@override String get unknownDevice => '알 수 없는 기기';
	@override late final _Translations$companionRemote$session$ko session = _Translations$companionRemote$session$ko._(_root);
	@override late final _Translations$companionRemote$pairing$ko pairing = _Translations$companionRemote$pairing$ko._(_root);
	@override late final _Translations$companionRemote$remote$ko remote = _Translations$companionRemote$remote$ko._(_root);
	@override late final _Translations$companionRemote$errors$ko errors = _Translations$companionRemote$errors$ko._(_root);
	@override String get closedBeforeAuth => '인증 전에 연결이 종료되었습니다';
}

// Path: videoSettings
class _Translations$videoSettings$ko extends Translations$videoSettings$en {
	_Translations$videoSettings$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => '재생 속도';
	@override String get normalSpeed => '보통';
	@override String sleepTimerActive({required Object duration}) => '활성 (${duration})';
	@override String get zoom => '확대/축소';
	@override String get sleepTimer => '취침 타이머';
	@override String get audioSync => '오디오 동기화';
	@override String get subtitleSync => '자막 동기화';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => '여기서는 HDR을 사용할 수 없습니다. 이 데스크톱 컴포지터 또는 비디오 출력에서 HDR을 전달할 수 없습니다.';
	@override String get hdrToneMapping => 'HDR 톤 매핑';
	@override String get hdrToneMappingCompositor => '컴포지터';
	@override String get hdrToneMappingCompositorDescription => '소스의 HDR 메타데이터를 그대로 전달하고 데스크톱 컴포지터에서 매핑하도록 합니다.';
	@override String get hdrToneMappingPlayer => '플레이어';
	@override String get hdrToneMappingPlayerDescription => '플레이어에서 디스플레이의 최대 밝기에 맞게 매핑한 다음 그 결과를 컴포지터에 전달합니다.';
	@override String get hdrToneMappingFailed => 'HDR 톤 매핑을 변경할 수 없습니다. 이전 모드가 계속 적용됩니다.';
	@override String get audioOutput => '오디오 출력';
	@override String get videoTrack => '비디오 트랙';
	@override String get videoTrackDescription => '표시할 비디오 스트림을 선택합니다. 파일에 대체 비디오 트랙이 있으면 MPV 재생에서 사용할 수 있습니다.';
	@override String get videoTrackDefault => '기본값';
	@override String get videoTrackUnavailable => '사용할 수 있는 대체 비디오 트랙이 없습니다.';
	@override String get videoTrackFailed => '비디오 트랙을 변경하지 못했습니다.';
	@override String videoTrackNumber({required Object id}) => '트랙 ${id}';
	@override String get performanceOverlay => '성능 오버레이';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => '서라운드';
	@override String get audioOutputSpatial => '공간 음향';
	@override String get audioOutputStereo => '스테레오';
	@override String get audioEqualizer => '오디오 균형';
	@override String get audioEqualizerDescription => '10 밴드 평등기 MPV. 오디오 필터는 해독 된 오디오를 사용하고 passthrough를 끄십시오.';
	@override String get audioEqualizerFlat => '플랫';
	@override String get audioEqualizerActive => '사용자 지정';
	@override String get audioEqualizerSaveFailed => '오디오 평등기 설정을 저장할 수 없었습니다.';
	@override String get audioEffectsDescription => '효과는 해독 된 오디오를 사용하여, 그래서 passthrough가 꺼집니다. 방 환경과 스테레오 확장은 MPV 건설 및 트랙';
	@override String get audioStereoWidth => '스테레오 확장';
	@override String get audioSpatializer => '방 환경';
	@override String get audioSpatializerDescription => '조용한 방 반응을 추가하십시오.';
	@override String get audioPitch => '피치 스위트';
	@override String get audioPitchDescription => '속도를 바꾸지 않고 플레이트를 변경합니다. MPV 건설은 포함되어야 합니다. Rubber Band그리고';
	@override String get audioEffectUnavailable => '이 효과는이 트랙에 사용할 수 없습니다 또는 MPV 건설하기';
	@override String get backgroundVideoAudio => '배경 비디오 오디오';
	@override String get backgroundVideoAudioDescription => '플레이어를 떠날 때 비디오 오디오 재생을 유지; 사진이 돌아올 때까지 숨겨져 있습니다. Android은 미디어 재생 알림을 사용합니다.';
	@override String get audioNormalization => '음량 정규화';
	@override String get audioNormalizationDisablesPassthrough => '오디오를 PCM으로 디코딩합니다. 켜져 있는 동안 패스스루가 꺼집니다';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$ko extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get color => '색상';
	@override String get performance => '성능';
	@override String get buffer => '버퍼';
	@override String get app => '앱';
	@override String get decoder => '디코더';
	@override String get rawDecoder => '원본 디코더';
	@override String get tunneling => '터널링';
	@override String get passthrough => '패스스루';
	@override String get aspect => '화면비';
	@override String get rotation => '회전';
	@override String get dvSource => 'DV 소스';
	@override String get dvPath => 'DV 경로';
	@override String get dvRouteDecoder => 'Dolby Vision 디코더';
	@override String get dvRouteDecoderP81 => 'Dolby Vision 디코더 (P7→8.1)';
	@override String get dvRouteBaseLayer => '베이스 레이어';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 베이스 레이어';
	@override String get dvRouteBaseLayerHlg => 'HLG 베이스 레이어';
	@override String get dvRouteBaseLayerSdr => 'SDR 베이스 레이어';
	@override String get dvRouteReshaped => 'RPU 리셰이핑 (gpu-next)';
	@override String get dvRouteFelGraphActive => '실험 P7 FEL 그래픽 (무료)';
	@override String get p7Conversion => 'P7 변환';
	@override String get sampleRate => '샘플 레이트';
	@override String get pixelFormat => '픽셀 형식';
	@override String get hwFormat => 'HW 형식';
	@override String get matrix => '매트릭스';
	@override String get primaries => '원색';
	@override String get transfer => '전송';
	@override String get renderFps => '렌더 FPS';
	@override String get displayFps => '디스플레이 FPS';
	@override String get avSync => 'A/V 동기화';
	@override String get dropped => '드롭됨';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'DV RPU 평균';
	@override String get dvSampleAverage => 'DV 샘플 평균';
	@override String get maxLuma => '최대 휘도';
	@override String get minLuma => '최소 휘도';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => '사용 캐시';
	@override String get cacheLimit => '캐시 제한';
	@override String get speed => '속도';
	@override String get player => '플레이어';
	@override String get playMethod => '게임 방법';
	@override String get memory => '메모리';
	@override String get uiFps => 'UI FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => '소프트웨어';
	@override String get decoderHardware => '하드웨어';
	@override String get tunnelingActive => '활성';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures}개 실패)';
}

// Path: externalPlayer
class _Translations$externalPlayer$ko extends Translations$externalPlayer$en {
	_Translations$externalPlayer$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '외부 플레이어';
	@override String get useExternalPlayer => '외부 플레이어 사용';
	@override String get useExternalPlayerDescription => '동영상을 다른 앱에서 열기';
	@override String get selectPlayer => '플레이어 선택';
	@override String get customPlayers => '사용자 정의 플레이어';
	@override String get systemDefault => '시스템 기본값';
	@override String get addCustomPlayer => '사용자 정의 플레이어 추가';
	@override String get playerName => '플레이어 이름';
	@override String get playerNameHint => '내 플레이어';
	@override String get playerCommand => '명령어';
	@override String get playerPackage => '패키지 이름';
	@override String get playerUrlScheme => 'URL 스킴';
	@override String get off => '꺼짐';
	@override String get launchFailed => '외부 플레이어를 열 수 없습니다';
	@override String appNotInstalled({required Object name}) => '${name}이(가) 설치되어 있지 않습니다';
	@override String get playInExternalPlayer => '외부 플레이어에서 재생';
	@override String get description => '다른 앱을 선택하여 비디오를 열 수 있습니다. 이용 가능한 플레이어는 장치와 설치된 앱에 따라 달라집니다.';
	@override String get systemDefaultDescription => '운영 체제가 기본 앱으로 비디오를 열어주십시오.';
	@override String playerOptionDescription({required Object player}) => '${player}와 함께 비디오를 열어보세요.';
	@override String get playerNameDescription => '플레이어 목록에 표시된 레이블.';
	@override String get playerPackageDescription => '플레이어 앱의 안드로이드 패키지 이름, 예를 들어 com.example.player을 입력합니다.';
	@override String get playerCommandDescription => '이 장치에 대한 설치된 플레이어 명령 또는 실행 가능한 경로를 입력합니다.';
	@override String get playerUrlSchemeDescription => 'URL 스케줄과 플레이어를 시작하는 데 사용되는 선택적인 URL 템플릿을 입력합니다.';
}

// Path: metadataEdit
class _Translations$metadataEdit$ko extends Translations$metadataEdit$en {
	_Translations$metadataEdit$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => '편집...';
	@override String get screenTitle => '메타데이터 편집';
	@override String get basicInfo => '기본 정보';
	@override String get artwork => '아트워크';
	@override String get advancedSettings => '고급 설정';
	@override String get title => '제목';
	@override String get sortTitle => '정렬 제목';
	@override String get originalTitle => '원제';
	@override String get releaseDate => '출시일';
	@override String get contentRating => '콘텐츠 등급';
	@override String get studio => '스튜디오';
	@override String get tagline => '태그라인';
	@override String get summary => '줄거리';
	@override String get poster => '포스터';
	@override String get background => '배경';
	@override String get logo => '로고';
	@override String get squareArt => '정사각형 아트';
	@override String get selectPoster => '포스터 선택';
	@override String get selectBackground => '배경 선택';
	@override String get selectLogo => '로고 선택';
	@override String get selectSquareArt => '정사각형 아트 선택';
	@override String get fromUrl => 'URL에서';
	@override String get uploadFile => '파일 업로드';
	@override String get enterImageUrl => '이미지 URL 입력';
	@override String get imageUrl => '이미지 URL';
	@override String get metadataUpdated => '메타데이터가 업데이트되었습니다';
	@override String get metadataUpdateFailed => '메타데이터 업데이트 실패';
	@override String get artworkUpdated => '아트워크가 업데이트되었습니다';
	@override String get artworkUpdateFailed => '아트워크 업데이트 실패';
	@override String get noArtworkAvailable => '사용 가능한 아트워크 없음';
	@override String artworkOption({required Object index}) => '아트워크 옵션 ${index}';
	@override String selectedArtworkOption({required Object index}) => '아트워크 옵션 ${index}, 선택됨';
	@override String get notSet => '설정되지 않음';
	@override String get libraryDefault => '라이브러리 기본값';
	@override String get accountDefault => '계정 기본값';
	@override String get seriesDefault => '시리즈 기본값';
	@override String get episodeSorting => '에피소드 정렬';
	@override String get oldestFirst => '오래된 순';
	@override String get newestFirst => '최신 순';
	@override String get keep => '유지';
	@override String get allEpisodes => '모든 에피소드';
	@override String latestEpisodes({required Object count}) => '최신 에피소드 ${count}개';
	@override String get latestEpisode => '최신 에피소드';
	@override String episodesAddedPastDays({required Object count}) => '최근 ${count}일 내 추가된 에피소드';
	@override String get deleteAfterPlaying => '재생 후 에피소드 삭제';
	@override String get never => '안 함';
	@override String get afterADay => '하루 후';
	@override String get afterAWeek => '일주일 후';
	@override String get afterAMonth => '한 달 후';
	@override String get onNextRefresh => '다음 새로고침 시';
	@override String get seasons => '시즌';
	@override String get show => '표시';
	@override String get hide => '숨기기';
	@override String get episodeOrdering => '에피소드 순서';
	@override String get tmdbAiring => 'The Movie Database (방영순)';
	@override String get tvdbAiring => 'TheTVDB (방영순)';
	@override String get tvdbAbsolute => 'TheTVDB (절대순)';
	@override String get metadataLanguage => '메타데이터 언어';
	@override String get useOriginalTitle => '원제 사용';
	@override String get preferredAudioLanguage => '선호 오디오 언어';
	@override String get preferredSubtitleLanguage => '선호 자막 언어';
	@override String get subtitleMode => '자막 자동 선택 모드';
	@override String get manuallySelected => '수동 선택';
	@override String get shownWithForeignAudio => '외국어 오디오 시 표시';
	@override String get alwaysEnabled => '항상 활성화';
	@override String get tags => '태그';
	@override String get addTag => '태그 추가';
	@override String get genre => '장르';
	@override String get director => '감독';
	@override String get writer => '작가';
	@override String get producer => '프로듀서';
	@override String get country => '국가';
	@override String get collection => '컬렉션';
	@override String get label => '라벨';
	@override String get quickTag => '빠른 태그…';
}

// Path: matchScreen
class _Translations$matchScreen$ko extends Translations$matchScreen$en {
	_Translations$matchScreen$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get match => '일치...';
	@override String get fixMatch => '일치 수정...';
	@override String get unmatch => '일치 해제';
	@override String get unmatchConfirm => '이 매칭을 지울까요? 다시 매칭될 때까지 Plex에서는 미매칭으로 처리됩니다.';
	@override String get unmatchSuccess => '일치 해제됨';
	@override String get unmatchFailed => '일치 해제에 실패했습니다';
	@override String get matchApplied => '일치 적용됨';
	@override String get matchFailed => '일치 적용에 실패했습니다';
	@override String get titleHint => '제목';
	@override String get yearHint => '연도';
	@override String get search => '검색';
	@override String get noMatchesFound => '일치하는 항목이 없습니다';
}

// Path: serverTasks
class _Translations$serverTasks$ko extends Translations$serverTasks$en {
	_Translations$serverTasks$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '서버 작업';
	@override String get failedToLoad => '작업을 불러올 수 없습니다';
	@override String get noTasks => '실행 중인 작업 없음';
}

// Path: trakt
class _Translations$trakt$ko extends Translations$trakt$en {
	_Translations$trakt$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '연결됨';
	@override String connectedAs({required Object username}) => '@${username}(으)로 연결됨';
	@override String get disconnectConfirm => 'Trakt 계정 연결을 끊으시겠습니까?';
	@override String get disconnectConfirmBody => 'Plezy가 Trakt로 이벤트 전송을 중지합니다. 언제든 다시 연결할 수 있습니다.';
	@override String get scrobble => '실시간 스크로블';
	@override String get scrobbleDescription => '재생 중 재생, 일시정지, 정지 이벤트를 Trakt로 전송합니다.';
	@override String get watchedSync => '시청 상태 동기화';
	@override String get watchedSyncDescription => 'Plezy에서 시청 완료로 표시한 항목이 Trakt에도 시청 완료로 표시됩니다.';
}

// Path: seerr
class _Translations$seerr$ko extends Translations$seerr$en {
	_Translations$seerr$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr에 연결';
	@override String get serverUrl => '서버 URL';
	@override String get serverUrlHelper => 'Seerr 인스턴스의 주소';
	@override String get checkServer => '계속';
	@override String get signInWithJellyfin => 'Jellyfin으로 로그인';
	@override String get signInWithEmby => 'Emby로 로그인';
	@override String get signInWithLocal => '로컬 계정 사용';
	@override String get email => '이메일';
	@override String get noSignInMethods => '이 Seerr 인스턴스에는 Plezy가 지원하는 로그인 방법이 없습니다.';
	@override String get instance => '인스턴스';
	@override String get disconnectConfirm => 'Seerr 연결을 해제하시겠습니까?';
	@override String get disconnectConfirmBody => 'Plezy가 이 Seerr 인스턴스를 삭제합니다. 언제든 다시 연결할 수 있습니다.';
	@override String get request => '요청';
	@override String get request4k => '4K로 요청';
	@override String get seasons => '시즌';
	@override String get allSeasons => '모든 시즌';
	@override String get advancedOptions => '고급';
	@override String get destinationServer => '대상 서버';
	@override String get qualityProfile => '화질 프로파일';
	@override String get rootFolder => '루트 폴더';
	@override String get languageProfile => '언어 프로파일';
	@override String get tags => '태그';
	@override String get noTags => '태그 없음';
	@override String defaultOption({required Object name}) => '${name} (기본값)';
	@override String get animeNote => '이 시리즈는 애니메이션입니다.';
	@override String get requestSubmitted => '요청을 제출했습니다';
	@override String requestFailed({required Object error}) => '요청 실패: ${error}';
	@override String get requestsLoadFailed => '요청 옵션을 불러올 수 없습니다';
	@override String get nothingToRequest => '모두 이미 사용 가능하거나 요청되었습니다.';
	@override String get statusAvailable => '사용 가능';
	@override String get statusPartiallyAvailable => '일부 사용 가능';
	@override String get statusRequested => '요청됨';
	@override String get statusProcessing => '처리 중';
	@override String get statusBlocklisted => '차단 목록에 있음';
	@override String couldNotReach({required Object url, required Object error}) => '${url}에 연결할 수 없습니다: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url}에 Seerr 인스턴스가 없습니다(HTTP ${status})';
	@override String get behindAuthProxy => 'Seerr 대신 인증이 필요한 리버스 프록시(SSO 또는 HTTP 인증)가 응답했습니다. Plezy는 이를 통해 로그인할 수 없습니다. 이 앱에서 Seerr의 /api/v1 경로가 프록시를 우회하도록 하거나, Seerr에 직접 연결되는 주소를 사용하세요.';
	@override String get invalidUrl => 'https://seerr.example.com과 같은 서버 주소를 입력하세요';
	@override String get quickConnectUnsupported => '이 Seerr 인스턴스는 Quick Connect를 지원하지 않습니다. Seerr 3.4 이상이 필요합니다.';
	@override String get notInitialized => '이 Seerr 인스턴스는 최초 실행 설정을 완료하지 않았습니다';
	@override String get noPlexTokenForReauth => '다시 로그인하는 데 사용할 수 있는 Plex 토큰이 없습니다';
	@override String get noStoredCredentials => '다시 로그인하는 데 사용할 수 있는 저장된 인증 정보가 없습니다';
	@override String get signInRejected => '로그인이 거부되었습니다';
	@override String get noSessionCookie => 'Seerr에서 세션 쿠키를 발급하지 않았습니다';
	@override String get freshCookieRejected => 'Seerr에서 새 세션 쿠키를 거부했습니다';
	@override String get noUserInformation => 'Seerr에서 사용자 정보를 반환하지 않았습니다';
	@override String get sessionRejectedAfterReauth => '다시 로그인한 후 세션이 거부되었습니다';
	@override String get permissionDenied => 'Seerr가 이 작업을 거부했습니다: 계정에 필요한 권한이 더 이상 없습니다';
	@override String get permissionRevoked => '이 항목을 요청할 권한이 더 이상 없습니다';
}

// Path: services
class _Translations$services$ko extends Translations$services$en {
	_Translations$services$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '서비스';
	@override String get hubSubtitle => '시청 진행률을 동기화하고 새 작품을 요청하세요.';
	@override String get integrations => '연동';
	@override String get notConnected => '연결되지 않음';
	@override String connectedAs({required Object username}) => '@${username}(으)로 연결됨';
	@override String get scrobble => '진행률 자동 추적';
	@override String get scrobbleDescription => '에피소드나 영화를 시청하면 목록을 업데이트합니다.';
	@override String disconnectConfirm({required Object service}) => '${service} 연결을 해제하시겠습니까?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy가 ${service} 업데이트를 중지합니다. 언제든 다시 연결할 수 있습니다.';
	@override String connectFailed({required Object service}) => '${service}에 연결할 수 없습니다. 다시 시도하세요.';
	@override late final _Translations$services$names$ko names = _Translations$services$names$ko._(_root);
	@override late final _Translations$services$simklReconnect$ko simklReconnect = _Translations$services$simklReconnect$ko._(_root);
	@override late final _Translations$services$deviceCode$ko deviceCode = _Translations$services$deviceCode$ko._(_root);
	@override late final _Translations$services$oauthProxy$ko oauthProxy = _Translations$services$oauthProxy$ko._(_root);
	@override late final _Translations$services$pendingAuth$ko pendingAuth = _Translations$services$pendingAuth$ko._(_root);
	@override late final _Translations$services$libraryFilter$ko libraryFilter = _Translations$services$libraryFilter$ko._(_root);
	@override String get seerrDescription => 'Seerr 또는 Overseerr에 연결하여 제목을 검색하고 미디어 요청을 제출합니다.';
	@override late final _Translations$services$trackerDescriptions$ko trackerDescriptions = _Translations$services$trackerDescriptions$ko._(_root);
}

// Path: addServer
class _Translations$addServer$ko extends Translations$addServer$en {
	_Translations$addServer$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product} 서버 추가';
	@override String get serverUrls => '서버 URL';
	@override String get serverUrlsHelper => '쉼표로 구분하여 여러 URL을 입력할 수 있습니다.';
	@override String get findServer => '서버 찾기';
	@override String searchingLocalMediaBrowserServers({required Object product}) => '로컬 ${product} 서버를 찾는 중...';
	@override String localMediaBrowserServers({required Object product}) => '로컬 ${product} 서버';
	@override String get username => '사용자 이름';
	@override String get password => '비밀번호';
	@override String get signIn => '로그인';
	@override String get change => '변경';
	@override String get required => '필수';
	@override String couldNotReachServer({required Object error}) => '서버에 연결할 수 없습니다: ${error}';
	@override String signInFailed({required Object error}) => '로그인 실패: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect 실패: ${error}';
	@override String get addPlexTitle => 'Plex로 로그인';
	@override String get pinExpired => '로그인 전에 PIN이 만료되었습니다. 다시 시도하세요.';
	@override String failedToRegisterAccount({required Object error}) => '계정 등록 실패: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => '${product} 서버 URL을 입력하세요';
	@override String get addConnectionTitle => '연결 추가';
	@override String addConnectionTitleScoped({required Object name}) => '${name}에 추가';
	@override String get signInWithPlexCard => 'Plex로 로그인';
	@override String get signInWithPlexCardSubtitle => '이 기기를 승인합니다. 공유 서버가 추가됩니다.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex 계정을 승인합니다. Home 사용자는 프로필이 됩니다.';
	@override String connectToMediaBrowserCard({required Object product}) => '${product}에 연결';
	@override String get connectToMediaBrowserCardSubtitle => '서버 URL, 사용자 이름, 비밀번호를 입력하세요.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '${product} 서버에 로그인하세요. ${name}에 연결됩니다.';
	@override String get borrowFromAnotherProfile => '다른 프로필에서 빌리기';
	@override String get borrowFromAnotherProfileSubtitle => '다른 프로필의 연결을 재사용합니다. PIN으로 보호된 프로필에는 PIN이 필요합니다.';
	@override String get invalidCredentials => '사용자 이름 또는 비밀번호가 올바르지 않습니다';
	@override String get authResponseNotJson => '인증 응답이 유효한 JSON이 아닙니다';
	@override String get authResponseIncomplete => '서버의 로그인 응답이 불완전합니다';
	@override String get quickConnectRejected => '서버에서 Quick Connect를 거부했습니다';
	@override String get quickConnectNotJson => 'Quick Connect 응답이 유효한 JSON이 아닙니다';
	@override String get quickConnectMissingFields => 'Quick Connect 응답에 코드 또는 비밀 키가 없습니다';
	@override String get quickConnectPollRejected => '서버에서 Quick Connect 폴링을 거부했습니다';
	@override String get serverTimedOut => '서버가 제시간에 응답하지 않았습니다';
	@override String get responseNotJson => '서버 응답이 유효한 JSON이 아닙니다';
	@override String responseMissingIdentity({required Object product}) => '응답에 ID 또는 서버 이름이 없습니다. 이 서버가 ${product} 서버인가요?';
	@override String probeFailed({required Object error}) => '서버에 연결할 수 없습니다: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => '${product} 서버 URL을 하나 이상 입력하세요';
	@override String noReachableServer({required Object product}) => '연결 가능한 ${product} 서버를 찾을 수 없습니다';
	@override String urlsPointToDifferentServers({required Object product}) => '이 URL들은 서로 다른 ${product} 서버를 가리킵니다';
	@override String urlDoesNotMatchServer({required Object product}) => '이 URL은 ${product} 서버와 일치하지 않습니다';
	@override String get redirectUnsupported => '서버가 지원되지 않는 URL로 리디렉션했습니다';
	@override String redirectDifferentHost({required Object product}) => '서버가 다른 호스트로 리디렉션했습니다. 최종 ${product} URL을 직접 입력하세요.';
	@override String get redirectInsecure => '서버가 HTTPS에서 안전하지 않은 URL로 리디렉션했습니다';
	@override String redirectUnsupportedEnterFinal({required Object product}) => '서버가 지원되지 않는 URL로 리디렉션했습니다. 최종 ${product} URL을 직접 입력하세요.';
	@override String get directPlexServerUrl => 'Plex 서버 URL';
	@override String get directPlexServerUrlHelper => 'Plex 미디어 서버의 로컬 IP 및 포트를 입력합니다.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex 토큰 (선택)';
	@override String get plexTokenHelper => 'Auth 없이 액세스할 수 있는 경우 이 서버에서 빈으로 남겨 두십시오.';
	@override String get plexTokenRequired => '확인이 필요합니다. Plex 토큰 (X-Plex-Token)을 입력하시기 바랍니다.';
	@override String get connectDirectPlexCard => 'Plex 미디어 서버 (직접 / 지역)';
	@override String get connectDirectPlexCardSubtitle => 'plex.tv 계정 없이 지역 IP 또는 URL을 사용하여 직접 연결합니다.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'IP 또는 URL을 사용하여 직접 연결합니다. ${name}에 연결합니다.';
	@override String get insecureTitle => '암호화되지 않은 연결';
	@override String insecureDescription({required Object url}) => '${url}은(는) HTTP를 사용합니다. 네트워크의 다른 사용자가 비밀번호, 토큰 및 미디어를 읽거나 변경할 수 있습니다. 가능하면 HTTPS를 사용하세요. 이 네트워크를 신뢰하고 위험을 감수하는 경우에만 계속하세요.';
	@override String get allowHttp => 'HTTP 허용';
	@override String get httpsRequired => 'HTTPS 또는 명시적으로 암호화되지 않은 연결을 허용합니다.';
}

// Path: cast
class _Translations$cast$ko extends Translations$cast$en {
	_Translations$cast$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => '장치에 던져';
	@override String get searching => '기계를 찾는 것에 대한 검색...';
	@override String connectedTo({required Object device}) => '${device}에 연결된';
	@override String get device => '장치 캡처';
	@override String get readyToCast => '던져질 준비';
	@override String get subtitle => '자막';
	@override String get serverNotAvailable => '미디어 서버는 사용할 수 없습니다.';
	@override String get stopCasting => '카스팅을 멈추세요';
	@override String get castToDevice => '장치에 던져';
	@override String get noEpisodeAvailable => '촬영할 에피소드가 없습니다.';
	@override String get startFailed => '캐스트를 시작할 수 없습니다. 서버를 확인하고 다시 시도하세요.';
}

// Path: automation
class _Translations$automation$ko extends Translations$automation$en {
	_Translations$automation$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => '통제할 수 있는 비디오 세션은 없습니다.';
}

// Path: notifications
class _Translations$notifications$ko extends Translations$notifications$en {
	_Translations$notifications$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => '새로운 에피소드';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$ko extends Translations$appAccess$en {
	_Translations$appAccess$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '7일 동안 무료로 모든 기능을 시도해 보세요.';
	@override String get description => '모든 PlezyNG 기능에 대한 완전한 액세스를 가진 7일간의 시험을 시작합니다. 시험 중에는 수수료가 없으며 구독이 없습니다. 시험 후에 매장 가격에 한 생명 구매가 PlezyNG를 생명으로 닫습니다.';
	@override String get trialEndedDescription => '매장 가격에 한 번 구매하여 PlezyNG에서 모든 기능을 잠그십시오.';
	@override String get startTrial => '내 7 일 무료 시험을 시작합니다.';
	@override String get trialActive => '7일간의 완전한 실험은 활성화됩니다.';
	@override String get trialEnded => '7일간의 재판이 끝났다.';
	@override String get trialStartFailed => '이 장치에서 테스트를 저장할 수 없었습니다. 다시 시도해 주십시오.';
	@override String get lifetimeTitle => 'PlezyNG 생명을 위해 잠금을 꺼내';
	@override String get lifetimeBody => '감사합니다!당신은 모든 PlezyNG 기능에 평생 액세스 할 수 있습니다.';
	@override String get manageTitle => 'PlezyNG 평생 액세스';
	@override String get manageDescription => '7 일 동안 모든 기능을 무료로 시도하고, 한 번의 지불으로 매장 가격으로 모든 것을 잠그십시오.';
	@override String buy({required Object price}) => '모든 기능을 ${price}에 대 한 끄기';
	@override String get loadingPrice => '짐 가게 가격...';
	@override String get retryPrice => '리트리 가격 검색';
	@override String get restore => '생명 구매 복원';
	@override String get pending => '귀하의 구매는 지불 또는 승인을 기다리고 있습니다.인생 접근은 상점이 완료되면 잠금됩니다.';
	@override String get storeUnavailable => '구매가 없습니다.이 장치에서 구매가 허용되고 상점에 가입하고 있는지 확인합니다.';
	@override String get productNotFound => 'PlezyNG 생명 잠금은 아직 이 가게에서 사용할 수 없습니다.';
	@override String get productQueryFailed => '가게 가격을 충전 할 수 없습니다. 연결을 확인하고 다시 시도하십시오.';
	@override String get purchaseFailed => '구매가 끝나지 않았는데 다시 한번 시도해 보세요.';
	@override String get restoreFailed => '당신의 구매를 복구하기 위해 상점에 도달 할 수 없습니다.다시 시도하십시오.';
	@override String get nothingToRestore => 'No. PlezyNG 생명 구매는 이 가게 계정에서 찾을 수 있습니다.';
}

// Path: detail
class _Translations$detail$ko extends Translations$detail$en {
	_Translations$detail$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => '${time}에 종료';
}

// Path: watchLink
class _Translations$watchLink$ko extends Translations$watchLink$en {
	_Translations$watchLink$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => '이 링크를 위해 Plex 서버에 접근할 수 없었습니다.';
	@override String get notFound => '이 쇼 또는 영화를 Plex 서버에서 찾을 수 없습니다.';
	@override String get ambiguous => '이 링크는 하나 이상의 서버에 항목과 일치합니다.이 링크에 서버를 추가합니다.';
	@override String get plexOnly => '현재 Plex 서버만 지원하는 링크를 확인합니다.';
	@override String get unsupportedItem => '링크를 볼 수 있는 쇼 또는 영화만 열 수 있습니다.';
	@override String get menuItem => '링크 보기 보기';
	@override String get dialogTitle => '링크 보기';
	@override String get dialogShowHint => '이 링크를 열면 다음 에피소드를 재생합니다. &mode=shuffle을 끝까지 추가하여 shuffle에서 쇼를 재생합니다';
	@override String get dialogMovieHint => '이 링크를 열면 영화를 재생합니다.';
	@override String get copy => '복사본';
	@override String get copied => '링크 복사';
}

// Path: homeLayout
class _Translations$homeLayout$ko extends Translations$homeLayout$en {
	_Translations$homeLayout$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '홈 레이아웃';
	@override String get resetToast => '홈 다시 원래 Plezy 영웅 레이아웃으로 설정';
	@override String get resetHeroTitle => '영웅 레이아웃을 주식으로 다시 설정할 수 있습니까 Plezy?';
	@override String get resetHeroBody => '각 라인의 영웅 설정을 끄고 홈의 상단에있는 단일 회전 밴드를 반환합니다, 영웅 라인이 존재하기 전과 마찬가지입니다.';
	@override String get removeRowTitle => '홈 화면의 행을 삭제할까요?';
	@override String removeRowBody({required Object title}) => '${title} 삭제될 것입니다.이것은 무시할 수 없습니다.';
	@override String get sync => '시나리오';
	@override String get syncAccountTitle => 'Plex 계정과 동기화된 배열';
	@override String get syncAccountOn => '이 장치는 다른 장치와 순서, 순서, 영웅 및 자동 슬라이드를 공유합니다.';
	@override String get syncAccountOff => '끄기: 이 장치는 자신의 레이아웃을 유지합니다.';
	@override String get syncNow => '지금 시너먼트';
	@override String get plexHomeManager => 'Plex 홈 관리자';
	@override String get managePlexRows => '관리 Plex 라인 Plezy';
	@override String get managePlexRowsDescription => '홈 선택된 라인을 조직하기 위해 열려 있습니다.';
	@override String get organizeHomeRows => '홈 라인 조직';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} 라인: 이동, 영웅, 자동 슬라이드, 제거';
	@override String organizeLibraryRows({required Object library}) => '${library} 라인을 조직';
	@override String organizeLibraryRowsDescription({required Object n}) => '계속 보기 + ${n} 라인: 이동, 도서관, 홈, 영웅, 자동 슬라이드';
	@override String get renderAsHero => '영웅 카드로 렌더';
	@override String get heroOnlySingleCollection => '이 순서가 단일 컬렉션의 실제 제목에 해결되면만 사용할 수 있습니다.';
	@override String get hero => '히어로';
	@override String get autoSlide => '자동 슬라이드';
	@override String get autoSlideDescription => '또한 몇 초마다 스스로 슬라이드합니다. 링 (PC) 및 d-pad (TV)는 항상 작동하고 타이머를 다시 시작합니다.';
	@override String get autoSlideEditDescription => '또한 몇 초마다 스스로 슬라이드합니다. 끄기 : 펜 (PC)을 클릭하거나 원격 (TV)에서 왼쪽/오른쪽을 누르면 움직입니다.';
	@override String get enableHeroFirst => '영웅을 먼저 할 수 있습니다.';
	@override String get showOnHome => 'Home 스크린에 표시';
	@override String get home => '홈';
	@override String get removeFromHome => '집에서 제거';
	@override String get selectRowsFirst => '먼저 아래의 홈 라인을 선택합니다.';
	@override String plexManagedRows({required Object n}) => '${n} Plex 관리 라인';
	@override String get continueWatching => '계속 시청';
	@override String get continueWatchingLibraryDescription => '이 도서관의 자체 재구성-진보 순서';
	@override String get continueWatchingHomeDescription => 'Home에 표시된 재현 진행 순서';
	@override String get nextUpHomeDescription => '다음 무시된 에피소드 순서가 집에서 별도로 표시됩니다.';
	@override String get library => '라이브러리';
	@override String get showInRecommended => '추천 도서관에서 제공하는';
	@override String get customPlexRow => '사용자 정의 Plex 라인';
	@override String get heroNeedsLibrary => '도서관을 먼저 확인하십시오 - 영웅은 어디서나 보여줄 필요가 있습니다.';
	@override String get heroNeedsSurface => '도서관 또는 홈을 먼저 확인하십시오 - 영웅은 어디서나 보여야합니다.';
	@override String get removeHub => 'Hub 삭제';
	@override String get noPlexRows => 'No. Plex 관리 라인이 이 도서관에 반환되었습니다.';
	@override String get openDetails => '개방된 세부 사항';
	@override String get heroCards => '영웅 카드';
	@override String get tapHeroCard => '히어로 카드를 탭할 때';
	@override String get tvPlayFocus => 'TV 원격: 히틀러 플레이 버튼';
	@override String get tvPlayFocusDescription => 'D-pad 아래는 다음 라인으로 이동하기 전에 플레이 버튼을 멈추고 다음 라인에 직접 스키를 끄십시오.';
	@override String get tvWrap => 'TV 원격: 롤 영웅 카드';
	@override String get tvWrapDescription => '마지막 카드에 바로 첫 번째 카드로 돌아갑니다. 마지막 카드에서 멈추는. 첫 번째 카드에 왼쪽은 항상 측면 바로 이동합니다.';
	@override String get castOnHero => '영웅의 밴더에 대한 헌신';
	@override String get castOnHeroDescription => '영웅의 바나나의 바닥을 따라 촬영을 보여줍니다.오프는 제목과 요약만 유지합니다.';
	@override String get customRows => 'Custom 라인';
	@override String get loading => '홈 리디렉션을 위한 ...';
	@override String get noCustomRows => '아직 흔적이 없음';
	@override String get addRowHint => 'Home 라인을 추가하여 하나를 만들 수 있습니다.';
	@override String get addHomeRow => 'Home 라인 추가';
	@override String get addHomeRowDescription => '카테고리를 선택; 새 라인은 자동으로 조직에 추가됩니다.';
	@override String get removeRow => '라인 삭제';
	@override String get recentlyAdded => '최근에 추가됨';
	@override String get recentlyReleased => '최근에 출시된';
	@override String get movieCollections => '영화 컬렉션';
	@override String get showCollections => '컬렉션 보기';
	@override String get rowTitle => '로이 제목';
	@override String get content => '흥미로운';
	@override String get showThisRowIn => '이 라인을 보여주십시오 :';
	@override String get libraryRecommended => '추천 도서관';
	@override String get heroCard => '영웅 카드';
	@override String get heroCardDescription => '포스터 셰프 대신 하나의 전체 광장 회전 카드로 표시됩니다.';
	@override String get heroUnavailableDescription => '이 순서가 단일 컬렉션의 실제 제목에 해결될 때만 사용할 수 있습니다 - 선택된 컬렉션 이상이 있는 경우에는 단일 제목이 롤러가 없습니다.';
	@override String get librariesSelection => '도서관 (모든 도서관을 포함하기 위해 모든 검사되지 않은 것을 남겨 두십시오)';
	@override String get librariesMergedDescription => '여기서 확인한 모든 도서관은 이 한 줄에 합쳐집니다.';
	@override String get movieCollectionsSelection => '영화 컬렉션 (모든 선택된 도서관에 대한 모든 검사되지 않은 것을 남겨두십시오)';
	@override String get showCollectionsSelection => '컬렉션을 표시합니다 (선택된 각 도서관에 대한 모든 검사되지 않은 것을 남겨 두십시오)';
	@override String get collectionRowsDescription => '만약 정확히 하나의 컬렉션이 일치한다면, 그 제목이 순서대로 표시됩니다. 만약 하나 이상의 컬렉티션이 일어나면, 각 컬렉션은 단일 포스터로 표시됩니다.';
	@override String get allCollections => '모든 컬렉션';
	@override String get noRowsHere => '아직 여기에는 라인이 없습니다.';
	@override String get hideWatchedRows => '흔들리는 흔들림으로 덮여 있는 물건들';
	@override String get hideWatchedRowsDescription => '완전히 보낸 제목은 홈 및 도서관 추천 라인을 떠나 있습니다.';
	@override String get untitledCollection => '제목 없는 컬렉션';
	@override String get moveRowHint => '위/다운: 이동 순서 · 선택: 여기에서 던져 · 반환: 취소';
	@override String get organizeRowsHint => '좌석/오른쪽: 순서 옵션 · 뒤로: 완료';
	@override String get layoutNavDescription => '라인, 도서관 및 컬렉션 카테고리를 선택합니다.';
	@override String get editHomeRow => '에디트 홈 라인';
	@override String get resetHeroButton => '영웅 레이아웃을 재설정 하 고 주식 Plezy';
	@override String get reorderingUnlocked => '다시 닫힌';
	@override String get reorderingLocked => '잠금을 다시 닫습니다';
	@override String get rowsCanBeDragged => '끈을 끌 수 있습니다 - 잠금을 눌러 그것을 방지합니다.';
	@override String get tapLockToDrag => '닫기 를 눌러 라인을 끌어내기';
	@override String customRowLabel({required Object title}) => '사용자 정의: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => '숨기기';
	@override String get remove => '제거';
	@override String get libraryResumeRow => '이 도서관의 재구성 순서';
	@override String get pressAgainToDelete => '다시 눌러 삭제';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => '에';
	@override String get resetHeroButtonDescription => '각 라인의 영웅 설정을 끄고 영웅 라인이 존재하기 전과 마찬가지로 상단에 단일 회전 밴드를 반환합니다.';
	@override String get tapHeroCardDescription => '영웅 카드를 탭하거나 선택하면 재생이 시작되거나 세부 사항이 열립니다.';
	@override String get heroTapPlayDescription => '선택한 항목을 즉시 시작합니다.';
	@override String get heroTapDetailsDescription => '선택한 항목의 세부 사항을 열기 전에 행동을 선택합니다.';
}

// Path: platform
class _Translations$platform$ko extends Translations$platform$en {
	_Translations$platform$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG은 현지 네트워크에서 미디어 서버 및 플레이백 장치에 연결됩니다.';
	@override String get locationPermission => 'PlezyNG는 로컬 네트워크를 찾고 미디어 서버에 연결하는 데 iOS가 요구하는 경우 위치 접근 권한을 사용합니다.';
	@override String get photoLibraryPermission => '사진 보관함에서 미디어 아트워크로 사용할 이미지를 선택하세요.';
	@override String get cameraPermission => 'QR 코드를 스캔하여 Companion Remote를 연결합니다.';
}

// Path: universalMedia
class _Translations$universalMedia$ko extends Translations$universalMedia$en {
	_Translations$universalMedia$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '오픈 미디어';
	@override String get shortcutHelp => '이 세션에 대한 링크, 플레이리스트 또는 파일을 재생합니다.';
	@override String get intro => 'Playback은 PlezyNG의 표준 플레이어를 사용하고 도서관에 역사를 추가하지 않습니다.';
	@override String get openWhat => '무엇을 열고 싶으신가요?';
	@override String get stream => '흐름 주소';
	@override String get playlist => '플레이리스트';
	@override String get files => '장치 파일';
	@override String get favorites => '저장된 스트림 좋아하는';
	@override String get address => '미디어 주소';
	@override String get addressHelp => '인증 또는 서명 매개 변수를 가진 URL은 이 세션에만 사용되며 좋아하는 것으로 저장될 수 없습니다.';
	@override String get displayName => '디스플레이 이름 (선택)';
	@override String get displayNameHelp => '플레이어 및 시스템 미디어 컨트롤에 대한 짧은 이름을 선택합니다.';
	@override String get allowHttp => '암호화되지 않은 HTTP 연결을 허용';
	@override String get allowHttpHelp => 'HTTP는 연결을 암호화하지 않습니다. 신뢰할 수 있는 네트워크에서만 허용합니다. 가능한 경우 HTTPS를 사용하십시오.';
	@override String get advancedProtocols => 'MPV만: RTSP, RTMP/RTMPS, UDP 또는 RTP 주소를 입력합니다.이 주소는 좋아하는 주소로 저장할 수 없습니다.';
	@override String get liveStream => '살아있는 것처럼 행동하라';
	@override String get liveStreamHelp => '이것을 라이브 비디오 또는 라디오에 사용하십시오.이 응용 프로그램은 시간표, 스키 버튼 및 go-to-time 옵션을 숨깁니다.';
	@override String get privateSession => '이 플레이백만이 주소를 사용합니다.이 프로필에 보관하기 위해 자격을 갖춘 스트림 좋아하는 것을 저장합니다.';
	@override String get saveFavorite => '좋아하는 저장';
	@override String get playNow => '지금 플레이';
	@override String get favoriteSaved => 'Stream Favorite 이 프로필에 저장';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '스키피드 ${count} 지원되지 않거나 불안정한 플레이리스트 입력.',
		other: '${count} 지원되지 않거나 불안정한 플레이리스트 입력을 벗어났습니다.',
	);
	@override String get playlistAddress => '플레이리스트 주소';
	@override String get playlistAddressHelp => '웹 주소에서 M3U, M3u8 또는 PLS 플레이리스트를 열 수 있습니다.Direct stream 링크는 플레이 리스트를 저장하지 않습니다.';
	@override String get choosePlaylist => '플레이리스트 파일 선택';
	@override String get openPlaylist => '오픈 플레이리스트';
	@override String get playlistFormatsHelp => '플레이리스트는 최대 1,000 개의 항목과 2 MB를 포함할 수 있습니다.HLS는 스트림으로 열려 있으므로 플레이어가 품질을 선택할 수 있도록합니다.';
	@override String get saveQueuePlaylist => '대기열을 재생목록으로 저장';
	@override String get queuePlaylistSaved => '재생목록을 미디어 파일 옆에 저장했습니다.';
	@override String get queuePlaylistUnavailable => '이 대기열은 재사용 가능한 로컬 재생목록으로 저장할 수 없습니다.';
	@override String get queuePlaylistFolderRequired => '대기열 파일과 같은 폴더를 저장 위치로 선택하세요.';
	@override String get noFavorites => '아직 좋아하는 스트림을 저장하지 않았습니다.Favorites 이 프로필에 남아 있습니다.';
	@override String get removeFavorite => '좋아하는 스트림을 제거';
	@override String get filesHelp => '오디오, 비디오 또는 ISO 파일을 일시적인 쿼드를 선택합니다.파일 및 URL은 도서관 역사에 추가되지 않습니다.';
	@override String get chooseFiles => '파일 선택';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '1 선택된 파일',
		other: '${count} 선택된 파일',
	);
	@override String get wifiTransfer => 'Wi-Fi를 통해 파일을 보내기';
	@override String get wifiTransferHelp => '동일한 신뢰할 수 있는 네트워크에서 브라우저에서 지원된 파일을 전송합니다.';
	@override String get wifiTransferIntro => '다른 장치에서 브라우저에서 이 주소를 열어 파일을 선택하여 이 장치의 파일 및 책 라이브러리에 추가합니다.';
	@override String get wifiTransferPrivacy => '이 장치는 현지 네트워크를 통해 파일을 수신합니다.이 주소를 아는 사람은 전송을 중단하거나 15 분 후에 주소가 만료 될 때까지 파일을 보낼 수 있습니다.';
	@override String get wifiTransferStarting => '개인적, 시간 제한된 전송을 준비하는 ...';
	@override String get wifiTransferUnavailable => '전송을 시작할 수 없습니다. 로컬 네트워크 액세스를 확인하고 다시 시도합니다.';
	@override String get openThisAddress => '이 주소 중 하나를 전송 장치에서 열어보세요.';
	@override String get copyAddress => '전송 주소 복사';
	@override String get addressCopied => '전송 주소 복사';
	@override String transferExpires({required Object time}) => '이 주소는 ${time}에서 만료됩니다.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${count} 파일 수신',
		other: '${count} 파일 수신',
	);
	@override String uploadedData({required Object size}) => '수신 ${size}';
	@override String get stopTransfer => '전송 중지 및 주소 취소';
	@override String get startTransfer => '전송 시작';
	@override String get wifiImportedFiles => 'Wi-Fi 전송';
	@override String get wifiBrowserTitle => '파일을 PlezyNG로 보내기';
	@override String get wifiBrowserIntro => '이 장치의 파일 및 책 라이브러리에 저장됩니다. 최대: 100 파일, 파일 당 4 GiB, 총 10 GiB.';
	@override String get uploadFilesLabel => '보내기 위한 파일';
	@override String get uploadSelected => '선택한 파일을 업로드';
	@override String get uploadSelectFirst => '먼저 하나 이상의 파일을 선택합니다.';
	@override String get uploading => '보내기';
	@override String get uploadComplete => '파일이 PlezyNG에 추가되었습니다.';
	@override String get uploadFailed => '이 페이지를 열고 다시 시도하십시오.';
	@override String get liveCue => '라이브';
	@override String get liveSession => '라이브 스트림';
	@override String get liveCueHelp => '라이브 비디오 또는 라디오를 위해, 앱은 시간표를 숨기고 스키 버튼.그것은 주소를 저장하거나 기록을 보지 않습니다.';
	@override String get sessionOnly => '이 플레이백은 세션에만';
	@override String get sessionOnlyHelp => 'Playback은 진보 또는 역사를 절대 저장하지 않습니다.이 프로필에 보관하기 위해 좋아하는 스트림을 저장하십시오.';
	@override String get pictureAdjustments => '사진 조정';
	@override String get pictureHelp => '이러한 이미지 변경은이 재생에만 영향을 미칩니다.그들은 재생이 끝날 때 다시 설정됩니다.';
	@override String get resetPicture => '사진 재설정';
	@override String get brightness => '밝기';
	@override String get contrast => '대조점';
	@override String get gamma => '가마';
	@override String get hue => '하우스';
	@override String get saturation => '토성화';
	@override String get view360 => '360° 비디오를 위한 평평한 전망';
	@override String get view360Help => 'MPV는 FFmpeg의 v360 필터가 필요합니다.';
	@override String get view360Unavailable => '이 MPV 구축은 360° 필터를 적용 할 수 없습니다.';
	@override String get view360Yaw => '수평 전망';
	@override String get view360Pitch => 'Vertical 전망';
	@override String get view360FieldOfView => '시야의 영역';
	@override String get recordStream => '레코드 라이브 스트림';
	@override String get stopRecording => '녹음을 멈추고 저장';
	@override String get recordingStarted => '녹음은 활성화됩니다.Leaving playback stops and saves the recording.';
	@override String get recordingSaved => '녹음이 완료되고 저장되었습니다.';
	@override String get recordingActive => '이 장치를 기록하십시오.Playback을 남기면 멈추고 저장됩니다.';
	@override String get recordingFormatHelp => '비디오를 위해 MKV 또는 MPEG-TS를 선택합니다.오디오를 위한 경우 MKA 또는 MKV를 선택하십시오.';
	@override String get replaceRecordingTitle => '이 레코드를 대체할 수 있나요?';
	@override String get replaceRecordingHelp => 'PlezyNG는 녹음하는 동안 기존 파일을 복구합니다. 새 녹음을 저장할 수 없다면 Plezy NG는 백업을 복원합니다.';
	@override String get replaceRecording => '파일 교체';
	@override String get discHelp => '이 컴퓨터의 광학 드라이브에서 디스크를 열 수 있습니다 장치 파일에서 ISO 이미지를 열 수 있음.';
	@override String get discs => '광학 디스크';
	@override String get editionOrTitle => '에디션 또는 디스크 제목';
	@override String get dvd => 'DVD';
	@override String get bluray => '블루레이';
	@override String get audioCd => '오디오 CD';
	@override String get discAvailability => '디스크 재생에는 호환되는 MPV 구축, 지원된 드라이브 및 운영 체제 허가가 필요합니다.그것은 상업적인 디스크 보호를 초과할 수 없습니다.';
	@override String get converterTitle => '현지 미디어 파일을 변환';
	@override String get converterHelp => '현지 파일을 변환하거나 로컬 파일로 재구성하십시오. FFmpeg그리고';
	@override String get converterIntro => '지역 오디오 또는 비디오 파일을 여러 장치에서 작동하는 형식으로 변환합니다.';
	@override String get converterPrivacy => 'FFmpeg는이 컴퓨터에 설치되어야합니다.Conversion은 로컬 파일만 읽습니다.그것은 스트림을 다운로드하거나 DRM을 제거하지 않습니다.';
	@override String get converterChooseInput => '지역 미디어 파일 선택';
	@override String get converterFormat => '출력 형식';
	@override String get converterMp4 => 'MP4 · H.264 및 AAC';
	@override String get converterM4a => 'M4A · AAC 오디오';
	@override String get converterMp3 => 'MP3 오디오';
	@override String get allowFtp => 'FTP 허용';
	@override String get allowFtpHelp => 'FTP는 암호화 없이 미디어를 보내고 신뢰할 수 있는 네트워크에서만 사용합니다.';
	@override String get converterSaveAs => '변환된 미디어를 저장하는 방법';
	@override String get converterExtensionMismatch => '선택한 출력 확장을 가진 파일 이름을 선택합니다.';
	@override String get converterUnsupportedInput => '오디오 또는 비디오 파일을 선택합니다.';
	@override String get converterLocalOnly => '선택한 파일은 현지 장치 경로로 사용할 수 없습니다.';
	@override String get converterReplaceTitle => '이 파일을 교체할 수 있나요?';
	@override String get converterReplaceHelp => 'PlezyNG은 변환 된 복사본이 저장 될 때까지 기존 파일을 복구합니다.';
	@override String get converterStarting => 'FFmpeg를 시작합니다.';
	@override String get converterProgress => '이 컴퓨터로 변환하는 ...';
	@override String get converterComplete => '변환이 완료되었습니다.새 파일은 준비되어 있습니다.';
	@override String get converterFfmpegMissing => 'FFmpeg 이 포맷이 없거나 지원되지 않습니다.';
	@override String get converterFailed => '변환이 실패했습니다.원본 파일이 읽을 수 있는지 확인하고 목적지가 충분한 공간을 갖추고 있음을 확인합니다.';
	@override String get converterCancelled => '변환이 취소되었습니다 불완전한 출력은 제거되었습니다.';
	@override String get converterDesktopOnly => '현지 변환은 FFmpeg 설치를 가진 데스크톱 컴퓨터에서 사용할 수 있습니다.';
	@override String get converterStart => '파일 변환';
	@override String get mediaToolsTitle => '미디어 도구';
	@override String get mediaToolsShortcut => '미디어를 캡처하거나 공유하거나 검색 확장 프로그램을 추가하거나 명령 라인을 사용합니다.';
	@override String get mediaToolsIntro => '이 데스크톱에 설치된 FFmpeg을 캡처하고 스트림을 사용합니다. 확장 및 CLI 명령은 제한된 HTTPS 요청과 기존의 Open media 흐름을 사용합니다.';
	@override String get mediaToolsAccessibility => '도구 선택 및 컨트롤은 터치, 지표, 키보드 및 D-pad 초점으로 작동합니다. 레코딩, 공유 및 검색 상태 변경이 발표됩니다.';
	@override String get mediaTool => '미디어 도구';
	@override String get captureIntro => 'Record your screen or a camera to an MP4 file on this computer. FFmpeg must be installed and include the H.264 encoder.';
	@override String get captureNoDevices => '스크린이나 카메라가 찾을 수 없습니다. FFmpeg 캡처 지원 및 운영 체제 개인 정보 보호 허가를 확인합니다.';
	@override String get captureSource => '스크린 또는 카메라';
	@override String get captureScreen => '스크린';
	@override String get captureAudioSource => '오디오 입력 (옵션)';
	@override String get captureAudioHelp => '마이크 또는 사용 가능한 입력에서 오디오를 추가합니다. 장치 선택은 FFmpeg 및 시스템 허가에 따라 달라집니다.';
	@override String get captureAudioNone => '오디오 없음';
	@override String get captureDefaultAudio => '기본 오디오 입력';
	@override String get captureWaylandHelp => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.';
	@override String get captureFrameRate => '녹음 프레임 속도';
	@override String get capturePrivacy => '녹음은 선택한 파일에만 저장됩니다.마이크로폰 캡처는 선택적입니다.PlezyNG은 녹음을 업로드하지 않습니다.';
	@override String get captureSaveAs => '스크린 레코딩을 저장하는 방법';
	@override String get captureExtensionMismatch => '.mp4에서 끝나는 파일 이름을 선택합니다.';
	@override String get captureFfmpegMissing => 'FFmpeg 또는 H.264 비디오 암호는 사용할 수 없습니다. 지원되는 FFmpeg 건물을 설치하고 다시 시도합니다.';
	@override String get captureFailed => '녹음은 저장할 수 없었습니다. 장치 허가, 사용 가능한 저장소 및 FFmpeg 지원을 확인합니다.';
	@override String get captureSaved => '스크린 녹음이 저장되었습니다.';
	@override String get captureElapsedLabel => '녹음 시간';
	@override String get captureStart => '녹음 시작';
	@override String get capturePreview => '플레이어에서 미리 보기';
	@override String get capturePreviewHelp => '선택한 소스를 기본 플레이어에서 미리 봅니다. 미리 보기는 현재 세션에서만 재생되며 녹화물을 저장하지 않습니다. 기기 지원과 권한은 MPV 및 운영체제에 따라 다릅니다. 미리 보기에는 비디오만 사용되며, 저장되는 녹화물에는 선택적으로 오디오를 포함할 수 있습니다.';
	@override String get capturePreviewActive => '실시간 미리 보기 · 녹화 중 아님';
	@override String get captureStop => '멈추고 저장';
	@override String get captureMode => '캡처';
	@override String get shareMode => '공유하기';
	@override String get shareIntro => '귀하의 개인 네트워크에서 다른 장치에 지역 미디어 파일을 보내십시오.PlezyNG은 일시적인 HLS 스트림을 생성합니다.';
	@override String get sharePrivacy => '귀하의 지역 네트워크에 있는 개인 링크를 받는 사람은 개인 링크가 활성화되는 동안 관찰할 수 있습니다. 링크는 60분 후에 만료됩니다. 공유를 중단하여 서버를 닫고 링크를 취소합니다.';
	@override String get shareChooseFile => '미디어 파일 선택';
	@override String get shareChooseHelp => '지역 오디오 또는 비디오 파일을 선택합니다.이 파일은이 컴퓨터에 남아 있습니다.';
	@override String get shareFfmpegMissing => 'FFmpeg 또는 H.264/AAC 암호가 사용할 수 없습니다. FFmpeg을 H.264 및 AAC 암호 지원으로 설치합니다.';
	@override String get shareFailed => '흐름은 예기치 않게 시작되거나 중지되지 않았습니다. FFmpeg 및 네트워크 액세스를 확인하십시오.';
	@override String get shareActive => '스트림은 개인 네트워크에서 준비되어 있습니다.';
	@override String get shareEnded => '미디어는 끝에 도달하고 더 이상 공유되지 않습니다.';
	@override String get shareStopped => '공유 중단되었습니다.시용 링크는 더 이상 유효하지 않습니다.';
	@override String get shareUrlCopied => '흐름 주소 복사';
	@override String get shareOpenUrl => '다른 장치에서 플레이어에서 이 주소를 열어';
	@override String get shareQrLabel => '임시 스트림 주소에 대한 QR 코드';
	@override String get shareQrHelp => '동일한 개인 네트워크에 연결된 호환 플레이어를 사용하여 스캔합니다.';
	@override String get shareHttpHint => '이 스트림은 암호화되지 않은 HTTP을 사용합니다. PlezyNG에서는 HTTP을 열기 전에 허용합니다.';
	@override String get shareCopyUrl => '스트림 주소 복사';
	@override String get shareExpiresLabel => '링크가 끝나고';
	@override String get shareStarting => '흐름을 준비하는 ...';
	@override String get shareStart => '공유 시작';
	@override String get shareStop => '공유 중지';
	@override String get extensionsMode => '확장 및 CLI';
	@override String get extensionsIntro => '미디어를 찾기 위해 데이터만 검색 확장을 추가합니다. 결과를 선택하여 익숙한 Open media 양식으로 업로드합니다.';
	@override String get extensionsPrivacy => '메니지스트는 하나의 HTTPS 검색 엔드 포인트와 지도 응답 필드를 정의 할 수 있습니다.그것은 코드를 실행 할 수 없습니다, 요청 헤드, 읽기 파일, 또는 시작 셔틀 명령.';
	@override String get extensionImport => '추가 확장 표시';
	@override String get extensionEmpty => '아직 검색 서비스가 없습니다. 신뢰할 수 있는 메시지 JSON 파일을 선택하여 하나를 추가합니다.';
	@override String get extensionChoose => '검색 서비스';
	@override String get extensionSearchConsent => '각 검색은 이 HTTPS 서비스에 귀하의 단어를 보냅니다.결과는 하나를 선택한 후에만 열립니다.';
	@override String get extensionSearchLabel => '미디어 검색';
	@override String get extensionSearch => '검색';
	@override String get extensionSearching => '검색...';
	@override String get extensionNoResults => '안전한 미디어 결과가 반환되지 않았습니다.다른 검색을 시도하십시오.';
	@override String get extensionInstallTitle => '이 검색 서비스를 추가하십시오?';
	@override String get extensionReplaceTitle => '이 검색 서비스 업데이트?';
	@override String get extensionService => '서비스';
	@override String get extensionEndpoint => 'HTTPS 최종 포인트';
	@override String get extensionConsent => '귀하의 검색 텍스트가 이 서비스에 전송됩니다. 메니지에는 실행 가능한 코드가 없습니다.이 끝점에 신뢰하는 경우에만 계속하십시오.';
	@override String get extensionInstall => '서비스 추가';
	@override String get extensionReplace => '업데이트 서비스';
	@override String get extensionRemoveTitle => '이 검색 서비스 삭제?';
	@override String get extensionRemoveHelp => '이 서비스는 이 프로필에서 제거됩니다.PlezyNG은 최종 포인트에 연락하지 않습니다.';
	@override String get extensionRemove => '서비스 제거';
	@override String get extensionInvalidManifest => '이 파일은 지원되는 확장 메시지가 아닙니다.이 형식에 대한 Open media 가이드를 참조하십시오.';
	@override String get extensionSaveFailed => '확장은 활성 프로필에 저장할 수 없었습니다.';
	@override String get extensionSearchFailed => '검색 서비스는 유효한 응답을 반환하지 않았습니다.결말 포인트를 확인하고 다시 시도하십시오.';
	@override String get cliTitle => '명령 라인';
	@override String get cliHelp => 'plezyctl 가이드를 사용하여 마니플을 확인하거나 동일한 확장을 검색합니다. 각 검색 전에 HTTPS 서비스를 검토합니다. 결과는 기존 미디어 양식에서 열립니다. 시작할 재생 버튼을 선택합니다.';
	@override String get cliCopyExample => '코멘트 복사본 예제';
	@override String get cliCopied => '명령 사례 복사.';
}

// Path: fileSources
class _Translations$fileSources$ko extends Translations$fileSources$en {
	_Translations$fileSources$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '파일 및 책';
	@override String get subtitle => '읽고, 듣고, 자신의 파일에서 관찰합니다.';
	@override String get add => '출처 추가';
	@override String get importFiles => '파일 수입';
	@override String get localFiles => '이 장치에서';
	@override String get source => '출처';
	@override String get name => '이름';
	@override String get endpoint => '서버 URL';
	@override String get smbEndpointHint => '예: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'SMB 서버와 공유 폴더 하나를 입력하세요.';
	@override String get root => '폴더 또는 접두사';
	@override String get smbFolderHelp => '공유 폴더 전체를 사용하려면 비워 두고, 일부만 사용하려면 그 안의 폴더를 입력하세요.';
	@override String get username => '사용자 이름';
	@override String get smbDomain => '도메인(선택 사항)';
	@override String get password => '비밀번호';
	@override String get token => 'API 토큰';
	@override String get accessKey => '액세스 키 ID';
	@override String get secretKey => '비밀 액세스 키';
	@override String get sessionToken => '세션 토큰 (선택)';
	@override String get region => '지역';
	@override String get clientId => 'OAuth 고객 ID';
	@override String get clientSecret => 'OAuth 클라이언트 비밀 (Google 데스크톱만)';
	@override String get allowHttp => '신뢰할 수 있는 네트워크에서 암호화되지 않은 HTTP 허용';
	@override String get smbEncryption => 'SMB3 연결 암호화';
	@override String get smbEncryptionHint => 'NAS에서 지원하는 경우 SMB3 암호화를 사용합니다.';
	@override String get connect => '연결';
	@override String get cancel => '취소';
	@override String get save => '저장';
	@override String get close => '닫기';
	@override String get removeSource => '분리된 출처';
	@override String get disconnectMessage => '이 소스의 연결을 해제할까요? 다운로드한 파일과 읽기 및 청취 기록은 이 기기에 유지됩니다.';
	@override String get localFolder => '선택한 폴더';
	@override String get empty => '아직 아무것도 없습니다';
	@override String get emptyHint => '출처를 추가하거나 책, 오디오, 음악 또는 비디오를 가져오십시오.';
	@override String get search => '이 폴더를 찾아보세요';
	@override String get searchCached => '검색 도서관 구원';
	@override String get refresh => '새로고침';
	@override String get loadMore => '더 충전';
	@override String get offline => 'Offline 이용 가능';
	@override String get download => '오프라인으로 유지';
	@override String get removeDownload => '오프라인 복사본 삭제';
	@override String get continueReading => '계속 읽기';
	@override String get continueListening => '계속 듣기';
	@override String get continueWatching => '계속 봐라';
	@override String get read => '읽기';
	@override String get listen => '듣기';
	@override String get play => '재생';
	@override String get pause => '일시정지';
	@override String get stop => '정지';
	@override String get startOver => '시작하기';
	@override String get finished => '재생 완료';
	@override String get markFinished => '마크가 끝났다';
	@override String get markUnfinished => '마크 끝없는';
	@override String get editions => '출판물 및 파일';
	@override String get chapters => '챕터';
	@override String get bookmarks => '책표 및 노트';
	@override String get bookmark => 'Bookmark 추가';
	@override String get highlight => '강조';
	@override String get note => '노트';
	@override String get delete => '삭제';
	@override String get export => '수출 노트';
	@override String get exported => '수출된 노트';
	@override String get sync => 'Sync 진행';
	@override String get synced => '진행 합성';
	@override String get conflict => '다른 장치가 다른 위치를 가지고 있습니다. 어디로 계속할지 선택합니다.';
	@override String get useLocal => '이 장치를 사용하라';
	@override String get useRemote => '다른 장치를 사용하라';
	@override String get history => '위치 역사';
	@override String get groupAudio => '한 개의 오디오 책으로 들으십시오.';
	@override String get groupHint => '현재 이 폴더에 불러온 오디오 파일을 하나로 묶습니다. 먼저 모든 페이지를 불러오세요.';
	@override String get order => '파일 명령';
	@override String get moveUp => '움직이기 위하여';
	@override String get moveDown => '아래로 이동';
	@override String get speed => '플레이버크 속도';
	@override String get sleep => '취침 타이머';
	@override String get sleepOff => '꺼짐';
	@override String get endChapter => '장의 끝';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}분',
	);
	@override String get skipBack => '다시 스키';
	@override String get skipForward => '앞으로 스키';
	@override String get smartRewind => '휴식 후 똑똑한 회복';
	@override String get playbackOptions => '듣기 옵션';
	@override String remaining({required Object time}) => '${time} 남은';
	@override String get contents => '콘텐츠';
	@override String get readerSettings => '읽기 설정';
	@override String get fontSize => '텍스트 크기';
	@override String get lineHeight => '라인 스페셜';
	@override String get margin => '마르지나';
	@override String get font => '타이프페이스';
	@override String get serif => '세리프';
	@override String get sans => '산세리프';
	@override String get mono => '고정폭';
	@override String get columns => '콜럼버스';
	@override String get scroll => 'Vertically 스크롤';
	@override String get justify => '양쪽 맞춤';
	@override String get readerTheme => '페이지 출현';
	@override String get appTheme => '앱 테마 추적';
	@override String get paper => '종이';
	@override String get sepia => '세피아';
	@override String get night => '밤이';
	@override String get readAloud => '이 페이지 소리 내어 읽기';
	@override String get readAlong => '음성에 맞춰 읽기';
	@override String get stopReading => '읽어주기 중지';
	@override String get searchBook => '책에서 검색';
	@override String get noMatches => '경기 없음';
	@override String get previousPage => '이전 페이지';
	@override String get nextPage => '다음 페이지';
	@override String page({required Object number}) => '페이지 ${number}';
	@override String get externalBlocked => '리더에서는 책의 외부 링크가 비활성화되어 있습니다.';
	@override String get loading => '열기...';
	@override String get narrator => '묘사기';
	@override String get audio => '오디오';
	@override String get video => '비디오';
	@override String get ebooks => 'Ebook의 발음을 Ebook [en]';
	@override String get all => '전체';
	@override String get downloads => '오프라인 파일';
	@override String get confirmDelete => '선택한 오프라인 사본을 삭제할까요? 읽기 또는 청취 위치와 메모는 유지됩니다.';
	@override String get errorAuthentication => '다시 이 소스를 다시 연결하려면 로그인하십시오.';
	@override String get errorPermission => '이 소스는 요청된 파일에 대한 액세스를 허용하지 않았습니다.';
	@override String get errorUnavailable => '소스를 사용할 수 없습니다. 다시 시도하거나 오프라인 사본을 여세요.';
	@override String get errorUnsupported => '이 형식 또는 연결이 이 장치에서 지원되지 않습니다.이 장치에서 원본 설정 가이드를 확인합니다.';
	@override String get errorInvalidData => '이 파일 또는 서버 응답은 안전하게 읽을 수 없습니다.';
	@override String get errorCancelled => '이 작업은 취소되었다.';
	@override String get errorConflict => '위치가 다른 세션에서 변경되었습니다. 항목을 다시 열어 위치를 선택합니다.';
	@override String get signIn => '로그인';
	@override String get reconnect => '다시 연결';
	@override String get folderHelp => '비워 두면 소스의 루트에서 시작합니다. S3 URL에는 버킷 이름이 포함됩니다.';
	@override String get preferences => '선호도';
	@override String get timePosition => '위치';
	@override String get audioTrack => '오디오 트랙';
	@override String get subtitleTrack => 'Subtitle 트랙';
	@override String get none => '아무도';
	@override String get fullscreen => '전체 화면';
	@override String get syncLocation => 'Progress sync 폴더 (선택)';
	@override String get syncLocationHint => 'PlezyNG 상태를 위한 전용 WebDAV 폴더.조건적인 글쓰기를 사용; 미디어는 변함없이 남아 있습니다.';
	@override String get audiobooks => '오디오 책';
	@override String get comics => '만화';
	@override String get scan => '책과 미디어를 위한 스캔';
	@override String get browserReader => '오픈 리더';
	@override String get browserReaderHelp => '브라우저에서 리더가 열려 있습니다. 읽던 위치와 메모를 저장하려면 PlezyNG를 열어 두세요.';
	@override String get on => '에';
	@override String get advancedSetup => 'App 등록';
	@override String get microsoftSignIn => 'Microsoft와 함께 가입하세요';
	@override String get zoomIn => 'Zoom에 대한';
	@override String get zoomOut => 'Zoom 출력';
	@override String get fitPage => '페이지에 맞춤';
	@override String get fitWidth => '넓은 넓은';
	@override String get actualSize => '현재 크기';
	@override String get goToPage => '페이지로 가기';
	@override String get goToSection => '챕터로 이동';
	@override String pageRange({required Object count}) => '1에서 ${count} 사이의 숫자를 입력하세요';
	@override String get pageLayout => '페이지 레이아웃';
	@override String get automatic => '자동';
	@override String get singlePage => '단일 페이지';
	@override String get twoPages => '2 페이지';
	@override String get readingDirection => '읽기 방향';
	@override String get leftToRight => '왼쪽에서 오른쪽으로';
	@override String get rightToLeft => '오른쪽에서 왼쪽으로';
	@override String get letterSpacing => '우주 편지';
	@override String get wordSpacing => '단어 스페셜';
	@override String get readerControlsHelp => '두 손가락을 벌리거나 확대/축소 컨트롤을 사용하여 페이지를 확대하세요. 드래그하여 페이지를 이동하세요. Ctrl/⌘와 + 또는 −로 배율을 조절하고, Ctrl/⌘와 0으로 초기화합니다. Page Up과 Page Down으로 페이지를 넘깁니다.';
	@override String get imagePage => '만화 페이지';
	@override String get resetReader => '읽기 선호도를 다시 설정';
	@override String get zoom => '확대/축소';
	@override String get useFiles => '파일과 책을 사용하십시오';
	@override String get cancelScan => '스캔 취소';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Offline 다운로드 제한';
	@override String get offlineQuotaHelp => '오프라인 복사본, 수입된 파일 및 쿠웨이드 다운로드에 사용되는 최대 공간을 설정합니다.제한을 낮추는 것은 기존 복사를 제거하지 않습니다.';
	@override String get offlineStorageUsage => '오프라인 스토리지';
	@override String get reservedStorage => '예약';
	@override String get downloadQueue => '다운로드 Queue';
	@override String get downloadRunning => '다운로드';
	@override String get downloadQueued => '기다리는';
	@override String get downloadPaused => '휴식';
	@override String get downloadFailed => '탈퇴가 필요하다';
	@override String get importing => '수입';
	@override String get importInterrupted => '수입 중단 · 제거 삭제';
	@override String get errorQuotaExceeded => '오프라인 스토리지 제한이 달성되었습니다.제한을 올리거나 다운로드 된 복사본을 제거합니다.';
	@override String get errorStorageLow => '보호된 저장소를 유지하기에 충분한 무료 장치 스토리지가 없습니다.';
	@override String get errorStorageUnavailable => 'PlezyNG는 무료 장치 저장소를 확인할 수 없었으므로 글쓰기가 중단되었습니다.';
	@override String get removeDownloadJob => '다운로드 삭제';
	@override String get downloadAlreadyComplete => '이 다운로드는 삭제되기 전에 완료되었습니다.이 항목은 이제 오프라인으로 사용할 수 있습니다.';
	@override String get confirmRemoveDownloadJob => '이 다운로드를 제거하고 부분적으로 다운로드 된 데이터를 삭제하십시오.당신의 위치와 노트는 남아있을 것입니다.';
}

// Path: lending
class _Translations$lending$ko extends Translations$lending$en {
	_Translations$lending$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '공공 도서관';
	@override String get add => '도서관 추가';
	@override String get other => '또 다른 도서관';
	@override String get libraryName => '도서관 이름';
	@override String get libraryUrl => '도서관 웹사이트';
	@override String get libraryUrlHint => '도서관의 도서 목록 또는 로그인 페이지를 사용하세요.';
	@override String get intro => '도서관에서 책을 빌리고 언제나 가까이 두세요.';
	@override String get handoff => '도서관 자체 서비스를 통해 로그인하고 책을 빌려 안전하게 읽으세요.';
	@override String get openService => '오픈 도서관';
	@override String get findLibrary => '도서관 찾기';
	@override String get search => '책과 저자를 찾아보세요';
	@override String get catalogue => '카탈로그';
	@override String get loans => '대출';
	@override String get holds => '예약';
	@override String get signIn => '도서관에 가입하십시오';
	@override String get waiting => '브라우저에서 가입을 마무리하고 여기로 돌아갑니다.';
	@override String get cancel => '취소';
	@override String get disconnect => '도서관 삭제';
	@override String get disconnectMessage => '이 프로필에서 이 도서관을 제거할까요? 대출 및 예약 내역은 도서관에 그대로 유지됩니다.';
	@override String get getBook => '책을 얻으라';
	@override String get checkAvailability => '이용 가능성을 확인하기';
	@override String get available => '대출을 위해 사용할 수 있는';
	@override String get unavailable => '현재 이용할 수 없는';
	@override String get borrow => '대출';
	@override String get placeHold => '예약하기';
	@override String get returnBook => '기한 전에 반납';
	@override String get cancelHold => '예약 취소';
	@override String get confirmBorrow => '이 책을 도서관에서 빌려주시나요?';
	@override String get confirmReturn => '이 제목을 지금 돌려주십시오.이 제목을 계속하기 위해 다시 대출해야 할 수도 있습니다.';
	@override String get confirmCancelHold => '이 도서의 예약을 취소할까요?';
	@override String get email => '이메일 통보를 유지';
	@override String due({required Object date}) => '반납 기한: ${date}';
	@override String queue({required Object position}) => '위치 ${position} 라인';
	@override String get empty => '아직 제목이 없습니다.';
	@override String get openLibraryNote => 'Open Library의 카탈로그를 탐색하십시오.읽기 및 대출 옵션은 각 제목의 페이지에 표시됩니다.';
	@override String get more => '더 충전';
	@override String get gateway => '도서관 서명 서비스';
	@override String get gatewayHint => '도서관 또는 관리자 PlezyNG에 의해 제공됩니다.';
	@override String get advanced => '도서관 통합';
	@override String get loadLibraries => '당신의 도서관을 선택하세요';
	@override String get expired => '이 대출은 끝났습니다.';
	@override String get updated => '도서관 업데이트';
	@override String get continueService => '계속 서비스에';
	@override String get comingSoon => '신속하게 도착하는 앱 대출';
	@override String get comingSoonDescription => 'Libby 통합은 그 길에 있습니다. Libby에서 도서관을 사용할 수 있습니다.';
	@override String get suspendHold => '예약 일시 중지';
	@override String get resumeHold => '예약 재개';
	@override String get suspendMessage => '대기 순서를 유지하고 다음 독자가 이 책을 먼저 빌리도록 할까요? 나중에 예약을 재개할 수 있습니다.';
	@override String get resumeMessage => '도서관에서 다음으로 이용 가능한 책을 제공할 수 있도록 이 예약을 재개할까요?';
	@override String get editEmail => '이메일 통지 변경';
}

// Path: audiobook
class _Translations$audiobook$ko extends Translations$audiobook$en {
	_Translations$audiobook$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => '읽기 & 듣기 Sync';
	@override String get syncHelp => '기기 내에서 읽기 위치, 듣기 위치, 완성 상태, 책표 및 노트를 유지하십시오. 연결된 스토리지 계정을 선택하고 각 장치에 동일한 동기화 코드를 사용하십시오. 읽기 및 듣기는 별도로 남아 있습니다.';
	@override String get addSyncSource => '먼저 Google 드라이브, OneDrive, Dropbox, WebDAV 또는 S3를 파일 및 책에 추가합니다.';
	@override String get syncDestination => 'Sync 스토리지 계정';
	@override String get syncFolder => '동기화 폴더 또는 Prefix';
	@override String get syncFolderHelp => 'WebDAV 소스 내에서 별도의 기존 폴더 또는 전용 S3 사전을 사용하십시오.책 파일은 변경되지 않습니다.';
	@override String get syncCode => '개인 동기화 코드';
	@override String get syncCodeHelp => '첫 번째 장치에서 코드를 만들고 다른 장치에서 그 코드를 입력하십시오.개인 복사본을 유지하십시오.그것은 암호화 상태의 열쇠입니다.모든 사람에게 다른 코드를 사용하십시오.';
	@override String get showCode => 'Sync 코드를 표시하거나 숨기십시오.';
	@override String get newSyncCode => '새로운 Sync 코드를 만들기';
	@override String get saveSync => '저장 및 동기화';
	@override String get disableSync => '이 장치에서 Sync를 끄십시오.';
	@override String get syncSourceDisconnect => '이 소스를 제거하면 여기에서 읽기 및 듣기 동기화가 중지됩니다. 암호화 된 동기화 파일은 공급자에 남아 있습니다.';
	@override String get syncReconnect => '스토리지 계좌 다시 연결';
	@override String lastSynced({required Object time}) => '마지막으로 합성된 ${time}';
	@override String get syncPrivacy => '오직 암호화된 프로세스 및 노트만 저장됩니다. 오디오 및 ebook 파일, 계정 토큰 및 암호는 업로드되지 않습니다. Google 드라이브 및 OneDrive는 애플리케이션 스토리지를 사용합니다. Dropbox는 PlezyNG Sync를 사용합니다. Sync를 활성화하는 것은 추가 글쓰기 액세스를 요구할 수 있습니다. 활성화하는 동안,이 목적지는 프로세스를 소유하고 있습니다. 서버 프로세스는 별도로 남아 있습니다.';
	@override String get syncConflicts => '다시 시작하는 곳을 선택하십시오';
	@override String get conflictHelp => '이러한 변경 사항은 독립적으로 수행되었습니다. 위치 또는 상표 버전을 선택하여 유지하십시오. 나중에 시간표 또는 더 높은 비율은 자동으로 이기지 않습니다.';
	@override String syncDevice({required Object device}) => '장치 ${device}';
	@override String get syncUnknownDevice => '알려지지 않은 장치';
	@override String get deletedBookmark => '삭제된 Bookmark';
	@override String get finished => '마무리';
	@override String readingPosition({required Object percent}) => '읽기 · ${percent}%';
	@override String get chapterTimeline => '제1장 진보';
	@override String get bookTimeline => '책 전체 진행';
	@override String bookRemaining({required Object time}) => '이 책에 남아있는 시간 : ${time}';
	@override String chapterRemaining({required Object time}) => '이 장에 남아있는 시간: ${time}';
	@override String get unknownRemaining => '전체 시간 사용할 수 있기 때문에 부분이 재생됩니다';
	@override String get undoSeek => '마지막 찾기';
	@override String get customSpeed => 'Custom Playback 속도';
	@override String get speedHelp => '0.25×에서 4×까지의 속도를 선택합니다.';
	@override String get apply => '응용';
	@override String get customSleep => '사용자 지정 수면 시간';
	@override String get sleepMinutes => '1 분 (1 - 1440)';
	@override String sleepChapters({required Object count}) => '${count} 장 후 중지';
	@override String get extendSleep => '추가 5 분';
	@override String sleepRemaining({required Object time}) => '잠자리 타이머: ${time}';
	@override String get useDefaults => '새로운 책을 위해 이러한 듣기 컨트롤을 사용하십시오.';
	@override String get librarySort => '다양한 책들';
	@override String get sortTitle => '제목';
	@override String get sortAuthor => '작가';
	@override String get sortNarrator => '연설자';
	@override String get sortSeries => '시리즈 명령';
	@override String get sortRecent => '최근에 열렸다';
	@override String get statusFilter => '읽기 상태';
	@override String get statusAll => '모든 책들';
	@override String get statusNew => '시작하지 않음';
	@override String get statusProgress => '진행 중에';
	@override String get statusFinished => '마무리';
	@override String get goToTime => '시간에 가라';
	@override String get timeHelp => '시간:분:초 또는 분:초';
	@override String get recoveryHelp => '동기화 데이터를 이동하거나 복구하기 전에 최근 암호화 된 복사본을 수출합니다.수입은 현재 상태와 결합됩니다; 그들은 결코 지역 동기 역사를 대체하지 않습니다.';
	@override String get recoveryExport => '수출 암호화 된 복구 파일';
	@override String get recoveryImport => '암호화된 복구 파일 수입';
	@override String get recoveryImportConfirm => '이 암호화 된 복구 파일을 현재 읽기 위치 및 노트와 결합하십시오? 기존 역사는 유지됩니다. 공유 라이브러리 및 항목 ID는 포함되지 않습니다; 수입하기 전에 각 장치에 해당 ID를 설정합니다.';
	@override String get recoveryExported => '암호화 된 복구 파일이 저장되었습니다.';
	@override String get recoveryImported => '복구 데이터가 합쳐졌습니다.';
}

// Path: sourceSetup
class _Translations$sourceSetup$ko extends Translations$sourceSetup$en {
	_Translations$sourceSetup$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => '저장된 서버 인증서';
	@override String get nfsEndpointInvalid => 'nfs://nas:2049/export와 같은 NFS URL을 입력하세요.';
	@override String get dlnaNone => 'DLNA 서버를 찾지 못했습니다. 장치 설명 URL을 직접 입력하세요.';
	@override String get dlnaServers => 'DLNA 미디어 서버';
	@override String get dlnaUnavailable => '이 네트워크에서는 DLNA 검색을 사용할 수 없습니다. 장치 설명 URL을 직접 입력하세요.';
	@override String get dlnaSearching => '로컬 네트워크에서 DLNA 서버 검색 중';
	@override String get networkSearching => '로컬 네트워크 검색 중…';
	@override String get dlnaDiscover => 'DLNA 서버 찾기';
	@override String get dlnaHelp => '장치를 찾으려면 로컬 네트워크의 멀티캐스트가 필요합니다. 서버가 나타나지 않으면 위에 장치 설명 URL을 입력하세요.';
	@override String get dlnaRoot => 'DLNA 개체 ID입니다. 비워 두면 장치의 루트를 사용합니다.';
	@override String get passwordOrKey => '비밀번호를 입력하거나 아래에 개인 키를 추가하세요.';
	@override String get sshFingerprint => 'SSH 호스트 키의 SHA256 지문';
	@override String get sshFingerprintHelp => '서버 관리자에게 확인하세요. 서버에서 ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub 명령을 실행하고 표시된 SHA256 값을 사용하세요.';
	@override String get sshFingerprintKeep => '현재 고정된 지문을 유지하려면 비워 두세요. 변경하려면 새 서버 지문을 입력하세요.';
	@override String get sshAuthentication => 'SSH 공개 키 인증';
	@override String get sshAuthenticationHelp => '선택 사항입니다. 비밀번호 인증도 지원합니다.';
	@override String get privateKey => '개인 키(PEM 또는 OpenSSH 형식)';
	@override String get privateKeyPassphrase => '개인 키 암호 구문';
	@override String get nfsMountPort => 'NFS 마운트 서비스 TCP 포트';
	@override String get nfsMountPortHelp => '기본값: 20048';
	@override String get nfsUserId => 'NFS 사용자 ID(AUTH_SYS)';
	@override String get nfsUserIdHelp => '기본값: 1000. NAS 내보내기 설정에서 허용한 ID를 사용하세요.';
	@override String get nfsGroupId => 'NFS 그룹 ID(AUTH_SYS)';
	@override String get nfsGroupIdHelp => '기본값: 1000. NAS 내보내기 설정에서 허용한 그룹 ID를 사용하세요.';
	@override String get nfsEncryption => 'NFS 암호화 필수(RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'NFS와 마운트 서비스에 TLS 1.3을 요구합니다. NAS가 지원하지 않으면 연결을 거부합니다.';
	@override String get nfsTrustCertificate => '사용자 지정 NFS CA 또는 서버 인증서(PEM, 선택 사항)';
	@override String get nfsTrustHelp => '이 장치에서 신뢰하는 인증서를 사용하려면 비워 두세요. 필요하면 사설 CA 또는 자체 서명 서버 인증서를 추가하세요. 인증서의 이름은 NFS URL의 호스트와 일치해야 합니다.';
	@override String get nfsTrustInvalid => 'PEM 형식의 CA 또는 서버 인증서를 사용하세요. 개인 키는 포함하지 마세요.';
	@override String get addTrustCertificate => '사용자 지정 신뢰 인증서 추가';
	@override String get replaceTrustCertificate => '저장된 사용자 지정 인증서 교체';
	@override String get nfsTlsHelp => 'RPC-with-TLS는 일반 NFS 및 마운트 서비스 포트를 사용하며, NAS가 RFC 9289를 지원해야 합니다. TLS 1.3이 필수입니다. 호스트 이름 또는 IP가 인증서와 일치해야 합니다. 암호화된 채널에서도 AUTH_SYS UID/GID가 적용됩니다.';
	@override String get clientCertificate => '클라이언트 인증서(선택 사항)';
	@override String get clientCertificateHelp => 'NAS가 이 클라이언트를 인증하도록 합니다. AUTH_SYS ID에는 여전히 NAS 내보내기 정책이 적용됩니다.';
	@override String get savedIdentity => '저장된 클라이언트 인증 정보를 사용합니다.';
	@override String get replaceIdentity => '저장된 클라이언트 인증 정보 교체';
	@override String get chooseIdentity => 'PKCS#12 클라이언트 인증 정보 선택';
	@override String get identityPassphrase => '클라이언트 인증 정보 암호 구문';
	@override String get identityPassphraseHelp => '파일에 암호 구문이 없으면 비워 두세요.';
	@override String get removeIdentity => '저장된 클라이언트 인증 정보 제거';
	@override String get identityStorageHelp => '클라이언트 인증 정보는 암호화된 소스 자격 증명 저장소에 저장됩니다. 저장된 인증 정보를 유지하려면 이 섹션을 변경하지 마세요.';
	@override String get nfsLimitations => 'TCP를 통한 읽기 전용 NFSv3입니다. RPC-with-TLS를 사용하지 않으면 NFS 트래픽이 암호화되지 않습니다. NAS는 선택한 AUTH_SYS ID와 비특권 클라이언트 포트를 허용해야 합니다(보통 내보내기 옵션에서 ‘insecure’로 표시됨). NFSv4와 UDP는 지원하지 않습니다.';
	@override String get nfsSetupHelp => 'NFS 설정 도움말';
	@override String get nfsSetupHint => '연결되지 않으면 이 설정들을 확인하세요.';
	@override String get nfsSetupDetails => 'TCP 기반 NFSv3 내보내기를 사용하세요. 암호화가 필수인 경우 NFS와 마운트 서비스가 모두 RPC-with-TLS를 지원해야 합니다. 이 장치에서 서버 인증서를 신뢰하면 사용자 지정 인증서를 비워 두세요. 그렇지 않으면 NAS CA 또는 자체 서명 인증서를 추가하세요. 인증서 이름은 엔드포인트의 호스트와 일치해야 합니다. NAS가 상호 TLS를 요구하면 해당 PKCS#12 클라이언트 인증 정보를 추가하세요. 마지막으로 내보내기 설정이 지정한 AUTH_SYS UID/GID와 클라이언트 포트 정책을 허용하는지 확인하세요.';
	@override String get ftpHelp => 'FTP는 패시브 모드를 사용합니다. 암호화되지 않은 FTP에는 ftp://, 명시적 TLS에는 ftpes://를 사용하세요. ftps://도 TLS를 사용하며, 포트 990에서는 암시적 TLS를, 다른 포트에서는 명시적 TLS를 사용합니다.';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => '독립 동영상 파일에 사용할 수 있는 선택적 자막 검색 기능입니다.';
	@override String get apiKey => 'API 키';
	@override String get optionalUsername => '계정 사용자 이름(선택 사항)';
	@override String get optionalPassword => '계정 비밀번호(선택 사항)';
	@override String get subtitlePrivacy => 'opensubtitles.com에서 API 키를 받으세요. 검색 시 동영상 제목과 사용 가능한 IMDb/TMDB ID만 전송하며, 동영상 파일은 절대 전송하지 않습니다. 키와 선택적 계정 자격 증명은 이 소스와 함께 암호화하여 저장합니다.';
	@override String get automaticMetadata => '온라인 동영상 메타데이터 자동 조회';
	@override String get metadataPrivacy => '파일명의 제목·연도·에피소드 번호 또는 NFO ID만 전송하며, 미디어나 자격 증명은 절대 전송하지 않습니다. NFO 필드가 항상 우선합니다.';
	@override String get nfsEncryptionFailure => '암호화된 NFS 연결에서는 NAS의 두 서비스가 RFC 9289와 TLS 1.3을 지원하는지, 인증서 이름과 내보내기 UID/GID가 올바른지 확인하세요. PlezyNG는 암호화 없이 이 연결을 다시 시도하지 않습니다.';
	@override String get sourceConnecting => '소스에 연결 중';
	@override String get metadataSearchPrivacy => '이 제목 검색은 Trakt로 전송됩니다. 입력한 제목만 전송하며, 동영상이나 소스 자격 증명은 전송하지 않습니다.';
	@override String get chooseMatch => '일치하는 결과 선택';
	@override String get metadataMatchHelp => '선택하기 전에 제목과 연도를 확인하세요. Trakt에는 검색 제목이 전송되며, 동영상은 원래 소스에 그대로 남습니다.';
	@override String get metadataNoMatches => '일치하는 온라인 제목을 찾지 못했습니다. 다른 제목으로 검색하세요.';
	@override String get metadataSearch => '온라인 메타데이터 검색';
	@override String get metadataLoading => '온라인 영화 및 TV 프로그램 정보 조회 중…';
	@override String get metadataFromTrakt => 'Trakt의 온라인 메타데이터';
	@override String get metadataNoAutomaticMatch => '자동으로 일치하는 제목을 찾지 못했습니다. 제목을 검색하여 일치하는 결과를 선택하세요.';
	@override String get metadataFailed => '온라인 메타데이터를 불러오지 못했습니다. 재생과 로컬 정보는 계속 사용할 수 있습니다.';
	@override String get videoDetailsLoading => '동영상 정보 불러오는 중';
	@override String get subtitleKeyRequired => 'OpenSubtitles API 키 필요';
	@override String get subtitleKeyHelp => '이 파일 소스를 편집하여 선택적 자막 설정에 OpenSubtitles API 키를 추가하세요.';
	@override String get subtitleSearchFailed => '자막 검색에 실패했습니다. API 키, 연결 및 서비스 접근 권한을 확인하세요.';
	@override String get subtitleApplyFailed => '이 자막을 다운로드하거나 적용하지 못했습니다. 연결을 확인하고 다른 결과를 선택하세요.';
	@override String get subtitleSearch => 'OpenSubtitles 검색';
	@override String get subtitleSearchPrivacy => '검색에는 제목과 사용 가능한 IMDb/TMDB ID를 사용합니다. 동영상 파일은 원래 소스에 그대로 남습니다. 선택하기 전에 언어, 강제 표시 또는 청각 장애인용 자막 표시, 평점을 확인하세요.';
	@override String get movieOrShow => '영화 또는 TV 프로그램';
	@override String get subtitleTitleHint => '제목을 입력하여 검색 결과 좁히기';
	@override String get subtitleLanguage => '자막 언어';
	@override String get subtitleSearching => 'OpenSubtitles 검색 중';
	@override String get subtitleNoMatches => '일치하는 자막을 찾지 못했습니다. 다른 제목이나 언어를 선택하세요.';
	@override String get downloadSubtitle => '자막 다운로드';
	@override String get subtitle => '자막';
	@override String get nfsTlsRequired => 'RPC-with-TLS 필수';
	@override String get nfsUnencrypted => '암호화되지 않은 NFS';
	@override String get tlsEncrypted => 'TLS로 암호화됨';
	@override String get ftpPlain => '암호화되지 않은 FTP';
	@override String get sshPinned => 'SSH 암호화 · 호스트 키 고정됨';
	@override String get smbEncrypted => 'SMB3 암호화 켜짐';
	@override String get smbUnencrypted => 'SMB3 암호화 꺼짐';
	@override String get httpUnencrypted => '전송 암호화 없는 HTTP';
	@override String get checkEndpointSecurity => '엔드포인트 보안 확인';
	@override String fieldRequired({required Object label}) => '필수 입력 항목: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => '${label}: ${min}부터 ${max}까지의 값을 입력하세요.';
	@override String replaceFile({required Object name}) => '${name} 교체';
	@override String selectedIdentity({required Object name}) => '선택한 클라이언트 인증 정보: ${name}';
	@override String subtitleRating({required Object rating}) => '평점 ${rating}';
	@override String subtitleDownloading({required Object title}) => '자막 다운로드 중: ${title}';
	@override String get sharedEntryPair => '이 항목을 쌍으로';
	@override String get sharedEntryPairHelp => '각 장치에서 이 항목에 대한 동일한 ID를 입력하십시오. 안정적인 공유 식별자를 사용하거나 하나를 생성하고 해당 항목으로 복사합니다. 업그레이드 파일 유형, 크기 및 주문이 일치하는 경우에만 커플됩니다. Blank은 이 맵링을 제거합니다.';
	@override String get sharedEntryId => '공유 항목 ID';
	@override String get generateSharedEntryId => '공유 항목 ID 생성';
	@override String get sharedLibraryId => '공유 도서관 ID (선택)';
	@override String get sharedLibraryHelp => '같은 도서관을 열고 있는 장치에서 동일한 ID를 사용하십시오.이 공공 ID는 다른 출처 연결을 통해 읽기 진행과 메모를 수행하는 데 도움이됩니다; 그것은 암호가 아닙니다.';
	@override String get sharedLibraryInvalid => '8 ~ 100 문자, 숫자, 포인트, 하위 코어 또는 하이펜을 사용하십시오.';
	@override String get generateSharedLibraryId => '공유 도서관 ID 만들기';
	@override String get nfsReadAhead => 'NFS 읽기-하이드 요청';
	@override String get nfsReadAheadHelp => '더 많은 병렬 리더는 빠른 NAS 또는 네트워크의 통로를 향상시킬 수 있습니다. 서버가 동일한 요청을 제한하는 경우 1을 사용합니다.';
	@override String get nfsReadTest => 'NFS 읽기 성능 측정';
	@override String get nfsReadTestHelp => '이 NAS 연결을 측정하기 위해 가장 큰 파일에서 64 MiB까지 읽습니다.이것은 네트워크 밴드 폭을 사용합니다.';
	@override String get nfsQualificationResult => 'NFS 읽기 측정';
	@override String get nfsReadBytes => '데이터 읽기';
	@override String get nfsReadSpeed => '속도 측정';
	@override String get nfsReadRequests => '요청 읽기';
	@override String get sharedEntryConflict => '이 공유 항목 ID는 이미 이 도서관의 다른 항목과 조화되어 있습니다.';
}

// Path: comics
class _Translations$comics$ko extends Translations$comics$en {
	_Translations$comics$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => '높이에 맞춤';
	@override String get readingMode => '읽기 모드';
	@override String get paged => '페이지';
	@override String get webtoon => '연속 스크롤';
	@override String get coverAlone => '표지 따로 표시';
	@override String get splitWide => '가로로 긴 페이지 나누기';
	@override String get splitWideHelp => '각 절반을 읽는 순서대로 따로 표시합니다. 이 옵션을 켜면 두 페이지 나란히 보기가 일시 중지됩니다.';
	@override String get thumbnails => '페이지 미리보기';
	@override String get controlsHelp => '스와이프하여 페이지를 넘기세요. 두 번 탭하여 맞춤 방식을 바꾸세요. 연속 스크롤에서는 세로로 스와이프하거나 Page Up 및 Page Down을 사용하세요.';
	@override String get savedForComic => '이 프로필에서 이 만화의 표시 설정을 기억합니다.';
	@override String get readLists => '읽기 목록';
	@override String get collections => '컬렉션';
}

// Path: games
class _Translations$games$ko extends Translations$games$en {
	_Translations$games$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

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
class _Translations$deepLinks$ko extends Translations$deepLinks$en {
	_Translations$deepLinks$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get invalid => '이 Plezy 링크는 유효하지 않습니다.';
	@override String profileNotFound({required Object profile}) => '프로필은 "${profile}"과 일치하지 않습니다.';
	@override String get serverUnavailable => '이 링크를 위해 서버에 접근할 수 없었습니다.';
	@override String get notFound => '이 책의 제목은 도서관에서 찾을 수 없습니다.';
	@override String get unsupportedItem => '이 링크는 재생할 수 없습니다.';
	@override String get noLiveTv => '이 링크를 위해 라이브 TV 서버가 없습니다.';
	@override String channelNotFound({required Object channel}) => '채널 "${channel}"을 찾을 수 없었습니다.';
	@override String get showLink => '링크 보기';
	@override String get showProfileLink => '프로필 링크 보기';
	@override String get dialogTitle => '링크';
	@override String get showHint => '이 링크를 열면 다음 에피소드를 재생합니다. shuffle에서 쇼를 재생하려면 &mode=shuffle을 추가합니다.';
	@override String get movieHint => '이 링크를 열면 영화가 재생됩니다.';
	@override String get episodeHint => '이 링크를 열면 이 에피소드를 재생합니다.';
	@override String get profileHint => '이 링크를 열면 이 프로필으로 스위치됩니다.';
	@override String openAsProfile({required Object name}) => '${name}으로 열기';
	@override String get copy => '복사본';
	@override String get copied => '링크 복사';
}

// Path: appIcon.names
class _Translations$appIcon$names$ko extends Translations$appIcon$names$en {
	_Translations$appIcon$names$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get midnight => '한밤';
	@override String get ember => '불씨';
	@override String get paper => '종이';
	@override String get oled => 'OLED';
	@override String get line => '라인';
	@override String get ocean => '바다';
	@override String get ultraviolet => '자외선';
	@override String get matcha => '말차';
	@override String get sunset => '노을';
	@override String get gold => '골드';
	@override String get titanium => '티타늄';
	@override String get glass => '유리';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => '신스웨이브';
	@override String get pixel => '픽셀';
	@override String get neon => '네온';
	@override String get sticker => '스티커';
	@override String get ticket => '티켓';
	@override String get pop => '팝';
	@override String get strata => '지층';
	@override String get facet => '패싯';
	@override String get tilde => '물결';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ko extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

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
class _Translations$common$mediaKind$ko extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get movie => '영화';
	@override String get show => '시리즈';
	@override String get season => '시즌';
	@override String get episode => '에피소드';
	@override String get artist => '아티스트';
	@override String get album => '앨범';
	@override String get track => '트랙';
	@override String get collection => '컬렉션';
	@override String get playlist => '재생목록';
	@override String get clip => '클립';
	@override String get photo => '사진';
	@override String get folder => '폴더';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$ko extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get discover => '연결된 발견 출처의 권장 사항 및 항목을 열어보세요.';
	@override String get libraries => '연결된 미디어 라이브러리를 열어보세요.';
	@override String get liveTv => '서버가 제공 할 때 라이브 TV를 열어; 그렇지 않으면 스타트업이 홈으로 돌아갑니다.';
	@override String get search => '오픈 미디어 검색';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$ko extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get bg => '배경';
	@override String get surface => '표면';
	@override String get outline => '윤곽선';
	@override String get text => '텍스트';
	@override String get textMuted => '보조 텍스트';
	@override String get accent => '강조색';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$ko extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => '배경 위 텍스트';
	@override String get textOnSurface => '표면 위 텍스트';
	@override String get textMutedOnBg => '배경 위 보조 텍스트';
	@override String get textMutedOnSurface => '표면 위 보조 텍스트';
	@override String get accentOnBg => '배경 위 강조색';
	@override String get accentOnSurface => '표면 위 강조색';
	@override String get labelOnAccent => '강조색 위 버튼 라벨';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$ko extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get playPause => '재생/일시정지';
	@override String get volumeUp => '볼륨 높이기';
	@override String get volumeDown => '볼륨 낮추기';
	@override String seekForward({required Object seconds}) => '앞으로 이동 (${seconds}초)';
	@override String seekBackward({required Object seconds}) => '뒤로 이동 (${seconds}초)';
	@override String get fullscreenToggle => '전체 화면 전환';
	@override String get muteToggle => '음소거 전환';
	@override String get subtitleToggle => '자막 전환';
	@override String get audioTrackNext => '다음 오디오 트랙';
	@override String get subtitleTrackNext => '다음 자막 트랙';
	@override String get chapterNext => '다음 챕터';
	@override String get chapterPrevious => '이전 챕터';
	@override String get episodeNext => '다음 에피소드';
	@override String get episodePrevious => '이전 에피소드';
	@override String get speedIncrease => '속도 높이기';
	@override String get speedDecrease => '속도 낮추기';
	@override String get speedReset => '속도 초기화';
	@override String get zoomIn => '확대';
	@override String get zoomOut => '축소';
	@override String get zoomReset => '확대/축소 초기화';
	@override String get subSeekNext => '다음 자막으로 이동';
	@override String get subSeekPrev => '이전 자막으로 이동';
	@override String get subtitleDelayIncrease => '자막 늦추기';
	@override String get subtitleDelayDecrease => '자막 앞당기기';
	@override String get shaderToggle => '셰이더 전환';
	@override String get skipMarker => '인트로/크레딧 건너뛰기';
	@override String get screenshot => '스크린샷 찍기';
	@override String get framePrevious => '이전 프레임';
	@override String get frameNext => '다음 프레임';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$ko extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 이상이 필요합니다';
	@override String get iosVersion => 'iOS 15.0 이상이 필요합니다';
	@override String get permissionDisabled => '화면 속 화면이 비활성화되어 있습니다. 시스템 설정에서 활성화하세요.';
	@override String get notSupported => '이 기기는 화면 속 화면 모드를 지원하지 않습니다';
	@override String get voSwitchFailed => '화면 속 화면을 위한 비디오 출력 전환에 실패했습니다';
	@override String get failed => '화면 속 화면 모드를 시작할 수 없습니다';
	@override String get prepareFailed => '화면 속 화면을 준비할 수 없습니다';
	@override String unknown({required Object error}) => '오류가 발생했습니다: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$ko extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get no => '글꼴, 색상, 크기 및 배치가 서브 타이틀 파일에 기록되어 있습니다.';
	@override String get yes => '플레이어의 하위 제목 스타일 설정을 ASS 하위 타이틀을 조정하도록 허용합니다.';
	@override String get scale => '플레이어 스타일링 및 스케일 내장 크기를 적용하여 비디오 차원과 일치합니다.';
	@override String get force => '삽입된 ASS 스타일을 플레이어의 하위 타이틀 스타일로 대체합니다.';
	@override String get strip => '삽입 된 ASS 형식을 제거하고 서브 타이틀 텍스트를 명확하게 수행합니다.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$ko extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get screen => '가장 뚜렷한 결과를 위해 전체 표면 해상도에서 렌더링합니다.';
	@override String get video => '참조로 비디오 해상도를 사용하여 고해상도 디스플레이에서 작업을 줄일 수 있습니다.';
	@override String get threeQuarter => '겸손한 성능 절약을 위해 디스플레이 표면 해상도의 75 %를 할인합니다.';
	@override String get half => '작업을 줄이기 위해 표시 표면 해상도의 50 %로 렌더링, 더 부드러운 가장자리.';
	@override String get third => '작업을 줄이기 위해 화면 표면 해상도의 3 분의 1에서 렌더링, 더 부드러운 가장자리.';
	@override String get quarter => '작업을 줄이기 위해 디스플레이 표면 해상도의 1 분의 1에서 렌더, 가장 부드러운 결과.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$ko extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => '오디오 및 자막';
	@override String get libraryDisplay => '라이브러리';
	@override String get personalMedia => '개인 미디어';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$ko extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get none => '수동 선택';
	@override String get noneDescription => '자동으로 자막을 켜지 않습니다.';
	@override String get defaultMode => '트랙 플래그 따르기';
	@override String get defaultModeDescription => '각 자막 트랙에 저장된 기본 및 강제 플래그를 사용합니다.';
	@override String get always => '항상 활성화';
	@override String get alwaysDescription => '선호 언어의 자막 트랙이 있으면 항상 켭니다.';
	@override String get onlyForced => '강제 자막만';
	@override String get onlyForcedDescription => '강제로 표시된 트랙만 로드합니다.';
	@override String get smart => '외국어 오디오 시 표시';
	@override String get smartDescription => '오디오가 다른 언어일 때만 자막을 켭니다.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$ko extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'SDH가 아닌 자막 선호';
	@override String get preferSdh => 'SDH 자막 선호';
	@override String get onlySdh => 'SDH 자막만';
	@override String get onlyNonSdh => 'SDH가 아닌 자막만';
	@override String get preferNonSdhDescription => '기본 및 SDH 버전 모두 사용할 수 있는 경우 표준 하위 제목을 선호합니다.';
	@override String get preferSdhDescription => '사용할 때 SDH 하위 제목을 선호하지만 표준 하위 타이틀을 붕괴로 허용합니다.';
	@override String get onlySdhDescription => 'SDH 하위 제목만 사용하십시오; 표준 하위 타이틀으로 돌아가지 마십시오.';
	@override String get onlyNonSdhDescription => '표준 하위 제목만 사용하십시오; SDH 하위 이름을 제외합니다.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$ko extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => '강제가 아닌 자막 선호';
	@override String get preferForced => '강제 자막 선호';
	@override String get onlyForced => '강제 자막만';
	@override String get onlyNonForced => '강제가 아닌 자막만';
	@override String get preferNonForcedDescription => '정기적 인 서브 타이틀을 선호하지만 붕괴로 강제 트랙을 허용합니다.';
	@override String get preferForcedDescription => '사용할 때 강제 트랙을 선호하지만, 붕괴로 정기적 인 서브 타이틀을 허용합니다.';
	@override String get onlyForcedDescription => '강제로 표시된 트랙만 사용하십시오.';
	@override String get onlyNonForcedDescription => '강제로 표시된 트랙을 제외합니다.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$ko extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get none => '안 함';
	@override String get moviesAndShows => '영화 및 TV 프로그램';
	@override String get movies => '영화만';
	@override String get shows => 'TV 프로그램만';
	@override String get noneDescription => '보관된 체크마크를 표시하지 마십시오.';
	@override String get moviesAndShowsDescription => '영화 및 TV 쇼에 대한 체크 마커를 표시합니다.';
	@override String get moviesDescription => '영화에만 시청된 체크 마크를 표시합니다.';
	@override String get showsDescription => '텔레비전 쇼에만 시청된 체크 마크를 표시합니다.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$ko extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => '사용자 및 평론가';
	@override String get usersOnly => '사용자만';
	@override String get criticsOnly => '평론가만';
	@override String get nobody => '숨김';
	@override String get usersAndCriticsDescription => '사용자 평가와 비판적 평가를 모두 표시합니다.';
	@override String get usersOnlyDescription => '사용자가 제출한 평가 및 리뷰를 표시합니다.';
	@override String get criticsOnlyDescription => '비판적 인 평가 및 리뷰를 표시합니다.';
	@override String get nobodyDescription => '평가 및 리뷰를 숨기십시오.';
}

// Path: discover.findNext
class _Translations$discover$findNext$ko extends Translations$discover$findNext$en {
	_Translations$discover$findNext$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '다음에 즐길 콘텐츠 찾기';
	@override String get open => '다음에 즐길 콘텐츠 찾기';
	@override String get anyTime => '시간 제한 없음';
	@override String get timeAvailable => '시간이 얼마나 있나요?';
	@override String get filters => '지금 이 순간에 맞게 선택하세요';
	@override String get watch => '보기';
	@override String get listen => '듣기';
	@override String get read => '읽기';
	@override String finishable({required Object duration}) => '${duration} 안에 끝낼 수 있습니다';
	@override String aboutDuration({required Object duration}) => '약 ${duration}';
	@override String nextUnit({required Object duration}) => '다음 챕터 · ${duration}';
	@override String totalDuration({required Object duration}) => '총 ${duration}';
	@override String get timingVaries => '소요 시간은 달라질 수 있습니다';
	@override String get notNow => '지금은 건너뛰기';
	@override String get swipeHint => '표지를 화살표 방향으로 밀거나 아래 버튼을 사용하세요.';
	@override String get saved => '저장한 추천';
	@override String savedCount({required Object count}) => '저장한 추천 · ${count}';
	@override String get undo => '실행 취소';
	@override String get details => '상세 정보';
	@override String get noPicks => '아직 선택할 콘텐츠가 없습니다';
	@override String get noPicksHint => '라이브러리를 연결하거나 미디어 소스를 추가하여 시작하세요.';
	@override String get noMatches => '지금 조건에 맞는 콘텐츠가 없습니다';
	@override String get noMatchesHint => '다른 미디어 종류를 선택하거나 시간을 조금 더 늘려 보세요.';
	@override String get allDone => '모든 추천을 확인했습니다';
	@override String get allDoneHint => '새로운 추천 조합을 만들면 이 선택지들을 다시 볼 수 있습니다.';
	@override String get refresh => '다른 추천 조합 찾기';
	@override String sourceReason({required Object source}) => '출처: ${source}';
	@override String libraryReason({required Object library}) => '라이브러리: ${library}';
	@override String get ownedReason => '내 라이브러리에서';
	@override String get liveNow => '현재 방송 중';
	@override String get watchLive => '실시간 시청';
	@override String get filterAnything => '모든 종류';
	@override String get filterWatch => '보기';
	@override String get filterListen => '듣기';
	@override String get filterRead => '읽기';
	@override String get twentyMinutes => '20분';
	@override String get fortyFiveMinutes => '45분';
	@override String get ninetyMinutes => '90분';
	@override String get apply => '적용';
	@override String get openFailed => '이 콘텐츠는 더 이상 이용할 수 없습니다. 새로고침하여 다시 확인하세요.';
	@override String get changeFailed => '변경 사항을 저장할 수 없습니다. 다시 시도하세요.';
	@override String get savedLimit => '저장한 추천 목록이 가득 찼습니다. 다른 추천을 저장하려면 하나를 삭제하세요.';
	@override String get chooseHint => '작품을 열거나, 나중을 위해 저장하거나, 건너뛰세요.';
	@override String get howItWorks => '사용 방법';
	@override String get notNowHelp => '이 작품을 지금은 건너뜁니다. 라이브러리에는 그대로 남습니다.';
	@override String get saveHelp => '이 기기의 현재 프로필에 저장된 추천으로 보관합니다. 저장해도 다운로드되지는 않습니다.';
	@override String get openHelp => '표지를 선택하면 상세 정보를 볼 수 있습니다. 기본 버튼으로 재생하거나 읽거나 작품을 여세요.';
	@override String get controlsHelp => '키보드나 리모컨: 버튼에 초점을 맞추고 Enter 또는 선택을 누르세요. 실행 취소는 마지막 선택을 되돌립니다.';
	@override String get artworkLoading => '이미지 불러오는 중…';
	@override String get artworkUnavailable => '이미지를 표시할 수 없음';
	@override String get savedFeedback => '저장된 추천에 추가됨';
	@override String get skippedFeedback => '지금은 건너뜀';
	@override String get releaseToConfirm => '놓아서 확인';
	@override String get remoteHint => '표지에 초점: ← / → 선택 · 선택 버튼: 상세 정보 · ↑ / ↓ 초점 이동';
}

// Path: discover.person
class _Translations$discover$person$ko extends Translations$discover$person$en {
	_Translations$discover$person$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get born => '출생';
	@override String get died => '사망';
	@override String get birthplace => '출생지';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age}세)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (향년 ${age}세)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$ko extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get recommended => '추천';
	@override String get browse => '찾아보기';
	@override String get collections => '컬렉션';
	@override String get playlists => '재생 목록';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$ko extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '그룹';
	@override String get all => '전체';
	@override String get movies => '영화';
	@override String get shows => 'TV 프로그램';
	@override String get seasons => '시즌';
	@override String get episodes => '화';
	@override String get artists => '아티스트';
	@override String get albums => '앨범';
	@override String get tracks => '트랙';
	@override String get folders => '폴더';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$ko extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get genre => '장르';
	@override String get year => '연도';
	@override String get contentRating => '시청 등급';
	@override String get tag => '태그';
	@override String get unwatched => '미시청';
	@override String get unplayed => '재생하지 않음';
	@override String get favorites => '즐겨찾기';
	@override String get filePath => '파일 경로';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$ko extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '제목';
	@override String get dateAdded => '추가된 날짜';
	@override String get releaseDate => '출시일';
	@override String get rating => '평점';
	@override String get communityRating => '커뮤니티 평점';
	@override String get criticRating => '평론가 평점';
	@override String get userRating => '사용자 평점';
	@override String get datePlayed => '재생일';
	@override String get playCount => '재생 횟수';
	@override String get productionYear => '제작 연도';
	@override String get runtime => '재생 시간';
	@override String get officialRating => '공식 등급';
	@override String get premiereDate => '최초 공개일';
	@override String get startDate => '시작일';
	@override String get airTime => '방영 시간';
	@override String get studio => '스튜디오';
	@override String get random => '무작위';
	@override String get dateShared => '공유된 날짜';
	@override String get latestEpisodeAirDate => '최신 에피소드 방영일';
	@override String get lastEpisodeDateAdded => '최신 에피소드 추가일';
	@override String get dateDownloaded => '다운로드된 날짜';
	@override String get size => '크기';
	@override String get library => '라이브러리';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$ko extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get include => '포함';
	@override String get exclude => '제외';
	@override String get any => '전체';
	@override String get yes => '예';
	@override String get no => '아니오';
	@override String not({required Object value}) => '${value} 제외';
	@override String valueCount({required Object count}) => '${count}개 선택됨';
	@override String valueCountExcluded({required Object count}) => '${count}개 제외됨';
	@override String get searchValues => '값 검색';
	@override String get noValues => '값 없음';
	@override String get matchContains => '포함';
	@override String get matchNotContains => '포함하지 않음';
	@override String get matchIs => '같음';
	@override String get matchIsNot => '같지 않음';
	@override String get matchBeginsWith => '시작 문자';
	@override String get matchEndsWith => '끝 문자';
	@override String get textHint => '일치시킬 텍스트 입력';
	@override String get from => '시작';
	@override String get to => '끝';
	@override String range({required Object from, required Object to}) => '${from}~${to}';
	@override String atLeast({required Object value}) => '${value} 이상';
	@override String atMost({required Object value}) => '${value} 이하';
	@override String dateLastDays({required Object count}) => '최근 ${count}일';
	@override String get dateLastYear => '최근 1년';
	@override String dateOlderThanDays({required Object count}) => '${count}일 이상 지남';
	@override String get dateOlderThanYear => '1년 이상 지남';
}

// Path: libraries.selection
class _Translations$libraries$selection$ko extends Translations$libraries$selection$en {
	_Translations$libraries$selection$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get selectItems => '선택 항목';
	@override String selectedCount({required Object count}) => '${count}개 선택됨';
	@override String get actions => '선택 행동';
	@override String get confirmDescendants => '이것은 선택한 쇼와 시즌의 모든 에피소드를 변경합니다.';
	@override String get confirmUnwatched => '선택한 항목의 재생 진행 상황도 초기화됩니다.';
	@override String confirmCount({required Object count}) => '선택된 항목: ${count}';
	@override String completed({required Object count}) => '업데이트된 항목: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => '업데이트 ${succeeded}; 실패 ${failed}. 실패 항목은 여전히 선택됩니다.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$ko extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get manage => '관리 탐험 층';
	@override String get manageDescription => 'MDBList 계정에서 목록을 선택하고 배열하십시오.';
	@override String get description => 'MDBList 계정에서 공개 영화 및 TV 목록을 선택하십시오. MDBList에 목록을 만들거나 복사하고 업데이트하십시오.';
	@override String get selected => '선택된 좌석';
	@override String get available => '사용 가능한 계좌 목록';
	@override String get noLists => '공개 영화 또는 TV 목록이 반환되지 않습니다. MDBList에 목록을 만들거나 복사한 다음 새롭게 해주십시오.';
	@override String get displayName => '셰일프 디스플레이 이름';
	@override String get nameHint => '출처 목록 이름을 사용하기 위해 빈을 남겨 두십시오.';
	@override String get add => '셰일프 추가';
	@override String get save => '좌석을 구하라';
	@override String moveUp({required Object title}) => '이동 ${title} 위로';
	@override String moveDown({required Object title}) => '이동 ${title} 아래로';
	@override String get unavailable => '이 목록은 사용할 수 없습니다. 설정에서 셰일을 제거하거나 제거합니다.';
	@override String get rateLimited => 'MDBList 요청 제한이 달성되었습니다. 나중에 철회하시기 바랍니다.';
	@override String get loadFailed => '선반을 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.';
	@override String get saveFailed => '선반을 저장할 수 없습니다. 다시 시도하세요.';
	@override String get accountChanged => '계정 또는 프로필이 변경되었습니다.이 설정을 다시 열어보세요.';
	@override String get settingsUnreadable => '저장된 탭은 읽을 수 없습니다.이 설정을 대체하기 위해 목록을 다시 선택합니다.';
}

// Path: explore.rows
class _Translations$explore$rows$ko extends Translations$explore$rows$en {
	_Translations$explore$rows$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get watchlist => '관심 목록';
	@override String get recommendedMovies => '추천 영화';
	@override String get recommendedShows => '추천 TV 프로그램';
	@override String get trendingMovies => '지금 뜨는 영화';
	@override String get trendingShows => '지금 뜨는 TV 프로그램';
	@override String get popularMovies => '인기 영화';
	@override String get popularShows => '인기 TV 프로그램';
	@override String get trendingAnime => '지금 뜨는 애니메이션';
	@override String get suggestedAnime => '추천 애니메이션';
	@override String get airingAnime => '방영 중인 인기 애니메이션';
	@override String get popularAnime => '가장 인기 있는 애니메이션';
	@override String get trending => '지금 뜨는 콘텐츠';
	@override String get upcomingMovies => '개봉 예정 영화';
	@override String get upcomingShows => '방영 예정 TV 프로그램';
}

// Path: explore.status
class _Translations$explore$status$ko extends Translations$explore$status$en {
	_Translations$explore$status$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get airing => '방영 중';
	@override String get ended => '종영';
	@override String get canceled => '취소됨';
	@override String get upcoming => '방영 예정';
}

// Path: explore.badge
class _Translations$explore$badge$ko extends Translations$explore$badge$en {
	_Translations$explore$badge$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} 인기';
	@override String rankAiring({required Object n}) => '#${n} 방영 중';
	@override String rankRated({required Object n}) => '#${n} 평가';
	@override String rankTrending({required Object n}) => '#${n} 트렌드';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} ${season}';
	@override String watchingNow({required Object n}) => '${n}명 시청 중';
	@override String get available => '이용 가능';
	@override String get partiallyAvailable => '부분 이용 가능';
	@override String get availableIn4k => '4K 이용 가능';
	@override String get requested => '요청됨';
	@override String get pendingApproval => '승인 대기 중';
	@override String get processing => '처리 중';
	@override String get declined => '거절됨';
	@override String get requestFailed => '요청 실패';
	@override String get requested4k => '4K 요청됨';
	@override String seasonsAvailable({required Object available, required Object total}) => '시즌 ${available}/${total}';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => '${episode}화 · ${duration} 후';
	@override String nextAiringIn({required Object duration}) => '${duration} 후 다음 화';
	@override String episodesShort({required Object n}) => '${n}화';
	@override String minutesPerEpisode({required Object n}) => '${n}분/화';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$ko extends Translations$explore$stats$en {
	_Translations$explore$stats$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n}명 등록';
	@override String viewersDay({required Object n}) => '오늘 ${n}명 시청';
	@override String viewersWeek({required Object n}) => '이번 주 ${n}명 시청';
	@override String viewersMonth({required Object n}) => '이번 달 ${n}명 시청';
	@override String viewersYear({required Object n}) => '올해 ${n}명 시청';
	@override String viewersAllTime({required Object n}) => '시청자 ${n}명';
	@override String planning({required Object n}) => '${n}명 볼 예정';
	@override String favorited({required Object n}) => '즐겨찾기 ${n}명';
	@override String dropRate({required Object percent}) => '${percent} 하차';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 댓글',
		other: '댓글 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개',
	);
	@override String votes({required Object n}) => '투표 ${n}개';
	@override String watching({required Object n}) => '시청 중 ${n}명';
	@override String completed({required Object n}) => '완료 ${n}명';
	@override String onHold({required Object n}) => '보류 ${n}명';
	@override String dropped({required Object n}) => '하차 ${n}명';
}

// Path: explore.season
class _Translations$explore$season$ko extends Translations$explore$season$en {
	_Translations$explore$season$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get winter => '겨울';
	@override String get spring => '봄';
	@override String get summer => '여름';
	@override String get fall => '가을';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}년';
}

// Path: explore.format
class _Translations$explore$format$ko extends Translations$explore$format$en {
	_Translations$explore$format$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV 단편';
	@override String get movie => '영화';
	@override String get special => '스페셜';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => '음악';
	@override String get other => '기타';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$ko extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get original => '오리지널';
	@override String get manga => '만화';
	@override String get lightNovel => '라이트 노벨';
	@override String get novel => '소설';
	@override String get visualNovel => '비주얼 노벨';
	@override String get game => '게임';
	@override String get webComic => '웹툰';
	@override String get musicRelease => '음악';
	@override String get otherMedia => '기타';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$ko extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get actor => '배우';
	@override String get director => '감독';
	@override String get writer => '각본';
	@override String get producer => '프로듀서';
	@override String get creator => '제작자';
	@override String get composer => '작곡';
}

// Path: explore.relation
class _Translations$explore$relation$ko extends Translations$explore$relation$en {
	_Translations$explore$relation$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get prequel => '프리퀄';
	@override String get sequel => '시퀄';
	@override String get sideStory => '사이드 스토리';
	@override String get spinOff => '스핀오프';
	@override String get alternativeVersion => '대체 버전';
	@override String get summary => '요약';
	@override String get parentStory => '원작';
	@override String get adaptation => '각색';
	@override String get other => '관련';
}

// Path: explore.detail
class _Translations$explore$detail$ko extends Translations$explore$detail$en {
	_Translations$explore$detail$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => '원제';
	@override String get alsoKnownAs => '다른 이름';
	@override String get studios => '스튜디오';
	@override String get country => '국가';
	@override String get language => '언어';
	@override String get released => '출시일';
	@override String get physicalRelease => '디스크 출시';
	@override String get ended => '종영';
	@override String addedOn({required Object date}) => '${date}에 추가됨';
	@override String get yourRating => '내 평점';
	@override String get budget => '제작비';
	@override String get revenue => '흥행 수익';
	@override String get contentAdvisory => '연령 등급';
	@override String get tags => '태그';
	@override String get revealSpoilerTags => '스포일러 태그 표시';
	@override String get links => '링크';
	@override String get watchOn => '시청처';
	@override String get watchTrailer => '예고편 보기';
	@override String openOn({required Object site}) => '${site}에서 열기';
	@override String get crew => '제작진';
	@override String get ratings => '평점';
	@override String get schedule => '방영 일정';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '사용자에 의해 권장 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: '사용자 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}명이 추천',
	);
	@override String recommendedBy({required Object who}) => '${who} 추천';
	@override String favoritedBy({required Object who}) => '${who} 즐겨찾기';
	@override String unairedEpisodes({required Object n}) => '미방영 ${n}개';
	@override String recommendedByPercent({required Object percent}) => '시청자의 ${percent} 추천';
	@override String get relatedTitles => '관련 작품';
	@override String get background => '배경';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$ko extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get startEarly => '일찍 시작 (초)';
	@override String get endLate => '늦게 종료 (초)';
	@override String get newOnly => '새 에피소드만';
	@override String get anyChannel => '모든 채널에서 녹화';
	@override String get anyTime => '모든 시간대에 녹화';
	@override String get skipInLibrary => '라이브러리에 이미 있는 에피소드 건너뛰기';
	@override String get keepUpTo => '보관할 에피소드 수';
	@override String get keepUpToHint => '0이면 모든 에피소드 보관';
}

// Path: music.discography
class _Translations$music$discography$ko extends Translations$music$discography$en {
	_Translations$music$discography$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => '싱글 및 EP';
	@override String get live => '라이브';
	@override String get compilations => '컴필레이션';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$ko extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name}님이 재생을 눌렀습니다';
	@override String get playbackStarted => '재생이 시작되었습니다';
	@override String paused({required Object name}) => '${name}님이 일시정지했습니다';
	@override String get playbackPaused => '재생이 일시정지되었습니다';
	@override String jumpedTo({required Object name, required Object position}) => '${name}님이 ${position}(으)로 이동했습니다';
	@override String roomJumpedTo({required Object position}) => '${position}(으)로 이동했습니다';
	@override String changedSpeed({required Object name, required Object speed}) => '${name}님이 속도를 ${speed}(으)로 설정했습니다';
	@override String speedChanged({required Object speed}) => '속도가 ${speed}(으)로 설정되었습니다';
	@override String startedMedia({required Object name, required Object title}) => '${name}님이 ${title} 재생을 시작했습니다';
	@override String mediaStarted({required Object title}) => '지금 재생 중: ${title}';
	@override String stoppedMedia({required Object name}) => '${name}님이 비디오를 중지했습니다';
	@override String get mediaStopped => '비디오가 중지되었습니다';
	@override String waitingFor({required Object name}) => '${name}님을 기다리는 중...';
	@override String get waitingForSomeone => '다른 참가자를 기다리는 중...';
	@override String get finished => '재생 완료';
	@override String hostChangedTo({required Object name}) => '${name}님이 호스트가 되었습니다';
	@override String get youAreNowHost => '이제 호스트입니다';
	@override String joined({required Object name}) => '${name}님이 참여했습니다';
	@override String left({required Object name}) => '${name}님이 나갔습니다';
	@override String get controlRefused => '호스트만 재생을 제어할 수 있습니다';
	@override String get searchFailed => '일부 서버에서 방의 비디오를 검색하지 못했습니다';
	@override String get playBlocked => '재생을 눌러 시작하세요';
	@override String get shareFailed => '이 비디오를 방에 공유하지 못했습니다';
	@override String get downloadNotShared => '서버가 오프라인인 동안에는 다운로드한 항목이 방에 공유되지 않습니다';
	@override String get openFailed => '방의 비디오를 열지 못했습니다';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$ko extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get ended => '호스트가 방을 종료했습니다';
	@override String get kicked => '방에서 내보내졌습니다';
	@override String get expired => '방이 만료되었습니다';
	@override String get replaced => '다른 기기에서 이 방에 참여했습니다';
	@override String get lost => '방과의 연결이 끊어졌습니다';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$ko extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => '방 코드가 아닙니다. 코드는 0, 1, I, L 또는 O를 제외한 영문자와 숫자 6자리입니다.';
	@override String get roomNotFound => '해당 코드의 방이 없습니다. 종료되었을 수 있습니다.';
	@override String get roomFull => '방이 가득 찼습니다.';
	@override String get roomLocked => '호스트가 방을 잠갔습니다.';
	@override String get relayFull => '지금은 함께 보기 이용자가 많습니다. 나중에 다시 시도하세요.';
	@override String get unreachable => '함께 보기 릴레이에 연결할 수 없습니다. 연결을 확인하세요.';
	@override String get rateLimited => '시도 횟수가 너무 많습니다. 잠시 후 다시 시도하세요.';
	@override String get clientBlocked => '이 버전의 Plezy는 릴레이를 사용할 수 없습니다. 앱을 업데이트하세요.';
	@override String get forbidden => '호스트만 이 작업을 할 수 있습니다.';
	@override String get notInRoom => '방에 참여하고 있지 않습니다.';
	@override String get alreadyInRoom => '이미 방에 참여하고 있습니다.';
	@override String get resumeFailed => '방에 다시 참여하지 못했습니다.';
	@override String get unsupported => '릴레이에서 지원하지 않는 기능입니다.';
	@override String get generic => '문제가 발생했습니다. 다시 시도하세요.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$ko extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => '앱에서 나가면 다운로드가 중지됩니다';
	@override String get bannerDegraded => '백그라운드 다운로드가 제한될 수 있습니다';
	@override String get bannerAction => '세부정보';
	@override String get sheetTitle => '백그라운드 다운로드가 차단됨';
	@override String get sheetTitleDegraded => '백그라운드 다운로드가 제한될 수 있음';
	@override String get sheetIntro => 'Android가 Plezy의 안정적인 백그라운드 다운로드를 차단하고 있습니다.';
	@override String get sheetIntroDegraded => '기기에서 Plezy가 백그라운드로 다운로드할 수 있는 시점을 제한하고 있습니다.';
	@override String get reasonBackgroundRestricted => 'Plezy의 백그라운드 사용이 제한되어 있습니다. 배터리 또는 백그라운드 사용을 "제한 없음"으로 설정하세요.';
	@override String get reasonStandbyRestricted => 'Android가 Plezy를 제한된 대기 상태로 전환했습니다. 배터리 사용량을 "제한 없음"으로 설정하세요.';
	@override String get reasonDownloadChannelBlocked => '다운로드 알림이 꺼져 있어 진행 상황과 제어 기능을 사용하지 못할 수 있습니다.';
	@override String get reasonNotificationsDisabled => '알림이 꺼져 있습니다. Android 13 이상에서는 장시간 백그라운드 다운로드에 알림이 필요합니다.';
	@override String get reasonDataSaver => '데이터 절약 모드가 켜져 있어 모바일 데이터로 백그라운드 다운로드를 할 수 없습니다. Wi-Fi에서는 계속 다운로드할 수 있습니다.';
	@override String get reasonOemUnknown => 'Plezy가 백그라운드에 있을 때 다운로드가 반복해서 중지되었습니다. Plezy의 배터리 또는 백그라운드 사용 설정을 확인하세요.';
	@override String get openSettings => '설정 열기';
	@override String get stillNotWorking => '기기별 도움말';
	@override String get stillNotWorkingDescription => '기기에 맞는 단계를 확인하세요. 문제가 계속되면 설정 › 로그 보기에서 로그를 보내 주세요.';
	@override String get dialogTitle => '다운로드가 완료되지 않을 수 있음';
	@override String get dialogDownloadAnyway => '그래도 다운로드';
	@override String get dialogFixFirst => '먼저 문제 해결';
	@override String get statusTile => '백그라운드 다운로드';
	@override String get statusOk => '백그라운드 실행 허용됨';
	@override String get statusBlocked => '시스템 설정에 의해 차단됨';
	@override String get statusDegraded => '시스템 설정에 의해 제한됨';
	@override String get statusUnknown => '아직 확인하지 않음';
	@override String get settingsUnavailable => '이 기기에서 시스템 설정을 열 수 없습니다';
	@override String get linkUnavailable => '이 기기에서 dontkillmyapp.com을 열 수 없습니다';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$ko extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get library => '라이브러리';
	@override String get collections => '컬렉션';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$ko extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get startingServer => '원격 서버 시작 중...';
	@override String get hostAddress => '호스트 주소';
	@override String get connected => '연결됨';
	@override String get serverRunning => '원격 서버 활성';
	@override String get serverStopped => '원격 서버 중지됨';
	@override String get serverRunningDescription => '네트워크의 모바일 기기가 이 앱에 연결할 수 있습니다';
	@override String get serverStoppedDescription => '모바일 기기의 연결을 허용하려면 서버를 시작하세요';
	@override String get usePhoneToControl => '모바일 기기로 이 앱을 제어하세요';
	@override String get startServer => '서버 시작';
	@override String get stopServer => '서버 중지';
	@override String get minimize => '최소화';
	@override String get manualAddressHint => '수동 연결 주소:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$ko extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '같은 Plex 계정의 PlezyNG 기기가 여기에 표시됩니다';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '연결 중...';
	@override String get searchingForDevices => '기기 검색 중...';
	@override String get noDevicesFound => '네트워크에서 기기를 찾을 수 없습니다';
	@override String get noDevicesHint => '데스크톱에서 Plezy를 열고 같은 Wi-Fi를 사용하세요';
	@override String get availableDevices => '사용 가능한 기기';
	@override String get manualConnection => '수동 연결';
	@override String get cryptoInitFailed => '보안 연결을 시작할 수 없습니다. 먼저 Plex에 로그인하세요.';
	@override String get validationHostRequired => '호스트 주소를 입력하세요';
	@override String get validationHostFormat => '형식은 IP:포트여야 합니다 (예: 192.168.1.100:48632)';
	@override String get connectionTimedOut => '연결 시간이 초과되었습니다. 두 기기에서 같은 네트워크를 사용하세요.';
	@override String get sessionNotFound => '기기를 찾을 수 없습니다. 호스트에서 Plezy가 실행 중인지 확인하세요.';
	@override String get authFailed => '인증에 실패했습니다. 두 기기 모두 같은 Plex 계정이 필요합니다.';
	@override String failedToConnect({required Object error}) => '연결 실패: ${error}';
	@override String get codeTitle => '커플 코드';
	@override String get codeDescription => '호스트 장치에서 Companion Remote에서 표시된 코드를 입력합니다.두 장치는 안전한 커플링을 지원하는 버전을 사용해야 합니다.';
	@override String get codeInvalid => '호스트 코드에서 32 문자와 숫자를 모두 입력합니다.';
	@override String get updateRequired => '두 장치를 안전한 커플링을 지원하는 버전으로 업데이트합니다.';
	@override String get hostDescription => '각 원격으로 한 번 이 코드를 입력합니다.이 코드를 개인적으로 유지하십시오.이 코드는 이 프로필을 제어합니다.';
	@override String get resetCode => '쌍 코드 복구';
	@override String get resetDescription => '모든 원격을 분리하고 새로운 코드를 만들 수 있습니다.모든 원격은 다시 쌍을해야합니다.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$ko extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '원격 세션 연결을 해제하시겠습니까?';
	@override String get reconnecting => '재연결 중...';
	@override String attemptOf({required Object current}) => '${current}/5 시도 중';
	@override String get retryNow => '지금 재시도';
	@override String get tabRemote => '리모컨';
	@override String get tabPlay => '재생';
	@override String get tabMore => '더 보기';
	@override String get menu => '메뉴';
	@override String get tabNavigation => '탭 탐색';
	@override String get tabDiscover => '둘러보기';
	@override String get tabLibraries => '미디어 라이브러리';
	@override String get tabSearch => '검색';
	@override String get tabDownloads => '다운로드';
	@override String get tabSettings => '설정';
	@override String get previous => '이전';
	@override String get playPause => '재생/일시정지';
	@override String get next => '다음';
	@override String get seekBack => '되감기';
	@override String get stop => '정지';
	@override String get seekForward => '빨리감기';
	@override String get volume => '볼륨';
	@override String get volumeDown => '줄이기';
	@override String get volumeUp => '높이기';
	@override String get fullscreen => '전체 화면';
	@override String get subtitles => '자막';
	@override String get audio => '오디오';
	@override String get searchHint => '데스크톱에서 검색...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$ko extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => '네트워크 인터페이스를 찾을 수 없습니다';
	@override String get authenticationFailed => '인증 실패';
	@override String serverStartFailed({required Object error}) => '원격 서버를 시작하지 못했습니다: ${error}';
	@override String commandFailed({required Object error}) => '원격 명령을 보내지 못했습니다: ${error}';
	@override String get joinTimedOut => '세션 참가 시간이 초과되었습니다';
	@override String get failedToConnectAnyAddress => '어떤 주소에도 연결하지 못했습니다';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts}회 시도 후 연결이 끊어졌습니다';
	@override String get connectionLost => '연결이 끊어졌습니다';
}

// Path: services.names
class _Translations$services$names$ko extends Translations$services$names$en {
	_Translations$services$names$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$ko extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Simkl 다시 연결';
	@override String get subtitle => 'Simkl이 이 연결에 사용되는 로그인 방식을 종료합니다. 다시 연결하면 simkl.com이 열리고 그곳에서 Plezy를 승인합니다 — Plezy는 비밀번호를 볼 수 없습니다. 시청 기록은 Simkl에 그대로 유지됩니다.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$ko extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service}에서 PlezyNG 활성화';
	@override String get instructions => 'QR 코드를 스캔하거나 아래 주소로 이동하여 이 코드를 입력하세요:';
	@override String openToActivate({required Object service}) => '활성화하려면 ${service} 열기';
	@override String get copyCode => '활성화 코드 복사';
	@override String get waitingForAuthorization => '인증을 기다리는 중…';
	@override String get codeCopied => '코드가 복사되었습니다';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$ko extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service}에 로그인';
	@override String get body => '이 QR 코드를 스캔하거나 아무 기기에서 URL을 여세요.';
	@override String openToSignIn({required Object service}) => '로그인하려면 ${service} 열기';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$ko extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => '로그인 URL 복사';
	@override String get urlCopied => 'URL이 복사되었습니다';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$ko extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '라이브러리 필터';
	@override String get subtitleAllSyncing => '모든 라이브러리 동기화 중';
	@override String get subtitleNoneSyncing => '동기화 안 함';
	@override String subtitleBlocked({required Object count}) => '${count}개 차단됨';
	@override String subtitleAllowed({required Object count}) => '${count}개 허용됨';
	@override String get mode => '필터 모드';
	@override String get modeBlacklist => '차단 목록';
	@override String get modeWhitelist => '허용 목록';
	@override String get modeHintBlacklist => '아래에 선택한 라이브러리를 제외한 모든 라이브러리를 동기화합니다.';
	@override String get modeHintWhitelist => '아래에 선택한 라이브러리만 동기화합니다.';
	@override String get libraries => '라이브러리';
	@override String get noLibraries => '사용 가능한 라이브러리가 없습니다';
	@override String get modeDescription => '검사된 도서관이 동기화에서 차단되었는지, 아니면 동기화를 하는 유일한 라이브러리인지 선택합니다.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$ko extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get trakt => '트랙 계정과 함께 시청된 에피소드와 영화를 동기화합니다.';
	@override String get mal => '애니메이션 목록을 동기화하고 MyAnimeList로 진행을 시청합니다.';
	@override String get anilist => '애니메이션 목록을 동기화하고 AniList와 함께 진행을 지켜보십시오.';
	@override String get simkl => 'Sync는 Simkl와 함께 영화, TV 쇼 및 애니메이션을 보았습니다.';
	@override String get mdblist => '추천 및 탐색에서 MDBList 등급 및 목록을 표시합니다.';
}

/// The flat map containing all translations for locale <ko>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsKo {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => '앱 아이콘',
			'appIcon.defaultIcon' => '기본',
			'appIcon.current' => '현재 아이콘',
			'appIcon.locked' => '인생 접근이 필요합니다',
			'appIcon.lockedHint' => '7일간의 시험을 시작하거나 PlezyNG을 잠그거나 대체 아이콘을 사용하십시오.',
			'appIcon.changeFailed' => '앱 아이콘을 변경하지 못했습니다',
			'appIcon.launcherHint' => 'Plezy를 나가면 홈 화면에 새 아이콘이 표시됩니다.',
			'appIcon.tvLauncherHint' => 'Plezy를 나가면 새 배너가 표시됩니다. Android TV에서는 TV를 다시 시작할 때까지 이전 배너가 계속 표시될 수 있습니다.',
			'appIcon.names.midnight' => '한밤',
			'appIcon.names.ember' => '불씨',
			'appIcon.names.paper' => '종이',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => '라인',
			'appIcon.names.ocean' => '바다',
			'appIcon.names.ultraviolet' => '자외선',
			'appIcon.names.matcha' => '말차',
			'appIcon.names.sunset' => '노을',
			'appIcon.names.gold' => '골드',
			'appIcon.names.titanium' => '티타늄',
			'appIcon.names.glass' => '유리',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => '신스웨이브',
			'appIcon.names.pixel' => '픽셀',
			'appIcon.names.neon' => '네온',
			'appIcon.names.sticker' => '스티커',
			'appIcon.names.ticket' => '티켓',
			'appIcon.names.pop' => '팝',
			'appIcon.names.strata' => '지층',
			'appIcon.names.facet' => '패싯',
			'appIcon.names.tilde' => '물결',
			'appIcon.description' => '장치 시작자에 의해 표시된 아이콘을 선택합니다.예비 보기에서는 각 옵션이 어떻게 보이는지 보여줍니다.',
			'auth.signInWithPlex' => 'Plex 계정으로 로그인',
			'auth.showQRCode' => 'QR 코드 표시',
			'auth.authenticate' => '인증',
			'auth.authenticationTimeout' => '인증 시간이 초과되었습니다. 다시 시도해 주세요.',
			'auth.scanQRToSignIn' => '로그인하려면 이 QR 코드를 스캔하세요',
			'auth.waitingForAuth' => '인증 대기 중...\n브라우저에서 로그인하세요.',
			'auth.useBrowser' => '브라우저 사용',
			'auth.or' => '또는',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}에 연결',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Quick Connect 사용',
			'auth.quickConnectInstructions' => 'Jellyfin에서 Quick Connect를 열고 이 코드를 입력하세요.',
			'auth.quickConnectWaiting' => '승인 대기 중…',
			'auth.quickConnectCancel' => '취소',
			'auth.quickConnectExpired' => 'Quick Connect가 만료되었습니다. 다시 시도하세요.',
			'auth.localDataRecoveryRequired' => 'Plezy에서 로컬 로그인 정보와 대기 중인 재생 데이터를 안전하게 복구하지 못했습니다. 다시 로그인해 주세요.',
			'auth.pinCheckRejected' => 'Plex PIN 확인이 거부되었습니다',
			'auth.connectToDirectPlex' => '지역 서버 Plex에 연결',
			'common.cancel' => '취소',
			'common.save' => '저장',
			'common.close' => '닫기',
			'common.closeMiniPlayer' => '미니 플레이어 근처',
			'common.closeWorkspaceWindow' => '가까운 창문',
			'common.returnToFullView' => '완전한 시야로 돌아가기',
			'common.manageMediaSessions' => '미디어 세션 관리',
			'common.hideMediaSessions' => '미디어 세션 숨기기',
			'common.mediaSessions' => '미디어 세션',
			'common.mediaSessionsHint' => '파크는 창을 숨기지만 열려 있습니다. 반환은 완전한 전망으로 열립니다; 가까운 끝은 그것입니다.',
			'common.sessionInWorkspace' => '워크샵에서',
			'common.sessionParked' => '주차',
			'common.sessionFullscreen' => '전체 스크린',
			'common.switchToNextWindow' => '다음 창으로 전환',
			'common.moveWindow' => '움직이는 창문',
			'common.finishMovingWindow' => '움직이는 창을 마무리',
			'common.moveWindowHint' => '긴 밀어 넣고 창을 끌어서 이동합니다.이 컨트롤은 또한 열쇠 움직임을 허용합니다.',
			'common.movingWindowHelp' => '끌기 이동 · 끌 키 조정 · 입력 저장 · 탈출 취소',
			'common.resizeWindow' => '윈도우 재설정',
			'common.resizeWindowHint' => '이 손잡이를 끌거나 창을 재구성하기 위해 총 열쇠를 사용하십시오.',
			'common.workspaceWindowHint' => '움직임 컨트롤 또는 긴 압축을 사용 하 여 이동 하 고 끌어.',
			'common.workspacePaneHint' => '이 패널을 선택하여 초점을 맞추십시오.전체 스크린 컨트롤을 사용하여 확장합니다.',
			'common.workspaceWindowLabel' => ({required Object title}) => '세션 창: ${title}',
			'common.workspaceTitleHint' => '초점을 선택합니다. 이동하려면 제목 바를 끌어; 확장하기 위해 전체 스크린 버튼을 사용합니다.',
			'common.moveToSessionTray' => '세션 트레이로 이동',
			'common.moveToSessionTrayHint' => '이 세션은 창을 표시하지 않고 사용할 수 있습니다.',
			'common.closeSessionHint' => '이 창을 닫고 세션이 끝납니다.',
			'common.sideBySideLayout' => '스위치 - Side-by-side layout',
			'common.floatingWindows' => '윈도우를 흐르는 스위치',
			'common.clear' => '지우기',
			'common.reset' => '초기화',
			'common.later' => '나중에',
			'common.submit' => '제출',
			'common.confirm' => '확인',
			'common.retry' => '재시도',
			'common.logout' => '로그아웃',
			'common.unknown' => '알 수 없는',
			'common.refresh' => '새로고침',
			'common.yes' => '예',
			'common.no' => '아니오',
			'common.delete' => '삭제',
			'common.edit' => '편집',
			'common.shuffle' => '무작위 재생',
			'common.addTo' => '추가하기...',
			'common.createNew' => '새로 만들기',
			'common.connect' => '연결',
			'common.disconnect' => '연결 해제',
			'common.play' => '재생',
			'common.pause' => '일시정지',
			'common.resume' => '재개',
			'common.error' => '오류',
			'common.search' => '검색',
			'common.home' => '홈',
			'common.back' => '뒤로',
			'common.settings' => '설정',
			'common.mute' => '음소거',
			'common.ok' => '확인',
			'common.off' => '꺼짐',
			'common.options' => '옵션',
			'common.seasonNumber' => ({required Object number}) => '시즌 ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '${number}화 - ${title}',
			'common.chapterNumber' => ({required Object number}) => '챕터 ${number}',
			'common.reconnect' => '다시 연결',
			'common.viewAll' => '모두 보기',
			'common.checkingNetwork' => '네트워크 확인 중...',
			'common.loadingServers' => '서버 로딩 중...',
			'common.connectingToServers' => '서버 연결 중...',
			'common.startingOfflineMode' => '오프라인 모드 시작 중...',
			'common.loading' => '로딩 중...',
			'common.fullscreen' => '전체 화면',
			'common.exitFullscreen' => '전체 화면 종료',
			'common.pressBackAgainToExit' => '한 번 더 누르면 종료됩니다',
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
			'common.mediaKind.movie' => '영화',
			'common.mediaKind.show' => '시리즈',
			'common.mediaKind.season' => '시즌',
			'common.mediaKind.episode' => '에피소드',
			'common.mediaKind.artist' => '아티스트',
			'common.mediaKind.album' => '앨범',
			'common.mediaKind.track' => '트랙',
			'common.mediaKind.collection' => '컬렉션',
			'common.mediaKind.playlist' => '재생목록',
			'common.mediaKind.clip' => '클립',
			'common.mediaKind.photo' => '사진',
			'common.mediaKind.folder' => '폴더',
			'screens.licenses' => '라이선스',
			'screens.switchProfile' => '프로필 전환',
			'screens.subtitleStyling' => '자막 스타일 설정',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => '로그',
			'update.available' => '업데이트 있음',
			'update.versionAvailable' => ({required Object version}) => '${version} 버전을 사용할 수 있습니다',
			'update.currentVersion' => ({required Object version}) => '현재 버전: ${version}',
			'update.skipVersion' => '이 버전 건너뛰기',
			'update.viewRelease' => '릴리스 정보 보기',
			'update.latestVersion' => '최신 버전을 사용 중입니다',
			'update.checkFailed' => '업데이트 확인 실패',
			'settings.title' => '설정',
			'settings.supportDeveloper' => 'PlezyNG 후원하기',
			'settings.supportDeveloperDescription' => '기부로 개발을 지원하세요',
			'settings.lifetimeAccess' => 'PlezyNG 평생 액세스',
			'settings.language' => '언어',
			'settings.theme' => '테마',
			'settings.appearance' => '디자인',
			'settings.detailPage' => '자세한 페이지',
			'settings.themeSongsEnabled' => '주제 노래를 연주',
			'settings.themeSongsEnabledDescription' => '미디어 세부 사항을 볼 때 사용 가능한 테마 노래를 재생합니다.',
			'settings.themeSongVolume' => '노래의 곡 Volume',
			'settings.videoPlayback' => '비디오 재생',
			'settings.videoPlaybackDescription' => '재생 동작 설정',
			'settings.advanced' => '고급',
			'settings.episodePosterMode' => '에피소드 포스터 스타일',
			'settings.seriesPoster' => '시리즈 포스터',
			'settings.seasonPoster' => '시즌 포스터',
			'settings.episodeThumbnail' => '썸네일',
			'settings.showHeroSectionDescription' => '홈 화면에 주요 콘텐츠 캐러셀(슬라이드) 표시',
			'settings.secondsLabel' => '초',
			'settings.minutesLabel' => '분',
			'settings.secondsShort' => '초',
			'settings.minutesShort' => '분',
			'settings.durationHint' => ({required Object min, required Object max}) => '기간 입력 (${min}-${max})',
			'settings.systemTheme' => '시스템',
			'settings.lightTheme' => '라이트',
			'settings.darkTheme' => '다크',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => '불씨',
			'settings.glacierTheme' => '빙하',
			'settings.forestTheme' => '숲',
			'settings.plumTheme' => '자두',
			'settings.paperTheme' => '종이',
			'settings.libraryDensity' => '라이브러리 표시 밀도',
			'settings.displayScale' => '표시 배율',
			'settings.compact' => '조밀하게',
			'settings.comfortable' => '여유롭게',
			'settings.gridSpacing' => '그리드 간격',
			'settings.gridSpacingTight' => '조밀하게',
			'settings.gridSpacingNormal' => '보통',
			'settings.gridSpacingSpacious' => '여유롭게',
			'settings.tvCornerSpotlightBackdrop' => '모서리 스포트라이트 배경',
			'settings.tvCornerSpotlightBackdropDescription' => '화면 전체를 채우는 대신 오른쪽 상단에 스포트라이트 아트워크를 표시합니다',
			'settings.viewMode' => '보기 모드',
			'settings.gridView' => '그리드 보기',
			'settings.listView' => '목록 보기',
			'settings.showHeroSection' => '주요 추천 영역 표시',
			'settings.showHomeBackdrop' => 'Home Backdrop 예술 작품 보기',
			'settings.showHomeBackdropDescription' => '큰 예술 작품을 보여주고, 가정 라인 뒤에',
			'settings.contentScreensaverEnabled' => '콘텐츠 스크린 스토어',
			'settings.contentScreensaverEnabledDescription' => '앱이 아이돌이 된 후에 전체 스크린 아트워크를 표시합니다.',
			'settings.contentScreensaverDelay' => '스크린 스토어를 시작한 후',
			'settings.contentScreensaverLibraries' => '스크린 스토어 도서관',
			'settings.contentScreensaverLibrariesDescription' => '화면 보호기 이미지에 사용할 라이브러리를 선택하세요. 아무것도 선택하지 않으면 모든 라이브러리의 이미지가 사용됩니다.',
			'settings.contentScreensaverAllLibraries' => '모든 도서관',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} 선택된 도서관',
			'settings.contentScreensaverNoLibraries' => '연결된 미디어 도서관은 없습니다.',
			'settings.contentScreensaverDismissHint' => '버튼을 누르거나 삭제를 눌러',
			'settings.newEpisodeNotifications' => '새로운 에피소드 알림',
			'settings.newEpisodeNotificationsDescription' => '새 에피소드가 쇼에 추가되면 경고를 받으십시오. Plezy이 열려있는 동안 확인합니다.',
			'settings.continueWatchingRowSize' => '계속해서 롤 크기를 보세요.',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} 카드',
			'settings.rowSizeCompact' => '조밀하게',
			'settings.rowSizeStandard' => '표준',
			'settings.rowSizeLarge' => '대형',
			'settings.continueWatchingAction' => '계속 보기 동작',
			'settings.continueWatchingPlay' => '재생',
			'settings.continueWatchingDetails' => '상세 정보 열기',
			'settings.episodeAction' => '에피소드 동작',
			'settings.episodePlay' => '재생',
			'settings.episodeDetails' => '상세 정보 열기',
			'settings.useGlobalHubs' => '홈 레이아웃 사용',
			'settings.useGlobalHubsDescription' => '통합 홈 허브를 표시합니다. 끄면 라이브러리 추천을 사용합니다.',
			'settings.showServerNameOnHubs' => '허브에 서버 이름 표시',
			'settings.showServerNameOnHubsDescription' => '허브 제목에 항상 서버 이름을 표시합니다.',
			'settings.groupLibrariesByServer' => '서버별로 라이브러리 그룹화',
			'settings.groupLibrariesByServerDescription' => '사이드바 라이브러리를 미디어 서버별로 그룹화합니다.',
			'settings.alwaysKeepSidebarOpen' => '사이드바 항상 열어두기',
			'settings.alwaysKeepSidebarOpenDescription' => '사이드바가 확장된 상태로 유지되고 콘텐츠 영역이 맞춰집니다',
			'settings.showUnwatchedCount' => '미시청 수 표시',
			'settings.showUnwatchedCountDescription' => '시리즈 및 시즌에 미시청 에피소드 수 표시',
			'settings.showWatchedIndicators' => '시청 표시 보이기',
			'settings.showWatchedIndicatorsDescription' => '시청한 영화, 프로그램, 에피소드에 체크 표시를 표시합니다',
			'settings.showEpisodeNumberOnCards' => '카드에 에피소드 번호 표시',
			'settings.showEpisodeNumberOnCardsDescription' => '에피소드 카드에 시즌 및 에피소드 번호 표시',
			'settings.showSeasonPostersOnTabs' => '탭에 시즌 포스터 표시',
			'settings.showSeasonPostersOnTabsDescription' => '각 시즌 포스터를 탭 위에 표시',
			'settings.tvFullCardLayout' => '전체 TV 카드',
			'settings.tvFullCardLayoutDescription' => 'TV 카드에 이미지만 표시하고 배우 이름을 오버레이로 표시',
			'settings.focusGlow' => '포커스 글로우',
			'settings.focusGlowDescription' => '포커스된 카드 주위에 은은한 빛 효과를 표시',
			'settings.visualEffects' => '시각 효과',
			'settings.visualEffectsAuto' => '자동',
			'settings.visualEffectsAutoDescription' => '저전력 기기에서 효과를 자동으로 줄입니다',
			'settings.visualEffectsFull' => '전체',
			'settings.visualEffectsReduced' => '축소',
			'settings.visualEffectsReducedDescription' => '애니메이션을 줄이고 아트워크 해상도를 낮춥니다',
			'settings.hideSpoilers' => '미시청 에피소드 스포일러 숨기기',
			'settings.hideSpoilersDescription' => '시청하지 않은 에피소드의 썸네일과 설명을 흐리게 처리',
			'settings.playerBackend' => '플레이어 백엔드',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => '하드웨어 디코딩',
			'settings.hardwareDecodingDescription' => '가능한 경우 하드웨어 가속을 사용합니다',
			'settings.playbackBuffer' => '재생 버퍼',
			'settings.playbackBufferAuto' => '자동 (권장)',
			'settings.playbackBufferLarge' => '대형',
			'settings.playbackBufferExtraLarge' => '초대형',
			'settings.playbackBufferDescription' => '불안정한 연결에 대비해 더 많은 버퍼를 사용합니다. 버퍼 크기에 의해서도 제한됩니다.',
			'settings.streamBufferSize' => '부퍼 크기',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => '얼마나 많은 비디오를 직접 재생할 때 앞으로 충전해야 하는지.Transcodes는 서버의 자체 transcode 버퍼에서 멈추게 됩니다. 0 = 자동',
			'settings.streamBufferSizeExoNote' => '설정할 때 Playback Buffer를 대체하고, 앱의 메모리 한도 절반에 캡처',
			'settings.streamBufferMegabytes' => '메가바이트',
			'settings.defaultQualityTitle' => '기본 화질',
			'settings.cellularQualityTitle' => '셀룰러에서 기본 화질',
			'settings.remoteQualityTitle' => '원격 스트리밍 품질',
			'settings.remoteQualitySameAsDefault' => '기본 품질과 동일한',
			'settings.cellularQualitySameAsDefault' => '기본 화질과 동일',
			'settings.directPlayCoveredQuality' => '작은 동영상을 원본 화질로 재생',
			'settings.directPlayCoveredQualityDescription' => '화질 제한 내의 동영상은 트랜스코딩하지 않고 Direct Play합니다',
			'settings.videoCodecs' => '비디오 코덱',
			'settings.videoCodecsDescription' => '선택 해제한 코덱은 서버가 트랜스코딩합니다',
			'settings.videoCodecsAlwaysAccepted' => '항상 허용',
			'settings.musicQualityTitle' => '음악 음질',
			'settings.subtitleStyling' => '자막 스타일',
			'settings.subtitleStylingDescription' => '자막 모양을 사용자 지정합니다',
			'settings.smallSkipDuration' => '짧은 건너뛰기 시간',
			'settings.largeSkipDuration' => '긴 건너뛰기 시간',
			'settings.rewindOnResume' => '재개 시 되감기',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)}초', ), 
			'settings.defaultSleepTimer' => '기본 취침 타이머',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)}분', ), 
			'settings.rememberTrackSelections' => '시리즈/영화별 트랙 선택 기억',
			'settings.chooseTracksBeforePlayback' => '재생 전에 오디오 및 하위 제목을 선택합니다.',
			'settings.chooseTracksBeforePlaybackDescription' => '각 비디오가 시작되기 전에 소스 오디오 및 하위 제목 트랙을 선택합니다.',
			'settings.alwaysShowSubtitlesOnDevice' => '항상 이 장치에 서브 타이틀을 표시합니다.',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => '서버가 선택된 하위 제목이 없으면 로컬로 트랙을 선택합니다.이것은 서버의 선호도를 결코 변경하지 않습니다.',
			'settings.autoDownloadPreferredSubtitle' => '페치가 좋아하는 언어 서브 타이틀을 놓치고 있다.',
			'settings.autoDownloadPreferredSubtitleDescription' => '좋아하는 언어로 사용할 수 있는 하위 제목을 현지적으로 선택합니다.이 언어가 존재하지 않는 경우, 지원되는 경우 서버에 하나를 캡처하도록 요청합니다.',
			'settings.rememberTrackSelectionsDescription' => '작품별 오디오 및 자막 선택 기억',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex는 파일별로 각 선택을 서버에 저장합니다. Jellyfin은 계정의 선택 기억도 활성화합니다. Emby는 지원되지 않습니다',
			'settings.followServerTrackSelections' => '서버의 에피소드별 트랙 선택 사용',
			'settings.followServerTrackSelectionsDescription' => '에피소드 전환 시 현재 선택을 유지하는 대신 서버에서 선택된 오디오와 자막을 적용합니다',
			'settings.resumeMusicOnLaunch' => '음악 세션 기억',
			'settings.resumeMusicOnLaunchDescription' => '앱 시작 시 마지막 곡을 멈춘 위치에서 일시정지 상태로 엽니다',
			'settings.showChapterMarkersOnTimeline' => '탐색 막대에 챕터 마커 표시',
			'settings.showChapterMarkersOnTimelineDescription' => '챕터 경계에서 탐색 막대 구분',
			'settings.specialsOrdering' => '에피소드 순서로 스페셜 표시',
			'settings.specialsOrderingDescription' => '시리즈 시청 순서에서 스페셜이 재생되는 위치',
			'settings.specialsOrderingServer' => '서버 순서 따르기',
			'settings.specialsOrderingAirDate' => '방영일 순서로 삽입',
			'settings.specialsOrderingLast' => '일반 시즌 뒤',
			'settings.clickVideoTogglesPlayback' => '동영상 클릭으로 재생/일시정지 전환',
			'settings.clickVideoTogglesPlaybackDescription' => '컨트롤을 표시하는 대신 동영상을 클릭하여 재생하거나 일시정지합니다.',
			'settings.videoPlayerControls' => '비디오 플레이어 컨트롤',
			'settings.keyboardShortcuts' => '키보드 단축키',
			'settings.keyboardShortcutsDescription' => '키보드 단축키를 사용자 지정합니다',
			'settings.videoPlayerNavigation' => '비디오 플레이어 탐색',
			'settings.videoPlayerNavigationDescription' => '방향 키로 비디오 플레이어 컨트롤을 탐색합니다',
			'settings.watchTogetherRelay' => '함께 보기 릴레이',
			'settings.watchTogetherRelayDescription' => '직접 설정하지 않으면 공개 Open Watch Party 릴레이를 사용합니다',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => '올바른 HTTP 또는 HTTPS 릴레이 기본 URL을 입력하세요.',
			'settings.crashReporting' => '충돌 보고',
			'settings.crashReportingDescription' => '앱 개선을 위해 충돌 보고서 전송',
			'settings.debugLogging' => '디버그 로깅',
			'settings.debugLoggingDescription' => '문제 해결을 위해 상세 로깅 활성화',
			'settings.viewLogs' => '로그 보기',
			'settings.viewLogsDescription' => '애플리케이션 로그 확인',
			'settings.clearImageCache' => '이미지 캐시 지우기',
			'settings.clearImageCacheDescription' => '캐시된 아트워크와 썸네일을 지웁니다. 다시 다운로드할 때까지 이미지가 느리게 로드될 수 있습니다.',
			'settings.clearImageCacheSuccess' => '이미지 캐시를 성공적으로 지웠습니다',
			'settings.resetSettings' => '설정 재설정',
			'settings.resetSettingsDescription' => '기본 설정으로 복원합니다. 되돌릴 수 없습니다.',
			'settings.resetSettingsSuccess' => '설정 재설정 성공',
			'settings.backup' => '백업',
			'settings.exportSettings' => '설정 내보내기',
			'settings.exportSettingsDescription' => '기본 설정을 파일로 저장',
			'settings.exportSettingsSuccess' => '설정 내보내기 완료',
			'settings.importSettings' => '설정 가져오기',
			'settings.importSettingsDescription' => '파일에서 기본 설정 복원',
			'settings.importSettingsConfirm' => '현재 설정을 대체합니다. 계속하시겠습니까?',
			'settings.importSettingsSuccess' => '설정 가져오기 완료',
			'settings.importSettingsInvalidFile' => '유효한 PlezyNG 설정 내보내기 파일이 아닙니다',
			'settings.importSettingsNoUser' => '설정을 가져오기 전에 로그인하세요',
			'settings.cloudBackup' => '클라우드 백업',
			'settings.cloudBackupDescription' => '이동 가능한 설정을 HTTPS를 통해 WebDAV 주소에 백업합니다. 서버 연결 및 로그인 정보는 이 기기에 유지됩니다.',
			'settings.cloudBackupUrl' => 'WebDAV JSON 파일 URL',
			'settings.cloudBackupUsername' => '사용자 이름',
			'settings.cloudBackupPassword' => '비밀번호',
			'settings.cloudBackupSaved' => '구름 백업 목적지 저장',
			'settings.cloudBackupNow' => '지금 다시 올라',
			'settings.cloudBackupComplete' => '설정 백업 업로드',
			'settings.cloudBackupRestore' => 'Backup 복구',
			'settings.cloudBackupRestoreConfirm' => '이 장치에서 해당 휴대용 설정을 대체합니다.',
			'settings.cloudBackupRestored' => 'Cloud Backup에서 복구된 설정',
			'settings.shortcutsReset' => '단축키가 기본값으로 재설정되었습니다',
			'settings.resetShortcutsConfirm' => '사용자 지정 단축키가 기본값으로 대체됩니다. 계속하시겠습니까?',
			'settings.about' => '정보',
			'settings.aboutDescription' => '앱 정보 및 라이선스',
			'settings.updates' => '업데이트',
			'settings.updateAvailable' => '사용 가능한 업데이트 있음',
			'settings.checkForUpdates' => '업데이트 확인',
			'settings.autoCheckUpdatesOnStartup' => '시작 시 자동으로 업데이트 확인',
			'settings.autoCheckUpdatesOnStartupDescription' => '실행 시 업데이트가 있으면 알림',
			'settings.validationErrorEnterNumber' => '유효한 숫자를 입력하세요',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '기간은 ${min}과 ${max} ${unit} 사이여야 합니다',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => '단축키가 이미 ${action}에 할당되었습니다',
			'settings.shortcutUpdated' => ({required Object action}) => '${action} 단축키가 업데이트되었습니다',
			'settings.saveFailed' => '변경 사항을 저장하지 못했습니다. 다시 시도하세요.',
			'settings.autoPlayAndSkip' => '자동 재생 및 건너뛰기',
			'settings.autoPlayNextEpisode' => '다음 에피소드 자동 재생',
			'settings.autoPlayNextEpisodeDescription' => '에피소드가 끝나면 다음 에피소드를 자동으로 재생',
			'settings.shuffleStartsFromBeginning' => '무작위 재생 시 처음부터 시작',
			'settings.shuffleStartsFromBeginningDescription' => '무작위 재생 시 이어보기 대신 각 에피소드를 처음부터 재생합니다',
			'settings.plexCinemaPreRoll' => '서버 영화관 인트로스 사용',
			'settings.plexCinemaPreRollDescription' => '영화가 시작되기 전에 Plex 사전 롤 또는 Jellyfin 및 Emby 입력을 구성합니다.',
			'settings.playNextCountdown' => '다음 재생 카운트다운',
			'settings.playNextCountdownImmediate' => '즉시 재생',
			'settings.skipIntroMode' => '인트로 건너뛰기',
			'settings.skipIntroModeOffDescription' => '건너뛰기 버튼 없이 인트로를 정상적으로 재생합니다',
			'settings.skipIntroModeButtonDescription' => '인트로가 시작되면 건너뛰기 버튼을 표시합니다',
			'settings.skipIntroModeAutoDescription' => '아래 지연 시간 후 인트로를 자동으로 건너뜁니다',
			'settings.skipCreditsMode' => '크레딧 건너뛰기',
			'settings.skipCreditsModeOffDescription' => '건너뛰기 버튼 없이 크레딧을 정상적으로 재생합니다',
			'settings.skipCreditsModeButtonDescription' => '크레딧이 시작되면 건너뛰기 버튼을 표시합니다',
			'settings.skipCreditsModeAutoDescription' => '크레딧을 자동으로 건너뛰고 다음 에피소드를 재생합니다',
			'settings.skipAdsMode' => '스키 광고',
			'settings.skipAdsModeOffDescription' => '스키 버튼 없이 일반적으로 발견된 광고를 재생합니다.',
			'settings.skipAdsModeButtonDescription' => 'Plex 광고를 발견할 때 스키 버튼을 표시합니다.',
			'settings.skipAdsModeAutoDescription' => '아래의 지연 후에 자동으로 발견된 광고를 삭제합니다.',
			'settings.musicPlayback' => '음악 플레이백',
			'settings.musicSweetFades' => '달콤한 파드',
			'settings.musicSweetFadesDescription' => 'Plex이 음성 데이터를 가지고 있는 경우 트랙 옆에 음악을 녹음합니다.앨범 재생은 변하지 않습니다.',
			'settings.skipMarkerModeOff' => '끄기',
			'settings.skipMarkerModeButton' => '버튼 표시',
			'settings.skipMarkerModeAuto' => '자동',
			'settings.forceSkipMarkerFallback' => '대체 마커 강제 사용',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex에 마커가 있어도 챕터 제목 패턴 사용',
			'settings.theIntroDbFallback' => 'IntroDB를 Intro Fallback로 사용하십시오.',
			'settings.theIntroDbFallbackDescription' => '커뮤니티 타이밍을 사용하면 서버에 입력 표시가 없을 때만 사용합니다.',
			'settings.autoSkipDelay' => '자동 건너뛰기 지연',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '자동으로 건너뛰기 전 ${seconds}초 대기',
			'settings.introPattern' => '인트로 마커 패턴',
			'settings.introPatternDescription' => '챕터 제목에서 인트로 마커를 인식하는 정규식 패턴',
			'settings.creditsPattern' => '크레딧 마커 패턴',
			'settings.creditsPatternDescription' => '챕터 제목에서 크레딧 마커를 인식하는 정규식 패턴',
			'settings.prerolls' => '프레로스',
			'settings.playPrerollsBeforeMovies' => '영화 전에 프레롤을 재생합니다.',
			'settings.playPrerollsBeforeMoviesDescription' => '각 영화 전에 아래의 선택에서 우연한 클립을 재생합니다.',
			'settings.prerollLibrary' => '프레롤 도서관',
			'settings.prerollLibraryNotSet' => '설정되지 않음',
			'settings.prerollLibraryNoneFound' => '서버에 도서관이 없습니다.',
			'settings.prerollSelection' => '선택된 선구자',
			'settings.prerollSelectionPickLibraryFirst' => '먼저 도서관을 선택하세요.',
			'settings.prerollSelectionNoneSelected' => '선택된 선구자 없음',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count}개 선택됨',
			'settings.prerollItemPicker' => '선호자 선택',
			'settings.prerollItemPickerLoadFailed' => '이 도서관에서 항목을 충전할 수는 없었습니다.',
			'settings.invalidRegex' => '잘못된 정규식',
			'settings.regex' => '정규식',
			'settings.downloads' => '다운로드',
			'settings.downloadLocationDescription' => '다운로드 콘텐츠 저장 위치 선택',
			'settings.downloadLocationDefault' => '기본값 (앱 저장소)',
			'settings.downloadLocationCustom' => '사용자 지정 위치',
			'settings.selectFolder' => '폴더 선택',
			'settings.resetToDefault' => '기본값으로 재설정',
			'settings.currentPath' => ({required Object path}) => '현재: ${path}',
			'settings.downloadLocationChanged' => '다운로드 위치가 변경되었습니다',
			'settings.downloadLocationReset' => '다운로드 위치가 기본값으로 재설정되었습니다',
			'settings.downloadLocationInvalid' => '선택한 폴더에 쓰기 권한이 없습니다',
			'settings.downloadLocationPickerUnavailable' => '이 기기에서는 폴더를 선택할 수 없습니다',
			'settings.downloadOnWifiOnly' => 'Wi-Fi 연결 시에만 다운로드',
			'settings.downloadOnWifiOnlyDescription' => '셀룰러 데이터 사용 중에는 다운로드하지 않습니다',
			'settings.autoRemoveWatchedDownloads' => '시청한 다운로드 항목 자동 삭제',
			'settings.autoRemoveWatchedDownloadsDescription' => '시청한 다운로드 항목을 자동으로 삭제합니다',
			'settings.autoDownloadContinueWatching' => '자동 다운로드 계속 보기',
			'settings.autoDownloadContinueWatchingDescription' => '계속 보면서 셰일에 항목을 다운로드하고 그들이 셰일을 떠나면 그들을 제거합니다.',
			'settings.downloadQuality' => '다운로드 품질',
			'settings.downloadQualityDescription' => 'Plex은 다운로드 쿼드에 변환 된 복사본을 준비합니다. Jellyfin 및 Emby는 파일 다운로드 중 트랜스코드; 중단 된 전송은 다시 시작해야 할 수 있습니다.',
			'settings.askDownloadQualityEachTime' => '각 다운로드에 대한 품질 선택',
			'settings.askDownloadQualityEachTimeDescription' => '각 동영상 다운로드를 대기열에 추가하기 전에 화질 선택 화면 표시',
			'settings.cellularDownloadBlocked' => '셀룰러에서는 다운로드가 차단됩니다. Wi-Fi를 사용하거나 설정을 변경하세요.',
			'settings.maxVolume' => '최대 볼륨',
			'settings.maxVolumeDescription' => '음량이 작은 콘텐츠를 위해 100% 이상의 볼륨을 허용합니다',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord에서 시청 중인 콘텐츠 표시',
			'settings.services' => '서비스',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr 등 연결',
			'settings.manageLibrariesDescription' => '라이브러리 순서를 변경하거나 숨깁니다',
			'settings.companionRemoteServer' => '컴패니언 리모트 서버',
			'settings.companionRemoteServerDescription' => '네트워크의 모바일 기기가 이 앱을 제어할 수 있도록 허용',
			'settings.companionRemoteServerStartFailed' => '컴패니언 리모트 서버를 시작할 수 없습니다',
			'settings.companionRemoteServerStopFailed' => '컴패니언 리모트 서버를 중지할 수 없습니다',
			'settings.autoPip' => '자동 PIP 모드',
			'settings.autoPipDescription' => '재생 중 앱을 떠나면 자동으로 화면 속 화면 모드로 전환합니다',
			'settings.matchContentFrameRate' => '콘텐츠 프레임 레이트 맞춤',
			'settings.matchContentFrameRateDescription' => '디스플레이 새로 고침 빈도를 동영상 콘텐츠에 맞춤',
			'settings.matchContentResolution' => '콘텐츠 해상도에 맞추기',
			'settings.matchContentResolutionDescription' => 'TV가 업스케일링을 처리하도록 디스플레이를 영상 본래 해상도로 전환합니다. 재생 중에는 메뉴와 자막도 함께 업스케일됩니다',
			'settings.matchRefreshRate' => '주사율 맞춤',
			'settings.matchRefreshRateDescription' => '전체 화면에서 디스플레이 새로 고침 빈도 맞춤',
			'settings.matchDynamicRange' => '다이나믹 레인지 맞춤',
			'settings.matchDynamicRangeDescription' => 'HDR 콘텐츠에서는 HDR로 전환한 뒤 SDR로 되돌림',
			'settings.displaySwitchDelay' => '디스플레이 전환 지연',
			'settings.tunneledPlayback' => '터널 재생',
			'settings.tunneledPlaybackDescription' => '비디오 터널링을 사용합니다. HDR 재생 시 검은 화면이 보이거나 움직임이 끊기면 비활성화하세요.',
			'settings.audioPassthrough' => '오디오 패스스루',
			'settings.audioPassthroughDescription' => 'Dolby/DTS 오디오를 재인코딩 없이 리시버나 TV로 전송하여 서라운드 사운드를 유지합니다. 소리가 나지 않으면 비활성화하세요.',
			'settings.audioPassthroughDescriptionApple' => 'Dolby Digital Plus(Atmos 포함)에 Apple의 기본 Dolby 디코더를 사용합니다. DTS와 TrueHD는 계속 멀티채널 PCM으로 재생됩니다. 소리가 나지 않으면 비활성화하세요.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Dolby Digital Plus(Atmos 포함)에 Apple의 기본 Dolby 디코더를 사용합니다. iOS, iPadOS, tvOS 26 이상에서는 TrueHD Atmos와 DTS:X가 공간 오디오로 재생됩니다. 그 밖의 DTS 및 TrueHD 트랙은 멀티채널 PCM으로 재생됩니다. 소리가 나지 않으면 비활성화하세요.',
			'settings.audioPassthroughOverriddenByNormalization' => '음량 정규화가 켜져 있는 동안 꺼짐',
			'settings.audioChannelLimit' => '오디오 채널',
			'settings.audioChannelLimitDescription' => '모든 채널을 재생할 수 없는 스피커, 헤드폰 또는 HDMI 환경에 맞게 디코딩된 오디오를 다운믹스합니다',
			'settings.audioChannelLimitOriginal' => '원본',
			'settings.audioChannelLimitOriginalDescription' => '트랙의 모든 채널을 재생합니다',
			'settings.audioChannelLimitSurround51' => '최대 5.1',
			'settings.audioChannelLimitSurround51Description' => '5.1 PCM만 지원하는 TV와 리시버를 위해 7.1을 5.1로 다운믹스합니다. 패스스루에는 영향을 주지 않습니다.',
			'settings.audioChannelLimitStereo' => '스테레오',
			'settings.audioChannelLimitStereoDescription' => '스테레오 스피커나 헤드폰에 맞게 2채널로 다운믹스합니다. 패스스루가 꺼집니다.',
			'settings.downmixCenterBoost' => '센터 채널 부스트',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '부스트 (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '다운믹스 시 음량 정규화',
			'settings.audioDownmixNormalizeDescription' => '클리핑을 방지하기 위해 믹스 음량을 낮춥니다. 원래 음량을 유지하려면 끄세요(큰 소리 장면에서 왜곡될 수 있음).',
			'settings.dvConversionMode' => 'Dolby Vision 변환',
			'settings.dvConversionModeDescription' => 'Dolby Vision Profile 7 파일을 처리하는 방식을 선택합니다.',
			'settings.dvConversionAuto' => '자동',
			'settings.dvConversionNative' => '네이티브 / 비활성화',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '기기 기능 감지와 일반 폴백 동작을 사용합니다',
			'settings.dvConversionNativeDescription' => '네이티브 DV7을 강제하고 DV 변환 재시도를 억제합니다',
			'settings.dvConversionDv81Description' => 'Dolby Vision 프로필 8.1로 인라인 RPU 변환을 강제합니다',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision RPU/EL 레이어를 제거하고 일반 HEVC로 제공합니다',
			'settings.experimentalDolbyVision' => '실험적 Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => '다음 재생에서 실험적 FEL 렌더러를 사용합니다. 별도로 빌드한 엔진이 필요합니다.',
			'settings.dvExperimentUnavailableDescription' => '이 실험은 현재 Linux에서만 사용할 수 있습니다.',
			'settings.dvCompatibilityFallback' => '호환성 대체 모드',
			'settings.dvCompatibilityFallbackDescription' => '실험을 시작할 수 없으면 기본 렌더러를 사용합니다. FEL 데이터가 손실될 수 있습니다.',
			'settings.dvExperimentDiagnostics' => '비디오 실험 로그',
			'settings.dvExperimentDiagnosticsDescription' => '다음 재생에서 상세 플레이어 로그를 활성화합니다.',
			'settings.disableDolbyVision' => 'Dolby Vision 끄기',
			'settings.disableDolbyVisionDescription' => '파일에 HDR10 또는 HLG 레이어가 있으면 Dolby Vision 대신 해당 레이어를 재생합니다',
			'settings.hdrSdrConversion' => 'HDR을 SDR로 변환',
			'settings.hdrSdrConversionDescription' => '디스플레이가 HDR을 표시할 수 없을 때 HDR 동영상을 무엇으로 변환할지 선택합니다.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => '자동',
			'settings.hdrSdrConversionAutoDescription' => 'Android 9 이상에서는 기기, 이전 버전에서는 플레이어',
			'settings.hdrSdrConversionDevice' => '기기',
			'settings.hdrSdrConversionDeviceDescription' => '기기의 비디오 하드웨어가 변환합니다. 가장 빠르지만 색상은 기기에 따라 다릅니다',
			'settings.hdrSdrConversionPlayer' => '플레이어',
			'settings.hdrSdrConversionPlayerDescription' => '플레이어가 변환합니다. 색상은 일정하지만 저사양 TV 박스에서는 4K가 끊길 수 있습니다',
			'settings.deinterlace' => '디인터레이싱',
			'settings.deinterlaceDescription' => '인터레이스 비디오의 빗살 무늬 아티팩트를 제거합니다 (mpv 플레이어만 해당)',
			'settings.deinterlaceOff' => '끄기',
			'settings.deinterlaceOffDescription' => '인터레이스 비디오를 디코딩된 그대로 표시합니다',
			'settings.deinterlaceVideo' => '비디오',
			'settings.deinterlaceVideoDescription' => '각 필드를 완전한 프레임으로 변환합니다. 스포츠, 뉴스, 콘서트처럼 TV용으로 촬영된 영상에 적합합니다',
			'settings.deinterlaceFilm' => '필름',
			'settings.deinterlaceFilmDescription' => 'NTSC DVD에서 흔한, 29.97fps로 텔레시네된 영화와 애니메이션의 원본 프레임을 복원합니다. TV용으로 촬영된 영상은 끊겨 보입니다. 라이브 TV에는 비디오 모드가 사용됩니다',
			'settings.requireProfileSelectionOnOpen' => '앱 실행 시 프로필 선택',
			'settings.requireProfileSelectionOnOpenDescription' => '앱을 열 때마다 프로필 선택 화면을 표시합니다',
			'settings.forceTvMode' => 'TV 모드 강제 사용',
			'settings.forceTvModeDescription' => 'TV 레이아웃을 강제합니다. 자동 감지되지 않는 기기용입니다. 재시작이 필요합니다.',
			'settings.startInFullscreen' => '전체 화면으로 시작',
			'settings.startInFullscreenDescription' => '실행 시 Plezy를 전체 화면 모드로 엽니다',
			'settings.exitFullscreenOnPlayerClose' => '플레이어를 닫을 때 전체 화면 종료',
			'settings.exitFullscreenOnPlayerCloseDescription' => '비디오 플레이어를 닫을 때 자동으로 전체 화면을 종료합니다',
			'settings.autoHidePerformanceOverlay' => '성능 오버레이 자동 숨기기',
			'settings.autoHidePerformanceOverlayDescription' => '재생 컨트롤과 함께 성능 오버레이를 페이드 처리',
			'settings.showNavBarLabels' => '내비게이션 바 라벨 표시',
			'settings.showNavBarLabelsDescription' => '내비게이션 바 아이콘 아래에 텍스트 라벨을 표시합니다',
			'settings.startupSection' => '시작 섹션',
			'settings.preferredServer' => '선호하는 서버',
			'settings.preferredServerDescription' => '이 서버의 결과를 우선시하고 모든 연결된 서버를 사용할 수 있도록 유지합니다.',
			'settings.preferredServerAutomatic' => '자동',
			'settings.showExploreTab' => '둘러보기 탭 표시',
			'settings.showExploreTabDescription' => 'Plex Discover와 연결된 트래커의 콘텐츠가 포함된 둘러보기 탭을 표시합니다',
			'settings.hideEmptyLibraries' => '빈 도서관을 숨기기',
			'settings.hideEmptyLibrariesDescription' => '서버에 의해 보고된 항목의 0을 가진 도서관을 탐색에서 제거합니다.',
			'settings.liveTvDefaultFavorites' => '즐겨찾기 채널 기본 설정',
			'settings.liveTvDefaultFavoritesDescription' => '라이브 TV를 열 때 즐겨찾기 채널만 표시',
			'settings.general' => '일반',
			'settings.generalDescription' => '언어, 시작 및 창 동작',
			'settings.languageAndRegion' => '언어 및 지역',
			'settings.startup' => '시작',
			'settings.display' => '디스플레이',
			'settings.libraryAndCards' => '라이브러리 및 카드',
			'settings.homeScreen' => '홈 화면',
			'settings.navigation' => '탐색',
			'settings.window' => '창',
			'settings.liveTv' => '라이브 TV',
			'settings.player' => '플레이어',
			'settings.videoAndDisplay' => '비디오 및 디스플레이',
			'settings.audio' => '오디오',
			'settings.quality' => '화질',
			'settings.subtitles' => '자막',
			'settings.seekAndTiming' => '탐색 및 타이밍',
			'settings.behavior' => '동작',
			'settings.gestures' => '제스처',
			'settings.gestureBrightnessSwipe' => '밝기 스와이프',
			'settings.gestureBrightnessSwipeDescription' => '왼쪽 가장자리에서 위아래로 스와이프하여 밝기를 조절합니다',
			'settings.gestureVolumeSwipe' => '볼륨 스와이프',
			'settings.gestureVolumeSwipeDescription' => '오른쪽 가장자리에서 위아래로 스와이프하여 볼륨을 조절합니다',
			'settings.gesturePinchToZoom' => '핀치 줌',
			'settings.gesturePinchToZoomDescription' => '비디오에서 핀치하여 확대하거나 축소합니다',
			'settings.gestureSeekSwipe' => '스위프 검색',
			'settings.gestureSeekSwipeDescription' => '검색하는 비디오의 왼쪽 또는 오른쪽으로 스위치; 던지기 위해 릴리스',
			'settings.rememberBrightnessLevel' => '밝기 수준 기억',
			'settings.rememberBrightnessLevelDescription' => '마지막으로 스와이프하여 설정한 밝기로 재생을 시작합니다',
			'settings.controls' => '컨트롤',
			'settings.rememberPlayerChanges' => '플레이어 변경 사항 기억',
			'settings.rememberPlayerChangesDescription' => '재생 중 변경한 사항을 저장하고 다시 적용할 위치',
			'settings.scopePlaybackSpeed' => '재생 속도',
			'settings.scopeShaderPreset' => '셰이더 프리셋',
			'settings.scopeAspectRatio' => '화면 비율',
			'settings.scopeSyncOffsets' => '오디오 및 자막 동기화',
			'settings.playerScopeOff' => '저장하지 않음',
			'settings.playerScopeGlobal' => '모든 곳',
			'settings.playerScopeLibrary' => '라이브러리별',
			'settings.playerScopeTitle' => '시리즈 또는 영화별',
			'settings.exportDialogTitle' => 'PlezyNG 설정 내보내기',
			'settings.followSystem' => '시스템 설정 따르기',
			'settings.followAppLanguage' => '인터페이스 언어와 동일하게',
			'settings.regionFormat' => '지역별 표시 형식',
			'settings.regionFormatDescription' => '날짜, 숫자, 측정 단위의 표시 형식을 선택하세요.',
			'settings.metadataLanguage' => '메타데이터 언어',
			'settings.metadataLanguageDescription' => '서버가 지원하는 경우 제목과 설명에 사용할 언어입니다. 오디오와 자막 언어는 별도로 설정합니다.',
			'settings.enterFullscreenOnPlaybackStart' => '플레이백이 시작되면 전체 스크린을 입력합니다.',
			'settings.enterFullscreenOnPlaybackStartDescription' => '플레이백이 시작되면 풀 스크린으로 데스크톱 비디오를 열어보세요.',
			'settings.extendVideoIntoDisplayCutout' => '비디오를 디스플레이 Cutout로 확장',
			'settings.extendVideoIntoDisplayCutoutDescription' => '전체 스크린 비디오를 안드로이드 휴대폰에서 카메라 절단을 사용하십시오.',
			'settings.languageDescription' => 'PlezyNG 컨트롤 및 메시지에 사용되는 언어를 선택하십시오.Follow system tracks your device language.',
			'settings.themeDescription' => '앱 전체에 걸쳐 사용되는 색상과 대조를 선택합니다.',
			'settings.libraryDensityDescription' => '각 라인에 얼마나 많은 도서관 카드가 적합한지 변경합니다.',
			'settings.displayScaleDescription' => '이 차 디스플레이에 있는 인터페이스를 다시 만들고 장치 전체 텍스트 크기를 변경하지 않습니다.',
			'settings.themeSongVolumeDescription' => '다른 오디오와 비교하여 테마 노래의 볼륨을 설정합니다.',
			'settings.viewModeDescription' => '도서관 항목이 네트워크에 포스터 또는 컴팩트 목록으로 표시되는지 여부를 선택합니다.',
			'settings.gridViewDescription' => '도서관 항목을 포스터의 줄과 열로 배열하십시오.',
			'settings.listViewDescription' => '수직 목록에서 도서관 항목을 표시하여 항목 당 더 많은 텍스트를 제공합니다.',
			'settings.gridSpacingDescription' => '도서관 네트워크에서 포스터 사이의 격차를 설정합니다.',
			'settings.gridSpacingTightDescription' => '더 작은 격차로 화면 위에 더 많은 포스터를 적합합니다.',
			'settings.gridSpacingNormalDescription' => '포스터 사이의 표준 간격을 사용하십시오.',
			'settings.gridSpacingSpaciousDescription' => '더 많은 분리를 위해 포스터 사이에 더 큰 격차를 추가합니다.',
			'settings.episodePosterModeDescription' => '에피소드 카드에 어떤 예술 작품이 나타나는지 선택합니다.',
			'settings.seriesPosterDescription' => '각 에피소드에 대한 쇼 시리즈 포스터를 사용하십시오.',
			'settings.seasonPosterDescription' => '사용할 때 각 에피소드에 대한 시즌 포스터를 사용하십시오.',
			'settings.episodeThumbnailDescription' => '사용할 때 에피소드에서 프레임을 사용하십시오.',
			'settings.continueWatchingActionDescription' => '계속 시청 카드를 활성화할 때 무슨 일이 일어나는지 선택합니다.',
			'settings.continueWatchingPlayDescription' => '즉시 영화 또는 에피소드를 시작합니다.',
			'settings.continueWatchingDetailsDescription' => '제목 페이지를 먼저 열어서 세부 사항을 검토하고 행동을 선택할 수 있습니다.',
			'settings.episodeActionDescription' => '에피소드 카드를 활성화할 때 무슨 일이 일어나는지 선택합니다.',
			'settings.episodePlayDescription' => '즉시 에피소드를 시작합니다.',
			'settings.episodeDetailsDescription' => 'Playback 전에 에피소드 페이지를 열어보세요.',
			'settings.contentScreensaverDelayDescription' => '예술 작품을 보여주기 전에 PlezyNG가 입력없이 얼마나 오래 기다리는지 선택하십시오.',
			'settings.continueWatchingRowSizeDescription' => '계속 관찰 라인에서 카드가 얼마나 큰지 선택하십시오.',
			'settings.rowSizeCompactDescription' => '더 작은 카드를 표시하여 더 많은 항목이 라인에 맞게됩니다.',
			'settings.rowSizeStandardDescription' => '표준 카드 크기를 사용하십시오.',
			'settings.rowSizeLargeDescription' => '더 큰 카드와 더 많은 예술 작품 세부 사항을 표시합니다.',
			'settings.visualEffectsDescription' => '이 장치에 대한 애니메이션 및 예술 효과 예산을 선택합니다.',
			'settings.visualEffectsFullDescription' => '모든 장치에 완전한 애니메이션 및 예술 작품 효과를 사용하십시오.',
			'settings.startupSectionDescription' => 'PlezyNG 시작할 때 어떤 섹션이 열리는지 선택합니다.',
			'settings.startupSectionOptions.discover' => '연결된 발견 출처의 권장 사항 및 항목을 열어보세요.',
			'settings.startupSectionOptions.libraries' => '연결된 미디어 라이브러리를 열어보세요.',
			'settings.startupSectionOptions.liveTv' => '서버가 제공 할 때 라이브 TV를 열어; 그렇지 않으면 스타트업이 홈으로 돌아갑니다.',
			'settings.startupSectionOptions.search' => '오픈 미디어 검색',
			'settings.smallSkipDurationDescription' => '짧은 뒤쪽으로 이동하는 거리를 설정하고 앞으로 컨트롤을 찾습니다.',
			'settings.largeSkipDurationDescription' => '긴 뒤쪽으로 움직이는 거리를 설정하고 앞으로 통제를 찾습니다.',
			'settings.rewindOnResumeDescription' => '비디오를 다시 재생할 때 이 금액으로 재생을 이동합니다.',
			'settings.defaultSleepTimerDescription' => '잠자리 타이머를 시작할 때 사용되는 초기 기간을 설정합니다.',
			'settings.playNextCountdownDescription' => '다음 에피소드를 시작하기 전에 이것을 오랫동안 기다리십시오. 즉시 시작하려면 0으로 설정합니다.',
			'settings.autoSkipDelaySettingDescription' => '입력, 크레딧 또는 광고가 자동으로 스파이를 설정할 때 적용됩니다.',
			'settings.downmixCenterBoostDescription' => '중앙 채널에서 대화를 높이면 주변 오디오가 스테레오로 혼합됩니다.',
			'settings.displaySwitchDelayDescription' => '디스플레이 모드를 변경하기 전에 TV 또는 수신기가 이전 스위치를 완료 할 수 있도록 기다리십시오.',
			'settings.playerBackendDescription' => '어떤 재생 엔진이 이 장치에서 비디오를 해독하고 회전하는지 선택합니다.',
			'settings.exoPlayerDescription' => '안드로이드의 원주민 Media3 기반 플레이어와 지원되는 하드웨어 경로를 사용하십시오.',
			'settings.mpvDescription' => 'MPV를 사용하여 추가 재생, 하위 제목 및 비디오 처리 컨트롤을 표시합니다.',
			'settings.scopeOffDescription' => '현재 플레이백 세션에 대한 변경 사항만 유지합니다.',
			'settings.scopeGlobalDescription' => '각 도서관 및 제목에 대해 동일한 가치를 다시 사용합니다.',
			'settings.scopeLibraryDescription' => '각 도서관에 대한 별도의 가치를 기억하십시오.',
			'settings.scopeTitleDescription' => '각 쇼 또는 영화에 대해 별도의 값을 기억하십시오.',
			'settings.specialsOrderingServerDescription' => '미디어 서버에 의해 제공되는 에피소드 주문을 유지합니다.',
			'settings.specialsOrderingAirDateDescription' => '그들의 날짜에 따라 정기적 인 에피소드 중 특별한 장소.',
			'settings.specialsOrderingLastDescription' => '각각의 특별한 장소는 정규 시즌 후에 배치합니다.',
			'settings.skipIntroModeDescription' => '입력 마커가 정상적으로 재생하는지, 스키 버튼을 표시하거나 자동으로 스키를 선택합니다.',
			'settings.skipCreditsModeDescription' => '크레딧이 정상적으로 재생되는지, 스키 버튼을 표시하거나 자동으로 스키를 선택합니다.',
			'settings.skipAdsModeDescription' => '발견된 광고가 정상적으로 재생되는지, 스키 버튼을 표시하거나 자동으로 스키를 선택합니다.',
			'settings.playbackBufferAutoDescription' => '활성 플레이어가 정상 버퍼 크기를 선택하도록 허용합니다.',
			'settings.playbackBufferLargeDescription' => '재생 전에 더 많은 미디어를 준비하십시오; 이것은 더 많은 메모리를 사용합니다.',
			'settings.playbackBufferExtraLargeDescription' => '가장 큰 읽기 넓은 버퍼를 유지하십시오; 이것은 대부분의 메모리를 사용합니다.',
			'settings.defaultQualityDescription' => '기본 비디오 해상도를 설정하고 서버가 트랜스코드하는 스트림에 대한 지붕을 비트레이션합니다.',
			'settings.cellularQualityDescription' => '장치가 셀룰러만 연결을 사용하는 경우 기본 품질을 초과합니다.',
			'settings.remoteQualityDescription' => '원격 연결을 통해 서버에 연결할 때 기본 품질을 초과합니다.',
			'settings.qualityPresetOriginalDescription' => '서버가 그것을 트랜스코드하도록 요청하지 않고 사용할 수있는 품질에서 소스를 재생합니다.',
			'settings.qualityPresetTranscodeOptionDescription' => '위에서 표시된 해상도와 비트라이트를 사용하여 서버에 변환 된 스트림을 요청하십시오.',
			'settings.qualityPresetSameAsDefaultDescription' => '기본 품질에서 선택한 품질을 사용합니다.',
			'settings.musicQualityDescription' => '서버에서 요청한 최대 오디오 비트 속도를 설정; 원본은 소스 스트림을 유지합니다.',
			'settings.musicQualityOriginalDescription' => '비트라이트 카프 트랜스코드 없이 소스 오디오를 재생합니다.',
			'settings.musicQualityTranscodeOptionDescription' => '위에서 표시된 비트 속도 근처에 서버 트랜스코드를 요청하십시오; 실제 출력은 다를 수 있습니다.',
			'settings.maxVolumeInputLabel' => '최대 수량 ( % )',
			'settings.checkForUpdatesDescription' => '이제 PlezyNG의 새 버전이 사용할 수 있는지 확인하십시오.',
			'settings.appearanceDescription' => '앱 테마를 선택하고 도서관 카드, 홈 라인 및 네비게이션을 조정합니다.',
			'settings.prerollLibraryDescription' => '영화 프리 롤로 사용할 수있는 클립을 포함하는 도서관을 선택합니다.',
			'settings.prerollSelectionDescription' => '선택한 도서관에서 어떤 클립이 영화 전에 재생할 수 있는지 선택합니다.',
			'settings.contentScreensaverDelayOptionDescription' => '스크린 저장 예술 작품을 보여주기 전에 입력없이 많은 분을 기다리십시오.',
			'settings.videoCodecOptionDescription' => '이 코덱을 지원할 때 직접 재생할 수 있습니다.Unchecked codecs are transcoded by the media server.',
			'themeEditor.builtIn' => '기본 제공',
			'themeEditor.presets' => '프리셋',
			'themeEditor.custom' => '사용자 지정',
			'themeEditor.customEmpty' => '아직 만들지 않음',
			'themeEditor.editCustom' => '사용자 지정 테마 편집',
			'themeEditor.editCustomDescription' => '모든 색상을 직접 선택',
			'themeEditor.locked' => '인생 접근이 필요합니다',
			'themeEditor.savedLocked' => '저장 - 평생 접근을 통해 사용할 수 있습니다',
			'themeEditor.title' => '사용자 지정 테마',
			'themeEditor.startFrom' => '기반 테마',
			'themeEditor.startFromDescription' => '다른 테마의 모든 색상을 복사합니다',
			'themeEditor.colors' => '색상',
			'themeEditor.preview' => '미리보기',
			'themeEditor.slots.bg' => '배경',
			'themeEditor.slots.surface' => '표면',
			'themeEditor.slots.outline' => '윤곽선',
			'themeEditor.slots.text' => '텍스트',
			'themeEditor.slots.textMuted' => '보조 텍스트',
			'themeEditor.slots.accent' => '강조색',
			'themeEditor.opacity' => '불투명도',
			'themeEditor.hexHint' => '#RRGGBB 또는 #AARRGGBB',
			'themeEditor.fromOtherThemes' => '다른 테마에서',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => '배경 위 텍스트',
			'themeEditor.contrast.textOnSurface' => '표면 위 텍스트',
			'themeEditor.contrast.textMutedOnBg' => '배경 위 보조 텍스트',
			'themeEditor.contrast.textMutedOnSurface' => '표면 위 보조 텍스트',
			'themeEditor.contrast.accentOnBg' => '배경 위 강조색',
			'themeEditor.contrast.accentOnSurface' => '표면 위 강조색',
			'themeEditor.contrast.labelOnAccent' => '강조색 위 버튼 라벨',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, 권장 기준 ${minimum}:1 미만',
			'themeEditor.discardTitle' => '변경 사항을 버리시겠습니까?',
			'themeEditor.discardMessage' => '저장하지 않은 색상 변경 사항이 사라집니다.',
			'themeEditor.discard' => '버리기',
			'themeEditor.previewCardTitle' => ({required Object number}) => '${number}화',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes}분 남음',
			'themeEditor.previewSwitch' => '자동 재생',
			'themeEditor.previewMutedText' => '보조 텍스트는 이렇게 표시됩니다',
			'themeEditor.themeSystemDescription' => '장치의 모습을 추적하고 빛과 어둠 사이를 자동으로 전환합니다.',
			'themeEditor.themeLightDescription' => '어두운 텍스트와 함께 밝은 배경을 사용하십시오.',
			'themeEditor.themeDarkDescription' => '밝은 텍스트를 가진 어두운 배경을 사용하십시오.',
			'themeEditor.themeOledDescription' => 'OLED 스크린에 빛을 줄이는 가까운 검은 표면을 사용하십시오.',
			'themeEditor.themeEmberDescription' => '따뜻한 빨간색과 암버 액센트 색상을 사용하십시오.',
			'themeEditor.themeGlacierDescription' => '차가운 파란색 액센트 색상을 사용하십시오.',
			'themeEditor.themeForestDescription' => '녹색과 자연적인 강조 색상을 사용하십시오.',
			'themeEditor.themePlumDescription' => '바이올렛과 플루미 액센트 색상을 사용합니다.',
			'themeEditor.themePaperDescription' => '따뜻한 종이와 같은 표면과 잉크 영감을받은 색상을 사용하십시오.',
			'themeEditor.themeCustomDescription' => '사용자 지정 테마 편집기에서 만든 색상 패널을 사용하십시오.',
			'themeEditor.editorDescription' => '팔레트 색상을 선택하고, 그것의 색깔, 만족도, 밝기 또는 오파시티를 조정하고, 예비 보기 업데이트를 보시기 전에 저장할 수 있습니다.',
			'search.hint' => '영화, 시리즈, 음악 등을 검색하세요...',
			'search.tryDifferentTerm' => '다른 검색어를 시도해 보세요',
			'search.searchYourMedia' => '미디어 검색',
			'search.enterTitleActorOrKeyword' => '제목, 배우 또는 키워드를 입력하세요',
			'search.people' => '인물',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName}에 대한 단축키 설정',
			'hotkeys.clearShortcut' => '단축키 삭제',
			'hotkeys.noShortcutSet' => '설정된 단축키 없음',
			'hotkeys.currentShortcut' => '현재 단축키:',
			'hotkeys.pressToRecord' => '단축키를 기록하려면 선택',
			'hotkeys.recordingShortcut' => '지금 단축키를 누르세요',
			'hotkeys.actions.playPause' => '재생/일시정지',
			'hotkeys.actions.volumeUp' => '볼륨 높이기',
			'hotkeys.actions.volumeDown' => '볼륨 낮추기',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => '앞으로 이동 (${seconds}초)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => '뒤로 이동 (${seconds}초)',
			'hotkeys.actions.fullscreenToggle' => '전체 화면 전환',
			'hotkeys.actions.muteToggle' => '음소거 전환',
			'hotkeys.actions.subtitleToggle' => '자막 전환',
			'hotkeys.actions.audioTrackNext' => '다음 오디오 트랙',
			'hotkeys.actions.subtitleTrackNext' => '다음 자막 트랙',
			'hotkeys.actions.chapterNext' => '다음 챕터',
			'hotkeys.actions.chapterPrevious' => '이전 챕터',
			'hotkeys.actions.episodeNext' => '다음 에피소드',
			'hotkeys.actions.episodePrevious' => '이전 에피소드',
			'hotkeys.actions.speedIncrease' => '속도 높이기',
			'hotkeys.actions.speedDecrease' => '속도 낮추기',
			'hotkeys.actions.speedReset' => '속도 초기화',
			'hotkeys.actions.zoomIn' => '확대',
			'hotkeys.actions.zoomOut' => '축소',
			'hotkeys.actions.zoomReset' => '확대/축소 초기화',
			'hotkeys.actions.subSeekNext' => '다음 자막으로 이동',
			'hotkeys.actions.subSeekPrev' => '이전 자막으로 이동',
			'hotkeys.actions.subtitleDelayIncrease' => '자막 늦추기',
			'hotkeys.actions.subtitleDelayDecrease' => '자막 앞당기기',
			'hotkeys.actions.shaderToggle' => '셰이더 전환',
			'hotkeys.actions.skipMarker' => '인트로/크레딧 건너뛰기',
			'hotkeys.actions.screenshot' => '스크린샷 찍기',
			'hotkeys.actions.framePrevious' => '이전 프레임',
			'hotkeys.actions.frameNext' => '다음 프레임',
			'fileInfo.title' => '파일 정보',
			'fileInfo.overview' => '개요',
			'fileInfo.video' => '비디오',
			'fileInfo.audio' => '오디오',
			'fileInfo.subtitles' => '자막',
			'fileInfo.images' => '내장 이미지',
			'fileInfo.dataStreams' => '데이터 스트림',
			'fileInfo.lyrics' => '가사',
			'fileInfo.file' => '파일',
			'fileInfo.attachments' => '첨부 파일',
			'fileInfo.delivery' => '재생 방식',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => '버전 ${index} / ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => '파일 ${index} / ${count}',
			'fileInfo.noStreams' => '서버에서 이 파일에 대한 스트림 정보를 보고하지 않았습니다.',
			'fileInfo.copyPath' => '경로 복사',
			'fileInfo.pathCopied' => '파일 경로가 복사되었습니다',
			'fileInfo.codec' => '코덱',
			'fileInfo.codecTag' => '코덱 태그',
			'fileInfo.resolution' => '해상도',
			'fileInfo.codedResolution' => '코딩 해상도',
			'fileInfo.bitrate' => '비트레이트',
			'fileInfo.frameRate' => '프레임 속도',
			'fileInfo.rotation' => '회전',
			'fileInfo.comment' => '주석',
			'fileInfo.audioDescription' => '오디오 설명',
			'fileInfo.headerCompression' => '헤더 압축',
			'fileInfo.sidecarFile' => '사이드카 파일',
			'fileInfo.transportTimestamp' => '전송 타임스탬프',
			'fileInfo.displayOffset' => '표시 오프셋',
			'fileInfo.previewFailureCode' => '미리보기 오류 코드',
			'fileInfo.previewRetries' => '미리보기 재시도 횟수',
			'fileInfo.aspectRatio' => '종횡비',
			'fileInfo.pixelAspectRatio' => '픽셀 종횡비',
			'fileInfo.profile' => '프로파일',
			'fileInfo.level' => '레벨',
			'fileInfo.bitDepth' => '비트 심도',
			'fileInfo.pixelFormat' => '픽셀 포맷',
			'fileInfo.colorSpace' => '색 공간',
			'fileInfo.colorRange' => '색 범위',
			'fileInfo.colorPrimaries' => '색 원색',
			'fileInfo.colorTransfer' => '색상 전송',
			'fileInfo.chromaSubsampling' => '색차 서브샘플링',
			'fileInfo.chromaLocation' => '크로마 위치',
			'fileInfo.scanType' => '주사 방식',
			'fileInfo.interlaced' => '비월 주사',
			'fileInfo.anamorphic' => '아나모픽',
			'fileInfo.referenceFrames' => '참조 프레임',
			'fileInfo.dynamicRange' => '동적 범위',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision 레벨',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision 버전',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision 레이어',
			'fileInfo.baseLayerCompatibility' => '베이스 레이어 호환성',
			'fileInfo.avcBitstream' => 'AVC 비트스트림',
			'fileInfo.nalLengthSize' => 'NAL 길이 크기',
			'fileInfo.scalingMatrix' => '사용자 지정 스케일링 매트릭스',
			'fileInfo.streamIdentifier' => '스트림 식별자',
			'fileInfo.streamIndex' => '스트림 인덱스',
			'fileInfo.streamId' => '스트림 ID',
			'fileInfo.language' => '언어',
			'fileInfo.languageCode' => '언어 코드',
			'fileInfo.streamTitle' => '트랙 제목',
			'fileInfo.channels' => '채널',
			'fileInfo.sampleRate' => '샘플 레이트',
			'fileInfo.spatialAudio' => '공간 오디오',
			'fileInfo.textBased' => '텍스트 기반',
			'fileInfo.subtitleFormat' => '사이드카 포맷',
			'fileInfo.provider' => '제공자',
			'fileInfo.matchScore' => '일치 점수',
			'fileInfo.externalDelivery' => '별도 제공 가능',
			'fileInfo.sidecarPath' => '사이드카 경로',
			'fileInfo.sourceStream' => '복사 출처',
			'fileInfo.temporary' => '임시',
			'fileInfo.timeBase' => '시간 기준',
			'fileInfo.overallBitrate' => '전체 비트레이트',
			'fileInfo.path' => '경로',
			'fileInfo.fileName' => '파일 이름',
			'fileInfo.size' => '크기',
			'fileInfo.totalSize' => '총 크기',
			'fileInfo.container' => '컨테이너',
			'fileInfo.duration' => '재생 시간',
			'fileInfo.previewThumbnails' => '미리보기 썸네일',
			'fileInfo.previewIndex' => '미리보기 인덱스',
			'fileInfo.packetLength' => '패킷 길이',
			'fileInfo.filePresent' => '파일 있음',
			'fileInfo.fileReadable' => '서버에서 읽기 가능',
			'fileInfo.streamPath' => '스트림 경로',
			'fileInfo.optimizedForStreaming' => '스트리밍 최적화',
			'fileInfo.has64bitOffsets' => '64비트 오프셋',
			'fileInfo.protocol' => '프로토콜',
			'fileInfo.mediaType' => '미디어 유형',
			'fileInfo.sourceKind' => '소스 종류',
			'fileInfo.optimizedVersion' => '최적화 버전',
			'fileInfo.optimizationTarget' => '최적화 대상',
			'fileInfo.deletedAt' => '삭제됨',
			'fileInfo.remoteSource' => '원격 소스',
			'fileInfo.infiniteStream' => '무한 스트림',
			'fileInfo.directPlay' => 'Direct Play',
			'fileInfo.directStream' => 'Direct Stream',
			'fileInfo.transcoding' => '트랜스코딩',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => '버전 ID',
			'fileInfo.fileId' => '파일 ID',
			'fileInfo.defaultAudioTrack' => '기본 오디오 트랙',
			'fileInfo.defaultSubtitleTrack' => '기본 자막 트랙',
			'fileInfo.subtitlesOff' => '꺼짐',
			'fileInfo.flagDefault' => '기본',
			'fileInfo.flagForced' => '강제',
			'fileInfo.flagSelected' => '선택됨',
			'fileInfo.flagExternal' => '외부',
			'fileInfo.flagHearingImpaired' => '청각 장애인용',
			'fileInfo.flagDub' => '더빙',
			'fileInfo.flagOriginal' => '원본',
			'fileInfo.channelsMono' => '모노',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => '프로파일 ${profile}',
			'mediaMenu.markAsWatched' => '시청 완료로 표시',
			'mediaMenu.markAsUnwatched' => '미시청으로 표시',
			'mediaMenu.removeFromContinueWatching' => '계속 보기에서 제거',
			'mediaMenu.viewDetails' => '상세 정보 보기',
			'mediaMenu.goToSeries' => '시리즈로 이동',
			'mediaMenu.shufflePlay' => '무작위 재생',
			'mediaMenu.shuffleNotAvailableOffline' => '오프라인에서는 무작위 재생을 사용할 수 없습니다',
			'mediaMenu.fileInfo' => '파일 정보',
			'mediaMenu.deleteEpisodeFromServer' => '서버에서 에피소드 삭제',
			'mediaMenu.deleteSeasonFromServer' => '서버에서 시즌 삭제',
			'mediaMenu.deleteShowFromServer' => '서버에서 프로그램 삭제',
			'mediaMenu.deleteMovieFromServer' => '서버에서 영화 삭제',
			'mediaMenu.deleteEpisodeTitle' => '이 에피소드를 삭제할까요?',
			'mediaMenu.deleteSeasonTitle' => '이 시즌을 삭제할까요?',
			'mediaMenu.deleteShowTitle' => '이 프로그램을 삭제할까요?',
			'mediaMenu.deleteMovieTitle' => '이 영화를 삭제할까요?',
			'mediaMenu.deleteEpisodeConfirm' => '에피소드 삭제',
			'mediaMenu.deleteSeasonConfirm' => '시즌 삭제',
			'mediaMenu.deleteShowConfirm' => '프로그램 삭제',
			'mediaMenu.deleteMovieConfirm' => '영화 삭제',
			'mediaMenu.deleteAnyway' => '그래도 삭제',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '서버에서 ${title}을(를) 영구 삭제할까요?',
			'mediaMenu.deleteMultipleWarning' => '모든 에피소드와 파일이 포함됩니다.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '포함된 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개와 해당 파일이 삭제됩니다.', other: '포함된 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개와 해당 파일이 모두 삭제됩니다.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '이 항목은 파일 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개에 저장되어 있으며, 해당 파일이 삭제됩니다.', other: '이 항목은 파일 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개에 걸쳐 저장되어 있으며, 모든 파일이 삭제됩니다.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '같은 파일에 저장된 다른 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개도 함께 삭제됩니다:', other: '같은 파일에 저장된 다른 에피소드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개도 함께 삭제됩니다:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy가 어떤 파일이 삭제될지 확인하지 못해 위 항목보다 더 많은 파일이 삭제될 수 있습니다. 취소하고 다시 시도하거나 그래도 삭제하세요.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => '서버가 이 항목의 파일 정보를 제공하지 않아 Plezy가 어떤 파일이 삭제될지 확인할 수 없습니다. 위 항목보다 더 많은 파일이 삭제될 수 있습니다.',
			'mediaMenu.mediaDeletedSuccessfully' => '미디어 항목이 성공적으로 삭제되었습니다',
			'mediaMenu.mediaFailedToDelete' => '미디어 항목 삭제 실패',
			'mediaMenu.rate' => '평가',
			'mediaMenu.playFromBeginning' => '처음부터 재생',
			'mediaMenu.playVersion' => '버전 재생...',
			'rateSheet.title' => '평가',
			'rateSheet.server' => '서버',
			'rateSheet.favorite' => '즐겨찾기',
			'rateSheet.favorited' => '즐겨찾기됨',
			'rateSheet.saved' => '저장됨',
			'rateSheet.notAvailable' => '일치 항목 없음',
			'rateSheet.noConnectedServices' => '평가하려면 설정에서 서비스를 연결하세요.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, 영화',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV 프로그램',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => '시청 완료',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent}% 시청 완료',
			'accessibility.mediaCardUnwatched' => '미시청',
			'accessibility.tapToPlay' => '탭하여 재생',
			'accessibility.decrease' => '낮추기',
			'accessibility.increase' => '높이기',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} 낮추기',
			'accessibility.increaseValue' => ({required Object label}) => '${label} 높이기',
			'accessibility.hue' => '색조',
			'accessibility.saturation' => '채도',
			'accessibility.brightness' => '밝기',
			'accessibility.hexColor' => '16진수 색상',
			'accessibility.expandText' => '텍스트 펼치기',
			'accessibility.collapseText' => '텍스트 접기',
			'accessibility.alphabetNavigation' => '알파벳 탐색',
			'accessibility.alphabetScrollHint' => '위아래로 스와이프하여 글자별로 이동',
			'accessibility.rowColumnPosition' => ({required Object rowCount, required Object row, required Object columnCount, required Object column}) => '${rowCount}행 중 ${row}행, ${columnCount}열 중 ${column}열',
			'accessibility.rowPosition' => ({required Object rowCount, required Object row}) => '${rowCount}행 중 ${row}행',
			'accessibility.autoScrollPlay' => '자동 스크롤 재생',
			'accessibility.autoScrollPause' => '자동 스크롤 일시정지',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => '빨간색',
			'accessibility.green' => '녹색',
			'accessibility.blue' => '블루',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => '접근성',
			'accessibility.summary' => '텍스트, 대조, 움직임 및 컨트롤',
			'accessibility.systemHint' => '장치의 접근성 설정은 항상 적용됩니다.이 옵션은 PlezyNG에 걸쳐 조정이 추가됩니다.',
			'accessibility.readability' => '읽기 및 시야',
			'accessibility.textSize' => '추가 텍스트 크기',
			'accessibility.preview' => '다음 이야기를 찾아보세요.읽고, 듣고, 자신의 속도로 보세요.',
			'accessibility.boldText' => '용감한 인터페이스 텍스트',
			'accessibility.highContrast' => '높은 대조',
			'accessibility.highContrastHint' => '밝거나 어두운 배경에서 텍스트, 윤곽선 및 포커스 표시를 더 선명하게 보여줍니다.',
			'accessibility.interaction' => '운동과 상호 작용',
			'accessibility.reduceMotion' => '움직임을 줄이기',
			'accessibility.reduceMotionHint' => '포커스 표시, 페이지 전환 및 장식 효과의 움직임을 멈춥니다.',
			'accessibility.largeTargets' => '더 큰 터치 목표',
			'accessibility.largeTargetsHint' => '공통 컨트롤의 영역을 넓혀 터치와 보조 기술을 통한 탐색을 쉽게 합니다.',
			'accessibility.navigationHint' => 'Tab과 Shift+Tab으로 컨트롤 사이를 이동하고, Enter 또는 Space로 실행하고, Escape 또는 뒤로 버튼으로 닫으세요. 책을 열면 확대/축소와 읽기 설정을 사용할 수 있습니다.',
			'accessibility.textSizeDescription' => 'PlezyNG에서 스케일 인터페이스 텍스트는 장치의 시스템 텍스트 크기 설정 외에도.',
			'accessibility.boldTextHint' => '인터페이스 라벨과 메시지에 더 무거운 무게를 사용하여 구별하기 쉽습니다.',
			'tooltips.shufflePlay' => '무작위 재생',
			'tooltips.playTrailer' => '예고편 재생',
			'tooltips.markAsWatched' => '시청 완료로 표시',
			'tooltips.markAsUnwatched' => '미시청으로 표시',
			'audioTracks.track' => ({required Object n}) => '오디오 트랙 ${n}',
			'videoControls.audioLabel' => '오디오',
			'videoControls.subtitlesLabel' => '자막',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => '레터박스 모드',
			'videoControls.fillScreen' => '화면 채우기',
			'videoControls.stretch' => '확장',
			'videoControls.lockRotation' => '회전 잠금',
			'videoControls.unlockRotation' => '회전 잠금 해제',
			'videoControls.timerActive' => '타이머 활성화됨',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => '${duration} 후 재생이 일시정지됩니다',
			'videoControls.sleepTimerEndOfVideo' => '현재 비디오의 끝',
			'videoControls.sleepTimerStopAtHeader' => '정지 시점',
			'videoControls.sleepTimerDurationHeader' => '타이머',
			'videoControls.playbackWillPauseAtEnd' => '재생이 이 비디오의 끝에서 일시 중지됩니다',
			'videoControls.stillWatching' => '아직 시청 중이신가요?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}초 후 일시 정지',
			'videoControls.continueWatching' => '계속',
			'videoControls.autoPlayNext' => '다음 자동 재생',
			'videoControls.playNext' => '다음 재생',
			'videoControls.playButton' => '재생',
			'videoControls.pauseButton' => '일시정지',
			'videoControls.playbackPaused' => '일시정지됨',
			'videoControls.playbackResumed' => '재생 중',
			'videoControls.loadingVideo' => '동영상 로딩 중...',
			'videoControls.showPlaybackControls' => '재생 컨트롤 표시',
			'videoControls.hidePlaybackControls' => '재생 컨트롤 숨기기',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds}초 뒤로 이동',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds}초 앞으로 이동',
			'videoControls.previousButton' => '이전 에피소드',
			'videoControls.nextButton' => '다음 에피소드',
			'videoControls.previousChapterButton' => '이전 챕터',
			'videoControls.nextChapterButton' => '다음 챕터',
			'videoControls.muteButton' => '음소거',
			'videoControls.unmuteButton' => '음소거 해제',
			'videoControls.settingsButton' => '재생 설정',
			'videoControls.tracksButton' => '오디오 및 자막',
			'videoControls.chaptersButton' => '챕터',
			'videoControls.segmentLoopHelp' => '이 재생 중에 섹션을 움직이십시오.A를 설정하고 나중에 B를 타임 라인에 설정합니다.',
			'videoControls.setLoopStart' => '세트 루프 시작 (A)',
			'videoControls.setLoopEnd' => '세트 루프 끝 (B)',
			'videoControls.clearSegmentLoop' => '분명한 세그먼트 루프',
			'videoControls.setLoopStartFirst' => '롤 시작 (A) 전에 끝 (B)을 설정합니다.',
			'videoControls.loopEndAfterStart' => '롤 끝은 시작보다 나중에 있어야합니다.',
			'videoControls.segmentLoopUnavailable' => '세그먼트 루핑은 이 플레이백을 위해 사용할 수 없습니다.',
			'videoControls.loopPointNotSet' => '설정하지 않는',
			'videoControls.bookmarksHelp' => '책표는 이 장치에 저장됩니다.이 시간에 가기 위해 하나를 선택합니다.',
			'videoControls.bookmarksButton' => '책표',
			'videoControls.chaptersAndBookmarks' => '장 및 책표',
			'videoControls.segmentLoop' => '세그먼트 루프',
			'videoControls.addBookmark' => 'Bookmark 추가하기',
			'videoControls.bookmarkName' => 'Bookmark 이름',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => '예를 들어, 개방 장면',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => '책표 ${n}',
			'videoControls.bookmarkNameRequired' => '이 책자에 대한 이름을 입력합니다.',
			'videoControls.deleteBookmark' => 'Bookmark 삭제',
			'videoControls.bookmarkLimitReached' => '이 항목은 이미 100 개의 책표를 가지고 있습니다.',
			'videoControls.bookmarkUnavailable' => '이 책을 저장하거나 제거할 수는 없습니다.',
			'videoControls.bookmarkSaved' => '도서관이 저장되었습니다.',
			'videoControls.bookmarkDeleted' => 'Bookmark 삭제됨',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => '로프 포인트 ${point} 세트 에 ${time}그리고',
			'videoControls.noChaptersOrBookmarks' => '장이나 책표가 없습니다.',
			'videoControls.versionQualityButton' => '버전 및 화질',
			'videoControls.versionColumnHeader' => '버전',
			'videoControls.qualityColumnHeader' => '화질',
			'videoControls.qualityOriginal' => '원본',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => '트랜스코딩을 사용할 수 없음 — 원본 화질로 재생',
			'videoControls.subtitleUnavailableFallback' => '선택한 자막을 불러올 수 없어 자막 없이 재생을 계속합니다',
			'videoControls.pipButton' => '픽처 인 픽처 모드',
			'videoControls.aspectRatioButton' => '화면비율',
			'videoControls.ambientLighting' => '주변 조명',
			'videoControls.fullscreenButton' => '전체 화면',
			'videoControls.exitFullscreenButton' => '전체 화면 종료',
			'videoControls.alwaysOnTopButton' => '창 최상위 고정',
			'videoControls.rotationLockButton' => '회전 잠금',
			'videoControls.lockScreen' => '화면 잠금',
			'videoControls.screenLockButton' => '화면 잠금',
			'videoControls.timelineSlider' => '타임라인',
			'videoControls.volumeSlider' => '볼륨 조절',
			'videoControls.endsAt' => ({required Object time}) => '${time}에 종료',
			'videoControls.pipActive' => '화면 속 화면으로 재생 중',
			'videoControls.pipFailed' => '화면 속 화면 모드를 시작할 수 없습니다',
			'videoControls.screenshotSaved' => '스크린샷 저장됨',
			'videoControls.screenshotFailed' => '스크린샷을 찍지 못했습니다',
			'videoControls.zoomPercent' => ({required Object percent}) => '확대/축소 ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => '볼륨 ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 이상이 필요합니다',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 이상이 필요합니다',
			'videoControls.pipErrors.permissionDisabled' => '화면 속 화면이 비활성화되어 있습니다. 시스템 설정에서 활성화하세요.',
			'videoControls.pipErrors.notSupported' => '이 기기는 화면 속 화면 모드를 지원하지 않습니다',
			'videoControls.pipErrors.voSwitchFailed' => '화면 속 화면을 위한 비디오 출력 전환에 실패했습니다',
			'videoControls.pipErrors.failed' => '화면 속 화면 모드를 시작할 수 없습니다',
			'videoControls.pipErrors.prepareFailed' => '화면 속 화면을 준비할 수 없습니다',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '오류가 발생했습니다: ${error}',
			'videoControls.chapters' => '챕터',
			'videoControls.noChaptersAvailable' => '사용 가능한 챕터가 없습니다',
			'videoControls.queue' => '재생 대기열',
			'videoControls.noQueueItems' => '대기열에 항목이 없습니다',
			'videoControls.noAudioDevicesAvailable' => '사용 가능한 오디오 기기가 없습니다',
			'videoControls.searchSubtitles' => '자막 검색',
			'videoControls.language' => '언어',
			'videoControls.noSubtitlesFound' => '자막을 찾을 수 없습니다',
			'videoControls.subtitleDownloaded' => '자막이 다운로드되었습니다',
			'videoControls.subtitleDownloadedNotApplied' => '자막을 다운로드했지만 선택할 수 없습니다',
			'videoControls.subtitleDownloadFailed' => '자막 다운로드에 실패했습니다',
			'videoControls.searchLanguages' => '언어 검색...',
			'videoControls.skipIntro' => '인트로 건너뛰기',
			'videoControls.skipCredits' => '크레딧 건너뛰기',
			'videoControls.nextEpisode' => '다음 에피소드',
			'videoControls.subtitleTrack' => ({required Object n}) => '트랙 ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => '자막 ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (강제)',
			'videoControls.osdSubtitlesOff' => '자막: 꺼짐',
			'videoControls.osdSubtitles' => ({required Object track}) => '자막: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => '오디오: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 프레임', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 프레임', ), 
			'videoControls.trackSelectionTitle' => '플레이백 전에 트랙을 선택합니다.',
			'videoControls.trackSelectionAuto' => '자동 선택',
			'videoControls.openMiniPlayer' => '오픈 미니 플레이어',
			'videoControls.returnToFullPlayer' => '완전한 플레이어로 돌아가기',
			'videoControls.loadSubtitleFile' => 'Subtitle 파일을 다운로드합니다.',
			'videoControls.subtitleLoadFailed' => 'Subtitle 파일을 다운로드하지 못했습니다.',
			'videoControls.skipAds' => '스키 광고',
			'videoControls.tapToUnlock' => '잠금을 해제하려면 탭하세요',
			'videoControls.tapAgainToUnlock' => '잠금을 해제하려면 다시 탭하세요',
			'messages.markedAsWatched' => '시청 완료로 표시됨',
			'messages.markedAsUnwatched' => '미시청으로 표시됨',
			'messages.markedAsWatchedOffline' => '시청 완료로 표시됨 (연결 시 동기화됨)',
			'messages.markedAsUnwatchedOffline' => '미시청으로 표시됨 (연결 시 동기화됨)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '자동 삭제됨: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '자동 삭제 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 다운로드 보기', other: '시청한 다운로드 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개를 자동 삭제했습니다', ), 
			'messages.removedFromContinueWatching' => '계속 시청 목록에서 제거됨',
			'messages.errorLoading' => ({required Object error}) => '오류: ${error}',
			'messages.searchPartialResults' => '일부 미디어 서버를 검색하지 못했습니다. 사용 가능한 결과만 표시합니다.',
			'messages.streamInterrupted' => '스트림이 중단되었습니다. 재생을 누르거나 탐색하여 다시 시도하세요.',
			'messages.liveStreamInterrupted' => '라이브 스트림이 중단되었습니다. 재생을 눌러 다시 시도하세요.',
			'messages.fileInfoNotAvailable' => '파일 정보가 없습니다',
			'messages.playbackAuthenticationRequired' => '이 항목을 재생하려면 미디어 서버에 다시 로그인하세요.',
			'messages.playbackServerUnavailable' => '미디어 서버를 사용할 수 없습니다. 나중에 다시 시도하세요.',
			'messages.playbackDataInvalid' => '서버에서 잘못된 재생 정보를 반환했습니다.',
			'messages.playbackCancelled' => '재생이 취소되었습니다.',
			'messages.playbackFailed' => '재생을 시작할 수 없습니다.',
			'messages.playbackFailedDetail' => ({required Object error}) => '재생을 시작할 수 없습니다: ${error}',
			'messages.audioOutputFailed' => '오디오 출력이 응답하지 않습니다. TV 또는 리시버의 오디오 연결을 확인하세요. 다른 앱에서도 소리가 나지 않으면 기기를 재시작하세요.',
			'messages.mediaUnavailable' => '이 콘텐츠는 더 이상 사용할 수 없습니다.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => '파일 정보 로딩 중 오류: ${error}',
			'messages.errorLoadingSeries' => '시리즈 로딩 중 오류',
			'messages.musicNotSupported' => '음악 재생 미지원',
			'messages.noDescriptionAvailable' => '설명이 없습니다',
			'messages.noProfilesAvailable' => '사용 가능한 프로필이 없습니다',
			'messages.contactAdminForProfiles' => '프로필을 추가하려면 서버 관리자에게 문의하세요',
			'messages.unableToDetermineLibrarySection' => '이 항목의 라이브러리 섹션을 확인할 수 없습니다',
			'messages.logsCleared' => '로그가 삭제되었습니다',
			'messages.logsCopied' => '로그가 클립보드에 복사되었습니다',
			'messages.noLogsAvailable' => '사용 가능한 로그가 없습니다',
			'messages.libraryScanning' => ({required Object title}) => '"${title}"을(를) 스캔 중입니다...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}" 미디어 라이브러리 스캔 시작',
			'messages.libraryScanFailed' => ({required Object error}) => '미디어 라이브러리 스캔 실패: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" 메타데이터 새로고침 중...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" 메타데이터 새로고침 시작됨',
			'messages.metadataRefreshFailed' => ({required Object error}) => '메타데이터 새로고침 실패: ${error}',
			'messages.logoutConfirm' => '로그아웃하시겠습니까?',
			'messages.noSeasonsFound' => '시즌을 찾을 수 없음',
			'messages.seasonsLoadFailed' => '시즌을 불러오지 못했습니다',
			'messages.noEpisodesFound' => '시즌 1에서 에피소드를 찾을 수 없습니다',
			'messages.noEpisodesFoundGeneral' => '에피소드를 찾을 수 없습니다',
			'messages.episodesLoadFailed' => '에피소드를 불러오지 못했습니다',
			'messages.noResultsFound' => '결과를 찾을 수 없습니다',
			'messages.sleepTimerSet' => ({required Object label}) => '취침 타이머가 ${label}(으)로 설정되었습니다',
			'messages.noItemsAvailable' => '사용 가능한 항목이 없습니다',
			'messages.failedToCreatePlayQueueNoItems' => '재생 대기열을 만들지 못했습니다 — 항목이 없습니다',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action}을(를) 수행할 수 없습니다: ${error}',
			'messages.switchingToCompatiblePlayer' => '호환되는 플레이어로 전환 중...',
			'messages.serverLimitTitle' => '재생 실패',
			'messages.serverLimitBody' => '서버 오류(HTTP 500). 대역폭/트랜스코딩 제한으로 세션이 거부된 것 같습니다. 소유자에게 조정을 요청하세요.',
			'messages.mediaUnreadableTitle' => '파일을 사용할 수 없음',
			'messages.mediaUnreadableBody' => '서버에서 이 항목을 찾았지만 파일을 읽을 수 없습니다(HTTP 404). 파일이 이동되거나 삭제되었거나 저장소가 오프라인 상태일 수 있습니다. 서버 관리자에게 파일 확인과 라이브러리 재스캔을 요청하세요.',
			'messages.serverBusyTitle' => '스트림을 사용할 수 없음',
			'messages.serverBusyBody' => '서버에서 이 파일의 스트리밍을 계속 거부했습니다(HTTP 503). 서버가 다시 시작 중이거나 사용량이 많을 수 있으며, 파일이 저장된 저장소가 오프라인일 수도 있습니다. 잠시 후 다시 시도하세요. 문제가 계속되면 서버 소유자에게 서버와 파일 저장소를 확인해 달라고 요청하세요.',
			'messages.playbackNotAllowedTitle' => '재생이 허용되지 않음',
			'messages.playbackNotAllowedBody' => '서버에서 이 항목의 스트리밍을 거부했습니다(HTTP 403). 계정에 재생 권한이 없거나 서버가 로컬 네트워크에서만 재생을 허용할 수 있습니다.',
			'messages.logsUploaded' => '로그 업로드 완료',
			'messages.logsUploadFailed' => '로그 업로드 실패',
			'messages.logId' => '로그 ID',
			'messages.burnedSubtitlesUseMenu' => '자막이 이 스트림에 입혀져 있습니다. 자막 메뉴에서 변경하세요.',
			'messages.noVideoUrl' => '사용 가능한 비디오 URL이 없습니다',
			'messages.playbackNoMediaSources' => '서버에서 재생 가능한 미디어 소스를 반환하지 않았습니다',
			'messages.playbackDataNotPrepared' => '재생 데이터가 준비되기 전에 재생이 시작되었습니다',
			'messages.streamSelectionUnavailable' => '이 소스에서는 스트림을 선택할 수 없습니다',
			'messages.streamSelectionFailed' => '선택한 스트림을 적용할 수 없습니다',
			'messages.trackSelectionNotRemembered' => '이 트랙 선택은 현재 재생에만 적용됩니다.',
			'messages.serverUnavailableForProfile' => '활성 프로필에 사용할 수 있는 서버가 없습니다',
			'subtitlingStyling.previewSample' => '빠른 갈색 엉덩이가 멍청한 개를 뛰어 넘는다.',
			'subtitlingStyling.text' => '텍스트',
			'subtitlingStyling.border' => '테두리',
			'subtitlingStyling.background' => '배경',
			'subtitlingStyling.fontSize' => '글자 크기',
			'subtitlingStyling.textColor' => '텍스트 색상',
			'subtitlingStyling.borderSize' => '테두리 크기',
			'subtitlingStyling.borderColor' => '테두리 색상',
			'subtitlingStyling.backgroundOpacity' => '배경 불투명도',
			'subtitlingStyling.backgroundColor' => '배경색',
			'subtitlingStyling.position' => '위치',
			'subtitlingStyling.assOverride' => 'ASS 오버라이드',
			'subtitlingStyling.overrideScale' => '크기 조정',
			'subtitlingStyling.overrideForce' => '강제 적용',
			'subtitlingStyling.overrideStrip' => '스타일 제거',
			'subtitlingStyling.positionTop' => '위',
			'subtitlingStyling.positionBottom' => '아래',
			'subtitlingStyling.useMargins' => '여백 사용',
			'subtitlingStyling.useMarginsDescription' => '텍스트 자막을 비디오 바깥 영역에 표시할 수 있습니다. 스타일이 적용된 자막은 원래 위치를 유지할 수 있습니다.',
			'subtitlingStyling.anchorToScreen' => '화면에 고정',
			'subtitlingStyling.anchorToScreenDescription' => '와이드스크린 비디오 아래의 검은 여백에 텍스트 자막을 표시합니다',
			'subtitlingStyling.bold' => '굵게',
			'subtitlingStyling.italic' => '기울임꼴',
			'subtitlingStyling.renderResolution' => '렌더링 해상도',
			'subtitlingStyling.renderResolutionScreen' => '화면 해상도',
			'subtitlingStyling.renderResolutionVideo' => '영상 해상도',
			'subtitlingStyling.fontSizeDescription' => '이 장치에 서브 텍스트 크기를 설정합니다.',
			'subtitlingStyling.textColorDescription' => 'Subtitle 텍스트에 사용되는 색상을 선택합니다.',
			'subtitlingStyling.borderSizeDescription' => 'Subtitle 텍스트 주위에 출력의 두께를 설정합니다.',
			'subtitlingStyling.borderColorDescription' => '서브 타이틀에 사용되는 색상을 선택합니다.',
			'subtitlingStyling.backgroundColorDescription' => '서브 타이틀 텍스트 뒤에 있는 색상을 선택합니다.',
			'subtitlingStyling.backgroundOpacityDescription' => '서브 타이틀 배경이 얼마나 투명한지 설정하십시오: 0%는 명확하고 100%는 견고합니다.',
			'subtitlingStyling.positionDescription' => '0 %는 비디오의 상단이며 100 %는 바닥입니다.',
			'subtitlingStyling.assOverrideDescription' => '플레이어가 ASS 하위 제목에 삽입 된 스타일링을 추적, 조정, 교체 또는 제거하는지 여부를 선택합니다.',
			'subtitlingStyling.assOverrideOptions.no' => '글꼴, 색상, 크기 및 배치가 서브 타이틀 파일에 기록되어 있습니다.',
			'subtitlingStyling.assOverrideOptions.yes' => '플레이어의 하위 제목 스타일 설정을 ASS 하위 타이틀을 조정하도록 허용합니다.',
			'subtitlingStyling.assOverrideOptions.scale' => '플레이어 스타일링 및 스케일 내장 크기를 적용하여 비디오 차원과 일치합니다.',
			'subtitlingStyling.assOverrideOptions.force' => '삽입된 ASS 스타일을 플레이어의 하위 타이틀 스타일로 대체합니다.',
			'subtitlingStyling.assOverrideOptions.strip' => '삽입 된 ASS 형식을 제거하고 서브 타이틀 텍스트를 명확하게 수행합니다.',
			'subtitlingStyling.renderResolutionDescription' => '이미지와 ASS 서브 타이틀을 라스테리화하는 데 사용되는 해상도를 선택합니다.더 낮은 안드로이드 스케일은 rendering 작업을 줄일 수 있지만 더 부드럽게 보입니다.',
			'subtitlingStyling.renderResolutionOptions.screen' => '가장 뚜렷한 결과를 위해 전체 표면 해상도에서 렌더링합니다.',
			'subtitlingStyling.renderResolutionOptions.video' => '참조로 비디오 해상도를 사용하여 고해상도 디스플레이에서 작업을 줄일 수 있습니다.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => '겸손한 성능 절약을 위해 디스플레이 표면 해상도의 75 %를 할인합니다.',
			'subtitlingStyling.renderResolutionOptions.half' => '작업을 줄이기 위해 표시 표면 해상도의 50 %로 렌더링, 더 부드러운 가장자리.',
			'subtitlingStyling.renderResolutionOptions.third' => '작업을 줄이기 위해 화면 표면 해상도의 3 분의 1에서 렌더링, 더 부드러운 가장자리.',
			'subtitlingStyling.renderResolutionOptions.quarter' => '작업을 줄이기 위해 디스플레이 표면 해상도의 1 분의 1에서 렌더, 가장 부드러운 결과.',
			'subtitlingStyling.boldDescription' => '더 무거운 무게로 서브 타이틀 텍스트를 그리십시오.',
			'subtitlingStyling.italicDescription' => '이탈리아어로 발음한 Subtitle 텍스트',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => '고급 비디오 플레이어 설정',
			'mpvConfig.presets' => '프리셋',
			'mpvConfig.noPresets' => '저장된 프리셋이 없습니다',
			'mpvConfig.saveAsPreset' => '프리셋으로 저장...',
			'mpvConfig.presetName' => '프리셋 이름',
			'mpvConfig.presetNameHint' => '이 프리셋의 이름을 입력하세요',
			'mpvConfig.loadPreset' => '불러오기',
			'mpvConfig.deletePreset' => '삭제',
			'mpvConfig.presetSaved' => '프리셋이 저장되었습니다',
			'mpvConfig.presetLoaded' => '프리셋을 불러왔습니다',
			'mpvConfig.presetDeleted' => '프리셋이 삭제되었습니다',
			'mpvConfig.confirmDeletePreset' => '이 프리셋을 삭제하시겠습니까?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => '줄 추가',
			'mpvConfig.removeLine' => '줄 제거',
			'mpvConfig.embeddedVoHint' => 'Linux에서는 vo, gpu-context, gpu-api가 무시됩니다. 내장 동영상은 항상 비디오 평면에서 vo=libmpv로 렌더링되며, gpu-next(ArtCNN 같은 컴퓨트 셰이더에 필요)는 내장 방식으로 실행할 수 없습니다.',
			'dialog.confirmAction' => '작업 확인',
			'profiles.addPlezyProfile' => 'PlezyNG 프로필 추가',
			'profiles.switchingProfile' => '프로필 전환 중…',
			'profiles.deleteThisProfileTitle' => '이 프로필을 삭제하시겠습니까?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName}을(를) 제거합니다. 연결에는 영향이 없습니다.',
			'profiles.active' => '활성',
			'profiles.manage' => '관리',
			'profiles.delete' => '삭제',
			'profiles.signOut' => '로그아웃',
			'profiles.signOutPlexTitle' => 'Plex에서 로그아웃하시겠습니까?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} 및 모든 Plex Home 사용자를 제거할까요? 언제든 다시 로그인할 수 있습니다.',
			'profiles.signOutPlexDeleteDownloads' => '다운로드도 삭제',
			'profiles.signOutPlexDeleteDownloadsDescription' => '삭제하지 않으면 다운로드가 이 기기에 남아 있다가 이 계정에 다시 로그인하면 다시 표시됩니다.',
			'profiles.signedOutPlex' => 'Plex에서 로그아웃되었습니다.',
			'profiles.signOutFailed' => '로그아웃에 실패했습니다.',
			'profiles.sectionTitle' => '프로필',
			'profiles.summarySingle' => '관리되는 사용자와 로컬 ID를 혼합하려면 프로필을 추가하세요',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count}개 프로필 · 활성: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count}개 프로필',
			'profiles.removeConnectionTitle' => '연결을 제거하시겠습니까?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName}의 ${connectionLabel} 접근 권한을 제거합니다. 다른 프로필에는 유지됩니다.',
			'profiles.deleteProfileTitle' => '프로필을 삭제하시겠습니까?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} 및 해당 연결을 제거합니다. 서버는 계속 사용할 수 있습니다.',
			'profiles.profileNameLabel' => '프로필 이름',
			'profiles.pinProtectionLabel' => 'PIN 보호',
			'profiles.copyAutomationLink' => '복사 Android 자동화 링크',
			'profiles.copyAutomationLinkDescription' => '이 프로필을 Android 의도 또는 자동화에서 선택합니다. 프로필 PIN 검사는 여전히 적용됩니다.',
			'profiles.automationLinkCopied' => '프로필 자동화 링크 복사.',
			'profiles.pinManagedByPlex' => 'PIN은 Plex에서 관리됩니다. plex.tv에서 편집하세요.',
			'profiles.noPinSetEditOnPlex' => '설정된 PIN이 없습니다. 요구하려면 plex.tv에서 Home 사용자를 편집하세요.',
			'profiles.setPin' => 'PIN 설정',
			'profiles.setPinTitle' => 'PIN 설정',
			'profiles.confirmPinTitle' => 'PIN 확인',
			'profiles.pinSet' => 'PIN 설정됨',
			'profiles.changePin' => '변경',
			'profiles.removePin' => '제거',
			'profiles.connectionsLabel' => '연결',
			'profiles.add' => '추가',
			'profiles.deleteProfileButton' => '프로필 삭제',
			'profiles.noConnectionsHint' => '연결이 없습니다 — 이 프로필을 사용하려면 하나 추가하세요.',
			'profiles.noConnections' => '연결 없음',
			'profiles.plexHomeAccount' => 'Plex Home 계정',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex 계정: ${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} 계정의 ${user}',
			'profiles.connectionDefault' => '기본값',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName}(으)로',
			'profiles.makeDefault' => '기본값으로 설정',
			'profiles.removeConnection' => '제거',
			'profiles.profileRenamed' => '프로필 이름이 변경되었습니다.',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName}에 추가',
			'profiles.borrowExplain' => '다른 프로필의 연결을 빌립니다. PIN으로 보호된 프로필에는 PIN이 필요합니다.',
			'profiles.borrowEmpty' => '아직 빌릴 것이 없습니다.',
			'profiles.borrowEmptySubtitle' => '먼저 다른 프로필에 Plex, Jellyfin 또는 Emby를 연결하세요.',
			'profiles.borrowLoadFailed' => '사용 가능한 연결을 불러오지 못했습니다. 다시 시도하세요.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName}에서',
			'profiles.borrowConnectionBorrowed' => '연결을 빌렸습니다.',
			'profiles.borrowFailed' => '연결을 빌리지 못했습니다.',
			'profiles.incorrectPin' => 'PIN이 올바르지 않습니다.',
			'profiles.incorrectPinTryAgain' => 'PIN이 올바르지 않습니다. 다시 시도하세요.',
			'profiles.sourceProfileMissingParentAccount' => '원본 프로필에 상위 계정이 없습니다.',
			'profiles.failedToLoadHomeUsers' => 'Plex Home 사용자를 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.',
			'profiles.failedToVerifyPin' => 'PIN을 확인하지 못했습니다.',
			'profiles.newProfile' => '새 프로필',
			'profiles.profileNameHint' => '예: 손님, 어린이, 가족실',
			'profiles.pinProtectionOptional' => 'PIN 보호 (선택 사항)',
			'profiles.pinExplain' => '프로필 전환에는 4자리 PIN이 필요합니다.',
			'profiles.continueButton' => '계속',
			'profiles.pinsDontMatch' => 'PIN이 일치하지 않습니다',
			'profiles.tokenIdentityMismatch' => 'Plex 프로필 토큰이 예상과 다른 서버로 확인되었습니다',
			'profiles.settingsLocked' => '이 프로필에 대한 설정이 잠겨 있습니다.',
			'profiles.unlockSettings' => '닫기 설정',
			'profiles.showExploreForProfile' => '이 프로필을 위한 탐색을 보여주기',
			'profiles.showExploreForProfileDescription' => '이 프로필의 항해에서 Explore를 제거하기 위해 끄십시오.',
			'connections.sectionTitle' => '연결',
			'connections.addConnection' => '연결 추가',
			'connections.addConnectionSubtitleNoProfile' => 'Plex로 로그인하거나 Jellyfin 또는 Emby 서버에 연결',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}에 추가: Plex, Jellyfin, Emby 또는 다른 프로필 연결',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name}의 세션이 만료되었습니다',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count}개 서버의 세션이 만료되었습니다',
			'connections.accessDeniedOne' => ({required Object name}) => '${name}에서 이 계정의 접근을 거부했습니다',
			'connections.accessDeniedMany' => ({required Object count}) => '${count}개 서버에서 이 계정의 접근을 거부했습니다',
			'connections.signInAgain' => '다시 로그인',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product} 연결 편집',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName}의 URL을 추가하거나 제거하세요. Plezy는 연결 가능한 URL 중 지연 시간이 가장 낮은 URL을 사용합니다.',
			'accountPreferences.sectionTitle' => '계정 기본 설정',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '${account}에 저장된 오디오, 자막 및 라이브러리 옵션',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '${count}개 계정에 저장된 오디오, 자막 및 라이브러리 옵션',
			'accountPreferences.pickAccount' => '각 계정은 고유한 기본 설정을 저장합니다. 편집할 계정을 선택하세요.',
			'accountPreferences.storedOnAccount' => '이 옵션은 계정 자체에 저장되므로 해당 계정으로 로그인한 모든 앱에서 사용됩니다 — 다른 기기의 Plezy를 포함합니다.',
			'accountPreferences.noAccounts' => '구성할 계정이 없습니다',
			'accountPreferences.noAccountsHint' => 'Plex에 로그인하거나 Jellyfin 또는 Emby 서버에 연결하면 해당 계정에 저장된 기본 설정이 여기에 표시됩니다.',
			'accountPreferences.unavailable' => '이 계정에 연결할 수 없습니다',
			'accountPreferences.loadFailed' => '이 기본 설정을 불러올 수 없습니다',
			'accountPreferences.noPreference' => '기본 설정 없음',
			'accountPreferences.notSet' => '설정되지 않음',
			'accountPreferences.groups.audioAndSubtitles' => '오디오 및 자막',
			'accountPreferences.groups.libraryDisplay' => '라이브러리',
			'accountPreferences.groups.personalMedia' => '개인 미디어',
			'accountPreferences.preferredAudioLanguage' => '선호 오디오 언어',
			'accountPreferences.autoSelectAudio' => '언어별로 오디오 선택',
			'accountPreferences.autoSelectAudioDescription' => '끄면 파일이 기본으로 표시한 오디오 트랙을 유지합니다.',
			'accountPreferences.preferredSubtitleLanguage' => '선호 자막 언어',
			'accountPreferences.subtitleMode' => '자막 자동 켜기',
			'accountPreferences.subtitleModes.none' => '수동 선택',
			'accountPreferences.subtitleModes.noneDescription' => '자동으로 자막을 켜지 않습니다.',
			'accountPreferences.subtitleModes.defaultMode' => '트랙 플래그 따르기',
			'accountPreferences.subtitleModes.defaultModeDescription' => '각 자막 트랙에 저장된 기본 및 강제 플래그를 사용합니다.',
			'accountPreferences.subtitleModes.always' => '항상 활성화',
			'accountPreferences.subtitleModes.alwaysDescription' => '선호 언어의 자막 트랙이 있으면 항상 켭니다.',
			'accountPreferences.subtitleModes.onlyForced' => '강제 자막만',
			'accountPreferences.subtitleModes.onlyForcedDescription' => '강제로 표시된 트랙만 로드합니다.',
			'accountPreferences.subtitleModes.smart' => '외국어 오디오 시 표시',
			'accountPreferences.subtitleModes.smartDescription' => '오디오가 다른 언어일 때만 자막을 켭니다.',
			'accountPreferences.subtitleAccessibility' => 'SDH 자막',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'SDH가 아닌 자막 선호',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH 자막 선호',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'SDH 자막만',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'SDH가 아닌 자막만',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => '기본 및 SDH 버전 모두 사용할 수 있는 경우 표준 하위 제목을 선호합니다.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => '사용할 때 SDH 하위 제목을 선호하지만 표준 하위 타이틀을 붕괴로 허용합니다.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'SDH 하위 제목만 사용하십시오; 표준 하위 타이틀으로 돌아가지 마십시오.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => '표준 하위 제목만 사용하십시오; SDH 하위 이름을 제외합니다.',
			'accountPreferences.forcedSubtitles' => '강제 자막',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => '강제가 아닌 자막 선호',
			'accountPreferences.forcedSubtitleOptions.preferForced' => '강제 자막 선호',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => '강제 자막만',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => '강제가 아닌 자막만',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => '정기적 인 서브 타이틀을 선호하지만 붕괴로 강제 트랙을 허용합니다.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => '사용할 때 강제 트랙을 선호하지만, 붕괴로 정기적 인 서브 타이틀을 허용합니다.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => '강제로 표시된 트랙만 사용하십시오.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => '강제로 표시된 트랙을 제외합니다.',
			'accountPreferences.displayMissingEpisodes' => '누락된 에피소드 표시',
			'accountPreferences.displayMissingEpisodesDescription' => '서버가 알고 있지만 파일이 없는 에피소드를 나열합니다.',
			'accountPreferences.hidePlayedInLatest' => '최신 항목에서 시청한 항목 숨기기',
			'accountPreferences.hidePlayedInLatestDescription' => '이미 시청한 항목은 서버의 최신 행에서 제외합니다.',
			'accountPreferences.displayCollectionsView' => '컬렉션 보기 표시',
			'accountPreferences.displayCollectionsViewDescription' => '라이브러리와 함께 서버의 컬렉션 보기를 제공합니다.',
			'accountPreferences.rewatchingInNextUp' => '재시청한 프로그램을 다음 에피소드에 유지',
			'accountPreferences.rewatchingInNextUpDescription' => '프로그램을 끝까지 본 뒤 다시 시작하면, 목록에서 제거하는 대신 다음 에피소드가 재시청을 따라갑니다.',
			'accountPreferences.watchedIndicator' => '시청 표시',
			'accountPreferences.watchedIndicatorOptions.none' => '안 함',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => '영화 및 TV 프로그램',
			'accountPreferences.watchedIndicatorOptions.movies' => '영화만',
			'accountPreferences.watchedIndicatorOptions.shows' => 'TV 프로그램만',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => '보관된 체크마크를 표시하지 마십시오.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => '영화 및 TV 쇼에 대한 체크 마커를 표시합니다.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => '영화에만 시청된 체크 마크를 표시합니다.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => '텔레비전 쇼에만 시청된 체크 마크를 표시합니다.',
			'accountPreferences.mediaReviewsVisibility' => '평점 및 리뷰',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => '사용자 및 평론가',
			'accountPreferences.mediaReviewsOptions.usersOnly' => '사용자만',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => '평론가만',
			'accountPreferences.mediaReviewsOptions.nobody' => '숨김',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => '사용자 평가와 비판적 평가를 모두 표시합니다.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => '사용자가 제출한 평가 및 리뷰를 표시합니다.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => '비판적 인 평가 및 리뷰를 표시합니다.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => '평가 및 리뷰를 숨기십시오.',
			'accountPreferences.preferredAudioLanguageDescription' => '서버 또는 플레이어가 자동으로 트랙을 선택할 때이 언어로 오디오 트래크를 선호합니다.',
			'accountPreferences.preferredSubtitleLanguageDescription' => '자막이 자동으로 선택되면 이 언어에서 자막을 추적하는 것을 선호합니다.',
			'accountPreferences.subtitleAccessibilityDescription' => '자동 하위 제목 선택 중에 SDH 캡션이 선호되거나 요구되는지 여부를 선택합니다.',
			'accountPreferences.forcedSubtitleDescription' => '자동 선택 중에 강제 서브 타이틀 트랙이 선호되거나 요구되는지 여부를 선택합니다.',
			'accountPreferences.watchedIndicatorDescription' => '어떤 미디어 유형이 서버 인터페이스에서 관찰된 체크 마크를 받는지 선택합니다.',
			'accountPreferences.mediaReviewsVisibilityDescription' => '서버가 미디어 페이지에 표시하는 관객과 비판적 평가를 선택합니다.',
			'accountPreferences.subtitleModeDescription' => '이 서버 계정에서 하위 제목이 자동으로 켜질 때를 선택합니다.',
			'accountPreferences.hubDescription' => '이러한 선호도는 미디어 서버 계정에 저장되며 다른 고객에게도 적용될 수 있습니다.',
			'discover.title' => '둘러보기',
			'discover.noContentAvailable' => '사용 가능한 콘텐츠가 없습니다',
			'discover.addMediaToLibraries' => '미디어 라이브러리에 미디어를 추가해 주세요',
			'discover.continueWatching' => '계속 시청',
			'discover.continueWatchingIn' => ({required Object library}) => '${library}에서 계속 시청',
			'discover.nextUp' => '다음 에피소드',
			'discover.nextUpIn' => ({required Object library}) => '${library}의 다음 에피소드',
			'discover.recentlyAdded' => '최근에 추가됨',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library}에 최근에 추가됨',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library}의 최신 앨범',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library}에서 최근 재생',
			'discover.mostPlayedIn' => ({required Object library}) => '${library}에서 가장 많이 재생',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => '개요',
			'discover.cast' => '출연진',
			'discover.findNext.title' => '다음에 즐길 콘텐츠 찾기',
			'discover.findNext.open' => '다음에 즐길 콘텐츠 찾기',
			'discover.findNext.anyTime' => '시간 제한 없음',
			'discover.findNext.timeAvailable' => '시간이 얼마나 있나요?',
			'discover.findNext.filters' => '지금 이 순간에 맞게 선택하세요',
			'discover.findNext.watch' => '보기',
			'discover.findNext.listen' => '듣기',
			'discover.findNext.read' => '읽기',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration} 안에 끝낼 수 있습니다',
			'discover.findNext.aboutDuration' => ({required Object duration}) => '약 ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => '다음 챕터 · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '총 ${duration}',
			'discover.findNext.timingVaries' => '소요 시간은 달라질 수 있습니다',
			'discover.findNext.notNow' => '지금은 건너뛰기',
			'discover.findNext.swipeHint' => '표지를 화살표 방향으로 밀거나 아래 버튼을 사용하세요.',
			'discover.findNext.saved' => '저장한 추천',
			'discover.findNext.savedCount' => ({required Object count}) => '저장한 추천 · ${count}',
			'discover.findNext.undo' => '실행 취소',
			'discover.findNext.details' => '상세 정보',
			'discover.findNext.noPicks' => '아직 선택할 콘텐츠가 없습니다',
			'discover.findNext.noPicksHint' => '라이브러리를 연결하거나 미디어 소스를 추가하여 시작하세요.',
			'discover.findNext.noMatches' => '지금 조건에 맞는 콘텐츠가 없습니다',
			'discover.findNext.noMatchesHint' => '다른 미디어 종류를 선택하거나 시간을 조금 더 늘려 보세요.',
			'discover.findNext.allDone' => '모든 추천을 확인했습니다',
			'discover.findNext.allDoneHint' => '새로운 추천 조합을 만들면 이 선택지들을 다시 볼 수 있습니다.',
			'discover.findNext.refresh' => '다른 추천 조합 찾기',
			'discover.findNext.sourceReason' => ({required Object source}) => '출처: ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => '라이브러리: ${library}',
			'discover.findNext.ownedReason' => '내 라이브러리에서',
			'discover.findNext.liveNow' => '현재 방송 중',
			'discover.findNext.watchLive' => '실시간 시청',
			'discover.findNext.filterAnything' => '모든 종류',
			'discover.findNext.filterWatch' => '보기',
			'discover.findNext.filterListen' => '듣기',
			'discover.findNext.filterRead' => '읽기',
			'discover.findNext.twentyMinutes' => '20분',
			'discover.findNext.fortyFiveMinutes' => '45분',
			'discover.findNext.ninetyMinutes' => '90분',
			'discover.findNext.apply' => '적용',
			'discover.findNext.openFailed' => '이 콘텐츠는 더 이상 이용할 수 없습니다. 새로고침하여 다시 확인하세요.',
			'discover.findNext.changeFailed' => '변경 사항을 저장할 수 없습니다. 다시 시도하세요.',
			'discover.findNext.savedLimit' => '저장한 추천 목록이 가득 찼습니다. 다른 추천을 저장하려면 하나를 삭제하세요.',
			'discover.findNext.chooseHint' => '작품을 열거나, 나중을 위해 저장하거나, 건너뛰세요.',
			'discover.findNext.howItWorks' => '사용 방법',
			'discover.findNext.notNowHelp' => '이 작품을 지금은 건너뜁니다. 라이브러리에는 그대로 남습니다.',
			'discover.findNext.saveHelp' => '이 기기의 현재 프로필에 저장된 추천으로 보관합니다. 저장해도 다운로드되지는 않습니다.',
			'discover.findNext.openHelp' => '표지를 선택하면 상세 정보를 볼 수 있습니다. 기본 버튼으로 재생하거나 읽거나 작품을 여세요.',
			'discover.findNext.controlsHelp' => '키보드나 리모컨: 버튼에 초점을 맞추고 Enter 또는 선택을 누르세요. 실행 취소는 마지막 선택을 되돌립니다.',
			'discover.findNext.artworkLoading' => '이미지 불러오는 중…',
			'discover.findNext.artworkUnavailable' => '이미지를 표시할 수 없음',
			'discover.findNext.savedFeedback' => '저장된 추천에 추가됨',
			'discover.findNext.skippedFeedback' => '지금은 건너뜀',
			'discover.findNext.releaseToConfirm' => '놓아서 확인',
			'discover.findNext.remoteHint' => '표지에 초점: ← / → 선택 · 선택 버튼: 상세 정보 · ↑ / ↓ 초점 이동',
			'discover.extras' => '예고편 및 부가영상',
			'discover.studio' => '제작사',
			'discover.rating' => '연령 등급',
			'discover.director' => '감독',
			'discover.directors' => '감독',
			'discover.movie' => '영화',
			'discover.tvShow' => 'TV 시리즈',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes}분 남음',
			'discover.moreLikeThis' => '비슷한 콘텐츠',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 제목', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 타이틀', ), 
			'discover.person.born' => '출생',
			'discover.person.died' => '사망',
			'discover.person.birthplace' => '출생지',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age}세)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (향년 ${age}세)',
			'errors.searchFailed' => ({required Object error}) => '검색 실패: ${error}',
			'errors.searchUnavailable' => '검색이 어떤 미디어 서버에도 연결할 수 없습니다.',
			'errors.connectionTimeout' => ({required Object context}) => '${context} 로드 중 연결 시간 초과',
			'errors.connectionFailed' => '미디어 서버에 연결할 수 없습니다',
			'errors.unableToLoad' => ({required Object context}) => '${context}을(를) 불러올 수 없습니다. 다시 시도하세요.',
			'errors.noClientAvailable' => '사용 가능한 클라이언트가 없습니다',
			'errors.pleaseEnterToken' => '토큰을 입력해 주세요',
			'errors.invalidToken' => '토큰이 유효하지 않습니다',
			'errors.failedToVerifyToken' => ({required Object error}) => '토큰을 확인할 수 없습니다: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName}으로 전환할 수 없습니다',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName}을(를) 삭제할 수 없습니다',
			'errors.failedToRate' => '평점을 업데이트하지 못했습니다',
			'errors.reasonTimedOut' => '연결 시간이 초과되었습니다',
			'errors.reasonUnreachable' => '서버에 연결할 수 없습니다',
			'errors.reasonRefused' => '서버가 요청을 거부했습니다',
			'errors.reasonNotFound' => '항목이 더 이상 서버에 없습니다',
			'errors.reasonServerError' => '서버에서 오류가 보고되었습니다',
			'errors.reasonCancelled' => '요청이 취소되었습니다',
			'errors.reasonUnexpected' => '예기치 않은 오류가 발생했습니다',
			'libraries.playRandomMovie' => '우연한 영화를 재생합니다.',
			'libraries.randomPickFailed' => '이 도서관에서 우연한 영화를 선택할 수 없습니다.',
			'libraries.title' => '미디어 라이브러리',
			'libraries.fallbackTitle' => '라이브러리',
			'libraries.scanLibraryFiles' => '미디어 라이브러리 파일 스캔',
			'libraries.scanLibrary' => '미디어 라이브러리 스캔',
			'libraries.analyze' => '분석',
			'libraries.analyzeLibrary' => '미디어 라이브러리 분석',
			'libraries.refreshMetadata' => '메타데이터 새로 고침',
			'libraries.emptyTrash' => '휴지통 비우기',
			'libraries.emptyingTrash' => ({required Object title}) => '「${title}」의 휴지통을 비우고 있습니다...',
			'libraries.trashEmptied' => ({required Object title}) => '「${title}」의 휴지통을 비웠습니다',
			'libraries.failedToEmptyTrash' => ({required Object error}) => '휴지통 비우기 실패: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" 분석 중...',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" 분석 시작됨',
			'libraries.failedToAnalyze' => ({required Object error}) => '미디어 라이브러리 분석 실패: ${error}',
			'libraries.noLibrariesFound' => '미디어 라이브러리 없음',
			'libraries.allLibrariesHidden' => '모든 라이브러리가 숨겨졌습니다',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => '숨겨진 라이브러리 (${count})',
			'libraries.thisLibraryIsEmpty' => '이 미디어 라이브러리는 비어 있습니다',
			'libraries.noItemsMatchFilters' => '활성화된 필터와 일치하는 항목이 없습니다',
			'libraries.resetFilters' => '필터 초기화',
			'libraries.all' => '전체',
			'libraries.clearAll' => '모두 삭제',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '「${title}」을(를) 스캔하시겠습니까?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '「${title}」을(를) 분석하시겠습니까?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '「${title}」의 메타데이터를 새로고침하시겠습니까?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '${title}의 휴지통을 비우시겠습니까?',
			'libraries.manageLibraries' => '미디어 라이브러리 관리',
			'libraries.sort' => '정렬',
			'libraries.sortBy' => '정렬 기준',
			'libraries.filters' => '필터',
			'libraries.confirmActionMessage' => '이 작업을 실행하시겠습니까?',
			'libraries.showLibrary' => '미디어 라이브러리 표시',
			'libraries.hideLibrary' => '미디어 라이브러리 숨기기',
			'libraries.libraryOptions' => '미디어 라이브러리 옵션',
			'libraries.content' => '미디어 라이브러리 콘텐츠',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => '미디어 라이브러리 선택',
			'libraries.filtersWithCount' => ({required Object count}) => '필터 (${count})',
			'libraries.noRecommendations' => '추천 없음',
			'libraries.noCollections' => '이 미디어 라이브러리에는 컬렉션이 없습니다',
			'libraries.noFoldersFound' => '폴더를 찾을 수 없습니다',
			'libraries.folders' => '폴더',
			'libraries.tabs.recommended' => '추천',
			'libraries.tabs.browse' => '찾아보기',
			'libraries.tabs.collections' => '컬렉션',
			'libraries.tabs.playlists' => '재생 목록',
			'libraries.groupings.title' => '그룹',
			'libraries.groupings.all' => '전체',
			'libraries.groupings.movies' => '영화',
			'libraries.groupings.shows' => 'TV 프로그램',
			'libraries.groupings.seasons' => '시즌',
			'libraries.groupings.episodes' => '화',
			'libraries.groupings.artists' => '아티스트',
			'libraries.groupings.albums' => '앨범',
			'libraries.groupings.tracks' => '트랙',
			'libraries.groupings.folders' => '폴더',
			'libraries.filterCategories.genre' => '장르',
			'libraries.filterCategories.year' => '연도',
			'libraries.filterCategories.contentRating' => '시청 등급',
			'libraries.filterCategories.tag' => '태그',
			'libraries.filterCategories.unwatched' => '미시청',
			'libraries.filterCategories.unplayed' => '재생하지 않음',
			'libraries.filterCategories.favorites' => '즐겨찾기',
			'libraries.filterCategories.filePath' => '파일 경로',
			'libraries.sortLabels.title' => '제목',
			'libraries.sortLabels.dateAdded' => '추가된 날짜',
			'libraries.sortLabels.releaseDate' => '출시일',
			'libraries.sortLabels.rating' => '평점',
			'libraries.sortLabels.communityRating' => '커뮤니티 평점',
			'libraries.sortLabels.criticRating' => '평론가 평점',
			'libraries.sortLabels.userRating' => '사용자 평점',
			'libraries.sortLabels.datePlayed' => '재생일',
			'libraries.sortLabels.playCount' => '재생 횟수',
			'libraries.sortLabels.productionYear' => '제작 연도',
			'libraries.sortLabels.runtime' => '재생 시간',
			'libraries.sortLabels.officialRating' => '공식 등급',
			'libraries.sortLabels.premiereDate' => '최초 공개일',
			'libraries.sortLabels.startDate' => '시작일',
			'libraries.sortLabels.airTime' => '방영 시간',
			'libraries.sortLabels.studio' => '스튜디오',
			'libraries.sortLabels.random' => '무작위',
			'libraries.sortLabels.dateShared' => '공유된 날짜',
			'libraries.sortLabels.latestEpisodeAirDate' => '최신 에피소드 방영일',
			'libraries.sortLabels.lastEpisodeDateAdded' => '최신 에피소드 추가일',
			'libraries.sortLabels.dateDownloaded' => '다운로드된 날짜',
			'libraries.sortLabels.size' => '크기',
			'libraries.sortLabels.library' => '라이브러리',
			'libraries.advancedFilters.include' => '포함',
			'libraries.advancedFilters.exclude' => '제외',
			'libraries.advancedFilters.any' => '전체',
			'libraries.advancedFilters.yes' => '예',
			'libraries.advancedFilters.no' => '아니오',
			'libraries.advancedFilters.not' => ({required Object value}) => '${value} 제외',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count}개 선택됨',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count}개 제외됨',
			'libraries.advancedFilters.searchValues' => '값 검색',
			'libraries.advancedFilters.noValues' => '값 없음',
			'libraries.advancedFilters.matchContains' => '포함',
			'libraries.advancedFilters.matchNotContains' => '포함하지 않음',
			'libraries.advancedFilters.matchIs' => '같음',
			'libraries.advancedFilters.matchIsNot' => '같지 않음',
			'libraries.advancedFilters.matchBeginsWith' => '시작 문자',
			'libraries.advancedFilters.matchEndsWith' => '끝 문자',
			'libraries.advancedFilters.textHint' => '일치시킬 텍스트 입력',
			'libraries.advancedFilters.from' => '시작',
			'libraries.advancedFilters.to' => '끝',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from}~${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} 이상',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value} 이하',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '최근 ${count}일',
			'libraries.advancedFilters.dateLastYear' => '최근 1년',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '${count}일 이상 지남',
			'libraries.advancedFilters.dateOlderThanYear' => '1년 이상 지남',
			'libraries.selection.selectItems' => '선택 항목',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count}개 선택됨',
			'libraries.selection.actions' => '선택 행동',
			'libraries.selection.confirmDescendants' => '이것은 선택한 쇼와 시즌의 모든 에피소드를 변경합니다.',
			'libraries.selection.confirmUnwatched' => '선택한 항목의 재생 진행 상황도 초기화됩니다.',
			'libraries.selection.confirmCount' => ({required Object count}) => '선택된 항목: ${count}',
			'libraries.selection.completed' => ({required Object count}) => '업데이트된 항목: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => '업데이트 ${succeeded}; 실패 ${failed}. 실패 항목은 여전히 선택됩니다.',
			'about.title' => '소개',
			'about.openSourceLicenses' => '오픈소스 라이선스',
			'about.versionLabel' => ({required Object version}) => '버전 ${version}',
			'about.appDescription' => 'Flutter로 만든 아름다운 Plex, Jellyfin 및 Emby 클라이언트',
			'about.viewLicensesDescription' => '타사 라이브러리 라이선스 보기',
			'about.privacyPolicy' => '개인정보 처리방침',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email})의 서버를 찾을 수 없습니다.',
			'serverSelection.failedToLoadServers' => ({required Object error}) => '서버를 로드할 수 없습니다: ${error}',
			'serverSelection.noValidServers' => '이 계정에서 사용할 수 있는 서버를 찾지 못했습니다',
			'hubDetail.title' => '제목',
			'hubDetail.releaseYear' => '출시 연도',
			'hubDetail.dateAdded' => '추가 날짜',
			'hubDetail.rating' => '평점',
			'hubDetail.noItemsFound' => '항목이 없습니다',
			'logs.clearLogs' => '로그 지우기',
			'logs.copyLogs' => '로그 복사',
			'logs.uploadLogs' => '로그 업로드',
			'logs.saveLogs' => '파일에 로그를 저장',
			'logs.logsSaved' => ({required Object path}) => '기록을 저장할 수 있습니다 ${path}',
			'logs.saveLogsFailed' => '로그 파일을 저장할 수 없었습니다.',
			'startup.failedTitle' => 'Plezy를 시작하지 못했습니다',
			'startup.failedBody' => '시작 중 문제가 발생했습니다. 아래 세부 정보에서 실패 원인을 확인할 수 있습니다.',
			'startup.failedBodyRepairable' => 'Plezy의 저장된 설정 파일이 손상되어 Plezy를 시작하려면 먼저 파일을 다시 만들어야 합니다. 재시도해도 해결되지 않습니다 — 저장소 복구를 선택하세요.',
			'startup.phaseLabel' => '단계',
			'startup.showDetails' => '세부 정보 표시',
			'startup.hideDetails' => '세부 정보 숨기기',
			'startup.copyDetails' => '세부 정보 복사',
			'startup.detailsCopied' => '세부 정보가 클립보드에 복사되었습니다',
			'startup.uploadDetails' => '세부 정보 업로드',
			'startup.repairStorage' => '저장소 복구',
			'startup.repairTitle' => '저장된 데이터를 복구할까요?',
			'startup.repairBodyCommon' => 'Plezy의 설정 파일이 손상되어 읽을 수 없습니다. 복구하면 모든 설정이 기본값으로 재설정됩니다.',
			'startup.repairBodyOneCredential' => '저장된 로그인 정보 하나가 손상되어 읽을 수 없습니다. 복구하면 해당 로그인 정보만 제거되며 다른 설정은 그대로 유지됩니다.',
			'startup.repairBodySignInsKept' => '서버와 프로필은 로그인 상태가 유지됩니다.',
			'startup.repairBodySignInsLost' => '저장된 로그인 정보를 보호하는 키를 이 파일에서 복구할 수 없어 모든 서버와 프로필에 다시 로그인해야 합니다. 미디어 서버의 데이터에는 영향이 없습니다.',
			'startup.repairBodySessionsUncertain' => '트래커(MAL, AniList, Simkl, Trakt)와 Seerr는 별도로 저장되며 유지 여부가 확실하지 않습니다. Plezy가 유지된 항목을 정확히 알려줄 것입니다.',
			'startup.repairConfirm' => '복구',
			'startup.repairSucceeded' => '저장소가 복구되었습니다',
			'startup.repairNeedsRestart' => '저장소가 복구되었습니다 — 재시작 필요',
			'startup.restartRequiredBody' => '데이터가 복구되었지만 Plezy는 이를 사용하려면 새로 시작해야 합니다. Plezy를 종료한 후 다시 열어주세요.',
			'startup.quitPlezy' => 'PlezyNG 종료',
			'startup.repairFailed' => '복구 실패',
			'startup.repairKeptSignIns' => '서버와 프로필이 계속 로그인 상태입니다.',
			'startup.repairLostSignIns' => '저장된 로그인 정보를 보호하는 키를 복구할 수 없었습니다. 모든 서버와 프로필에 다시 로그인해야 합니다.',
			'startup.repairLostSessions' => '트래커 또는 Seerr 연결이 하나 이상 끊어져 다시 연결해야 합니다.',
			'startup.backupTitle' => '손상된 파일의 복사본이 보관되었습니다',
			'startup.backupWarning' => '로그인 자격 증명이 포함되어 있습니다. 업로드하거나 공유하지 마세요.',
			'startup.deleteBackup' => '복사본 삭제',
			'startup.backupDeleted' => '복사본이 삭제되었습니다.',
			'startup.previousFailureTitle' => '지난번에 Plezy를 시작하지 못했습니다',
			'licenses.relatedPackages' => '관련 소프트웨어 패키지',
			'licenses.license' => '라이선스',
			'licenses.licenseNumber' => ({required Object number}) => '라이선스 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count}개의 라이선스',
			'navigation.libraries' => '미디어 라이브러리',
			'navigation.downloads' => '다운로드',
			'navigation.liveTv' => '실시간 TV',
			'navigation.explore' => '탐색',
			'explore.mdblistShelves.manage' => '관리 탐험 층',
			'explore.mdblistShelves.manageDescription' => 'MDBList 계정에서 목록을 선택하고 배열하십시오.',
			'explore.mdblistShelves.description' => 'MDBList 계정에서 공개 영화 및 TV 목록을 선택하십시오. MDBList에 목록을 만들거나 복사하고 업데이트하십시오.',
			'explore.mdblistShelves.selected' => '선택된 좌석',
			'explore.mdblistShelves.available' => '사용 가능한 계좌 목록',
			'explore.mdblistShelves.noLists' => '공개 영화 또는 TV 목록이 반환되지 않습니다. MDBList에 목록을 만들거나 복사한 다음 새롭게 해주십시오.',
			'explore.mdblistShelves.displayName' => '셰일프 디스플레이 이름',
			'explore.mdblistShelves.nameHint' => '출처 목록 이름을 사용하기 위해 빈을 남겨 두십시오.',
			'explore.mdblistShelves.add' => '셰일프 추가',
			'explore.mdblistShelves.save' => '좌석을 구하라',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '이동 ${title} 위로',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '이동 ${title} 아래로',
			'explore.mdblistShelves.unavailable' => '이 목록은 사용할 수 없습니다. 설정에서 셰일을 제거하거나 제거합니다.',
			'explore.mdblistShelves.rateLimited' => 'MDBList 요청 제한이 달성되었습니다. 나중에 철회하시기 바랍니다.',
			'explore.mdblistShelves.loadFailed' => '선반을 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.',
			'explore.mdblistShelves.saveFailed' => '선반을 저장할 수 없습니다. 다시 시도하세요.',
			'explore.mdblistShelves.accountChanged' => '계정 또는 프로필이 변경되었습니다.이 설정을 다시 열어보세요.',
			'explore.mdblistShelves.settingsUnreadable' => '저장된 탭은 읽을 수 없습니다.이 설정을 대체하기 위해 목록을 다시 선택합니다.',
			'explore.title' => '탐색',
			'explore.selectSource' => '소스 선택',
			'explore.rows.watchlist' => '관심 목록',
			'explore.rows.recommendedMovies' => '추천 영화',
			'explore.rows.recommendedShows' => '추천 TV 프로그램',
			'explore.rows.trendingMovies' => '지금 뜨는 영화',
			'explore.rows.trendingShows' => '지금 뜨는 TV 프로그램',
			'explore.rows.popularMovies' => '인기 영화',
			'explore.rows.popularShows' => '인기 TV 프로그램',
			'explore.rows.trendingAnime' => '지금 뜨는 애니메이션',
			'explore.rows.suggestedAnime' => '추천 애니메이션',
			'explore.rows.airingAnime' => '방영 중인 인기 애니메이션',
			'explore.rows.popularAnime' => '가장 인기 있는 애니메이션',
			'explore.rows.trending' => '지금 뜨는 콘텐츠',
			'explore.rows.upcomingMovies' => '개봉 예정 영화',
			'explore.rows.upcomingShows' => '방영 예정 TV 프로그램',
			'explore.status.airing' => '방영 중',
			'explore.status.ended' => '종영',
			'explore.status.canceled' => '취소됨',
			'explore.status.upcoming' => '방영 예정',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 에피소드', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}화', ), 
			'explore.cast' => '출연진',
			'explore.characters' => '캐릭터',
			'explore.addToWatchlist' => '관심 목록에 추가',
			'explore.removeFromWatchlist' => '관심 목록에서 제거',
			'explore.addedToWatchlist' => '관심 목록에 추가했습니다',
			'explore.removedFromWatchlist' => '관심 목록에서 삭제했습니다',
			'explore.watchlistUpdateFailed' => '관심 목록을 업데이트하지 못했습니다',
			'explore.watchlistNoMatch' => '이 항목을 관심 목록과 연결할 수 없습니다',
			'explore.notInLibrary' => '라이브러리에 없음',
			'explore.inTheseLibraries' => '이 라이브러리에 있음',
			'explore.checkingLibrary' => '라이브러리 확인 중...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 서버를 확인할 수 없음', other: '서버 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개를 확인할 수 없습니다', ), 
			'explore.emptyTitle' => '아직 아무것도 없습니다',
			'explore.emptyMessage' => ({required Object source}) => '${source}에 콘텐츠가 추가되면 여기에 표시됩니다.',
			'explore.searchHint' => ({required Object source}) => '${source}에서 검색',
			'explore.searchEmpty' => ({required Object query}) => '「${query}」에 대한 결과가 없습니다',
			'explore.searchPrompt' => ({required Object source}) => '${source}에서 영화와 TV 프로그램을 검색하세요.',
			'explore.searchFailed' => '검색에 실패했습니다. 연결을 확인하고 다시 시도하세요.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} 인기',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} 방영 중',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} 평가',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} 트렌드',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n}명 시청 중',
			'explore.badge.available' => '이용 가능',
			'explore.badge.partiallyAvailable' => '부분 이용 가능',
			'explore.badge.availableIn4k' => '4K 이용 가능',
			'explore.badge.requested' => '요청됨',
			'explore.badge.pendingApproval' => '승인 대기 중',
			'explore.badge.processing' => '처리 중',
			'explore.badge.declined' => '거절됨',
			'explore.badge.requestFailed' => '요청 실패',
			'explore.badge.requested4k' => '4K 요청됨',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '시즌 ${available}/${total}',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => '${episode}화 · ${duration} 후',
			'explore.badge.nextAiringIn' => ({required Object duration}) => '${duration} 후 다음 화',
			'explore.badge.episodesShort' => ({required Object n}) => '${n}화',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n}분/화',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n}명 등록',
			'explore.stats.viewersDay' => ({required Object n}) => '오늘 ${n}명 시청',
			'explore.stats.viewersWeek' => ({required Object n}) => '이번 주 ${n}명 시청',
			'explore.stats.viewersMonth' => ({required Object n}) => '이번 달 ${n}명 시청',
			'explore.stats.viewersYear' => ({required Object n}) => '올해 ${n}명 시청',
			'explore.stats.viewersAllTime' => ({required Object n}) => '시청자 ${n}명',
			'explore.stats.planning' => ({required Object n}) => '${n}명 볼 예정',
			'explore.stats.favorited' => ({required Object n}) => '즐겨찾기 ${n}명',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} 하차',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 댓글', other: '댓글 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개', ), 
			'explore.stats.votes' => ({required Object n}) => '투표 ${n}개',
			'explore.stats.watching' => ({required Object n}) => '시청 중 ${n}명',
			'explore.stats.completed' => ({required Object n}) => '완료 ${n}명',
			'explore.stats.onHold' => ({required Object n}) => '보류 ${n}명',
			'explore.stats.dropped' => ({required Object n}) => '하차 ${n}명',
			'explore.season.winter' => '겨울',
			'explore.season.spring' => '봄',
			'explore.season.summer' => '여름',
			'explore.season.fall' => '가을',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}년',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV 단편',
			'explore.format.movie' => '영화',
			'explore.format.special' => '스페셜',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => '음악',
			'explore.format.other' => '기타',
			'explore.sourceMaterial.original' => '오리지널',
			'explore.sourceMaterial.manga' => '만화',
			'explore.sourceMaterial.lightNovel' => '라이트 노벨',
			'explore.sourceMaterial.novel' => '소설',
			'explore.sourceMaterial.visualNovel' => '비주얼 노벨',
			'explore.sourceMaterial.game' => '게임',
			'explore.sourceMaterial.webComic' => '웹툰',
			'explore.sourceMaterial.musicRelease' => '음악',
			'explore.sourceMaterial.otherMedia' => '기타',
			'explore.creditRole.actor' => '배우',
			'explore.creditRole.director' => '감독',
			'explore.creditRole.writer' => '각본',
			'explore.creditRole.producer' => '프로듀서',
			'explore.creditRole.creator' => '제작자',
			'explore.creditRole.composer' => '작곡',
			'explore.relation.prequel' => '프리퀄',
			'explore.relation.sequel' => '시퀄',
			'explore.relation.sideStory' => '사이드 스토리',
			'explore.relation.spinOff' => '스핀오프',
			'explore.relation.alternativeVersion' => '대체 버전',
			'explore.relation.summary' => '요약',
			'explore.relation.parentStory' => '원작',
			'explore.relation.adaptation' => '각색',
			'explore.relation.other' => '관련',
			'explore.broadcast' => ({required Object day, required Object time}) => '${day} ${time} 방영',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '${day} ${time} ${timezone} 방영',
			'explore.detail.originalTitle' => '원제',
			'explore.detail.alsoKnownAs' => '다른 이름',
			'explore.detail.studios' => '스튜디오',
			'explore.detail.country' => '국가',
			'explore.detail.language' => '언어',
			'explore.detail.released' => '출시일',
			'explore.detail.physicalRelease' => '디스크 출시',
			'explore.detail.ended' => '종영',
			'explore.detail.addedOn' => ({required Object date}) => '${date}에 추가됨',
			'explore.detail.yourRating' => '내 평점',
			'explore.detail.budget' => '제작비',
			'explore.detail.revenue' => '흥행 수익',
			'explore.detail.contentAdvisory' => '연령 등급',
			'explore.detail.tags' => '태그',
			'explore.detail.revealSpoilerTags' => '스포일러 태그 표시',
			'explore.detail.links' => '링크',
			'explore.detail.watchOn' => '시청처',
			'explore.detail.watchTrailer' => '예고편 보기',
			'explore.detail.openOn' => ({required Object site}) => '${site}에서 열기',
			'explore.detail.crew' => '제작진',
			'explore.detail.ratings' => '평점',
			'explore.detail.schedule' => '방영 일정',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '사용자에 의해 권장 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: '사용자 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}명이 추천', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} 추천',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who} 즐겨찾기',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '미방영 ${n}개',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '시청자의 ${percent} 추천',
			'explore.detail.relatedTitles' => '관련 작품',
			'explore.detail.background' => '배경',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 결과', other: '결과 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개', ), 
			'liveTv.title' => '실시간 TV',
			'liveTv.guide' => '편성표',
			'liveTv.noChannels' => '사용 가능한 채널이 없습니다',
			'liveTv.noDvr' => '서버에 DVR이 구성되어 있지 않습니다',
			'liveTv.serverUnavailable' => '라이브 TV 서버를 사용할 수 없습니다.',
			'liveTv.serverNotConnected' => '라이브 TV 서버에 연결되어 있지 않습니다.',
			'liveTv.noPrograms' => '프로그램 데이터가 없습니다',
			'liveTv.liveStreamFailed' => '라이브 스트림 실패',
			'liveTv.unknownProgram' => '알 수 없는 프로그램',
			'liveTv.timelineLiveProgram' => '라이브 프로그램 (플레이백은 이 프로그램 이외의 프로그램이 될 수 있습니다)',
			'liveTv.timelineBuffer' => '버퍼 타임 라인',
			'liveTv.timelineUnavailable' => '시간표가 불가능',
			'liveTv.timelineEstimated' => '값진 플레이백',
			'liveTv.timelinePending' => '재생 위치 이동 대기 중',
			'liveTv.timelineStale' => '일정은 과장될 수 있습니다.',
			'liveTv.unknownHub' => '알 수 없음',
			'liveTv.unknownError' => '알 수 없는 오류',
			'liveTv.channelNumber' => ({required Object number}) => '채널 ${number}',
			'liveTv.unknownChannel' => '알 수 없는 채널',
			'liveTv.live' => '실시간',
			'liveTv.premiereBadge' => '새로운',
			'liveTv.reloadGuide' => '편성표 새로고침',
			'liveTv.searchGuide' => '편성표 검색',
			'liveTv.searchHint' => '채널 및 프로그램 검색',
			'liveTv.searchNoResults' => ({required Object query}) => '「${query}」와(과) 일치하는 항목이 없습니다',
			'liveTv.channelsSection' => '채널',
			'liveTv.programsSection' => '프로그램',
			'liveTv.now' => '지금',
			'liveTv.today' => '오늘',
			'liveTv.tomorrow' => '내일',
			'liveTv.midnight' => '자정',
			'liveTv.overnight' => '심야',
			'liveTv.morning' => '아침',
			'liveTv.daytime' => '낮',
			'liveTv.evening' => '저녁',
			'liveTv.lateNight' => '심야 방송',
			'liveTv.whatsOn' => '지금 방송 중',
			'liveTv.watchChannel' => '채널 시청',
			'liveTv.favorites' => '즐겨찾기',
			'liveTv.reorderFavorites' => '즐겨찾기 순서 변경',
			'liveTv.noFavoriteChannels' => '즐겨찾기 채널 없음',
			'liveTv.noFavoriteChannelsHint' => '모든 채널을 표시한 다음 채널을 길게 눌러 즐겨찾기에 추가하세요.',
			'liveTv.showAllChannels' => '모든 채널 표시',
			'liveTv.favoritesLoadFailed' => '즐겨찾기를 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.',
			'liveTv.favoritesUpdateFailed' => '즐겨찾기를 업데이트할 수 없습니다. 연결을 확인하고 다시 시도하세요.',
			'liveTv.joinSession' => '진행 중인 세션 참여',
			'liveTv.watchFromStart' => ({required Object minutes}) => '처음부터 시청 (${minutes}분 전 시작)',
			'liveTv.watchLive' => '실시간 시청',
			'liveTv.goToLive' => '실시간으로 이동',
			'liveTv.record' => '녹화',
			'liveTv.recordEpisode' => '에피소드 녹화',
			'liveTv.recordSeries' => '시리즈 녹화',
			'liveTv.recordOptions' => '녹화 옵션',
			'liveTv.saveTo' => '저장 위치',
			'liveTv.recordings' => '녹화',
			'liveTv.scheduledRecordings' => '예약됨',
			'liveTv.recordingRules' => '녹화 규칙',
			'liveTv.noScheduledRecordings' => '예약된 녹화 없음',
			'liveTv.manageRecording' => '녹화 관리',
			'liveTv.cancelRecording' => '녹화 취소',
			'liveTv.cancelRecordingTitle' => '이 녹화를 취소할까요?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title}이(가) 더 이상 녹화되지 않습니다.',
			'liveTv.deleteRule' => '규칙 삭제',
			'liveTv.deleteRuleTitle' => '녹화 규칙을 삭제할까요?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title}의 향후 에피소드는 녹화되지 않습니다.',
			'liveTv.recordingScheduled' => '녹화 예약됨',
			'liveTv.alreadyScheduled' => '이 프로그램은 이미 예약되어 있습니다',
			'liveTv.dvrAdminRequired' => 'DVR 설정은 관리자 계정이 필요합니다',
			'liveTv.recordingFailed' => '녹화를 예약할 수 없습니다',
			'liveTv.recordingTargetMissing' => '녹화 라이브러리를 확인할 수 없습니다',
			'liveTv.recordNotAvailable' => '이 프로그램은 녹화할 수 없습니다',
			'liveTv.recordingCancelled' => '녹화 취소됨',
			'liveTv.recordingRuleDeleted' => '녹화 규칙 삭제됨',
			'liveTv.processRecordingRules' => '규칙 재평가',
			'liveTv.recordingInProgress' => '녹화 중',
			'liveTv.recordingsCount' => ({required Object count}) => '${count}개 예약됨',
			'liveTv.editRule' => '규칙 편집',
			'liveTv.editRuleAction' => '편집',
			'liveTv.recordingRuleUpdated' => '녹화 규칙 업데이트됨',
			'liveTv.guideReloadRequested' => '가이드 새로고침 요청됨',
			'liveTv.guideReloadFailed' => '편성표를 새로고침할 수 없습니다',
			'liveTv.rulesProcessRequested' => '규칙 재평가 요청됨',
			'liveTv.rulesProcessFailed' => '녹화 규칙을 다시 적용할 수 없습니다',
			'liveTv.recordShow' => '프로그램 녹화',
			'liveTv.recordSettings.startEarly' => '일찍 시작 (초)',
			'liveTv.recordSettings.endLate' => '늦게 종료 (초)',
			'liveTv.recordSettings.newOnly' => '새 에피소드만',
			'liveTv.recordSettings.anyChannel' => '모든 채널에서 녹화',
			'liveTv.recordSettings.anyTime' => '모든 시간대에 녹화',
			'liveTv.recordSettings.skipInLibrary' => '라이브러리에 이미 있는 에피소드 건너뛰기',
			'liveTv.recordSettings.keepUpTo' => '보관할 에피소드 수',
			'liveTv.recordSettings.keepUpToHint' => '0이면 모든 에피소드 보관',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes}분 후 시작',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product}에서 잘못된 실시간 TV 재생 데이터를 반환했습니다',
			'liveTv.failedToStartChannel' => '실시간 채널을 시작할 수 없습니다',
			'liveTv.failedToBuildStreamUrl' => '스트림 URL을 생성할 수 없습니다',
			'liveTv.playbackStartFailed' => ({required Object reason}) => '채널을 시작하지 못했습니다: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => '채널을 전환하지 못했습니다: ${reason}',
			'collections.title' => '컬렉션',
			'collections.collection' => '컬렉션',
			'collections.empty' => '컬렉션이 비어 있습니다',
			'collections.deleteCollection' => '컬렉션 삭제',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}"을(를) 삭제할까요? 되돌릴 수 없습니다.',
			'collections.deleted' => '컬렉션 삭제됨',
			'collections.deleteFailed' => '컬렉션 삭제 실패',
			'collections.deleteFailedWithError' => ({required Object error}) => '컬렉션 삭제 실패: ${error}',
			'collections.selectCollection' => '컬렉션 선택',
			'collections.collectionName' => '컬렉션 이름',
			'collections.enterCollectionName' => '컬렉션 이름 입력',
			'collections.addedToCollection' => '컬렉션에 추가됨',
			'collections.errorAddingToCollection' => '컬렉션에 추가 실패',
			'collections.created' => '컬렉션 생성됨',
			'collections.removeFromCollection' => '컬렉션에서 제거',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '${title}을(를) 이 컬렉션에서 제거하시겠습니까?',
			'collections.removedFromCollection' => '컬렉션에서 제거됨',
			'collections.removeFromCollectionFailed' => '컬렉션에서 제거 실패',
			'collections.removeFromCollectionError' => ({required Object error}) => '컬렉션에서 제거 중 오류 발생: ${error}',
			'collections.searchCollections' => '컬렉션 검색...',
			'playlists.title' => '플레이리스트',
			'playlists.playlist' => '재생 목록',
			'playlists.noPlaylists' => '재생 목록을 찾을 수 없습니다',
			'playlists.create' => '재생 목록 생성',
			'playlists.playlistName' => '재생 목록 이름',
			'playlists.enterPlaylistName' => '재생 목록 이름 입력',
			'playlists.delete' => '재생 목록 삭제',
			'playlists.removeItem' => '재생 목록에서 항목 제거',
			'playlists.smartPlaylist' => '스마트 재생 목록',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}개 항목', ), 
			'playlists.emptyPlaylist' => '이 재생 목록은 비어 있습니다',
			'playlists.deleteConfirm' => '재생 목록을 삭제하시겠습니까?',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}"을(를) 삭제하시겠습니까?',
			'playlists.created' => '재생 목록이 생성되었습니다',
			'playlists.deleted' => '재생 목록이 삭제되었습니다',
			'playlists.itemAdded' => '재생 목록에 추가되었습니다',
			'playlists.itemRemoved' => '재생 목록에서 제거됨',
			'playlists.selectPlaylist' => '재생 목록 선택',
			'playlists.searchPlaylists' => '재생 목록 검색...',
			'playlists.errorCreating' => '재생 목록 생성 실패',
			'playlists.errorDeleting' => '재생 목록 삭제 실패',
			'playlists.errorLoading' => '재생 목록 로드 실패',
			'playlists.errorAdding' => '재생 목록에 추가 실패',
			'playlists.errorReordering' => '재생 목록 항목 재정렬 실패',
			'playlists.errorRemoving' => '재생 목록에서 제거 실패',
			'music.goToAlbum' => '앨범으로 이동',
			'music.goToArtist' => '아티스트로 이동',
			'music.instantMix' => '인스턴트 믹스',
			'music.playNext' => '다음에 재생',
			'music.addToQueue' => '대기열에 추가',
			'music.discNumber' => ({required Object n}) => '디스크 ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 트랙', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}곡', ), 
			'music.nowPlaying' => '재생 중',
			'music.playingFrom' => ({required Object title}) => '${title}에서 재생 중',
			'music.queue' => '재생 대기열',
			'music.clearQueue' => '대기열 비우기',
			'music.lyrics' => '가사',
			'music.visualizer' => '시각화',
			'music.visualizerProfileLoading' => '트랙 분석을 읽고...',
			'music.visualizerAmbientMotion' => '환경 운동',
			'music.visualizerPlexLoudness' => 'Plex 소음',
			'music.visualizerPreviousPreset' => '이전 시각적 스타일',
			'music.visualizerNextPreset' => '다음 시각적 스타일',
			'music.visualizerPresetAurora' => '오로라',
			'music.visualizerPresetBloom' => '블루',
			'music.visualizerPresetOrbitals' => '궤도',
			'music.visualizerPresetPrism' => '프리스마스',
			'music.visualizerPresetTunnel' => '터널',
			'music.visualizerPresetTrackMap' => '트랙지도',
			'music.noLyrics' => '가사 없음',
			'music.sleepTimer' => '취침 타이머',
			'music.sleepTimerEndOfTrack' => '곡 종료 시',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}분', ), 
			'music.stopPlayback' => '재생 중지',
			'music.previousTrack' => '이전 곡',
			'music.nextTrack' => '다음 곡',
			'music.repeat' => '반복',
			'music.repeatAll' => '전체 반복',
			'music.repeatOne' => '한 곡 반복',
			'music.instantMixNoServer' => '즉석 믹스에 사용할 수 있는 서버가 없습니다',
			'music.instantMixFailed' => '인스턴트 믹스를 불러오지 못했습니다',
			'music.instantMixEmpty' => '인스턴트 믹스에 트랙이 없습니다',
			'music.noAudioUrl' => ({required Object track}) => '${track}에 사용할 수 있는 오디오 URL이 없습니다',
			'music.discography.singlesAndEps' => '싱글 및 EP',
			'music.discography.live' => '라이브',
			'music.discography.compilations' => '컴필레이션',
			'watchTogether.title' => '함께 보기',
			'watchTogether.description' => '친구 및 가족과 콘텐츠를 동시에 시청하세요',
			'watchTogether.createRoom' => '방 만들기',
			'watchTogether.creatingRoom' => '방 만드는 중...',
			'watchTogether.joinRoom' => '방 참여',
			'watchTogether.joiningRoom' => '방에 참여하는 중...',
			'watchTogether.connecting' => '연결 중...',
			'watchTogether.relayPublic' => '방은 공개 Open Watch Party 릴레이를 사용합니다.',
			'watchTogether.relayCustom' => ({required Object url}) => '방은 ${url}에 있는 내 릴레이를 사용합니다.',
			'watchTogether.recentRooms' => '최근 참여한 방',
			'watchTogether.roomActions' => '방 작업',
			'watchTogether.renameRoom' => '방 이름 변경',
			'watchTogether.removeRoom' => '제거',
			'watchTogether.enterRoomCode' => '호스트에게 받은 6자리 코드를 입력하세요.',
			'watchTogether.roomCode' => '방 코드',
			'watchTogether.paste' => '붙여넣기',
			'watchTogether.noCodeInClipboard' => '클립보드에 방 코드가 없습니다',
			'watchTogether.copyCode' => '코드 복사',
			'watchTogether.codeCopied' => '방 코드가 복사되었습니다',
			'watchTogether.shareInvite' => '초대 공유',
			'watchTogether.inviteCopied' => '초대 메시지가 복사되었습니다. 메시지에 붙여넣으세요.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'PlezyNG 함께 보기 방에 초대합니다. \'함께 보기\'를 열고 \'방 참여\'를 선택한 다음 ${code} 코드를 입력하세요.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.openSessionControls' => '함께 보기 세션 제어 열기',
			'watchTogether.reconnecting' => '재연결 중...',
			'watchTogether.reconnectingDescription' => '연결이 끊어졌습니다. 자동으로 방에 다시 참여합니다.',
			'watchTogether.connected' => '연결됨',
			'watchTogether.disconnected' => '연결 끊김',
			'watchTogether.youAreHost' => '호스트입니다',
			'watchTogether.hostedBy' => ({required Object name}) => '호스트: ${name}',
			'watchTogether.hostControlsPlayback' => '호스트 재생 제어',
			'watchTogether.anyoneCanControl' => '누구나 재생 제어 가능',
			'watchTogether.roomLocked' => '방 잠김',
			'watchTogether.nowPlaying' => '지금 재생 중',
			'watchTogether.nothingPlaying' => '재생 중인 항목 없음',
			'watchTogether.nothingPlayingHost' => '라이브러리에서 아무 콘텐츠나 재생하면 방에 공유됩니다.',
			'watchTogether.nothingPlayingGuest' => '호스트가 콘텐츠를 재생하면 여기에서 열립니다.',
			'watchTogether.notShareable' => '이 비디오는 카탈로그와 일치하는 항목이 없어 같은 서버에 접근할 수 있는 사람만 재생할 수 있습니다.',
			'watchTogether.searching' => '라이브러리에서 이 비디오를 찾는 중...',
			'watchTogether.yourCopy' => '내 사본',
			'watchTogether.sharingYourCopy' => '내 사본을 공유하는 중',
			'watchTogether.playingOtherLength' => ({required Object difference}) => '내 사본 재생 중(${difference})',
			'watchTogether.mismatchTitle' => '내 사본의 길이가 다릅니다',
			'watchTogether.mismatchDescription' => ({required Object difference}) => '가장 근접한 내 사본이 방의 비디오와 길이가 다릅니다(${difference}). 다른 편집본이나 버전일 수 있습니다.',
			'watchTogether.playAnyway' => '그래도 재생',
			'watchTogether.chooseAnotherCopy' => '다른 사본 선택',
			'watchTogether.dontPlay' => '재생 안 함',
			'watchTogether.unavailableTitle' => '이 비디오가 없습니다',
			'watchTogether.unavailableDescription' => 'Plezy가 라이브러리에서 이 비디오를 찾지 못했습니다. 직접 사본을 선택하거나 다시 검색하세요.',
			'watchTogether.chooseCopy' => '사본 선택',
			'watchTogether.searchAgain' => '다시 검색',
			'watchTogether.noCandidates' => '라이브러리에서 사본을 찾을 수 없습니다.',
			'watchTogether.choiceFailed' => '방에서 이 사본을 재생할 수 없습니다',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} 더 김',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} 더 짧음',
			'watchTogether.lengthSame' => '길이 같음',
			'watchTogether.lengthUnknown' => '길이 알 수 없음',
			'watchTogether.joinCurrentPlayback' => '현재 재생 참여',
			'watchTogether.joinCurrentPlaybackDescription' => '호스트가 현재 시청 중인 콘텐츠로 이동합니다',
			'watchTogether.stopMedia' => '모든 참가자의 비디오 중지',
			'watchTogether.syncOffset' => '동기화 오프셋',
			'watchTogether.syncOffsetDescription' => '비디오가 방보다 앞서거나 뒤처지면 시간을 조정하세요.',
			'watchTogether.offsetHint' => ({required Object difference}) => '내 사본이 방의 비디오와 길이가 다릅니다(${difference}).',
			'watchTogether.applyDifference' => ({required Object offset}) => '${offset} 적용',
			'watchTogether.offsetMinusSecond' => '-1초',
			'watchTogether.offsetMinusTenth' => '-100ms',
			'watchTogether.offsetPlusTenth' => '+100ms',
			'watchTogether.offsetPlusSecond' => '+1초',
			'watchTogether.participants' => '참가자',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 참가자', other: '참가자 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}명', ), 
			'watchTogether.hostBadge' => '호스트',
			'watchTogether.nameYou' => ({required Object name}) => '${name}(나)',
			'watchTogether.playerIdle' => '대기 중',
			'watchTogether.playerLoading' => '로딩 중',
			'watchTogether.playerReady' => '준비됨',
			'watchTogether.playerBuffering' => '버퍼링 중',
			'watchTogether.matchSearching' => '찾는 중',
			'watchTogether.matchMatched' => '비디오 있음',
			'watchTogether.matchMismatched' => '길이 다름',
			'watchTogether.matchUnavailable' => '비디오 없음',
			'watchTogether.participantOffset' => ({required Object offset}) => '오프셋 ${offset}',
			'watchTogether.makeHost' => '호스트로 지정',
			'watchTogether.makeHostQuestion' => '호스트를 이전하시겠습니까?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name}님이 재생을 제어하고 모든 참가자의 세션을 이끕니다.',
			'watchTogether.transfer' => '이전',
			'watchTogether.removeParticipant' => '방에서 내보내기',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name}님을 내보내시겠습니까?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name}님이 방에서 나가게 됩니다. 방을 잠그지 않으면 코드로 다시 참여할 수 있습니다.',
			'watchTogether.remove' => '내보내기',
			'watchTogether.roomSettings' => '방 설정',
			'watchTogether.letEveryoneControl' => '모든 참가자에게 재생 제어 허용',
			'watchTogether.lockRoom' => '방 잠그기',
			'watchTogether.lockRoomDescription' => '새 참가자가 참여할 수 없습니다',
			'watchTogether.leaveRoom' => '방 나가기',
			'watchTogether.leaveRoomQuestion' => '방에서 나가시겠습니까?',
			'watchTogether.leaveRoomConfirm' => '방 코드로 다시 참여할 수 있습니다.',
			'watchTogether.leave' => '나가기',
			'watchTogether.endRoom' => '방 종료',
			'watchTogether.endRoomQuestion' => '방을 종료하시겠습니까?',
			'watchTogether.endRoomConfirm' => '모든 참가자에게 방이 종료됩니다.',
			'watchTogether.end' => '종료',
			'watchTogether.playBlockedTitle' => '재생이 시작되지 않았습니다',
			'watchTogether.playBlockedDescription' => '재생을 눌러 방 참가자들과 함께 시청을 시작하세요.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name}님이 재생을 눌렀습니다',
			'watchTogether.notices.playbackStarted' => '재생이 시작되었습니다',
			'watchTogether.notices.paused' => ({required Object name}) => '${name}님이 일시정지했습니다',
			'watchTogether.notices.playbackPaused' => '재생이 일시정지되었습니다',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name}님이 ${position}(으)로 이동했습니다',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '${position}(으)로 이동했습니다',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name}님이 속도를 ${speed}(으)로 설정했습니다',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => '속도가 ${speed}(으)로 설정되었습니다',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name}님이 ${title} 재생을 시작했습니다',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => '지금 재생 중: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name}님이 비디오를 중지했습니다',
			'watchTogether.notices.mediaStopped' => '비디오가 중지되었습니다',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '${name}님을 기다리는 중...',
			'watchTogether.notices.waitingForSomeone' => '다른 참가자를 기다리는 중...',
			'watchTogether.notices.finished' => '재생 완료',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name}님이 호스트가 되었습니다',
			'watchTogether.notices.youAreNowHost' => '이제 호스트입니다',
			'watchTogether.notices.joined' => ({required Object name}) => '${name}님이 참여했습니다',
			'watchTogether.notices.left' => ({required Object name}) => '${name}님이 나갔습니다',
			'watchTogether.notices.controlRefused' => '호스트만 재생을 제어할 수 있습니다',
			'watchTogether.notices.searchFailed' => '일부 서버에서 방의 비디오를 검색하지 못했습니다',
			'watchTogether.notices.playBlocked' => '재생을 눌러 시작하세요',
			'watchTogether.notices.shareFailed' => '이 비디오를 방에 공유하지 못했습니다',
			'watchTogether.notices.downloadNotShared' => '서버가 오프라인인 동안에는 다운로드한 항목이 방에 공유되지 않습니다',
			'watchTogether.notices.openFailed' => '방의 비디오를 열지 못했습니다',
			'watchTogether.ended.ended' => '호스트가 방을 종료했습니다',
			'watchTogether.ended.kicked' => '방에서 내보내졌습니다',
			'watchTogether.ended.expired' => '방이 만료되었습니다',
			'watchTogether.ended.replaced' => '다른 기기에서 이 방에 참여했습니다',
			'watchTogether.ended.lost' => '방과의 연결이 끊어졌습니다',
			'watchTogether.errors.invalidCode' => '방 코드가 아닙니다. 코드는 0, 1, I, L 또는 O를 제외한 영문자와 숫자 6자리입니다.',
			'watchTogether.errors.roomNotFound' => '해당 코드의 방이 없습니다. 종료되었을 수 있습니다.',
			'watchTogether.errors.roomFull' => '방이 가득 찼습니다.',
			'watchTogether.errors.roomLocked' => '호스트가 방을 잠갔습니다.',
			'watchTogether.errors.relayFull' => '지금은 함께 보기 이용자가 많습니다. 나중에 다시 시도하세요.',
			'watchTogether.errors.unreachable' => '함께 보기 릴레이에 연결할 수 없습니다. 연결을 확인하세요.',
			'watchTogether.errors.rateLimited' => '시도 횟수가 너무 많습니다. 잠시 후 다시 시도하세요.',
			'watchTogether.errors.clientBlocked' => '이 버전의 Plezy는 릴레이를 사용할 수 없습니다. 앱을 업데이트하세요.',
			'watchTogether.errors.forbidden' => '호스트만 이 작업을 할 수 있습니다.',
			'watchTogether.errors.notInRoom' => '방에 참여하고 있지 않습니다.',
			'watchTogether.errors.alreadyInRoom' => '이미 방에 참여하고 있습니다.',
			'watchTogether.errors.resumeFailed' => '방에 다시 참여하지 못했습니다.',
			'watchTogether.errors.unsupported' => '릴레이에서 지원하지 않는 기능입니다.',
			'watchTogether.errors.generic' => '문제가 발생했습니다. 다시 시도하세요.',
			'watchTogether.untitledEpisode' => ({required Object number}) => '${number}화',
			'downloads.title' => '다운로드',
			'downloads.manage' => '관리',
			'downloads.tvShows' => 'TV 프로그램',
			'downloads.movies' => '영화',
			'downloads.music' => '음악',
			'downloads.tracksQueued' => ({required Object count}) => '${count}곡 다운로드 대기 중',
			'downloads.noDownloads' => '다운로드 없음',
			'downloads.noDownloadsDescription' => '다운로드한 콘텐츠는 오프라인 시청을 위해 여기에 표시됩니다',
			'downloads.downloadNow' => '다운로드',
			'downloads.deleteDownload' => '다운로드 삭제',
			'downloads.retryDownload' => '다운로드 재시도',
			'downloads.downloadQueued' => '다운로드 대기 중',
			'downloads.downloadResumed' => '다운로드를 재개했습니다',
			'downloads.serverErrorBitrate' => '서버 오류: 파일이 원격 비트레이트 제한을 초과할 수 있습니다',
			'downloads.storageFull' => '사용 가능한 저장 공간을 보호하기 위해 다운로드를 중지했습니다. 공간을 확보하거나 다른 다운로드 위치를 선택한 후 다시 시도하세요.',
			'downloads.storageUnavailable' => '사용 가능한 저장 공간을 확인할 수 없어 다운로드를 중지했습니다. 다운로드 위치를 확인한 후 다시 시도하세요.',
			'downloads.episodesQueued' => ({required Object count}) => '에피소드 ${count}개가 다운로드 대기열에 추가되었습니다',
			'downloads.downloadDeleted' => '다운로드 삭제됨',
			'downloads.deleteConfirm' => ({required Object title}) => '이 기기에서 "${title}"을(를) 삭제할까요?',
			'downloads.deleteCollectionDownloads' => '다운로드 삭제',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '이 기기에서 "${title}"의 모든 다운로드를 삭제할까요?',
			'downloads.collectionDownloadsDeleted' => '다운로드 삭제됨',
			'downloads.cancelledDownloadTitle' => '취소된 다운로드',
			'downloads.cancelledDownloadMessage' => '이 다운로드가 취소되었습니다. 어떻게 하시겠습니까?',
			'downloads.allEpisodesAlreadyDownloaded' => '모든 에피소드가 이미 다운로드되었습니다',
			'downloads.resumeDownload' => '다운로드 재개',
			'downloads.cancelledDownload' => '취소된 다운로드',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} 동기화 중)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} 다운로드됨 — 클릭하여 완료',
			'downloads.partialDownloadClickToComplete' => '부분 다운로드됨 — 클릭하여 완료',
			'downloads.deleting' => '삭제 중...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})',
			'downloads.queuedTooltip' => '대기 중',
			'downloads.queuedFilesTooltip' => ({required Object files}) => '대기 중: ${files}',
			'downloads.downloadingTooltip' => '다운로드 중...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '${files} 다운로드 중',
			'downloads.noDownloadsTree' => '다운로드 없음',
			'downloads.pauseAll' => '모두 일시정지',
			'downloads.resumeAll' => '모두 재개',
			'downloads.retryAll' => '모두 재시도',
			'downloads.retryFailed' => '실패한 다운로드 재시도',
			'downloads.deleteAll' => '모두 삭제',
			'downloads.selectVersion' => '버전 선택',
			'downloads.allEpisodes' => '모든 에피소드',
			'downloads.unwatchedOnly' => '시청하지 않은 것만',
			'downloads.nextNUnwatched' => ({required Object count}) => '다음 ${count}개 미시청',
			'downloads.customAmount' => '직접 입력...',
			'downloads.customAmountAny' => '각각의 수량(일반적으로)',
			'downloads.randomEpisodes' => '우연한 사건',
			'downloads.includeSpecials' => '스페셜 포함',
			'downloads.howManyEpisodes' => '몇 개의 에피소드?',
			'downloads.invalidEpisodeCount' => '올바른 에피소드 수를 입력하세요.',
			'downloads.keepSynced' => '동기화 유지',
			'downloads.downloadOnce' => '한 번만 다운로드',
			'downloads.keepNUnwatched' => ({required Object count}) => '미시청 ${count}개 유지',
			'downloads.editSyncRule' => '동기화 규칙 편집',
			'downloads.removeSyncRule' => '동기화 규칙 제거',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" 동기화를 중단하시겠습니까? 다운로드된 에피소드는 유지됩니다.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '"${title}" 동기화를 중지할까요?',
			'downloads.deleteSyncRuleDownloads' => '연결된 다운로드도 삭제',
			'downloads.deleteSyncRuleDownloadsDescription' => '다른 동기화 규칙이나 프로필에서 사용하는 다운로드는 유지됩니다.',
			'downloads.syncRuleCreated' => ({required Object count}) => '동기화 규칙 생성됨 — 미시청 에피소드 ${count}개 유지',
			'downloads.syncRuleUpdated' => '동기화 규칙 업데이트됨',
			'downloads.syncRuleRemoved' => '동기화 규칙 제거됨',
			'downloads.syncRuleAndDownloadsRemoved' => '동기화 규칙과 연결된 다운로드가 삭제되었습니다',
			'downloads.syncRuleCleanupBusy' => '동기화 규칙이 현재 업데이트 중입니다. 잠시 후 다시 시도하세요.',
			'downloads.syncRuleCleanupUnavailable' => '연결된 다운로드를 안전하게 확인할 수 없습니다. 서버에 다시 연결한 후 시도하거나, 다운로드를 삭제하지 않고 규칙만 제거하세요.',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title}의 새 에피소드 ${count}개 동기화됨',
			'downloads.syncNow' => '지금 시너먼트',
			'downloads.downloadsUpToDate' => '다운로드는 현재까지 진행되고 있습니다.',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => '동기화 완료 · ${queued} queued, ${removed} 제거',
			'downloads.activeSyncRules' => '동기화 규칙',
			'downloads.reviewOrphanFiles' => '기록이 없는 다운로드 검토',
			'downloads.orphanReviewTitle' => '기록이 없는 다운로드 검토',
			'downloads.orphanReviewDescription' => '이 태그가 지정된 파일은 PlezyNG가 관리하는 기본 다운로드 폴더에 있지만, 일치하는 다운로드 기록이나 활성 작업이 없습니다. 삭제하기 전에 목록을 확인하세요.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count}개 파일 · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count}개 파일 삭제',
			'downloads.orphanCleanupNone' => '기록이 없는 다운로드 파일을 찾지 못했습니다',
			'downloads.orphanCleanupFailed' => 'PlezyNG에서 관리되는 다운로드 폴더를 안전하게 검색할 수 없습니다. 파일은 삭제되지 않았습니다.',
			'downloads.orphanCleanupChanged' => '검토 중 다운로드 목록이 변경되었습니다. 정리하기 전에 파일을 다시 확인하세요.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count}개 기록 없는 파일 삭제됨 · ${size} 확보',
			'downloads.noSyncRules' => '동기화 규칙 없음',
			'downloads.manageSyncRule' => '동기화 관리',
			'downloads.editEpisodeCount' => '에피소드 수',
			'downloads.editSyncFilter' => '동기화 필터',
			'downloads.syncAllItems' => '모든 항목 동기화 중',
			'downloads.syncUnwatchedItems' => '시청하지 않은 항목 동기화 중',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => '서버: ${server} • ${status}',
			'downloads.syncRuleAvailable' => '사용 가능',
			'downloads.syncRuleOffline' => '오프라인',
			'downloads.syncRuleSignInRequired' => '로그인 필요',
			'downloads.syncRuleAccessDenied' => '접근 거부됨',
			'downloads.syncRuleNotAvailableForProfile' => '현재 프로필에서 사용할 수 없음',
			'downloads.syncRuleUnknownServer' => '알 수 없는 서버',
			'downloads.syncRuleListCreated' => '동기화 규칙이 생성되었습니다',
			'downloads.backgroundWarning.bannerBlocked' => '앱에서 나가면 다운로드가 중지됩니다',
			'downloads.backgroundWarning.bannerDegraded' => '백그라운드 다운로드가 제한될 수 있습니다',
			'downloads.backgroundWarning.bannerAction' => '세부정보',
			'downloads.backgroundWarning.sheetTitle' => '백그라운드 다운로드가 차단됨',
			'downloads.backgroundWarning.sheetTitleDegraded' => '백그라운드 다운로드가 제한될 수 있음',
			'downloads.backgroundWarning.sheetIntro' => 'Android가 Plezy의 안정적인 백그라운드 다운로드를 차단하고 있습니다.',
			'downloads.backgroundWarning.sheetIntroDegraded' => '기기에서 Plezy가 백그라운드로 다운로드할 수 있는 시점을 제한하고 있습니다.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy의 백그라운드 사용이 제한되어 있습니다. 배터리 또는 백그라운드 사용을 "제한 없음"으로 설정하세요.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android가 Plezy를 제한된 대기 상태로 전환했습니다. 배터리 사용량을 "제한 없음"으로 설정하세요.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => '다운로드 알림이 꺼져 있어 진행 상황과 제어 기능을 사용하지 못할 수 있습니다.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => '알림이 꺼져 있습니다. Android 13 이상에서는 장시간 백그라운드 다운로드에 알림이 필요합니다.',
			'downloads.backgroundWarning.reasonDataSaver' => '데이터 절약 모드가 켜져 있어 모바일 데이터로 백그라운드 다운로드를 할 수 없습니다. Wi-Fi에서는 계속 다운로드할 수 있습니다.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy가 백그라운드에 있을 때 다운로드가 반복해서 중지되었습니다. Plezy의 배터리 또는 백그라운드 사용 설정을 확인하세요.',
			'downloads.backgroundWarning.openSettings' => '설정 열기',
			'downloads.backgroundWarning.stillNotWorking' => '기기별 도움말',
			'downloads.backgroundWarning.stillNotWorkingDescription' => '기기에 맞는 단계를 확인하세요. 문제가 계속되면 설정 › 로그 보기에서 로그를 보내 주세요.',
			'downloads.backgroundWarning.dialogTitle' => '다운로드가 완료되지 않을 수 있음',
			'downloads.backgroundWarning.dialogDownloadAnyway' => '그래도 다운로드',
			'downloads.backgroundWarning.dialogFixFirst' => '먼저 문제 해결',
			'downloads.backgroundWarning.statusTile' => '백그라운드 다운로드',
			'downloads.backgroundWarning.statusOk' => '백그라운드 실행 허용됨',
			'downloads.backgroundWarning.statusBlocked' => '시스템 설정에 의해 차단됨',
			'downloads.backgroundWarning.statusDegraded' => '시스템 설정에 의해 제한됨',
			'downloads.backgroundWarning.statusUnknown' => '아직 확인하지 않음',
			'downloads.backgroundWarning.settingsUnavailable' => '이 기기에서 시스템 설정을 열 수 없습니다',
			'downloads.backgroundWarning.linkUnavailable' => '이 기기에서 dontkillmyapp.com을 열 수 없습니다',
			'downloads.options' => '다운로드 옵션',
			'downloads.groupings.library' => '라이브러리',
			'downloads.groupings.collections' => '컬렉션',
			'downloads.unknownLibrary' => '알 수 없는 라이브러리',
			'downloads.unknownShow' => '알 수 없는 프로그램',
			'downloads.unknownSeason' => '알 수 없는 시즌',
			'downloads.unknownAlbum' => '알 수 없는 앨범',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} 완료',
			'downloads.storageUsed' => ({required Object size}) => '사용된 저장소: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 다운로드', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 다운로드', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 쇼', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 표시', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 영화', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 영화', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 앨범', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}개 앨범', ), 
			'downloads.errorFileNotFound' => '파일을 찾을 수 없음(404)',
			'downloads.errorDownloadNotAllowed' => '서버에서 다운로드를 허용하지 않음(403)',
			'downloads.errorDownloadFailed' => '다운로드 실패',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => '다운로드 실패: ${reason}',
			'downloads.convertingOnServer' => '서버로 변환하는 ...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => '서버로 변환 · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => '다운로드 실패(HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => '후처리 실패: ${reason}',
			'downloads.reasonFileNotSaved' => '이 기기에 파일을 저장할 수 없습니다',
			'downloads.reasonCannotResume' => '일부만 받은 다운로드를 이어서 받을 수 없습니다',
			'downloads.reasonDeviceStorageFull' => '이 기기의 저장 공간이 부족합니다',
			'downloads.notificationDownloading' => '다운로드 중...',
			'downloads.notificationComplete' => '다운로드 완료',
			'downloads.notificationPaused' => '다운로드 일시 중지',
			'shaders.title' => '셰이더',
			'shaders.noShaderDescription' => '비디오 향상 없음',
			'shaders.nvscalerDescription' => '더 선명한 비디오를 위한 NVIDIA 이미지 스케일링',
			'shaders.artcnnVariantNeutral' => '중립',
			'shaders.artcnnVariantDenoise' => '노이즈 제거',
			'shaders.artcnnVariantDenoiseSharpen' => '노이즈 제거 + 선명화',
			'shaders.qualityFast' => '빠름',
			'shaders.qualityHQ' => '고품질',
			'shaders.mode' => '모드',
			'shaders.importShader' => '셰이더 가져오기',
			'shaders.customShaderDescription' => '사용자 정의 GLSL 셰이더',
			'shaders.shaderImported' => '셰이더를 가져왔습니다',
			'shaders.shaderImportFailed' => '셰이더 가져오기 실패',
			'shaders.deleteShader' => '셰이더 삭제',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}"을(를) 삭제하시겠습니까?',
			'companionRemote.title' => '컴패니언 리모컨',
			'companionRemote.connectedTo' => ({required Object name}) => '${name}에 연결됨',
			'companionRemote.unknownDevice' => '알 수 없는 기기',
			'companionRemote.session.startingServer' => '원격 서버 시작 중...',
			'companionRemote.session.hostAddress' => '호스트 주소',
			'companionRemote.session.connected' => '연결됨',
			'companionRemote.session.serverRunning' => '원격 서버 활성',
			'companionRemote.session.serverStopped' => '원격 서버 중지됨',
			'companionRemote.session.serverRunningDescription' => '네트워크의 모바일 기기가 이 앱에 연결할 수 있습니다',
			'companionRemote.session.serverStoppedDescription' => '모바일 기기의 연결을 허용하려면 서버를 시작하세요',
			'companionRemote.session.usePhoneToControl' => '모바일 기기로 이 앱을 제어하세요',
			'companionRemote.session.startServer' => '서버 시작',
			'companionRemote.session.stopServer' => '서버 중지',
			'companionRemote.session.minimize' => '최소화',
			'companionRemote.session.manualAddressHint' => '수동 연결 주소:',
			'companionRemote.pairing.discoveryDescription' => '같은 Plex 계정의 PlezyNG 기기가 여기에 표시됩니다',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '연결 중...',
			'companionRemote.pairing.searchingForDevices' => '기기 검색 중...',
			'companionRemote.pairing.noDevicesFound' => '네트워크에서 기기를 찾을 수 없습니다',
			'companionRemote.pairing.noDevicesHint' => '데스크톱에서 Plezy를 열고 같은 Wi-Fi를 사용하세요',
			'companionRemote.pairing.availableDevices' => '사용 가능한 기기',
			'companionRemote.pairing.manualConnection' => '수동 연결',
			'companionRemote.pairing.cryptoInitFailed' => '보안 연결을 시작할 수 없습니다. 먼저 Plex에 로그인하세요.',
			'companionRemote.pairing.validationHostRequired' => '호스트 주소를 입력하세요',
			'companionRemote.pairing.validationHostFormat' => '형식은 IP:포트여야 합니다 (예: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => '연결 시간이 초과되었습니다. 두 기기에서 같은 네트워크를 사용하세요.',
			'companionRemote.pairing.sessionNotFound' => '기기를 찾을 수 없습니다. 호스트에서 Plezy가 실행 중인지 확인하세요.',
			'companionRemote.pairing.authFailed' => '인증에 실패했습니다. 두 기기 모두 같은 Plex 계정이 필요합니다.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '연결 실패: ${error}',
			'companionRemote.pairing.codeTitle' => '커플 코드',
			'companionRemote.pairing.codeDescription' => '호스트 장치에서 Companion Remote에서 표시된 코드를 입력합니다.두 장치는 안전한 커플링을 지원하는 버전을 사용해야 합니다.',
			'companionRemote.pairing.codeInvalid' => '호스트 코드에서 32 문자와 숫자를 모두 입력합니다.',
			'companionRemote.pairing.updateRequired' => '두 장치를 안전한 커플링을 지원하는 버전으로 업데이트합니다.',
			'companionRemote.pairing.hostDescription' => '각 원격으로 한 번 이 코드를 입력합니다.이 코드를 개인적으로 유지하십시오.이 코드는 이 프로필을 제어합니다.',
			'companionRemote.pairing.resetCode' => '쌍 코드 복구',
			'companionRemote.pairing.resetDescription' => '모든 원격을 분리하고 새로운 코드를 만들 수 있습니다.모든 원격은 다시 쌍을해야합니다.',
			'companionRemote.remote.disconnectConfirm' => '원격 세션 연결을 해제하시겠습니까?',
			'companionRemote.remote.reconnecting' => '재연결 중...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '${current}/5 시도 중',
			'companionRemote.remote.retryNow' => '지금 재시도',
			'companionRemote.remote.tabRemote' => '리모컨',
			'companionRemote.remote.tabPlay' => '재생',
			'companionRemote.remote.tabMore' => '더 보기',
			'companionRemote.remote.menu' => '메뉴',
			'companionRemote.remote.tabNavigation' => '탭 탐색',
			'companionRemote.remote.tabDiscover' => '둘러보기',
			'companionRemote.remote.tabLibraries' => '미디어 라이브러리',
			'companionRemote.remote.tabSearch' => '검색',
			'companionRemote.remote.tabDownloads' => '다운로드',
			'companionRemote.remote.tabSettings' => '설정',
			'companionRemote.remote.previous' => '이전',
			'companionRemote.remote.playPause' => '재생/일시정지',
			'companionRemote.remote.next' => '다음',
			'companionRemote.remote.seekBack' => '되감기',
			'companionRemote.remote.stop' => '정지',
			'companionRemote.remote.seekForward' => '빨리감기',
			'companionRemote.remote.volume' => '볼륨',
			'companionRemote.remote.volumeDown' => '줄이기',
			'companionRemote.remote.volumeUp' => '높이기',
			'companionRemote.remote.fullscreen' => '전체 화면',
			'companionRemote.remote.subtitles' => '자막',
			'companionRemote.remote.audio' => '오디오',
			'companionRemote.remote.searchHint' => '데스크톱에서 검색...',
			'companionRemote.errors.noNetworkInterface' => '네트워크 인터페이스를 찾을 수 없습니다',
			'companionRemote.errors.authenticationFailed' => '인증 실패',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => '원격 서버를 시작하지 못했습니다: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => '원격 명령을 보내지 못했습니다: ${error}',
			'companionRemote.errors.joinTimedOut' => '세션 참가 시간이 초과되었습니다',
			'companionRemote.errors.failedToConnectAnyAddress' => '어떤 주소에도 연결하지 못했습니다',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts}회 시도 후 연결이 끊어졌습니다',
			'companionRemote.errors.connectionLost' => '연결이 끊어졌습니다',
			'companionRemote.closedBeforeAuth' => '인증 전에 연결이 종료되었습니다',
			'videoSettings.playbackSpeed' => '재생 속도',
			'videoSettings.normalSpeed' => '보통',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '활성 (${duration})',
			'videoSettings.zoom' => '확대/축소',
			'videoSettings.sleepTimer' => '취침 타이머',
			'videoSettings.audioSync' => '오디오 동기화',
			'videoSettings.subtitleSync' => '자막 동기화',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => '여기서는 HDR을 사용할 수 없습니다. 이 데스크톱 컴포지터 또는 비디오 출력에서 HDR을 전달할 수 없습니다.',
			'videoSettings.hdrToneMapping' => 'HDR 톤 매핑',
			'videoSettings.hdrToneMappingCompositor' => '컴포지터',
			'videoSettings.hdrToneMappingCompositorDescription' => '소스의 HDR 메타데이터를 그대로 전달하고 데스크톱 컴포지터에서 매핑하도록 합니다.',
			'videoSettings.hdrToneMappingPlayer' => '플레이어',
			'videoSettings.hdrToneMappingPlayerDescription' => '플레이어에서 디스플레이의 최대 밝기에 맞게 매핑한 다음 그 결과를 컴포지터에 전달합니다.',
			'videoSettings.hdrToneMappingFailed' => 'HDR 톤 매핑을 변경할 수 없습니다. 이전 모드가 계속 적용됩니다.',
			'videoSettings.audioOutput' => '오디오 출력',
			'videoSettings.videoTrack' => '비디오 트랙',
			'videoSettings.videoTrackDescription' => '표시할 비디오 스트림을 선택합니다. 파일에 대체 비디오 트랙이 있으면 MPV 재생에서 사용할 수 있습니다.',
			'videoSettings.videoTrackDefault' => '기본값',
			'videoSettings.videoTrackUnavailable' => '사용할 수 있는 대체 비디오 트랙이 없습니다.',
			'videoSettings.videoTrackFailed' => '비디오 트랙을 변경하지 못했습니다.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => '트랙 ${id}',
			'videoSettings.performanceOverlay' => '성능 오버레이',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => '서라운드',
			'videoSettings.audioOutputSpatial' => '공간 음향',
			'videoSettings.audioOutputStereo' => '스테레오',
			'videoSettings.audioEqualizer' => '오디오 균형',
			'videoSettings.audioEqualizerDescription' => '10 밴드 평등기 MPV. 오디오 필터는 해독 된 오디오를 사용하고 passthrough를 끄십시오.',
			'videoSettings.audioEqualizerFlat' => '플랫',
			'videoSettings.audioEqualizerActive' => '사용자 지정',
			'videoSettings.audioEqualizerSaveFailed' => '오디오 평등기 설정을 저장할 수 없었습니다.',
			'videoSettings.audioEffectsDescription' => '효과는 해독 된 오디오를 사용하여, 그래서 passthrough가 꺼집니다. 방 환경과 스테레오 확장은 MPV 건설 및 트랙',
			'videoSettings.audioStereoWidth' => '스테레오 확장',
			'videoSettings.audioSpatializer' => '방 환경',
			'videoSettings.audioSpatializerDescription' => '조용한 방 반응을 추가하십시오.',
			'videoSettings.audioPitch' => '피치 스위트',
			'videoSettings.audioPitchDescription' => '속도를 바꾸지 않고 플레이트를 변경합니다. MPV 건설은 포함되어야 합니다. Rubber Band그리고',
			'videoSettings.audioEffectUnavailable' => '이 효과는이 트랙에 사용할 수 없습니다 또는 MPV 건설하기',
			'videoSettings.backgroundVideoAudio' => '배경 비디오 오디오',
			'videoSettings.backgroundVideoAudioDescription' => '플레이어를 떠날 때 비디오 오디오 재생을 유지; 사진이 돌아올 때까지 숨겨져 있습니다. Android은 미디어 재생 알림을 사용합니다.',
			'videoSettings.audioNormalization' => '음량 정규화',
			'videoSettings.audioNormalizationDisablesPassthrough' => '오디오를 PCM으로 디코딩합니다. 켜져 있는 동안 패스스루가 꺼집니다',
			'performanceOverlay.color' => '색상',
			'performanceOverlay.performance' => '성능',
			'performanceOverlay.buffer' => '버퍼',
			'performanceOverlay.app' => '앱',
			'performanceOverlay.decoder' => '디코더',
			'performanceOverlay.rawDecoder' => '원본 디코더',
			'performanceOverlay.tunneling' => '터널링',
			'performanceOverlay.passthrough' => '패스스루',
			'performanceOverlay.aspect' => '화면비',
			'performanceOverlay.rotation' => '회전',
			'performanceOverlay.dvSource' => 'DV 소스',
			'performanceOverlay.dvPath' => 'DV 경로',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision 디코더',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision 디코더 (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => '베이스 레이어',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 베이스 레이어',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG 베이스 레이어',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR 베이스 레이어',
			'performanceOverlay.dvRouteReshaped' => 'RPU 리셰이핑 (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => '실험 P7 FEL 그래픽 (무료)',
			'performanceOverlay.p7Conversion' => 'P7 변환',
			'performanceOverlay.sampleRate' => '샘플 레이트',
			'performanceOverlay.pixelFormat' => '픽셀 형식',
			'performanceOverlay.hwFormat' => 'HW 형식',
			'performanceOverlay.matrix' => '매트릭스',
			'performanceOverlay.primaries' => '원색',
			'performanceOverlay.transfer' => '전송',
			'performanceOverlay.renderFps' => '렌더 FPS',
			'performanceOverlay.displayFps' => '디스플레이 FPS',
			'performanceOverlay.avSync' => 'A/V 동기화',
			'performanceOverlay.dropped' => '드롭됨',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'DV RPU 평균',
			'performanceOverlay.dvSampleAverage' => 'DV 샘플 평균',
			'performanceOverlay.maxLuma' => '최대 휘도',
			'performanceOverlay.minLuma' => '최소 휘도',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => '사용 캐시',
			'performanceOverlay.cacheLimit' => '캐시 제한',
			'performanceOverlay.speed' => '속도',
			'performanceOverlay.player' => '플레이어',
			'performanceOverlay.playMethod' => '게임 방법',
			'performanceOverlay.memory' => '메모리',
			'performanceOverlay.uiFps' => 'UI FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => '소프트웨어',
			'performanceOverlay.decoderHardware' => '하드웨어',
			'performanceOverlay.tunnelingActive' => '활성',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures}개 실패)',
			'externalPlayer.title' => '외부 플레이어',
			'externalPlayer.useExternalPlayer' => '외부 플레이어 사용',
			'externalPlayer.useExternalPlayerDescription' => '동영상을 다른 앱에서 열기',
			'externalPlayer.selectPlayer' => '플레이어 선택',
			'externalPlayer.customPlayers' => '사용자 정의 플레이어',
			'externalPlayer.systemDefault' => '시스템 기본값',
			'externalPlayer.addCustomPlayer' => '사용자 정의 플레이어 추가',
			'externalPlayer.playerName' => '플레이어 이름',
			'externalPlayer.playerNameHint' => '내 플레이어',
			'externalPlayer.playerCommand' => '명령어',
			'externalPlayer.playerPackage' => '패키지 이름',
			'externalPlayer.playerUrlScheme' => 'URL 스킴',
			'externalPlayer.off' => '꺼짐',
			'externalPlayer.launchFailed' => '외부 플레이어를 열 수 없습니다',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name}이(가) 설치되어 있지 않습니다',
			'externalPlayer.playInExternalPlayer' => '외부 플레이어에서 재생',
			'externalPlayer.description' => '다른 앱을 선택하여 비디오를 열 수 있습니다. 이용 가능한 플레이어는 장치와 설치된 앱에 따라 달라집니다.',
			'externalPlayer.systemDefaultDescription' => '운영 체제가 기본 앱으로 비디오를 열어주십시오.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => '${player}와 함께 비디오를 열어보세요.',
			'externalPlayer.playerNameDescription' => '플레이어 목록에 표시된 레이블.',
			'externalPlayer.playerPackageDescription' => '플레이어 앱의 안드로이드 패키지 이름, 예를 들어 com.example.player을 입력합니다.',
			'externalPlayer.playerCommandDescription' => '이 장치에 대한 설치된 플레이어 명령 또는 실행 가능한 경로를 입력합니다.',
			'externalPlayer.playerUrlSchemeDescription' => 'URL 스케줄과 플레이어를 시작하는 데 사용되는 선택적인 URL 템플릿을 입력합니다.',
			'metadataEdit.editMetadata' => '편집...',
			'metadataEdit.screenTitle' => '메타데이터 편집',
			'metadataEdit.basicInfo' => '기본 정보',
			'metadataEdit.artwork' => '아트워크',
			'metadataEdit.advancedSettings' => '고급 설정',
			'metadataEdit.title' => '제목',
			'metadataEdit.sortTitle' => '정렬 제목',
			'metadataEdit.originalTitle' => '원제',
			'metadataEdit.releaseDate' => '출시일',
			'metadataEdit.contentRating' => '콘텐츠 등급',
			'metadataEdit.studio' => '스튜디오',
			'metadataEdit.tagline' => '태그라인',
			'metadataEdit.summary' => '줄거리',
			'metadataEdit.poster' => '포스터',
			'metadataEdit.background' => '배경',
			'metadataEdit.logo' => '로고',
			'metadataEdit.squareArt' => '정사각형 아트',
			'metadataEdit.selectPoster' => '포스터 선택',
			'metadataEdit.selectBackground' => '배경 선택',
			'metadataEdit.selectLogo' => '로고 선택',
			'metadataEdit.selectSquareArt' => '정사각형 아트 선택',
			'metadataEdit.fromUrl' => 'URL에서',
			'metadataEdit.uploadFile' => '파일 업로드',
			'metadataEdit.enterImageUrl' => '이미지 URL 입력',
			'metadataEdit.imageUrl' => '이미지 URL',
			'metadataEdit.metadataUpdated' => '메타데이터가 업데이트되었습니다',
			'metadataEdit.metadataUpdateFailed' => '메타데이터 업데이트 실패',
			'metadataEdit.artworkUpdated' => '아트워크가 업데이트되었습니다',
			'metadataEdit.artworkUpdateFailed' => '아트워크 업데이트 실패',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.noArtworkAvailable' => '사용 가능한 아트워크 없음',
			'metadataEdit.artworkOption' => ({required Object index}) => '아트워크 옵션 ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => '아트워크 옵션 ${index}, 선택됨',
			'metadataEdit.notSet' => '설정되지 않음',
			'metadataEdit.libraryDefault' => '라이브러리 기본값',
			'metadataEdit.accountDefault' => '계정 기본값',
			'metadataEdit.seriesDefault' => '시리즈 기본값',
			'metadataEdit.episodeSorting' => '에피소드 정렬',
			'metadataEdit.oldestFirst' => '오래된 순',
			'metadataEdit.newestFirst' => '최신 순',
			'metadataEdit.keep' => '유지',
			'metadataEdit.allEpisodes' => '모든 에피소드',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '최신 에피소드 ${count}개',
			'metadataEdit.latestEpisode' => '최신 에피소드',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => '최근 ${count}일 내 추가된 에피소드',
			'metadataEdit.deleteAfterPlaying' => '재생 후 에피소드 삭제',
			'metadataEdit.never' => '안 함',
			'metadataEdit.afterADay' => '하루 후',
			'metadataEdit.afterAWeek' => '일주일 후',
			'metadataEdit.afterAMonth' => '한 달 후',
			'metadataEdit.onNextRefresh' => '다음 새로고침 시',
			'metadataEdit.seasons' => '시즌',
			'metadataEdit.show' => '표시',
			'metadataEdit.hide' => '숨기기',
			'metadataEdit.episodeOrdering' => '에피소드 순서',
			'metadataEdit.tmdbAiring' => 'The Movie Database (방영순)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (방영순)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (절대순)',
			'metadataEdit.metadataLanguage' => '메타데이터 언어',
			'metadataEdit.useOriginalTitle' => '원제 사용',
			'metadataEdit.preferredAudioLanguage' => '선호 오디오 언어',
			'metadataEdit.preferredSubtitleLanguage' => '선호 자막 언어',
			'metadataEdit.subtitleMode' => '자막 자동 선택 모드',
			'metadataEdit.manuallySelected' => '수동 선택',
			'metadataEdit.shownWithForeignAudio' => '외국어 오디오 시 표시',
			'metadataEdit.alwaysEnabled' => '항상 활성화',
			'metadataEdit.tags' => '태그',
			'metadataEdit.addTag' => '태그 추가',
			'metadataEdit.genre' => '장르',
			'metadataEdit.director' => '감독',
			'metadataEdit.writer' => '작가',
			'metadataEdit.producer' => '프로듀서',
			'metadataEdit.country' => '국가',
			'metadataEdit.collection' => '컬렉션',
			'metadataEdit.label' => '라벨',
			'metadataEdit.quickTag' => '빠른 태그…',
			'matchScreen.match' => '일치...',
			'matchScreen.fixMatch' => '일치 수정...',
			'matchScreen.unmatch' => '일치 해제',
			'matchScreen.unmatchConfirm' => '이 매칭을 지울까요? 다시 매칭될 때까지 Plex에서는 미매칭으로 처리됩니다.',
			'matchScreen.unmatchSuccess' => '일치 해제됨',
			'matchScreen.unmatchFailed' => '일치 해제에 실패했습니다',
			'matchScreen.matchApplied' => '일치 적용됨',
			'matchScreen.matchFailed' => '일치 적용에 실패했습니다',
			'matchScreen.titleHint' => '제목',
			'matchScreen.yearHint' => '연도',
			'matchScreen.search' => '검색',
			'matchScreen.noMatchesFound' => '일치하는 항목이 없습니다',
			'serverTasks.title' => '서버 작업',
			'serverTasks.failedToLoad' => '작업을 불러올 수 없습니다',
			'serverTasks.noTasks' => '실행 중인 작업 없음',
			'trakt.title' => 'Trakt',
			'trakt.connected' => '연결됨',
			'trakt.connectedAs' => ({required Object username}) => '@${username}(으)로 연결됨',
			'trakt.disconnectConfirm' => 'Trakt 계정 연결을 끊으시겠습니까?',
			'trakt.disconnectConfirmBody' => 'Plezy가 Trakt로 이벤트 전송을 중지합니다. 언제든 다시 연결할 수 있습니다.',
			'trakt.scrobble' => '실시간 스크로블',
			'trakt.scrobbleDescription' => '재생 중 재생, 일시정지, 정지 이벤트를 Trakt로 전송합니다.',
			'trakt.watchedSync' => '시청 상태 동기화',
			'trakt.watchedSyncDescription' => 'Plezy에서 시청 완료로 표시한 항목이 Trakt에도 시청 완료로 표시됩니다.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr에 연결',
			'seerr.serverUrl' => '서버 URL',
			'seerr.serverUrlHelper' => 'Seerr 인스턴스의 주소',
			'seerr.checkServer' => '계속',
			'seerr.signInWithJellyfin' => 'Jellyfin으로 로그인',
			'seerr.signInWithEmby' => 'Emby로 로그인',
			'seerr.signInWithLocal' => '로컬 계정 사용',
			'seerr.email' => '이메일',
			'seerr.noSignInMethods' => '이 Seerr 인스턴스에는 Plezy가 지원하는 로그인 방법이 없습니다.',
			'seerr.instance' => '인스턴스',
			'seerr.disconnectConfirm' => 'Seerr 연결을 해제하시겠습니까?',
			'seerr.disconnectConfirmBody' => 'Plezy가 이 Seerr 인스턴스를 삭제합니다. 언제든 다시 연결할 수 있습니다.',
			'seerr.request' => '요청',
			'seerr.request4k' => '4K로 요청',
			'seerr.seasons' => '시즌',
			'seerr.allSeasons' => '모든 시즌',
			'seerr.advancedOptions' => '고급',
			'seerr.destinationServer' => '대상 서버',
			'seerr.qualityProfile' => '화질 프로파일',
			'seerr.rootFolder' => '루트 폴더',
			'seerr.languageProfile' => '언어 프로파일',
			'seerr.tags' => '태그',
			'seerr.noTags' => '태그 없음',
			'seerr.defaultOption' => ({required Object name}) => '${name} (기본값)',
			'seerr.animeNote' => '이 시리즈는 애니메이션입니다.',
			'seerr.requestSubmitted' => '요청을 제출했습니다',
			'seerr.requestFailed' => ({required Object error}) => '요청 실패: ${error}',
			'seerr.requestsLoadFailed' => '요청 옵션을 불러올 수 없습니다',
			'seerr.nothingToRequest' => '모두 이미 사용 가능하거나 요청되었습니다.',
			'seerr.statusAvailable' => '사용 가능',
			'seerr.statusPartiallyAvailable' => '일부 사용 가능',
			'seerr.statusRequested' => '요청됨',
			'seerr.statusProcessing' => '처리 중',
			'seerr.statusBlocklisted' => '차단 목록에 있음',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url}에 연결할 수 없습니다: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url}에 Seerr 인스턴스가 없습니다(HTTP ${status})',
			'seerr.behindAuthProxy' => 'Seerr 대신 인증이 필요한 리버스 프록시(SSO 또는 HTTP 인증)가 응답했습니다. Plezy는 이를 통해 로그인할 수 없습니다. 이 앱에서 Seerr의 /api/v1 경로가 프록시를 우회하도록 하거나, Seerr에 직접 연결되는 주소를 사용하세요.',
			'seerr.invalidUrl' => 'https://seerr.example.com과 같은 서버 주소를 입력하세요',
			'seerr.quickConnectUnsupported' => '이 Seerr 인스턴스는 Quick Connect를 지원하지 않습니다. Seerr 3.4 이상이 필요합니다.',
			'seerr.notInitialized' => '이 Seerr 인스턴스는 최초 실행 설정을 완료하지 않았습니다',
			'seerr.noPlexTokenForReauth' => '다시 로그인하는 데 사용할 수 있는 Plex 토큰이 없습니다',
			'seerr.noStoredCredentials' => '다시 로그인하는 데 사용할 수 있는 저장된 인증 정보가 없습니다',
			'seerr.signInRejected' => '로그인이 거부되었습니다',
			'seerr.noSessionCookie' => 'Seerr에서 세션 쿠키를 발급하지 않았습니다',
			'seerr.freshCookieRejected' => 'Seerr에서 새 세션 쿠키를 거부했습니다',
			'seerr.noUserInformation' => 'Seerr에서 사용자 정보를 반환하지 않았습니다',
			'seerr.sessionRejectedAfterReauth' => '다시 로그인한 후 세션이 거부되었습니다',
			'seerr.permissionDenied' => 'Seerr가 이 작업을 거부했습니다: 계정에 필요한 권한이 더 이상 없습니다',
			'seerr.permissionRevoked' => '이 항목을 요청할 권한이 더 이상 없습니다',
			'services.title' => '서비스',
			'services.hubSubtitle' => '시청 진행률을 동기화하고 새 작품을 요청하세요.',
			'services.integrations' => '연동',
			'services.notConnected' => '연결되지 않음',
			'services.connectedAs' => ({required Object username}) => '@${username}(으)로 연결됨',
			'services.scrobble' => '진행률 자동 추적',
			'services.scrobbleDescription' => '에피소드나 영화를 시청하면 목록을 업데이트합니다.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} 연결을 해제하시겠습니까?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy가 ${service} 업데이트를 중지합니다. 언제든 다시 연결할 수 있습니다.',
			'services.connectFailed' => ({required Object service}) => '${service}에 연결할 수 없습니다. 다시 시도하세요.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Simkl 다시 연결',
			'services.simklReconnect.subtitle' => 'Simkl이 이 연결에 사용되는 로그인 방식을 종료합니다. 다시 연결하면 simkl.com이 열리고 그곳에서 Plezy를 승인합니다 — Plezy는 비밀번호를 볼 수 없습니다. 시청 기록은 Simkl에 그대로 유지됩니다.',
			'services.deviceCode.title' => ({required Object service}) => '${service}에서 PlezyNG 활성화',
			'services.deviceCode.instructions' => 'QR 코드를 스캔하거나 아래 주소로 이동하여 이 코드를 입력하세요:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '활성화하려면 ${service} 열기',
			'services.deviceCode.copyCode' => '활성화 코드 복사',
			'services.deviceCode.waitingForAuthorization' => '인증을 기다리는 중…',
			'services.deviceCode.codeCopied' => '코드가 복사되었습니다',
			'services.oauthProxy.title' => ({required Object service}) => '${service}에 로그인',
			'services.oauthProxy.body' => '이 QR 코드를 스캔하거나 아무 기기에서 URL을 여세요.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '로그인하려면 ${service} 열기',
			'services.pendingAuth.copyUrl' => '로그인 URL 복사',
			'services.pendingAuth.urlCopied' => 'URL이 복사되었습니다',
			'services.libraryFilter.title' => '라이브러리 필터',
			'services.libraryFilter.subtitleAllSyncing' => '모든 라이브러리 동기화 중',
			'services.libraryFilter.subtitleNoneSyncing' => '동기화 안 함',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count}개 차단됨',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count}개 허용됨',
			'services.libraryFilter.mode' => '필터 모드',
			'services.libraryFilter.modeBlacklist' => '차단 목록',
			'services.libraryFilter.modeWhitelist' => '허용 목록',
			'services.libraryFilter.modeHintBlacklist' => '아래에 선택한 라이브러리를 제외한 모든 라이브러리를 동기화합니다.',
			'services.libraryFilter.modeHintWhitelist' => '아래에 선택한 라이브러리만 동기화합니다.',
			'services.libraryFilter.libraries' => '라이브러리',
			'services.libraryFilter.noLibraries' => '사용 가능한 라이브러리가 없습니다',
			'services.libraryFilter.modeDescription' => '검사된 도서관이 동기화에서 차단되었는지, 아니면 동기화를 하는 유일한 라이브러리인지 선택합니다.',
			'services.seerrDescription' => 'Seerr 또는 Overseerr에 연결하여 제목을 검색하고 미디어 요청을 제출합니다.',
			'services.trackerDescriptions.trakt' => '트랙 계정과 함께 시청된 에피소드와 영화를 동기화합니다.',
			'services.trackerDescriptions.mal' => '애니메이션 목록을 동기화하고 MyAnimeList로 진행을 시청합니다.',
			'services.trackerDescriptions.anilist' => '애니메이션 목록을 동기화하고 AniList와 함께 진행을 지켜보십시오.',
			'services.trackerDescriptions.simkl' => 'Sync는 Simkl와 함께 영화, TV 쇼 및 애니메이션을 보았습니다.',
			'services.trackerDescriptions.mdblist' => '추천 및 탐색에서 MDBList 등급 및 목록을 표시합니다.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product} 서버 추가',
			'addServer.serverUrls' => '서버 URL',
			'addServer.serverUrlsHelper' => '쉼표로 구분하여 여러 URL을 입력할 수 있습니다.',
			'addServer.findServer' => '서버 찾기',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => '로컬 ${product} 서버를 찾는 중...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => '로컬 ${product} 서버',
			'addServer.username' => '사용자 이름',
			'addServer.password' => '비밀번호',
			'addServer.signIn' => '로그인',
			'addServer.change' => '변경',
			'addServer.required' => '필수',
			'addServer.couldNotReachServer' => ({required Object error}) => '서버에 연결할 수 없습니다: ${error}',
			'addServer.signInFailed' => ({required Object error}) => '로그인 실패: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect 실패: ${error}',
			'addServer.addPlexTitle' => 'Plex로 로그인',
			'addServer.pinExpired' => '로그인 전에 PIN이 만료되었습니다. 다시 시도하세요.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => '계정 등록 실패: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '${product} 서버 URL을 입력하세요',
			'addServer.addConnectionTitle' => '연결 추가',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name}에 추가',
			'addServer.signInWithPlexCard' => 'Plex로 로그인',
			'addServer.signInWithPlexCardSubtitle' => '이 기기를 승인합니다. 공유 서버가 추가됩니다.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex 계정을 승인합니다. Home 사용자는 프로필이 됩니다.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '${product}에 연결',
			'addServer.connectToMediaBrowserCardSubtitle' => '서버 URL, 사용자 이름, 비밀번호를 입력하세요.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '${product} 서버에 로그인하세요. ${name}에 연결됩니다.',
			'addServer.borrowFromAnotherProfile' => '다른 프로필에서 빌리기',
			'addServer.borrowFromAnotherProfileSubtitle' => '다른 프로필의 연결을 재사용합니다. PIN으로 보호된 프로필에는 PIN이 필요합니다.',
			'addServer.invalidCredentials' => '사용자 이름 또는 비밀번호가 올바르지 않습니다',
			'addServer.authResponseNotJson' => '인증 응답이 유효한 JSON이 아닙니다',
			'addServer.authResponseIncomplete' => '서버의 로그인 응답이 불완전합니다',
			'addServer.quickConnectRejected' => '서버에서 Quick Connect를 거부했습니다',
			'addServer.quickConnectNotJson' => 'Quick Connect 응답이 유효한 JSON이 아닙니다',
			'addServer.quickConnectMissingFields' => 'Quick Connect 응답에 코드 또는 비밀 키가 없습니다',
			'addServer.quickConnectPollRejected' => '서버에서 Quick Connect 폴링을 거부했습니다',
			'addServer.serverTimedOut' => '서버가 제시간에 응답하지 않았습니다',
			'addServer.responseNotJson' => '서버 응답이 유효한 JSON이 아닙니다',
			'addServer.responseMissingIdentity' => ({required Object product}) => '응답에 ID 또는 서버 이름이 없습니다. 이 서버가 ${product} 서버인가요?',
			'addServer.probeFailed' => ({required Object error}) => '서버에 연결할 수 없습니다: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => '${product} 서버 URL을 하나 이상 입력하세요',
			'addServer.noReachableServer' => ({required Object product}) => '연결 가능한 ${product} 서버를 찾을 수 없습니다',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => '이 URL들은 서로 다른 ${product} 서버를 가리킵니다',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => '이 URL은 ${product} 서버와 일치하지 않습니다',
			'addServer.redirectUnsupported' => '서버가 지원되지 않는 URL로 리디렉션했습니다',
			'addServer.redirectDifferentHost' => ({required Object product}) => '서버가 다른 호스트로 리디렉션했습니다. 최종 ${product} URL을 직접 입력하세요.',
			'addServer.redirectInsecure' => '서버가 HTTPS에서 안전하지 않은 URL로 리디렉션했습니다',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => '서버가 지원되지 않는 URL로 리디렉션했습니다. 최종 ${product} URL을 직접 입력하세요.',
			'addServer.directPlexServerUrl' => 'Plex 서버 URL',
			'addServer.directPlexServerUrlHelper' => 'Plex 미디어 서버의 로컬 IP 및 포트를 입력합니다.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex 토큰 (선택)',
			'addServer.plexTokenHelper' => 'Auth 없이 액세스할 수 있는 경우 이 서버에서 빈으로 남겨 두십시오.',
			'addServer.plexTokenRequired' => '확인이 필요합니다. Plex 토큰 (X-Plex-Token)을 입력하시기 바랍니다.',
			'addServer.connectDirectPlexCard' => 'Plex 미디어 서버 (직접 / 지역)',
			'addServer.connectDirectPlexCardSubtitle' => 'plex.tv 계정 없이 지역 IP 또는 URL을 사용하여 직접 연결합니다.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'IP 또는 URL을 사용하여 직접 연결합니다. ${name}에 연결합니다.',
			'addServer.insecureTitle' => '암호화되지 않은 연결',
			'addServer.insecureDescription' => ({required Object url}) => '${url}은(는) HTTP를 사용합니다. 네트워크의 다른 사용자가 비밀번호, 토큰 및 미디어를 읽거나 변경할 수 있습니다. 가능하면 HTTPS를 사용하세요. 이 네트워크를 신뢰하고 위험을 감수하는 경우에만 계속하세요.',
			'addServer.allowHttp' => 'HTTP 허용',
			'addServer.httpsRequired' => 'HTTPS 또는 명시적으로 암호화되지 않은 연결을 허용합니다.',
			'cast.chooseDevice' => '장치에 던져',
			'cast.searching' => '기계를 찾는 것에 대한 검색...',
			'cast.connectedTo' => ({required Object device}) => '${device}에 연결된',
			'cast.device' => '장치 캡처',
			'cast.readyToCast' => '던져질 준비',
			'cast.subtitle' => '자막',
			'cast.serverNotAvailable' => '미디어 서버는 사용할 수 없습니다.',
			'cast.stopCasting' => '카스팅을 멈추세요',
			'cast.castToDevice' => '장치에 던져',
			'cast.noEpisodeAvailable' => '촬영할 에피소드가 없습니다.',
			'cast.startFailed' => '캐스트를 시작할 수 없습니다. 서버를 확인하고 다시 시도하세요.',
			'automation.noActivePlayback' => '통제할 수 있는 비디오 세션은 없습니다.',
			'notifications.newEpisodeTitle' => '새로운 에피소드',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => '7일 동안 무료로 모든 기능을 시도해 보세요.',
			'appAccess.description' => '모든 PlezyNG 기능에 대한 완전한 액세스를 가진 7일간의 시험을 시작합니다. 시험 중에는 수수료가 없으며 구독이 없습니다. 시험 후에 매장 가격에 한 생명 구매가 PlezyNG를 생명으로 닫습니다.',
			'appAccess.trialEndedDescription' => '매장 가격에 한 번 구매하여 PlezyNG에서 모든 기능을 잠그십시오.',
			'appAccess.startTrial' => '내 7 일 무료 시험을 시작합니다.',
			'appAccess.trialActive' => '7일간의 완전한 실험은 활성화됩니다.',
			'appAccess.trialEnded' => '7일간의 재판이 끝났다.',
			'appAccess.trialStartFailed' => '이 장치에서 테스트를 저장할 수 없었습니다. 다시 시도해 주십시오.',
			'appAccess.lifetimeTitle' => 'PlezyNG 생명을 위해 잠금을 꺼내',
			'appAccess.lifetimeBody' => '감사합니다!당신은 모든 PlezyNG 기능에 평생 액세스 할 수 있습니다.',
			'appAccess.manageTitle' => 'PlezyNG 평생 액세스',
			'appAccess.manageDescription' => '7 일 동안 모든 기능을 무료로 시도하고, 한 번의 지불으로 매장 가격으로 모든 것을 잠그십시오.',
			'appAccess.buy' => ({required Object price}) => '모든 기능을 ${price}에 대 한 끄기',
			'appAccess.loadingPrice' => '짐 가게 가격...',
			'appAccess.retryPrice' => '리트리 가격 검색',
			'appAccess.restore' => '생명 구매 복원',
			'appAccess.pending' => '귀하의 구매는 지불 또는 승인을 기다리고 있습니다.인생 접근은 상점이 완료되면 잠금됩니다.',
			'appAccess.storeUnavailable' => '구매가 없습니다.이 장치에서 구매가 허용되고 상점에 가입하고 있는지 확인합니다.',
			'appAccess.productNotFound' => 'PlezyNG 생명 잠금은 아직 이 가게에서 사용할 수 없습니다.',
			'appAccess.productQueryFailed' => '가게 가격을 충전 할 수 없습니다. 연결을 확인하고 다시 시도하십시오.',
			'appAccess.purchaseFailed' => '구매가 끝나지 않았는데 다시 한번 시도해 보세요.',
			'appAccess.restoreFailed' => '당신의 구매를 복구하기 위해 상점에 도달 할 수 없습니다.다시 시도하십시오.',
			'appAccess.nothingToRestore' => 'No. PlezyNG 생명 구매는 이 가게 계정에서 찾을 수 있습니다.',
			'detail.endsAt' => ({required Object time}) => '${time}에 종료',
			'watchLink.serverUnavailable' => '이 링크를 위해 Plex 서버에 접근할 수 없었습니다.',
			'watchLink.notFound' => '이 쇼 또는 영화를 Plex 서버에서 찾을 수 없습니다.',
			'watchLink.ambiguous' => '이 링크는 하나 이상의 서버에 항목과 일치합니다.이 링크에 서버를 추가합니다.',
			'watchLink.plexOnly' => '현재 Plex 서버만 지원하는 링크를 확인합니다.',
			'watchLink.unsupportedItem' => '링크를 볼 수 있는 쇼 또는 영화만 열 수 있습니다.',
			'watchLink.menuItem' => '링크 보기 보기',
			'watchLink.dialogTitle' => '링크 보기',
			'watchLink.dialogShowHint' => '이 링크를 열면 다음 에피소드를 재생합니다. &mode=shuffle을 끝까지 추가하여 shuffle에서 쇼를 재생합니다',
			'watchLink.dialogMovieHint' => '이 링크를 열면 영화를 재생합니다.',
			'watchLink.copy' => '복사본',
			'watchLink.copied' => '링크 복사',
			'homeLayout.title' => '홈 레이아웃',
			'homeLayout.resetToast' => '홈 다시 원래 Plezy 영웅 레이아웃으로 설정',
			'homeLayout.resetHeroTitle' => '영웅 레이아웃을 주식으로 다시 설정할 수 있습니까 Plezy?',
			'homeLayout.resetHeroBody' => '각 라인의 영웅 설정을 끄고 홈의 상단에있는 단일 회전 밴드를 반환합니다, 영웅 라인이 존재하기 전과 마찬가지입니다.',
			'homeLayout.removeRowTitle' => '홈 화면의 행을 삭제할까요?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} 삭제될 것입니다.이것은 무시할 수 없습니다.',
			'homeLayout.sync' => '시나리오',
			'homeLayout.syncAccountTitle' => 'Plex 계정과 동기화된 배열',
			'homeLayout.syncAccountOn' => '이 장치는 다른 장치와 순서, 순서, 영웅 및 자동 슬라이드를 공유합니다.',
			'homeLayout.syncAccountOff' => '끄기: 이 장치는 자신의 레이아웃을 유지합니다.',
			'homeLayout.syncNow' => '지금 시너먼트',
			'homeLayout.plexHomeManager' => 'Plex 홈 관리자',
			'homeLayout.managePlexRows' => '관리 Plex 라인 Plezy',
			'homeLayout.managePlexRowsDescription' => '홈 선택된 라인을 조직하기 위해 열려 있습니다.',
			'homeLayout.organizeHomeRows' => '홈 라인 조직',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} 라인: 이동, 영웅, 자동 슬라이드, 제거',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '${library} 라인을 조직',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => '계속 보기 + ${n} 라인: 이동, 도서관, 홈, 영웅, 자동 슬라이드',
			'homeLayout.renderAsHero' => '영웅 카드로 렌더',
			'homeLayout.heroOnlySingleCollection' => '이 순서가 단일 컬렉션의 실제 제목에 해결되면만 사용할 수 있습니다.',
			'homeLayout.hero' => '히어로',
			'homeLayout.autoSlide' => '자동 슬라이드',
			'homeLayout.autoSlideDescription' => '또한 몇 초마다 스스로 슬라이드합니다. 링 (PC) 및 d-pad (TV)는 항상 작동하고 타이머를 다시 시작합니다.',
			'homeLayout.autoSlideEditDescription' => '또한 몇 초마다 스스로 슬라이드합니다. 끄기 : 펜 (PC)을 클릭하거나 원격 (TV)에서 왼쪽/오른쪽을 누르면 움직입니다.',
			'homeLayout.enableHeroFirst' => '영웅을 먼저 할 수 있습니다.',
			'homeLayout.showOnHome' => 'Home 스크린에 표시',
			'homeLayout.home' => '홈',
			'homeLayout.removeFromHome' => '집에서 제거',
			'homeLayout.selectRowsFirst' => '먼저 아래의 홈 라인을 선택합니다.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex 관리 라인',
			'homeLayout.continueWatching' => '계속 시청',
			'homeLayout.continueWatchingLibraryDescription' => '이 도서관의 자체 재구성-진보 순서',
			'homeLayout.continueWatchingHomeDescription' => 'Home에 표시된 재현 진행 순서',
			'homeLayout.nextUpHomeDescription' => '다음 무시된 에피소드 순서가 집에서 별도로 표시됩니다.',
			'homeLayout.library' => '라이브러리',
			'homeLayout.showInRecommended' => '추천 도서관에서 제공하는',
			'homeLayout.customPlexRow' => '사용자 정의 Plex 라인',
			'homeLayout.heroNeedsLibrary' => '도서관을 먼저 확인하십시오 - 영웅은 어디서나 보여줄 필요가 있습니다.',
			'homeLayout.heroNeedsSurface' => '도서관 또는 홈을 먼저 확인하십시오 - 영웅은 어디서나 보여야합니다.',
			'homeLayout.removeHub' => 'Hub 삭제',
			'homeLayout.noPlexRows' => 'No. Plex 관리 라인이 이 도서관에 반환되었습니다.',
			'homeLayout.openDetails' => '개방된 세부 사항',
			'homeLayout.heroCards' => '영웅 카드',
			'homeLayout.tapHeroCard' => '히어로 카드를 탭할 때',
			'homeLayout.tvPlayFocus' => 'TV 원격: 히틀러 플레이 버튼',
			'homeLayout.tvPlayFocusDescription' => 'D-pad 아래는 다음 라인으로 이동하기 전에 플레이 버튼을 멈추고 다음 라인에 직접 스키를 끄십시오.',
			'homeLayout.tvWrap' => 'TV 원격: 롤 영웅 카드',
			'homeLayout.tvWrapDescription' => '마지막 카드에 바로 첫 번째 카드로 돌아갑니다. 마지막 카드에서 멈추는. 첫 번째 카드에 왼쪽은 항상 측면 바로 이동합니다.',
			'homeLayout.castOnHero' => '영웅의 밴더에 대한 헌신',
			'homeLayout.castOnHeroDescription' => '영웅의 바나나의 바닥을 따라 촬영을 보여줍니다.오프는 제목과 요약만 유지합니다.',
			'homeLayout.customRows' => 'Custom 라인',
			'homeLayout.loading' => '홈 리디렉션을 위한 ...',
			'homeLayout.noCustomRows' => '아직 흔적이 없음',
			'homeLayout.addRowHint' => 'Home 라인을 추가하여 하나를 만들 수 있습니다.',
			'homeLayout.addHomeRow' => 'Home 라인 추가',
			'homeLayout.addHomeRowDescription' => '카테고리를 선택; 새 라인은 자동으로 조직에 추가됩니다.',
			'homeLayout.removeRow' => '라인 삭제',
			'homeLayout.recentlyAdded' => '최근에 추가됨',
			'homeLayout.recentlyReleased' => '최근에 출시된',
			'homeLayout.movieCollections' => '영화 컬렉션',
			'homeLayout.showCollections' => '컬렉션 보기',
			'homeLayout.rowTitle' => '로이 제목',
			'homeLayout.content' => '흥미로운',
			'homeLayout.showThisRowIn' => '이 라인을 보여주십시오 :',
			'homeLayout.libraryRecommended' => '추천 도서관',
			'homeLayout.heroCard' => '영웅 카드',
			'homeLayout.heroCardDescription' => '포스터 셰프 대신 하나의 전체 광장 회전 카드로 표시됩니다.',
			'homeLayout.heroUnavailableDescription' => '이 순서가 단일 컬렉션의 실제 제목에 해결될 때만 사용할 수 있습니다 - 선택된 컬렉션 이상이 있는 경우에는 단일 제목이 롤러가 없습니다.',
			'homeLayout.librariesSelection' => '도서관 (모든 도서관을 포함하기 위해 모든 검사되지 않은 것을 남겨 두십시오)',
			'homeLayout.librariesMergedDescription' => '여기서 확인한 모든 도서관은 이 한 줄에 합쳐집니다.',
			'homeLayout.movieCollectionsSelection' => '영화 컬렉션 (모든 선택된 도서관에 대한 모든 검사되지 않은 것을 남겨두십시오)',
			'homeLayout.showCollectionsSelection' => '컬렉션을 표시합니다 (선택된 각 도서관에 대한 모든 검사되지 않은 것을 남겨 두십시오)',
			'homeLayout.collectionRowsDescription' => '만약 정확히 하나의 컬렉션이 일치한다면, 그 제목이 순서대로 표시됩니다. 만약 하나 이상의 컬렉티션이 일어나면, 각 컬렉션은 단일 포스터로 표시됩니다.',
			'homeLayout.allCollections' => '모든 컬렉션',
			'homeLayout.noRowsHere' => '아직 여기에는 라인이 없습니다.',
			'homeLayout.hideWatchedRows' => '흔들리는 흔들림으로 덮여 있는 물건들',
			'homeLayout.hideWatchedRowsDescription' => '완전히 보낸 제목은 홈 및 도서관 추천 라인을 떠나 있습니다.',
			'homeLayout.untitledCollection' => '제목 없는 컬렉션',
			'homeLayout.moveRowHint' => '위/다운: 이동 순서 · 선택: 여기에서 던져 · 반환: 취소',
			'homeLayout.organizeRowsHint' => '좌석/오른쪽: 순서 옵션 · 뒤로: 완료',
			'homeLayout.layoutNavDescription' => '라인, 도서관 및 컬렉션 카테고리를 선택합니다.',
			'homeLayout.editHomeRow' => '에디트 홈 라인',
			'homeLayout.resetHeroButton' => '영웅 레이아웃을 재설정 하 고 주식 Plezy',
			'homeLayout.reorderingUnlocked' => '다시 닫힌',
			'homeLayout.reorderingLocked' => '잠금을 다시 닫습니다',
			'homeLayout.rowsCanBeDragged' => '끈을 끌 수 있습니다 - 잠금을 눌러 그것을 방지합니다.',
			'homeLayout.tapLockToDrag' => '닫기 를 눌러 라인을 끌어내기',
			'homeLayout.customRowLabel' => ({required Object title}) => '사용자 정의: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => '숨기기',
			'homeLayout.remove' => '제거',
			'homeLayout.libraryResumeRow' => '이 도서관의 재구성 순서',
			'homeLayout.pressAgainToDelete' => '다시 눌러 삭제',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => '에',
			'homeLayout.resetHeroButtonDescription' => '각 라인의 영웅 설정을 끄고 영웅 라인이 존재하기 전과 마찬가지로 상단에 단일 회전 밴드를 반환합니다.',
			'homeLayout.tapHeroCardDescription' => '영웅 카드를 탭하거나 선택하면 재생이 시작되거나 세부 사항이 열립니다.',
			'homeLayout.heroTapPlayDescription' => '선택한 항목을 즉시 시작합니다.',
			'homeLayout.heroTapDetailsDescription' => '선택한 항목의 세부 사항을 열기 전에 행동을 선택합니다.',
			'platform.localNetworkPermission' => 'PlezyNG은 현지 네트워크에서 미디어 서버 및 플레이백 장치에 연결됩니다.',
			'platform.locationPermission' => 'PlezyNG는 로컬 네트워크를 찾고 미디어 서버에 연결하는 데 iOS가 요구하는 경우 위치 접근 권한을 사용합니다.',
			'platform.photoLibraryPermission' => '사진 보관함에서 미디어 아트워크로 사용할 이미지를 선택하세요.',
			'platform.cameraPermission' => 'QR 코드를 스캔하여 Companion Remote를 연결합니다.',
			'universalMedia.title' => '오픈 미디어',
			'universalMedia.shortcutHelp' => '이 세션에 대한 링크, 플레이리스트 또는 파일을 재생합니다.',
			'universalMedia.intro' => 'Playback은 PlezyNG의 표준 플레이어를 사용하고 도서관에 역사를 추가하지 않습니다.',
			'universalMedia.openWhat' => '무엇을 열고 싶으신가요?',
			'universalMedia.stream' => '흐름 주소',
			'universalMedia.playlist' => '플레이리스트',
			'universalMedia.files' => '장치 파일',
			'universalMedia.favorites' => '저장된 스트림 좋아하는',
			'universalMedia.address' => '미디어 주소',
			'universalMedia.addressHelp' => '인증 또는 서명 매개 변수를 가진 URL은 이 세션에만 사용되며 좋아하는 것으로 저장될 수 없습니다.',
			'universalMedia.displayName' => '디스플레이 이름 (선택)',
			'universalMedia.displayNameHelp' => '플레이어 및 시스템 미디어 컨트롤에 대한 짧은 이름을 선택합니다.',
			'universalMedia.allowHttp' => '암호화되지 않은 HTTP 연결을 허용',
			'universalMedia.allowHttpHelp' => 'HTTP는 연결을 암호화하지 않습니다. 신뢰할 수 있는 네트워크에서만 허용합니다. 가능한 경우 HTTPS를 사용하십시오.',
			'universalMedia.advancedProtocols' => 'MPV만: RTSP, RTMP/RTMPS, UDP 또는 RTP 주소를 입력합니다.이 주소는 좋아하는 주소로 저장할 수 없습니다.',
			'universalMedia.liveStream' => '살아있는 것처럼 행동하라',
			'universalMedia.liveStreamHelp' => '이것을 라이브 비디오 또는 라디오에 사용하십시오.이 응용 프로그램은 시간표, 스키 버튼 및 go-to-time 옵션을 숨깁니다.',
			'universalMedia.privateSession' => '이 플레이백만이 주소를 사용합니다.이 프로필에 보관하기 위해 자격을 갖춘 스트림 좋아하는 것을 저장합니다.',
			'universalMedia.saveFavorite' => '좋아하는 저장',
			'universalMedia.playNow' => '지금 플레이',
			'universalMedia.favoriteSaved' => 'Stream Favorite 이 프로필에 저장',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '스키피드 ${count} 지원되지 않거나 불안정한 플레이리스트 입력.', other: '${count} 지원되지 않거나 불안정한 플레이리스트 입력을 벗어났습니다.', ), 
			'universalMedia.playlistAddress' => '플레이리스트 주소',
			'universalMedia.playlistAddressHelp' => '웹 주소에서 M3U, M3u8 또는 PLS 플레이리스트를 열 수 있습니다.Direct stream 링크는 플레이 리스트를 저장하지 않습니다.',
			'universalMedia.choosePlaylist' => '플레이리스트 파일 선택',
			'universalMedia.openPlaylist' => '오픈 플레이리스트',
			'universalMedia.playlistFormatsHelp' => '플레이리스트는 최대 1,000 개의 항목과 2 MB를 포함할 수 있습니다.HLS는 스트림으로 열려 있으므로 플레이어가 품질을 선택할 수 있도록합니다.',
			'universalMedia.saveQueuePlaylist' => '대기열을 재생목록으로 저장',
			'universalMedia.queuePlaylistSaved' => '재생목록을 미디어 파일 옆에 저장했습니다.',
			'universalMedia.queuePlaylistUnavailable' => '이 대기열은 재사용 가능한 로컬 재생목록으로 저장할 수 없습니다.',
			'universalMedia.queuePlaylistFolderRequired' => '대기열 파일과 같은 폴더를 저장 위치로 선택하세요.',
			'universalMedia.noFavorites' => '아직 좋아하는 스트림을 저장하지 않았습니다.Favorites 이 프로필에 남아 있습니다.',
			'universalMedia.removeFavorite' => '좋아하는 스트림을 제거',
			'universalMedia.filesHelp' => '오디오, 비디오 또는 ISO 파일을 일시적인 쿼드를 선택합니다.파일 및 URL은 도서관 역사에 추가되지 않습니다.',
			'universalMedia.chooseFiles' => '파일 선택',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '1 선택된 파일', other: '${count} 선택된 파일', ), 
			'universalMedia.wifiTransfer' => 'Wi-Fi를 통해 파일을 보내기',
			'universalMedia.wifiTransferHelp' => '동일한 신뢰할 수 있는 네트워크에서 브라우저에서 지원된 파일을 전송합니다.',
			'universalMedia.wifiTransferIntro' => '다른 장치에서 브라우저에서 이 주소를 열어 파일을 선택하여 이 장치의 파일 및 책 라이브러리에 추가합니다.',
			'universalMedia.wifiTransferPrivacy' => '이 장치는 현지 네트워크를 통해 파일을 수신합니다.이 주소를 아는 사람은 전송을 중단하거나 15 분 후에 주소가 만료 될 때까지 파일을 보낼 수 있습니다.',
			'universalMedia.wifiTransferStarting' => '개인적, 시간 제한된 전송을 준비하는 ...',
			'universalMedia.wifiTransferUnavailable' => '전송을 시작할 수 없습니다. 로컬 네트워크 액세스를 확인하고 다시 시도합니다.',
			'universalMedia.openThisAddress' => '이 주소 중 하나를 전송 장치에서 열어보세요.',
			'universalMedia.copyAddress' => '전송 주소 복사',
			'universalMedia.addressCopied' => '전송 주소 복사',
			'universalMedia.transferExpires' => ({required Object time}) => '이 주소는 ${time}에서 만료됩니다.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${count} 파일 수신', other: '${count} 파일 수신', ), 
			'universalMedia.uploadedData' => ({required Object size}) => '수신 ${size}',
			'universalMedia.stopTransfer' => '전송 중지 및 주소 취소',
			'universalMedia.startTransfer' => '전송 시작',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi 전송',
			'universalMedia.wifiBrowserTitle' => '파일을 PlezyNG로 보내기',
			'universalMedia.wifiBrowserIntro' => '이 장치의 파일 및 책 라이브러리에 저장됩니다. 최대: 100 파일, 파일 당 4 GiB, 총 10 GiB.',
			'universalMedia.uploadFilesLabel' => '보내기 위한 파일',
			'universalMedia.uploadSelected' => '선택한 파일을 업로드',
			'universalMedia.uploadSelectFirst' => '먼저 하나 이상의 파일을 선택합니다.',
			'universalMedia.uploading' => '보내기',
			'universalMedia.uploadComplete' => '파일이 PlezyNG에 추가되었습니다.',
			'universalMedia.uploadFailed' => '이 페이지를 열고 다시 시도하십시오.',
			'universalMedia.liveCue' => '라이브',
			'universalMedia.liveSession' => '라이브 스트림',
			'universalMedia.liveCueHelp' => '라이브 비디오 또는 라디오를 위해, 앱은 시간표를 숨기고 스키 버튼.그것은 주소를 저장하거나 기록을 보지 않습니다.',
			'universalMedia.sessionOnly' => '이 플레이백은 세션에만',
			'universalMedia.sessionOnlyHelp' => 'Playback은 진보 또는 역사를 절대 저장하지 않습니다.이 프로필에 보관하기 위해 좋아하는 스트림을 저장하십시오.',
			'universalMedia.pictureAdjustments' => '사진 조정',
			'universalMedia.pictureHelp' => '이러한 이미지 변경은이 재생에만 영향을 미칩니다.그들은 재생이 끝날 때 다시 설정됩니다.',
			'universalMedia.resetPicture' => '사진 재설정',
			'universalMedia.brightness' => '밝기',
			'universalMedia.contrast' => '대조점',
			'universalMedia.gamma' => '가마',
			'universalMedia.hue' => '하우스',
			'universalMedia.saturation' => '토성화',
			'universalMedia.view360' => '360° 비디오를 위한 평평한 전망',
			'universalMedia.view360Help' => 'MPV는 FFmpeg의 v360 필터가 필요합니다.',
			'universalMedia.view360Unavailable' => '이 MPV 구축은 360° 필터를 적용 할 수 없습니다.',
			'universalMedia.view360Yaw' => '수평 전망',
			'universalMedia.view360Pitch' => 'Vertical 전망',
			'universalMedia.view360FieldOfView' => '시야의 영역',
			'universalMedia.recordStream' => '레코드 라이브 스트림',
			'universalMedia.stopRecording' => '녹음을 멈추고 저장',
			'universalMedia.recordingStarted' => '녹음은 활성화됩니다.Leaving playback stops and saves the recording.',
			'universalMedia.recordingSaved' => '녹음이 완료되고 저장되었습니다.',
			'universalMedia.recordingActive' => '이 장치를 기록하십시오.Playback을 남기면 멈추고 저장됩니다.',
			'universalMedia.recordingFormatHelp' => '비디오를 위해 MKV 또는 MPEG-TS를 선택합니다.오디오를 위한 경우 MKA 또는 MKV를 선택하십시오.',
			'universalMedia.replaceRecordingTitle' => '이 레코드를 대체할 수 있나요?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG는 녹음하는 동안 기존 파일을 복구합니다. 새 녹음을 저장할 수 없다면 Plezy NG는 백업을 복원합니다.',
			'universalMedia.replaceRecording' => '파일 교체',
			'universalMedia.discHelp' => '이 컴퓨터의 광학 드라이브에서 디스크를 열 수 있습니다 장치 파일에서 ISO 이미지를 열 수 있음.',
			'universalMedia.discs' => '광학 디스크',
			'universalMedia.editionOrTitle' => '에디션 또는 디스크 제목',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => '블루레이',
			'universalMedia.audioCd' => '오디오 CD',
			'universalMedia.discAvailability' => '디스크 재생에는 호환되는 MPV 구축, 지원된 드라이브 및 운영 체제 허가가 필요합니다.그것은 상업적인 디스크 보호를 초과할 수 없습니다.',
			'universalMedia.converterTitle' => '현지 미디어 파일을 변환',
			'universalMedia.converterHelp' => '현지 파일을 변환하거나 로컬 파일로 재구성하십시오. FFmpeg그리고',
			'universalMedia.converterIntro' => '지역 오디오 또는 비디오 파일을 여러 장치에서 작동하는 형식으로 변환합니다.',
			'universalMedia.converterPrivacy' => 'FFmpeg는이 컴퓨터에 설치되어야합니다.Conversion은 로컬 파일만 읽습니다.그것은 스트림을 다운로드하거나 DRM을 제거하지 않습니다.',
			'universalMedia.converterChooseInput' => '지역 미디어 파일 선택',
			'universalMedia.converterFormat' => '출력 형식',
			'universalMedia.converterMp4' => 'MP4 · H.264 및 AAC',
			'universalMedia.converterM4a' => 'M4A · AAC 오디오',
			'universalMedia.converterMp3' => 'MP3 오디오',
			'universalMedia.allowFtp' => 'FTP 허용',
			'universalMedia.allowFtpHelp' => 'FTP는 암호화 없이 미디어를 보내고 신뢰할 수 있는 네트워크에서만 사용합니다.',
			'universalMedia.converterSaveAs' => '변환된 미디어를 저장하는 방법',
			'universalMedia.converterExtensionMismatch' => '선택한 출력 확장을 가진 파일 이름을 선택합니다.',
			'universalMedia.converterUnsupportedInput' => '오디오 또는 비디오 파일을 선택합니다.',
			'universalMedia.converterLocalOnly' => '선택한 파일은 현지 장치 경로로 사용할 수 없습니다.',
			'universalMedia.converterReplaceTitle' => '이 파일을 교체할 수 있나요?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG은 변환 된 복사본이 저장 될 때까지 기존 파일을 복구합니다.',
			'universalMedia.converterStarting' => 'FFmpeg를 시작합니다.',
			'universalMedia.converterProgress' => '이 컴퓨터로 변환하는 ...',
			'universalMedia.converterComplete' => '변환이 완료되었습니다.새 파일은 준비되어 있습니다.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg 이 포맷이 없거나 지원되지 않습니다.',
			'universalMedia.converterFailed' => '변환이 실패했습니다.원본 파일이 읽을 수 있는지 확인하고 목적지가 충분한 공간을 갖추고 있음을 확인합니다.',
			'universalMedia.converterCancelled' => '변환이 취소되었습니다 불완전한 출력은 제거되었습니다.',
			'universalMedia.converterDesktopOnly' => '현지 변환은 FFmpeg 설치를 가진 데스크톱 컴퓨터에서 사용할 수 있습니다.',
			'universalMedia.converterStart' => '파일 변환',
			'universalMedia.mediaToolsTitle' => '미디어 도구',
			'universalMedia.mediaToolsShortcut' => '미디어를 캡처하거나 공유하거나 검색 확장 프로그램을 추가하거나 명령 라인을 사용합니다.',
			'universalMedia.mediaToolsIntro' => '이 데스크톱에 설치된 FFmpeg을 캡처하고 스트림을 사용합니다. 확장 및 CLI 명령은 제한된 HTTPS 요청과 기존의 Open media 흐름을 사용합니다.',
			'universalMedia.mediaToolsAccessibility' => '도구 선택 및 컨트롤은 터치, 지표, 키보드 및 D-pad 초점으로 작동합니다. 레코딩, 공유 및 검색 상태 변경이 발표됩니다.',
			'universalMedia.mediaTool' => '미디어 도구',
			'universalMedia.captureIntro' => 'Record your screen or a camera to an MP4 file on this computer. FFmpeg must be installed and include the H.264 encoder.',
			'universalMedia.captureNoDevices' => '스크린이나 카메라가 찾을 수 없습니다. FFmpeg 캡처 지원 및 운영 체제 개인 정보 보호 허가를 확인합니다.',
			'universalMedia.captureSource' => '스크린 또는 카메라',
			'universalMedia.captureScreen' => '스크린',
			'universalMedia.captureAudioSource' => '오디오 입력 (옵션)',
			'universalMedia.captureAudioHelp' => '마이크 또는 사용 가능한 입력에서 오디오를 추가합니다. 장치 선택은 FFmpeg 및 시스템 허가에 따라 달라집니다.',
			'universalMedia.captureAudioNone' => '오디오 없음',
			'universalMedia.captureDefaultAudio' => '기본 오디오 입력',
			'universalMedia.captureWaylandHelp' => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.',
			'universalMedia.captureFrameRate' => '녹음 프레임 속도',
			_ => null,
		} ?? switch (path) {
			'universalMedia.capturePrivacy' => '녹음은 선택한 파일에만 저장됩니다.마이크로폰 캡처는 선택적입니다.PlezyNG은 녹음을 업로드하지 않습니다.',
			'universalMedia.captureSaveAs' => '스크린 레코딩을 저장하는 방법',
			'universalMedia.captureExtensionMismatch' => '.mp4에서 끝나는 파일 이름을 선택합니다.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg 또는 H.264 비디오 암호는 사용할 수 없습니다. 지원되는 FFmpeg 건물을 설치하고 다시 시도합니다.',
			'universalMedia.captureFailed' => '녹음은 저장할 수 없었습니다. 장치 허가, 사용 가능한 저장소 및 FFmpeg 지원을 확인합니다.',
			'universalMedia.captureSaved' => '스크린 녹음이 저장되었습니다.',
			'universalMedia.captureElapsedLabel' => '녹음 시간',
			'universalMedia.captureStart' => '녹음 시작',
			'universalMedia.capturePreview' => '플레이어에서 미리 보기',
			'universalMedia.capturePreviewHelp' => '선택한 소스를 기본 플레이어에서 미리 봅니다. 미리 보기는 현재 세션에서만 재생되며 녹화물을 저장하지 않습니다. 기기 지원과 권한은 MPV 및 운영체제에 따라 다릅니다. 미리 보기에는 비디오만 사용되며, 저장되는 녹화물에는 선택적으로 오디오를 포함할 수 있습니다.',
			'universalMedia.capturePreviewActive' => '실시간 미리 보기 · 녹화 중 아님',
			'universalMedia.captureStop' => '멈추고 저장',
			'universalMedia.captureMode' => '캡처',
			'universalMedia.shareMode' => '공유하기',
			'universalMedia.shareIntro' => '귀하의 개인 네트워크에서 다른 장치에 지역 미디어 파일을 보내십시오.PlezyNG은 일시적인 HLS 스트림을 생성합니다.',
			'universalMedia.sharePrivacy' => '귀하의 지역 네트워크에 있는 개인 링크를 받는 사람은 개인 링크가 활성화되는 동안 관찰할 수 있습니다. 링크는 60분 후에 만료됩니다. 공유를 중단하여 서버를 닫고 링크를 취소합니다.',
			'universalMedia.shareChooseFile' => '미디어 파일 선택',
			'universalMedia.shareChooseHelp' => '지역 오디오 또는 비디오 파일을 선택합니다.이 파일은이 컴퓨터에 남아 있습니다.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg 또는 H.264/AAC 암호가 사용할 수 없습니다. FFmpeg을 H.264 및 AAC 암호 지원으로 설치합니다.',
			'universalMedia.shareFailed' => '흐름은 예기치 않게 시작되거나 중지되지 않았습니다. FFmpeg 및 네트워크 액세스를 확인하십시오.',
			'universalMedia.shareActive' => '스트림은 개인 네트워크에서 준비되어 있습니다.',
			'universalMedia.shareEnded' => '미디어는 끝에 도달하고 더 이상 공유되지 않습니다.',
			'universalMedia.shareStopped' => '공유 중단되었습니다.시용 링크는 더 이상 유효하지 않습니다.',
			'universalMedia.shareUrlCopied' => '흐름 주소 복사',
			'universalMedia.shareOpenUrl' => '다른 장치에서 플레이어에서 이 주소를 열어',
			'universalMedia.shareQrLabel' => '임시 스트림 주소에 대한 QR 코드',
			'universalMedia.shareQrHelp' => '동일한 개인 네트워크에 연결된 호환 플레이어를 사용하여 스캔합니다.',
			'universalMedia.shareHttpHint' => '이 스트림은 암호화되지 않은 HTTP을 사용합니다. PlezyNG에서는 HTTP을 열기 전에 허용합니다.',
			'universalMedia.shareCopyUrl' => '스트림 주소 복사',
			'universalMedia.shareExpiresLabel' => '링크가 끝나고',
			'universalMedia.shareStarting' => '흐름을 준비하는 ...',
			'universalMedia.shareStart' => '공유 시작',
			'universalMedia.shareStop' => '공유 중지',
			'universalMedia.extensionsMode' => '확장 및 CLI',
			'universalMedia.extensionsIntro' => '미디어를 찾기 위해 데이터만 검색 확장을 추가합니다. 결과를 선택하여 익숙한 Open media 양식으로 업로드합니다.',
			'universalMedia.extensionsPrivacy' => '메니지스트는 하나의 HTTPS 검색 엔드 포인트와 지도 응답 필드를 정의 할 수 있습니다.그것은 코드를 실행 할 수 없습니다, 요청 헤드, 읽기 파일, 또는 시작 셔틀 명령.',
			'universalMedia.extensionImport' => '추가 확장 표시',
			'universalMedia.extensionEmpty' => '아직 검색 서비스가 없습니다. 신뢰할 수 있는 메시지 JSON 파일을 선택하여 하나를 추가합니다.',
			'universalMedia.extensionChoose' => '검색 서비스',
			'universalMedia.extensionSearchConsent' => '각 검색은 이 HTTPS 서비스에 귀하의 단어를 보냅니다.결과는 하나를 선택한 후에만 열립니다.',
			'universalMedia.extensionSearchLabel' => '미디어 검색',
			'universalMedia.extensionSearch' => '검색',
			'universalMedia.extensionSearching' => '검색...',
			'universalMedia.extensionNoResults' => '안전한 미디어 결과가 반환되지 않았습니다.다른 검색을 시도하십시오.',
			'universalMedia.extensionInstallTitle' => '이 검색 서비스를 추가하십시오?',
			'universalMedia.extensionReplaceTitle' => '이 검색 서비스 업데이트?',
			'universalMedia.extensionService' => '서비스',
			'universalMedia.extensionEndpoint' => 'HTTPS 최종 포인트',
			'universalMedia.extensionConsent' => '귀하의 검색 텍스트가 이 서비스에 전송됩니다. 메니지에는 실행 가능한 코드가 없습니다.이 끝점에 신뢰하는 경우에만 계속하십시오.',
			'universalMedia.extensionInstall' => '서비스 추가',
			'universalMedia.extensionReplace' => '업데이트 서비스',
			'universalMedia.extensionRemoveTitle' => '이 검색 서비스 삭제?',
			'universalMedia.extensionRemoveHelp' => '이 서비스는 이 프로필에서 제거됩니다.PlezyNG은 최종 포인트에 연락하지 않습니다.',
			'universalMedia.extensionRemove' => '서비스 제거',
			'universalMedia.extensionInvalidManifest' => '이 파일은 지원되는 확장 메시지가 아닙니다.이 형식에 대한 Open media 가이드를 참조하십시오.',
			'universalMedia.extensionSaveFailed' => '확장은 활성 프로필에 저장할 수 없었습니다.',
			'universalMedia.extensionSearchFailed' => '검색 서비스는 유효한 응답을 반환하지 않았습니다.결말 포인트를 확인하고 다시 시도하십시오.',
			'universalMedia.cliTitle' => '명령 라인',
			'universalMedia.cliHelp' => 'plezyctl 가이드를 사용하여 마니플을 확인하거나 동일한 확장을 검색합니다. 각 검색 전에 HTTPS 서비스를 검토합니다. 결과는 기존 미디어 양식에서 열립니다. 시작할 재생 버튼을 선택합니다.',
			'universalMedia.cliCopyExample' => '코멘트 복사본 예제',
			'universalMedia.cliCopied' => '명령 사례 복사.',
			'fileSources.title' => '파일 및 책',
			'fileSources.subtitle' => '읽고, 듣고, 자신의 파일에서 관찰합니다.',
			'fileSources.add' => '출처 추가',
			'fileSources.importFiles' => '파일 수입',
			'fileSources.localFiles' => '이 장치에서',
			'fileSources.source' => '출처',
			'fileSources.name' => '이름',
			'fileSources.endpoint' => '서버 URL',
			'fileSources.smbEndpointHint' => '예: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'SMB 서버와 공유 폴더 하나를 입력하세요.',
			'fileSources.root' => '폴더 또는 접두사',
			'fileSources.smbFolderHelp' => '공유 폴더 전체를 사용하려면 비워 두고, 일부만 사용하려면 그 안의 폴더를 입력하세요.',
			'fileSources.username' => '사용자 이름',
			'fileSources.smbDomain' => '도메인(선택 사항)',
			'fileSources.password' => '비밀번호',
			'fileSources.token' => 'API 토큰',
			'fileSources.accessKey' => '액세스 키 ID',
			'fileSources.secretKey' => '비밀 액세스 키',
			'fileSources.sessionToken' => '세션 토큰 (선택)',
			'fileSources.region' => '지역',
			'fileSources.clientId' => 'OAuth 고객 ID',
			'fileSources.clientSecret' => 'OAuth 클라이언트 비밀 (Google 데스크톱만)',
			'fileSources.allowHttp' => '신뢰할 수 있는 네트워크에서 암호화되지 않은 HTTP 허용',
			'fileSources.smbEncryption' => 'SMB3 연결 암호화',
			'fileSources.smbEncryptionHint' => 'NAS에서 지원하는 경우 SMB3 암호화를 사용합니다.',
			'fileSources.connect' => '연결',
			'fileSources.cancel' => '취소',
			'fileSources.save' => '저장',
			'fileSources.close' => '닫기',
			'fileSources.removeSource' => '분리된 출처',
			'fileSources.disconnectMessage' => '이 소스의 연결을 해제할까요? 다운로드한 파일과 읽기 및 청취 기록은 이 기기에 유지됩니다.',
			'fileSources.localFolder' => '선택한 폴더',
			'fileSources.empty' => '아직 아무것도 없습니다',
			'fileSources.emptyHint' => '출처를 추가하거나 책, 오디오, 음악 또는 비디오를 가져오십시오.',
			'fileSources.search' => '이 폴더를 찾아보세요',
			'fileSources.searchCached' => '검색 도서관 구원',
			'fileSources.refresh' => '새로고침',
			'fileSources.loadMore' => '더 충전',
			'fileSources.offline' => 'Offline 이용 가능',
			'fileSources.download' => '오프라인으로 유지',
			'fileSources.removeDownload' => '오프라인 복사본 삭제',
			'fileSources.continueReading' => '계속 읽기',
			'fileSources.continueListening' => '계속 듣기',
			'fileSources.continueWatching' => '계속 봐라',
			'fileSources.read' => '읽기',
			'fileSources.listen' => '듣기',
			'fileSources.play' => '재생',
			'fileSources.pause' => '일시정지',
			'fileSources.stop' => '정지',
			'fileSources.startOver' => '시작하기',
			'fileSources.finished' => '재생 완료',
			'fileSources.markFinished' => '마크가 끝났다',
			'fileSources.markUnfinished' => '마크 끝없는',
			'fileSources.editions' => '출판물 및 파일',
			'fileSources.chapters' => '챕터',
			'fileSources.bookmarks' => '책표 및 노트',
			'fileSources.bookmark' => 'Bookmark 추가',
			'fileSources.highlight' => '강조',
			'fileSources.note' => '노트',
			'fileSources.delete' => '삭제',
			'fileSources.export' => '수출 노트',
			'fileSources.exported' => '수출된 노트',
			'fileSources.sync' => 'Sync 진행',
			'fileSources.synced' => '진행 합성',
			'fileSources.conflict' => '다른 장치가 다른 위치를 가지고 있습니다. 어디로 계속할지 선택합니다.',
			'fileSources.useLocal' => '이 장치를 사용하라',
			'fileSources.useRemote' => '다른 장치를 사용하라',
			'fileSources.history' => '위치 역사',
			'fileSources.groupAudio' => '한 개의 오디오 책으로 들으십시오.',
			'fileSources.groupHint' => '현재 이 폴더에 불러온 오디오 파일을 하나로 묶습니다. 먼저 모든 페이지를 불러오세요.',
			'fileSources.order' => '파일 명령',
			'fileSources.moveUp' => '움직이기 위하여',
			'fileSources.moveDown' => '아래로 이동',
			'fileSources.speed' => '플레이버크 속도',
			'fileSources.sleep' => '취침 타이머',
			'fileSources.sleepOff' => '꺼짐',
			'fileSources.endChapter' => '장의 끝',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}분', ), 
			'fileSources.skipBack' => '다시 스키',
			'fileSources.skipForward' => '앞으로 스키',
			'fileSources.smartRewind' => '휴식 후 똑똑한 회복',
			'fileSources.playbackOptions' => '듣기 옵션',
			'fileSources.remaining' => ({required Object time}) => '${time} 남은',
			'fileSources.contents' => '콘텐츠',
			'fileSources.readerSettings' => '읽기 설정',
			'fileSources.fontSize' => '텍스트 크기',
			'fileSources.lineHeight' => '라인 스페셜',
			'fileSources.margin' => '마르지나',
			'fileSources.font' => '타이프페이스',
			'fileSources.serif' => '세리프',
			'fileSources.sans' => '산세리프',
			'fileSources.mono' => '고정폭',
			'fileSources.columns' => '콜럼버스',
			'fileSources.scroll' => 'Vertically 스크롤',
			'fileSources.justify' => '양쪽 맞춤',
			'fileSources.readerTheme' => '페이지 출현',
			'fileSources.appTheme' => '앱 테마 추적',
			'fileSources.paper' => '종이',
			'fileSources.sepia' => '세피아',
			'fileSources.night' => '밤이',
			'fileSources.readAloud' => '이 페이지 소리 내어 읽기',
			'fileSources.readAlong' => '음성에 맞춰 읽기',
			'fileSources.stopReading' => '읽어주기 중지',
			'fileSources.searchBook' => '책에서 검색',
			'fileSources.noMatches' => '경기 없음',
			'fileSources.previousPage' => '이전 페이지',
			'fileSources.nextPage' => '다음 페이지',
			'fileSources.page' => ({required Object number}) => '페이지 ${number}',
			'fileSources.externalBlocked' => '리더에서는 책의 외부 링크가 비활성화되어 있습니다.',
			'fileSources.loading' => '열기...',
			'fileSources.narrator' => '묘사기',
			'fileSources.audio' => '오디오',
			'fileSources.video' => '비디오',
			'fileSources.ebooks' => 'Ebook의 발음을 Ebook [en]',
			'fileSources.all' => '전체',
			'fileSources.downloads' => '오프라인 파일',
			'fileSources.confirmDelete' => '선택한 오프라인 사본을 삭제할까요? 읽기 또는 청취 위치와 메모는 유지됩니다.',
			'fileSources.errorAuthentication' => '다시 이 소스를 다시 연결하려면 로그인하십시오.',
			'fileSources.errorPermission' => '이 소스는 요청된 파일에 대한 액세스를 허용하지 않았습니다.',
			'fileSources.errorUnavailable' => '소스를 사용할 수 없습니다. 다시 시도하거나 오프라인 사본을 여세요.',
			'fileSources.errorUnsupported' => '이 형식 또는 연결이 이 장치에서 지원되지 않습니다.이 장치에서 원본 설정 가이드를 확인합니다.',
			'fileSources.errorInvalidData' => '이 파일 또는 서버 응답은 안전하게 읽을 수 없습니다.',
			'fileSources.errorCancelled' => '이 작업은 취소되었다.',
			'fileSources.errorConflict' => '위치가 다른 세션에서 변경되었습니다. 항목을 다시 열어 위치를 선택합니다.',
			'fileSources.signIn' => '로그인',
			'fileSources.reconnect' => '다시 연결',
			'fileSources.folderHelp' => '비워 두면 소스의 루트에서 시작합니다. S3 URL에는 버킷 이름이 포함됩니다.',
			'fileSources.preferences' => '선호도',
			'fileSources.timePosition' => '위치',
			'fileSources.audioTrack' => '오디오 트랙',
			'fileSources.subtitleTrack' => 'Subtitle 트랙',
			'fileSources.none' => '아무도',
			'fileSources.fullscreen' => '전체 화면',
			'fileSources.syncLocation' => 'Progress sync 폴더 (선택)',
			'fileSources.syncLocationHint' => 'PlezyNG 상태를 위한 전용 WebDAV 폴더.조건적인 글쓰기를 사용; 미디어는 변함없이 남아 있습니다.',
			'fileSources.audiobooks' => '오디오 책',
			'fileSources.comics' => '만화',
			'fileSources.scan' => '책과 미디어를 위한 스캔',
			'fileSources.browserReader' => '오픈 리더',
			'fileSources.browserReaderHelp' => '브라우저에서 리더가 열려 있습니다. 읽던 위치와 메모를 저장하려면 PlezyNG를 열어 두세요.',
			'fileSources.on' => '에',
			'fileSources.advancedSetup' => 'App 등록',
			'fileSources.microsoftSignIn' => 'Microsoft와 함께 가입하세요',
			'fileSources.zoomIn' => 'Zoom에 대한',
			'fileSources.zoomOut' => 'Zoom 출력',
			'fileSources.fitPage' => '페이지에 맞춤',
			'fileSources.fitWidth' => '넓은 넓은',
			'fileSources.actualSize' => '현재 크기',
			'fileSources.goToPage' => '페이지로 가기',
			'fileSources.goToSection' => '챕터로 이동',
			'fileSources.pageRange' => ({required Object count}) => '1에서 ${count} 사이의 숫자를 입력하세요',
			'fileSources.pageLayout' => '페이지 레이아웃',
			'fileSources.automatic' => '자동',
			'fileSources.singlePage' => '단일 페이지',
			'fileSources.twoPages' => '2 페이지',
			'fileSources.readingDirection' => '읽기 방향',
			'fileSources.leftToRight' => '왼쪽에서 오른쪽으로',
			'fileSources.rightToLeft' => '오른쪽에서 왼쪽으로',
			'fileSources.letterSpacing' => '우주 편지',
			'fileSources.wordSpacing' => '단어 스페셜',
			'fileSources.readerControlsHelp' => '두 손가락을 벌리거나 확대/축소 컨트롤을 사용하여 페이지를 확대하세요. 드래그하여 페이지를 이동하세요. Ctrl/⌘와 + 또는 −로 배율을 조절하고, Ctrl/⌘와 0으로 초기화합니다. Page Up과 Page Down으로 페이지를 넘깁니다.',
			'fileSources.imagePage' => '만화 페이지',
			'fileSources.resetReader' => '읽기 선호도를 다시 설정',
			'fileSources.zoom' => '확대/축소',
			'fileSources.useFiles' => '파일과 책을 사용하십시오',
			'fileSources.cancelScan' => '스캔 취소',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Offline 다운로드 제한',
			'fileSources.offlineQuotaHelp' => '오프라인 복사본, 수입된 파일 및 쿠웨이드 다운로드에 사용되는 최대 공간을 설정합니다.제한을 낮추는 것은 기존 복사를 제거하지 않습니다.',
			'fileSources.offlineStorageUsage' => '오프라인 스토리지',
			'fileSources.reservedStorage' => '예약',
			'fileSources.downloadQueue' => '다운로드 Queue',
			'fileSources.downloadRunning' => '다운로드',
			'fileSources.downloadQueued' => '기다리는',
			'fileSources.downloadPaused' => '휴식',
			'fileSources.downloadFailed' => '탈퇴가 필요하다',
			'fileSources.importing' => '수입',
			'fileSources.importInterrupted' => '수입 중단 · 제거 삭제',
			'fileSources.errorQuotaExceeded' => '오프라인 스토리지 제한이 달성되었습니다.제한을 올리거나 다운로드 된 복사본을 제거합니다.',
			'fileSources.errorStorageLow' => '보호된 저장소를 유지하기에 충분한 무료 장치 스토리지가 없습니다.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG는 무료 장치 저장소를 확인할 수 없었으므로 글쓰기가 중단되었습니다.',
			'fileSources.removeDownloadJob' => '다운로드 삭제',
			'fileSources.downloadAlreadyComplete' => '이 다운로드는 삭제되기 전에 완료되었습니다.이 항목은 이제 오프라인으로 사용할 수 있습니다.',
			'fileSources.confirmRemoveDownloadJob' => '이 다운로드를 제거하고 부분적으로 다운로드 된 데이터를 삭제하십시오.당신의 위치와 노트는 남아있을 것입니다.',
			'lending.title' => '공공 도서관',
			'lending.add' => '도서관 추가',
			'lending.other' => '또 다른 도서관',
			'lending.libraryName' => '도서관 이름',
			'lending.libraryUrl' => '도서관 웹사이트',
			'lending.libraryUrlHint' => '도서관의 도서 목록 또는 로그인 페이지를 사용하세요.',
			'lending.intro' => '도서관에서 책을 빌리고 언제나 가까이 두세요.',
			'lending.handoff' => '도서관 자체 서비스를 통해 로그인하고 책을 빌려 안전하게 읽으세요.',
			'lending.openService' => '오픈 도서관',
			'lending.findLibrary' => '도서관 찾기',
			'lending.search' => '책과 저자를 찾아보세요',
			'lending.catalogue' => '카탈로그',
			'lending.loans' => '대출',
			'lending.holds' => '예약',
			'lending.signIn' => '도서관에 가입하십시오',
			'lending.waiting' => '브라우저에서 가입을 마무리하고 여기로 돌아갑니다.',
			'lending.cancel' => '취소',
			'lending.disconnect' => '도서관 삭제',
			'lending.disconnectMessage' => '이 프로필에서 이 도서관을 제거할까요? 대출 및 예약 내역은 도서관에 그대로 유지됩니다.',
			'lending.getBook' => '책을 얻으라',
			'lending.checkAvailability' => '이용 가능성을 확인하기',
			'lending.available' => '대출을 위해 사용할 수 있는',
			'lending.unavailable' => '현재 이용할 수 없는',
			'lending.borrow' => '대출',
			'lending.placeHold' => '예약하기',
			'lending.returnBook' => '기한 전에 반납',
			'lending.cancelHold' => '예약 취소',
			'lending.confirmBorrow' => '이 책을 도서관에서 빌려주시나요?',
			'lending.confirmReturn' => '이 제목을 지금 돌려주십시오.이 제목을 계속하기 위해 다시 대출해야 할 수도 있습니다.',
			'lending.confirmCancelHold' => '이 도서의 예약을 취소할까요?',
			'lending.email' => '이메일 통보를 유지',
			'lending.due' => ({required Object date}) => '반납 기한: ${date}',
			'lending.queue' => ({required Object position}) => '위치 ${position} 라인',
			'lending.empty' => '아직 제목이 없습니다.',
			'lending.openLibraryNote' => 'Open Library의 카탈로그를 탐색하십시오.읽기 및 대출 옵션은 각 제목의 페이지에 표시됩니다.',
			'lending.more' => '더 충전',
			'lending.gateway' => '도서관 서명 서비스',
			'lending.gatewayHint' => '도서관 또는 관리자 PlezyNG에 의해 제공됩니다.',
			'lending.advanced' => '도서관 통합',
			'lending.loadLibraries' => '당신의 도서관을 선택하세요',
			'lending.expired' => '이 대출은 끝났습니다.',
			'lending.updated' => '도서관 업데이트',
			'lending.continueService' => '계속 서비스에',
			'lending.comingSoon' => '신속하게 도착하는 앱 대출',
			'lending.comingSoonDescription' => 'Libby 통합은 그 길에 있습니다. Libby에서 도서관을 사용할 수 있습니다.',
			'lending.suspendHold' => '예약 일시 중지',
			'lending.resumeHold' => '예약 재개',
			'lending.suspendMessage' => '대기 순서를 유지하고 다음 독자가 이 책을 먼저 빌리도록 할까요? 나중에 예약을 재개할 수 있습니다.',
			'lending.resumeMessage' => '도서관에서 다음으로 이용 가능한 책을 제공할 수 있도록 이 예약을 재개할까요?',
			'lending.editEmail' => '이메일 통지 변경',
			'audiobook.syncTitle' => '읽기 & 듣기 Sync',
			'audiobook.syncHelp' => '기기 내에서 읽기 위치, 듣기 위치, 완성 상태, 책표 및 노트를 유지하십시오. 연결된 스토리지 계정을 선택하고 각 장치에 동일한 동기화 코드를 사용하십시오. 읽기 및 듣기는 별도로 남아 있습니다.',
			'audiobook.addSyncSource' => '먼저 Google 드라이브, OneDrive, Dropbox, WebDAV 또는 S3를 파일 및 책에 추가합니다.',
			'audiobook.syncDestination' => 'Sync 스토리지 계정',
			'audiobook.syncFolder' => '동기화 폴더 또는 Prefix',
			'audiobook.syncFolderHelp' => 'WebDAV 소스 내에서 별도의 기존 폴더 또는 전용 S3 사전을 사용하십시오.책 파일은 변경되지 않습니다.',
			'audiobook.syncCode' => '개인 동기화 코드',
			'audiobook.syncCodeHelp' => '첫 번째 장치에서 코드를 만들고 다른 장치에서 그 코드를 입력하십시오.개인 복사본을 유지하십시오.그것은 암호화 상태의 열쇠입니다.모든 사람에게 다른 코드를 사용하십시오.',
			'audiobook.showCode' => 'Sync 코드를 표시하거나 숨기십시오.',
			'audiobook.newSyncCode' => '새로운 Sync 코드를 만들기',
			'audiobook.saveSync' => '저장 및 동기화',
			'audiobook.disableSync' => '이 장치에서 Sync를 끄십시오.',
			'audiobook.syncSourceDisconnect' => '이 소스를 제거하면 여기에서 읽기 및 듣기 동기화가 중지됩니다. 암호화 된 동기화 파일은 공급자에 남아 있습니다.',
			'audiobook.syncReconnect' => '스토리지 계좌 다시 연결',
			'audiobook.lastSynced' => ({required Object time}) => '마지막으로 합성된 ${time}',
			'audiobook.syncPrivacy' => '오직 암호화된 프로세스 및 노트만 저장됩니다. 오디오 및 ebook 파일, 계정 토큰 및 암호는 업로드되지 않습니다. Google 드라이브 및 OneDrive는 애플리케이션 스토리지를 사용합니다. Dropbox는 PlezyNG Sync를 사용합니다. Sync를 활성화하는 것은 추가 글쓰기 액세스를 요구할 수 있습니다. 활성화하는 동안,이 목적지는 프로세스를 소유하고 있습니다. 서버 프로세스는 별도로 남아 있습니다.',
			'audiobook.syncConflicts' => '다시 시작하는 곳을 선택하십시오',
			'audiobook.conflictHelp' => '이러한 변경 사항은 독립적으로 수행되었습니다. 위치 또는 상표 버전을 선택하여 유지하십시오. 나중에 시간표 또는 더 높은 비율은 자동으로 이기지 않습니다.',
			'audiobook.syncDevice' => ({required Object device}) => '장치 ${device}',
			'audiobook.syncUnknownDevice' => '알려지지 않은 장치',
			'audiobook.deletedBookmark' => '삭제된 Bookmark',
			'audiobook.finished' => '마무리',
			'audiobook.readingPosition' => ({required Object percent}) => '읽기 · ${percent}%',
			'audiobook.chapterTimeline' => '제1장 진보',
			'audiobook.bookTimeline' => '책 전체 진행',
			'audiobook.bookRemaining' => ({required Object time}) => '이 책에 남아있는 시간 : ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => '이 장에 남아있는 시간: ${time}',
			'audiobook.unknownRemaining' => '전체 시간 사용할 수 있기 때문에 부분이 재생됩니다',
			'audiobook.undoSeek' => '마지막 찾기',
			'audiobook.customSpeed' => 'Custom Playback 속도',
			'audiobook.speedHelp' => '0.25×에서 4×까지의 속도를 선택합니다.',
			'audiobook.apply' => '응용',
			'audiobook.customSleep' => '사용자 지정 수면 시간',
			'audiobook.sleepMinutes' => '1 분 (1 - 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} 장 후 중지',
			'audiobook.extendSleep' => '추가 5 분',
			'audiobook.sleepRemaining' => ({required Object time}) => '잠자리 타이머: ${time}',
			'audiobook.useDefaults' => '새로운 책을 위해 이러한 듣기 컨트롤을 사용하십시오.',
			'audiobook.librarySort' => '다양한 책들',
			'audiobook.sortTitle' => '제목',
			'audiobook.sortAuthor' => '작가',
			'audiobook.sortNarrator' => '연설자',
			'audiobook.sortSeries' => '시리즈 명령',
			'audiobook.sortRecent' => '최근에 열렸다',
			'audiobook.statusFilter' => '읽기 상태',
			'audiobook.statusAll' => '모든 책들',
			'audiobook.statusNew' => '시작하지 않음',
			'audiobook.statusProgress' => '진행 중에',
			'audiobook.statusFinished' => '마무리',
			'audiobook.goToTime' => '시간에 가라',
			'audiobook.timeHelp' => '시간:분:초 또는 분:초',
			'audiobook.recoveryHelp' => '동기화 데이터를 이동하거나 복구하기 전에 최근 암호화 된 복사본을 수출합니다.수입은 현재 상태와 결합됩니다; 그들은 결코 지역 동기 역사를 대체하지 않습니다.',
			'audiobook.recoveryExport' => '수출 암호화 된 복구 파일',
			'audiobook.recoveryImport' => '암호화된 복구 파일 수입',
			'audiobook.recoveryImportConfirm' => '이 암호화 된 복구 파일을 현재 읽기 위치 및 노트와 결합하십시오? 기존 역사는 유지됩니다. 공유 라이브러리 및 항목 ID는 포함되지 않습니다; 수입하기 전에 각 장치에 해당 ID를 설정합니다.',
			'audiobook.recoveryExported' => '암호화 된 복구 파일이 저장되었습니다.',
			'audiobook.recoveryImported' => '복구 데이터가 합쳐졌습니다.',
			'sourceSetup.savedCertificate' => '저장된 서버 인증서',
			'sourceSetup.nfsEndpointInvalid' => 'nfs://nas:2049/export와 같은 NFS URL을 입력하세요.',
			'sourceSetup.dlnaNone' => 'DLNA 서버를 찾지 못했습니다. 장치 설명 URL을 직접 입력하세요.',
			'sourceSetup.dlnaServers' => 'DLNA 미디어 서버',
			'sourceSetup.dlnaUnavailable' => '이 네트워크에서는 DLNA 검색을 사용할 수 없습니다. 장치 설명 URL을 직접 입력하세요.',
			'sourceSetup.dlnaSearching' => '로컬 네트워크에서 DLNA 서버 검색 중',
			'sourceSetup.networkSearching' => '로컬 네트워크 검색 중…',
			'sourceSetup.dlnaDiscover' => 'DLNA 서버 찾기',
			'sourceSetup.dlnaHelp' => '장치를 찾으려면 로컬 네트워크의 멀티캐스트가 필요합니다. 서버가 나타나지 않으면 위에 장치 설명 URL을 입력하세요.',
			'sourceSetup.dlnaRoot' => 'DLNA 개체 ID입니다. 비워 두면 장치의 루트를 사용합니다.',
			'sourceSetup.passwordOrKey' => '비밀번호를 입력하거나 아래에 개인 키를 추가하세요.',
			'sourceSetup.sshFingerprint' => 'SSH 호스트 키의 SHA256 지문',
			'sourceSetup.sshFingerprintHelp' => '서버 관리자에게 확인하세요. 서버에서 ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub 명령을 실행하고 표시된 SHA256 값을 사용하세요.',
			'sourceSetup.sshFingerprintKeep' => '현재 고정된 지문을 유지하려면 비워 두세요. 변경하려면 새 서버 지문을 입력하세요.',
			'sourceSetup.sshAuthentication' => 'SSH 공개 키 인증',
			'sourceSetup.sshAuthenticationHelp' => '선택 사항입니다. 비밀번호 인증도 지원합니다.',
			'sourceSetup.privateKey' => '개인 키(PEM 또는 OpenSSH 형식)',
			'sourceSetup.privateKeyPassphrase' => '개인 키 암호 구문',
			'sourceSetup.nfsMountPort' => 'NFS 마운트 서비스 TCP 포트',
			'sourceSetup.nfsMountPortHelp' => '기본값: 20048',
			'sourceSetup.nfsUserId' => 'NFS 사용자 ID(AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => '기본값: 1000. NAS 내보내기 설정에서 허용한 ID를 사용하세요.',
			'sourceSetup.nfsGroupId' => 'NFS 그룹 ID(AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => '기본값: 1000. NAS 내보내기 설정에서 허용한 그룹 ID를 사용하세요.',
			'sourceSetup.nfsEncryption' => 'NFS 암호화 필수(RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'NFS와 마운트 서비스에 TLS 1.3을 요구합니다. NAS가 지원하지 않으면 연결을 거부합니다.',
			'sourceSetup.nfsTrustCertificate' => '사용자 지정 NFS CA 또는 서버 인증서(PEM, 선택 사항)',
			'sourceSetup.nfsTrustHelp' => '이 장치에서 신뢰하는 인증서를 사용하려면 비워 두세요. 필요하면 사설 CA 또는 자체 서명 서버 인증서를 추가하세요. 인증서의 이름은 NFS URL의 호스트와 일치해야 합니다.',
			'sourceSetup.nfsTrustInvalid' => 'PEM 형식의 CA 또는 서버 인증서를 사용하세요. 개인 키는 포함하지 마세요.',
			'sourceSetup.addTrustCertificate' => '사용자 지정 신뢰 인증서 추가',
			'sourceSetup.replaceTrustCertificate' => '저장된 사용자 지정 인증서 교체',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS는 일반 NFS 및 마운트 서비스 포트를 사용하며, NAS가 RFC 9289를 지원해야 합니다. TLS 1.3이 필수입니다. 호스트 이름 또는 IP가 인증서와 일치해야 합니다. 암호화된 채널에서도 AUTH_SYS UID/GID가 적용됩니다.',
			'sourceSetup.clientCertificate' => '클라이언트 인증서(선택 사항)',
			'sourceSetup.clientCertificateHelp' => 'NAS가 이 클라이언트를 인증하도록 합니다. AUTH_SYS ID에는 여전히 NAS 내보내기 정책이 적용됩니다.',
			'sourceSetup.savedIdentity' => '저장된 클라이언트 인증 정보를 사용합니다.',
			'sourceSetup.replaceIdentity' => '저장된 클라이언트 인증 정보 교체',
			'sourceSetup.chooseIdentity' => 'PKCS#12 클라이언트 인증 정보 선택',
			'sourceSetup.identityPassphrase' => '클라이언트 인증 정보 암호 구문',
			'sourceSetup.identityPassphraseHelp' => '파일에 암호 구문이 없으면 비워 두세요.',
			'sourceSetup.removeIdentity' => '저장된 클라이언트 인증 정보 제거',
			'sourceSetup.identityStorageHelp' => '클라이언트 인증 정보는 암호화된 소스 자격 증명 저장소에 저장됩니다. 저장된 인증 정보를 유지하려면 이 섹션을 변경하지 마세요.',
			'sourceSetup.nfsLimitations' => 'TCP를 통한 읽기 전용 NFSv3입니다. RPC-with-TLS를 사용하지 않으면 NFS 트래픽이 암호화되지 않습니다. NAS는 선택한 AUTH_SYS ID와 비특권 클라이언트 포트를 허용해야 합니다(보통 내보내기 옵션에서 ‘insecure’로 표시됨). NFSv4와 UDP는 지원하지 않습니다.',
			'sourceSetup.nfsSetupHelp' => 'NFS 설정 도움말',
			'sourceSetup.nfsSetupHint' => '연결되지 않으면 이 설정들을 확인하세요.',
			'sourceSetup.nfsSetupDetails' => 'TCP 기반 NFSv3 내보내기를 사용하세요. 암호화가 필수인 경우 NFS와 마운트 서비스가 모두 RPC-with-TLS를 지원해야 합니다. 이 장치에서 서버 인증서를 신뢰하면 사용자 지정 인증서를 비워 두세요. 그렇지 않으면 NAS CA 또는 자체 서명 인증서를 추가하세요. 인증서 이름은 엔드포인트의 호스트와 일치해야 합니다. NAS가 상호 TLS를 요구하면 해당 PKCS#12 클라이언트 인증 정보를 추가하세요. 마지막으로 내보내기 설정이 지정한 AUTH_SYS UID/GID와 클라이언트 포트 정책을 허용하는지 확인하세요.',
			'sourceSetup.ftpHelp' => 'FTP는 패시브 모드를 사용합니다. 암호화되지 않은 FTP에는 ftp://, 명시적 TLS에는 ftpes://를 사용하세요. ftps://도 TLS를 사용하며, 포트 990에서는 암시적 TLS를, 다른 포트에서는 명시적 TLS를 사용합니다.',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => '독립 동영상 파일에 사용할 수 있는 선택적 자막 검색 기능입니다.',
			'sourceSetup.apiKey' => 'API 키',
			'sourceSetup.optionalUsername' => '계정 사용자 이름(선택 사항)',
			'sourceSetup.optionalPassword' => '계정 비밀번호(선택 사항)',
			'sourceSetup.subtitlePrivacy' => 'opensubtitles.com에서 API 키를 받으세요. 검색 시 동영상 제목과 사용 가능한 IMDb/TMDB ID만 전송하며, 동영상 파일은 절대 전송하지 않습니다. 키와 선택적 계정 자격 증명은 이 소스와 함께 암호화하여 저장합니다.',
			'sourceSetup.automaticMetadata' => '온라인 동영상 메타데이터 자동 조회',
			'sourceSetup.metadataPrivacy' => '파일명의 제목·연도·에피소드 번호 또는 NFO ID만 전송하며, 미디어나 자격 증명은 절대 전송하지 않습니다. NFO 필드가 항상 우선합니다.',
			'sourceSetup.nfsEncryptionFailure' => '암호화된 NFS 연결에서는 NAS의 두 서비스가 RFC 9289와 TLS 1.3을 지원하는지, 인증서 이름과 내보내기 UID/GID가 올바른지 확인하세요. PlezyNG는 암호화 없이 이 연결을 다시 시도하지 않습니다.',
			'sourceSetup.sourceConnecting' => '소스에 연결 중',
			'sourceSetup.metadataSearchPrivacy' => '이 제목 검색은 Trakt로 전송됩니다. 입력한 제목만 전송하며, 동영상이나 소스 자격 증명은 전송하지 않습니다.',
			'sourceSetup.chooseMatch' => '일치하는 결과 선택',
			'sourceSetup.metadataMatchHelp' => '선택하기 전에 제목과 연도를 확인하세요. Trakt에는 검색 제목이 전송되며, 동영상은 원래 소스에 그대로 남습니다.',
			'sourceSetup.metadataNoMatches' => '일치하는 온라인 제목을 찾지 못했습니다. 다른 제목으로 검색하세요.',
			'sourceSetup.metadataSearch' => '온라인 메타데이터 검색',
			'sourceSetup.metadataLoading' => '온라인 영화 및 TV 프로그램 정보 조회 중…',
			'sourceSetup.metadataFromTrakt' => 'Trakt의 온라인 메타데이터',
			'sourceSetup.metadataNoAutomaticMatch' => '자동으로 일치하는 제목을 찾지 못했습니다. 제목을 검색하여 일치하는 결과를 선택하세요.',
			'sourceSetup.metadataFailed' => '온라인 메타데이터를 불러오지 못했습니다. 재생과 로컬 정보는 계속 사용할 수 있습니다.',
			'sourceSetup.videoDetailsLoading' => '동영상 정보 불러오는 중',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles API 키 필요',
			'sourceSetup.subtitleKeyHelp' => '이 파일 소스를 편집하여 선택적 자막 설정에 OpenSubtitles API 키를 추가하세요.',
			'sourceSetup.subtitleSearchFailed' => '자막 검색에 실패했습니다. API 키, 연결 및 서비스 접근 권한을 확인하세요.',
			'sourceSetup.subtitleApplyFailed' => '이 자막을 다운로드하거나 적용하지 못했습니다. 연결을 확인하고 다른 결과를 선택하세요.',
			'sourceSetup.subtitleSearch' => 'OpenSubtitles 검색',
			'sourceSetup.subtitleSearchPrivacy' => '검색에는 제목과 사용 가능한 IMDb/TMDB ID를 사용합니다. 동영상 파일은 원래 소스에 그대로 남습니다. 선택하기 전에 언어, 강제 표시 또는 청각 장애인용 자막 표시, 평점을 확인하세요.',
			'sourceSetup.movieOrShow' => '영화 또는 TV 프로그램',
			'sourceSetup.subtitleTitleHint' => '제목을 입력하여 검색 결과 좁히기',
			'sourceSetup.subtitleLanguage' => '자막 언어',
			'sourceSetup.subtitleSearching' => 'OpenSubtitles 검색 중',
			'sourceSetup.subtitleNoMatches' => '일치하는 자막을 찾지 못했습니다. 다른 제목이나 언어를 선택하세요.',
			'sourceSetup.downloadSubtitle' => '자막 다운로드',
			'sourceSetup.subtitle' => '자막',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS 필수',
			'sourceSetup.nfsUnencrypted' => '암호화되지 않은 NFS',
			'sourceSetup.tlsEncrypted' => 'TLS로 암호화됨',
			'sourceSetup.ftpPlain' => '암호화되지 않은 FTP',
			'sourceSetup.sshPinned' => 'SSH 암호화 · 호스트 키 고정됨',
			'sourceSetup.smbEncrypted' => 'SMB3 암호화 켜짐',
			'sourceSetup.smbUnencrypted' => 'SMB3 암호화 꺼짐',
			'sourceSetup.httpUnencrypted' => '전송 암호화 없는 HTTP',
			'sourceSetup.checkEndpointSecurity' => '엔드포인트 보안 확인',
			'sourceSetup.fieldRequired' => ({required Object label}) => '필수 입력 항목: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => '${label}: ${min}부터 ${max}까지의 값을 입력하세요.',
			'sourceSetup.replaceFile' => ({required Object name}) => '${name} 교체',
			'sourceSetup.selectedIdentity' => ({required Object name}) => '선택한 클라이언트 인증 정보: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => '평점 ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => '자막 다운로드 중: ${title}',
			'sourceSetup.sharedEntryPair' => '이 항목을 쌍으로',
			'sourceSetup.sharedEntryPairHelp' => '각 장치에서 이 항목에 대한 동일한 ID를 입력하십시오. 안정적인 공유 식별자를 사용하거나 하나를 생성하고 해당 항목으로 복사합니다. 업그레이드 파일 유형, 크기 및 주문이 일치하는 경우에만 커플됩니다. Blank은 이 맵링을 제거합니다.',
			'sourceSetup.sharedEntryId' => '공유 항목 ID',
			'sourceSetup.generateSharedEntryId' => '공유 항목 ID 생성',
			'sourceSetup.sharedLibraryId' => '공유 도서관 ID (선택)',
			'sourceSetup.sharedLibraryHelp' => '같은 도서관을 열고 있는 장치에서 동일한 ID를 사용하십시오.이 공공 ID는 다른 출처 연결을 통해 읽기 진행과 메모를 수행하는 데 도움이됩니다; 그것은 암호가 아닙니다.',
			'sourceSetup.sharedLibraryInvalid' => '8 ~ 100 문자, 숫자, 포인트, 하위 코어 또는 하이펜을 사용하십시오.',
			'sourceSetup.generateSharedLibraryId' => '공유 도서관 ID 만들기',
			'sourceSetup.nfsReadAhead' => 'NFS 읽기-하이드 요청',
			'sourceSetup.nfsReadAheadHelp' => '더 많은 병렬 리더는 빠른 NAS 또는 네트워크의 통로를 향상시킬 수 있습니다. 서버가 동일한 요청을 제한하는 경우 1을 사용합니다.',
			'sourceSetup.nfsReadTest' => 'NFS 읽기 성능 측정',
			'sourceSetup.nfsReadTestHelp' => '이 NAS 연결을 측정하기 위해 가장 큰 파일에서 64 MiB까지 읽습니다.이것은 네트워크 밴드 폭을 사용합니다.',
			'sourceSetup.nfsQualificationResult' => 'NFS 읽기 측정',
			'sourceSetup.nfsReadBytes' => '데이터 읽기',
			'sourceSetup.nfsReadSpeed' => '속도 측정',
			'sourceSetup.nfsReadRequests' => '요청 읽기',
			'sourceSetup.sharedEntryConflict' => '이 공유 항목 ID는 이미 이 도서관의 다른 항목과 조화되어 있습니다.',
			'comics.fitHeight' => '높이에 맞춤',
			'comics.readingMode' => '읽기 모드',
			'comics.paged' => '페이지',
			'comics.webtoon' => '연속 스크롤',
			'comics.coverAlone' => '표지 따로 표시',
			'comics.splitWide' => '가로로 긴 페이지 나누기',
			'comics.splitWideHelp' => '각 절반을 읽는 순서대로 따로 표시합니다. 이 옵션을 켜면 두 페이지 나란히 보기가 일시 중지됩니다.',
			'comics.thumbnails' => '페이지 미리보기',
			'comics.controlsHelp' => '스와이프하여 페이지를 넘기세요. 두 번 탭하여 맞춤 방식을 바꾸세요. 연속 스크롤에서는 세로로 스와이프하거나 Page Up 및 Page Down을 사용하세요.',
			'comics.savedForComic' => '이 프로필에서 이 만화의 표시 설정을 기억합니다.',
			'comics.readLists' => '읽기 목록',
			'comics.collections' => '컬렉션',
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
			_ => null,
		} ?? switch (path) {
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
			'deepLinks.invalid' => '이 Plezy 링크는 유효하지 않습니다.',
			'deepLinks.profileNotFound' => ({required Object profile}) => '프로필은 "${profile}"과 일치하지 않습니다.',
			'deepLinks.serverUnavailable' => '이 링크를 위해 서버에 접근할 수 없었습니다.',
			'deepLinks.notFound' => '이 책의 제목은 도서관에서 찾을 수 없습니다.',
			'deepLinks.unsupportedItem' => '이 링크는 재생할 수 없습니다.',
			'deepLinks.noLiveTv' => '이 링크를 위해 라이브 TV 서버가 없습니다.',
			'deepLinks.channelNotFound' => ({required Object channel}) => '채널 "${channel}"을 찾을 수 없었습니다.',
			'deepLinks.showLink' => '링크 보기',
			'deepLinks.showProfileLink' => '프로필 링크 보기',
			'deepLinks.dialogTitle' => '링크',
			'deepLinks.showHint' => '이 링크를 열면 다음 에피소드를 재생합니다. shuffle에서 쇼를 재생하려면 &mode=shuffle을 추가합니다.',
			'deepLinks.movieHint' => '이 링크를 열면 영화가 재생됩니다.',
			'deepLinks.episodeHint' => '이 링크를 열면 이 에피소드를 재생합니다.',
			'deepLinks.profileHint' => '이 링크를 열면 이 프로필으로 스위치됩니다.',
			'deepLinks.openAsProfile' => ({required Object name}) => '${name}으로 열기',
			'deepLinks.copy' => '복사본',
			'deepLinks.copied' => '링크 복사',
			_ => null,
		};
	}
}
