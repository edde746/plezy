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
	@override late final _Translations$auth$ko auth = _Translations$auth$ko._(_root);
	@override late final _Translations$common$ko common = _Translations$common$ko._(_root);
	@override late final _Translations$screens$ko screens = _Translations$screens$ko._(_root);
	@override late final _Translations$update$ko update = _Translations$update$ko._(_root);
	@override late final _Translations$settings$ko settings = _Translations$settings$ko._(_root);
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
}

// Path: app
class _Translations$app$ko extends Translations$app$en {
	_Translations$app$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy Labs';
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
	@override String get useQuickConnect => 'Quick Connect 사용';
	@override String get quickConnectInstructions => 'Jellyfin에서 Quick Connect를 열고 이 코드를 입력하세요.';
	@override String get quickConnectWaiting => '승인 대기 중…';
	@override String get quickConnectCancel => '취소';
	@override String get quickConnectExpired => 'Quick Connect가 만료되었습니다. 다시 시도하세요.';
	@override String get localDataRecoveryRequired => 'Plezy에서 로컬 로그인 정보와 대기 중인 재생 데이터를 안전하게 복구하지 못했습니다. 다시 로그인해 주세요.';
	@override String get pinCheckRejected => 'Plex PIN 확인이 거부되었습니다';
}

// Path: common
class _Translations$common$ko extends Translations$common$en {
	_Translations$common$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get cancel => '취소';
	@override String get save => '저장';
	@override String get close => '닫기';
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
	@override String get chooseChannelTitle => 'Choose your update channel';
	@override String get chooseChannelDescription => 'Plezy Labs adds experimental features on top of published Plezy releases. You can use Labs updates or return to official Plezy.';
	@override String get useLabs => 'Use Plezy Labs';
	@override String get returnToOfficial => 'Return to Official Plezy';
	@override String get returnToOfficialTitle => 'Leave Plezy Labs?';
	@override String get returnToOfficialWarning => 'Labs-only features and preferences may no longer be available. Official Plezy cannot update back to Plezy Labs; reinstall Labs manually if you want to return.';
	@override String get openOfficialRelease => 'Open Official Release';
	@override String get releaseNotes => 'Release notes';
}

// Path: settings
class _Translations$settings$ko extends Translations$settings$en {
	_Translations$settings$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '설정';
	@override String get supportDeveloper => 'Plezy 후원하기';
	@override String get supportDeveloperDescription => 'Liberapay로 후원하여 개발 지원';
	@override String get language => '언어';
	@override String get theme => '테마';
	@override String get appearance => '디자인';
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
	@override String get libraryDensity => '라이브러리 표시 밀도';
	@override String get compact => '조밀하게';
	@override String get comfortable => '여유롭게';
	@override String get tvCornerSpotlightBackdrop => '모서리 스포트라이트 배경';
	@override String get tvCornerSpotlightBackdropDescription => '화면 전체를 채우는 대신 오른쪽 상단에 스포트라이트 아트워크를 표시합니다';
	@override String get viewMode => '보기 모드';
	@override String get gridView => '그리드 보기';
	@override String get listView => '목록 보기';
	@override String get showHeroSection => '주요 추천 영역 표시';
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
	@override String get packedStereoUi => '3D Playback UI';
	@override String get bufferSize => '버퍼 크기';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => '자동 (권장)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB 메모리를 사용할 수 있습니다. ${size}MB 버퍼는 재생에 영향을 줄 수 있습니다.';
	@override String get defaultQualityTitle => '기본 화질';
	@override String get musicQualityTitle => '음악 음질';
	@override String get subtitleStyling => '자막 스타일';
	@override String get subtitleStylingDescription => '자막 모양을 사용자 지정합니다';
	@override String get smallSkipDuration => '짧은 건너뛰기 시간';
	@override String get largeSkipDuration => '긴 건너뛰기 시간';
	@override String get rewindOnResume => '재개 시 되감기';
	@override String secondsUnit({required Object seconds}) => '${seconds}초';
	@override String get defaultSleepTimer => '기본 취침 타이머';
	@override String minutesUnit({required Object minutes}) => '${minutes}분';
	@override String get rememberTrackSelections => '시리즈/영화별 트랙 선택 기억';
	@override String get rememberTrackSelectionsDescription => '작품별 오디오 및 자막 선택 기억';
	@override String get followServerTrackSelections => '서버의 에피소드별 트랙 선택 사용';
	@override String get followServerTrackSelectionsDescription => '에피소드 전환 시 현재 선택을 유지하는 대신 서버에서 선택된 오디오와 자막을 적용합니다';
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
	@override String get watchTogetherRelayDescription => '사용자 지정 릴레이를 설정합니다. 모두 같은 서버를 사용해야 합니다.';
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
	@override String get importSettingsInvalidFile => '유효한 Plezy 설정 내보내기 파일이 아닙니다';
	@override String get importSettingsNoUser => '설정을 가져오기 전에 로그인하세요';
	@override String get shortcutsReset => '단축키가 기본값으로 재설정되었습니다';
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
	@override String get autoSkip => '자동 건너뛰기';
	@override String get autoSkipIntro => '자동으로 오프닝 건너뛰기';
	@override String get autoSkipIntroDescription => '몇 초 후 오프닝을 자동으로 건너뛰기';
	@override String get autoSkipCredits => '자동으로 엔딩 건너뛰기';
	@override String get autoSkipCreditsDescription => '엔딩 크레딧 자동 건너뛰기 후 다음 에피소드 재생';
	@override String get forceSkipMarkerFallback => '대체 마커 강제 사용';
	@override String get forceSkipMarkerFallbackDescription => 'Plex에 마커가 있어도 챕터 제목 패턴 사용';
	@override String get autoSkipDelay => '자동 건너뛰기 지연';
	@override String autoSkipDelayDescription({required Object seconds}) => '자동으로 건너뛰기 전 ${seconds}초 대기';
	@override String get introPattern => '인트로 마커 패턴';
	@override String get introPatternDescription => '챕터 제목에서 인트로 마커를 인식하는 정규식 패턴';
	@override String get creditsPattern => '크레딧 마커 패턴';
	@override String get creditsPatternDescription => '챕터 제목에서 크레딧 마커를 인식하는 정규식 패턴';
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
	@override String get downloadLocationSelectError => 'Failed to select folder';
	@override String get mediaCapture => 'Media Capture';
	@override String get clips => 'Clips';
	@override String get screenshots => 'Screenshots';
	@override String captureLocationTitle({required Object title}) => '${title} Location';
	@override String get clipLocationDescription => 'Choose where clips are saved.';
	@override String get screenshotLocationDescription => 'Choose where screenshots are saved.';
	@override String get clipLocationChanged => 'Clip location changed';
	@override String get screenshotLocationChanged => 'Screenshot location changed';
	@override String get clipLocationReset => 'Clip location reset to Desktop';
	@override String get screenshotLocationReset => 'Screenshot location reset to Desktop';
	@override String get downloadOnWifiOnly => 'Wi-Fi 연결 시에만 다운로드';
	@override String get downloadOnWifiOnlyDescription => '셀룰러 데이터 사용 중에는 다운로드하지 않습니다';
	@override String get autoRemoveWatchedDownloads => '시청한 다운로드 항목 자동 삭제';
	@override String get autoRemoveWatchedDownloadsDescription => '시청한 다운로드 항목을 자동으로 삭제합니다';
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
	@override String get tunneledPlaybackDescription => '비디오 터널링을 사용합니다. HDR 재생 시 검은 화면이 보이면 비활성화하세요.';
	@override String get audioPassthrough => '오디오 패스스루';
	@override String get audioPassthroughDescription => 'Dolby/DTS 오디오를 재인코딩 없이 리시버나 TV로 전송하여 서라운드 사운드를 유지합니다. 소리가 나지 않으면 비활성화하세요.';
	@override String get audioPassthroughDescriptionAppleTv => 'Dolby Digital Plus(Atmos 포함)에 Apple의 기본 Dolby 디코더를 사용합니다. DTS와 TrueHD는 계속 멀티채널 PCM으로 재생됩니다. 소리가 나지 않으면 비활성화하세요.';
	@override String get audioDownmix => '스테레오로 다운믹스';
	@override String get audioDownmixDescription => '서라운드 오디오를 스테레오 스피커나 헤드폰용 2채널로 믹스합니다';
	@override String get downmixCenterBoost => '센터 채널 부스트';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '부스트 (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '다운믹스 시 음량 정규화';
	@override String get audioDownmixNormalizeDescription => '클리핑을 방지하기 위해 믹스 음량을 낮춥니다. 원래 음량을 유지하려면 끄세요(큰 소리 장면에서 왜곡될 수 있음).';
	@override String get dvConversionMode => 'Dolby Vision 변환';
	@override String get dvConversionModeDescription => 'ExoPlayer가 Dolby Vision Profile 7 파일을 처리하는 방식을 선택합니다.';
	@override String get dvConversionAuto => '자동';
	@override String get dvConversionNative => '네이티브 / 비활성화';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '기기 기능 감지와 일반 폴백 동작을 사용합니다';
	@override String get dvConversionNativeDescription => '네이티브 DV7을 강제하고 DV 변환 재시도를 억제합니다';
	@override String get dvConversionDv81Description => 'Dolby Vision 프로필 8.1로 인라인 RPU 변환을 강제합니다';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision RPU/EL 레이어를 제거하고 일반 HEVC로 제공합니다';
	@override String get demuxer => '컨테이너 디먹서';
	@override String get demuxerDescription => '다이렉트 재생 파일을 분석할 디먹서입니다. 파일이 제대로 재생되지 않으면 media3으로 전환하세요.';
	@override String get demuxerFfmpeg => 'FFmpeg (권장)';
	@override String get demuxerMedia3 => 'media3';
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
	@override String get liveTvDefaultFavorites => '즐겨찾기 채널 기본 설정';
	@override String get liveTvDefaultFavoritesDescription => '라이브 TV를 열 때 즐겨찾기 채널만 표시';
	@override String get display => '디스플레이';
	@override String get homeScreen => '홈 화면';
	@override String get navigation => '탐색';
	@override String get window => '창';
	@override String get content => '콘텐츠';
	@override String get player => '플레이어';
	@override String get subtitlesAndConfig => '자막 및 구성';
	@override String get seekAndTiming => '탐색 및 타이밍';
	@override String get behavior => '동작';
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
	@override String get exportDialogTitle => 'Plezy 설정 내보내기';
	@override String get displayScale => '표시 배율';
	@override String get playbackBuffer => '재생 버퍼';
	@override String get playbackBufferAuto => '자동 (권장)';
	@override String get playbackBufferLarge => '대형';
	@override String get playbackBufferExtraLarge => '초대형';
	@override String get playbackBufferDescription => '불안정한 연결에 대비해 더 많은 버퍼를 사용합니다. 버퍼 크기에 의해서도 제한됩니다.';
	@override String get showExploreTab => '둘러보기 탭 표시';
	@override String get showExploreTabDescription => 'Plex Discover와 연결된 트래커의 콘텐츠가 포함된 둘러보기 탭을 표시합니다';
	@override String get officialPlezy => 'Official Plezy';
	@override String get plezyLabs => 'Plezy Labs';
	@override String labsNotAvailable({required Object version}) => 'Plezy Labs for Plezy ${version} is not available yet';
	@override String latestLabsRelease({required Object version}) => 'Latest Labs release: ${version}';
	@override String latestOfficialRelease({required Object version}) => 'Latest official release: ${version}';
	@override String get releaseStatusUnavailable => 'Release status unavailable';
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
		one: 'This deletes all ${n} episode in it, and its file.',
		other: '포함된 에피소드 ${n}개와 해당 파일이 모두 삭제됩니다.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: 'This item is stored as ${n} file, which will be deleted.',
		other: '이 항목은 파일 ${n}개에 걸쳐 저장되어 있으며, 모든 파일이 삭제됩니다.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${n} other episode is stored in the same file and will be deleted too:',
		other: '같은 파일에 저장된 다른 에피소드 ${n}개도 함께 삭제됩니다:',
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
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${n} frame',
		other: '${n} frames',
	);
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
	@override String get versionQualityButton => '버전 및 화질';
	@override String get versionColumnHeader => '버전';
	@override String get qualityColumnHeader => '화질';
	@override String get qualityOriginal => '원본';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => '트랜스코딩을 사용할 수 없음 — 원본 화질로 재생';
	@override String get subtitleUnavailableFallback => '선택한 자막을 불러올 수 없어 자막 없이 재생을 계속합니다';
	@override String get pipButton => '픽처 인 픽처 모드';
	@override String get aspectRatioButton => '화면비율';
	@override String get packedStereoSizingLocked => 'Cannot change while playing 3D source';
	@override String get ambientLighting => '주변 조명';
	@override String get fullscreenButton => '전체 화면';
	@override String get exitFullscreenButton => '전체 화면 종료';
	@override String get alwaysOnTopButton => '창 최상위 고정';
	@override String get rotationLockButton => '회전 잠금';
	@override String get lockScreen => '화면 잠금';
	@override String get screenLockButton => '화면 잠금';
	@override String get longPressToUnlock => '길게 눌러 잠금 해제';
	@override String get timelineSlider => '타임라인';
	@override String get volumeSlider => '볼륨 조절';
	@override String endsAt({required Object time}) => '${time}에 종료';
	@override String get pipActive => '화면 속 화면으로 재생 중';
	@override String get pipFailed => '화면 속 화면 모드를 시작할 수 없습니다';
	@override String get screenshotSaved => '스크린샷 저장됨';
	@override late final _Translations$videoControls$clip$ko clip = _Translations$videoControls$clip$ko._(_root);
	@override String zoomPercent({required Object percent}) => '확대/축소 ${percent}%';
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
		one: 'Auto-removed ${n} watched download',
		other: '시청한 다운로드 ${n}개를 자동 삭제했습니다',
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
	@override String get logsUploaded => '로그 업로드 완료';
	@override String get logsUploadFailed => '로그 업로드 실패';
	@override String get logId => '로그 ID';
	@override String get burnedSubtitlesUseMenu => '자막이 이 스트림에 입혀져 있습니다. 자막 메뉴에서 변경하세요.';
	@override String get noVideoUrl => '사용 가능한 비디오 URL이 없습니다';
	@override String get playbackNoMediaSources => '서버에서 재생 가능한 미디어 소스를 반환하지 않았습니다';
	@override String get playbackDataNotPrepared => '재생 데이터가 준비되기 전에 재생이 시작되었습니다';
	@override String get streamSelectionUnavailable => '이 소스에서는 스트림을 선택할 수 없습니다';
	@override String get streamSelectionFailed => '선택한 스트림을 적용할 수 없습니다';
	@override String get serverUnavailableForProfile => '활성 프로필에 사용할 수 있는 서버가 없습니다';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ko extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
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
	@override String get anchorToScreen => '화면에 고정';
	@override String get anchorToScreenDescription => '와이드스크린 비디오 아래의 검은 여백에 텍스트 자막을 표시합니다';
	@override String get bold => '굵게';
	@override String get italic => '기울임꼴';
	@override String get renderResolution => '렌더링 해상도';
	@override String get renderResolutionScreen => '화면 해상도';
	@override String get renderResolutionVideo => '영상 해상도';
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
	@override String get addPlezyProfile => 'Plezy 프로필 추가';
	@override String get switchingProfile => '프로필 전환 중…';
	@override String get deleteThisProfileTitle => '이 프로필을 삭제하시겠습니까?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName}을(를) 제거합니다. 연결에는 영향이 없습니다.';
	@override String get active => '활성';
	@override String get manage => '관리';
	@override String get delete => '삭제';
	@override String get signOut => '로그아웃';
	@override String get signOutPlexTitle => 'Plex에서 로그아웃하시겠습니까?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} 및 모든 Plex Home 사용자를 제거할까요? 언제든 다시 로그인할 수 있습니다.';
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
	@override String get borrowEmptySubtitle => '먼저 다른 프로필에 Plex 또는 Jellyfin을 연결하세요.';
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
}

// Path: connections
class _Translations$connections$ko extends Translations$connections$en {
	_Translations$connections$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '연결';
	@override String get addConnection => '연결 추가';
	@override String get addConnectionSubtitleNoProfile => 'Plex로 로그인하거나 Jellyfin 서버에 연결';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}에 추가: Plex, Jellyfin 또는 다른 프로필 연결';
	@override String sessionExpiredOne({required Object name}) => '${name}의 세션이 만료되었습니다';
	@override String sessionExpiredMany({required Object count}) => '${count}개 서버의 세션이 만료되었습니다';
	@override String get signInAgain => '다시 로그인';
	@override String editMediaBrowserTitle({required Object product}) => '${product} 연결 편집';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName}의 URL을 추가하거나 제거하세요. Plezy는 연결 가능한 URL 중 지연 시간이 가장 낮은 URL을 사용합니다.';
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
		one: '${n} title',
		other: '${n}개 타이틀',
	);
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
}

// Path: libraries
class _Translations$libraries$ko extends Translations$libraries$en {
	_Translations$libraries$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$ko extends Translations$about$en {
	_Translations$about$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '소개';
	@override String get openSourceLicenses => '오픈소스 라이선스';
	@override String versionLabel({required Object version}) => '버전 ${version}';
	@override String get appDescription => 'Flutter로 만든 아름다운 Plex 및 Jellyfin 클라이언트';
	@override String get viewLicensesDescription => '타사 라이브러리 라이선스 보기';
	@override String get labsDescription => 'An experimental Plezy edition built only on published official releases';
	@override String get labsModifiedNotice => 'Plezy Labs is a modified GPL-3.0 build maintained by RyanTheTechMan, not an official Plezy release.';
	@override String get labsSource => 'Plezy Labs source code';
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
	@override String get quitPlezy => 'Plezy 종료';
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
	@override String get title => '탐색';
	@override String get selectSource => '소스 선택';
	@override late final _Translations$explore$rows$ko rows = _Translations$explore$rows$ko._(_root);
	@override late final _Translations$explore$status$ko status = _Translations$explore$status$ko._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n,
		one: '${n} episode',
		other: '${n}화',
	);
	@override String get cast => '출연진';
	@override String get characters => '캐릭터';
	@override String get addToWatchlist => '관심 목록에 추가';
	@override String get removeFromWatchlist => '관심 목록에서 제거';
	@override String get addedToWatchlist => '관심 목록에 추가했습니다';
	@override String get removedFromWatchlist => '관심 목록에서 삭제했습니다';
	@override String get watchlistUpdateFailed => '관심 목록을 업데이트하지 못했습니다';
	@override String get watchlistNoMatch => '이 항목을 관심 목록과 연결할 수 없습니다';
	@override String get openInLibrary => '라이브러리에서 열기';
	@override String get notInLibrary => '라이브러리에 없음';
	@override String get inTheseLibraries => '이 라이브러리에 있음';
	@override String get checkingLibrary => '라이브러리 확인 중...';
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
		one: '${n} result',
		other: '결과 ${n}개',
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
	@override String get unknownHub => '알 수 없음';
	@override String get unknownError => '알 수 없는 오류';
	@override String channelNumber({required Object number}) => '채널 ${number}';
	@override String get unknownChannel => '알 수 없는 채널';
	@override String get live => '실시간';
	@override String get reloadGuide => '편성표 새로고침';
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
	@override String get rulesProcessRequested => '규칙 재평가 요청됨';
	@override String get recordShow => '프로그램 녹화';
	@override late final _Translations$liveTv$recordSettings$ko recordSettings = _Translations$liveTv$recordSettings$ko._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes}분 후 시작';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product}에서 잘못된 실시간 TV 재생 데이터를 반환했습니다';
	@override String get failedToStartChannel => '실시간 채널을 시작할 수 없습니다';
	@override String get failedToBuildStreamUrl => '스트림 URL을 생성할 수 없습니다';
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
	@override String itemCount({required Object count}) => '${count}개 항목';
	@override String get oneItem => '1개 항목';
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
		one: '${n} track',
		other: '${n}곡',
	);
	@override String get nowPlaying => '재생 중';
	@override String playingFrom({required Object title}) => '${title}에서 재생 중';
	@override String get queue => '재생 대기열';
	@override String get clearQueue => '대기열 비우기';
	@override String get lyrics => '가사';
	@override String get noLyrics => '가사 없음';
	@override String get sleepTimer => '취침 타이머';
	@override String get sleepTimerEndOfTrack => '곡 종료 시';
	@override String sleepTimerMinutes({required Object n}) => '${n}분';
	@override String get stopPlayback => '재생 중지';
	@override String get previousTrack => '이전 곡';
	@override String get nextTrack => '다음 곡';
	@override String get repeat => '반복';
	@override String get repeatAll => '전체 반복';
	@override String get repeatOne => '한 곡 반복';
	@override String get instantMixNoServer => '즉석 믹스에 사용할 수 있는 서버가 없습니다';
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
	@override String get createSession => '세션 생성';
	@override String get creating => '생성 중...';
	@override String get joinSession => '세션 참여';
	@override String get joining => '참가 중...';
	@override String get controlMode => '제어 모드';
	@override String get controlModeQuestion => '누가 재생을 제어할 수 있나요?';
	@override String get hostOnly => '호스트만';
	@override String get anyone => '누구나';
	@override String get hostingSession => '세션 호스팅 중';
	@override String get inSession => '세션 중';
	@override String get sessionCode => '세션 코드';
	@override String get openSessionControls => '함께 보기 세션 제어 열기';
	@override String get copySessionCode => '세션 코드 복사';
	@override String get hostControlsPlayback => '호스트 재생 제어';
	@override String get anyoneCanControl => '누구나 재생 제어 가능';
	@override String get hostControls => '호스트 제어';
	@override String get anyoneControls => '누구나 제어';
	@override String get participants => '참가자';
	@override String get host => '호스트';
	@override String get hostBadge => '호스트';
	@override String get youAreHost => '호스트입니다';
	@override String get watchingWithOthers => '다른 사람과 함께 시청 중';
	@override String get endSession => '세션 종료';
	@override String get leaveSession => '세션 나가기';
	@override String get endSessionQuestion => '세션을 종료하시겠습니까?';
	@override String get leaveSessionQuestion => '세션에서 나가시겠습니까?';
	@override String get endSessionConfirm => '모든 참가자의 세션이 종료됩니다.';
	@override String get leaveSessionConfirm => '세션에서 나가게 됩니다.';
	@override String get endSessionConfirmOverlay => '모든 참가자의 함께 보기 세션이 종료됩니다.';
	@override String get leaveSessionConfirmOverlay => '함께 보기 세션의 연결이 끊어집니다.';
	@override String get end => '종료';
	@override String get leave => '나가기';
	@override String get syncing => '동기화 중...';
	@override String get joinWatchSession => '시청 세션에 참여';
	@override String get enterCodeHint => '5자리 코드 입력';
	@override String get pasteFromClipboard => '클립보드에서 붙여넣기';
	@override String get pleaseEnterCode => '세션 코드를 입력하세요';
	@override String get codeMustBe5Chars => '세션 코드는 반드시 5자리여야 합니다';
	@override String get joinInstructions => '참여하려면 호스트의 세션 코드를 입력하세요.';
	@override String get failedToCreate => '세션 생성 실패';
	@override String get failedToJoin => '세션 참여 실패';
	@override String get sessionCodeCopied => '세션 코드가 클립보드에 복사되었습니다';
	@override String get relayUnreachable => '릴레이 서버에 연결할 수 없습니다. ISP 차단으로 함께 보기를 사용하지 못할 수 있습니다.';
	@override String get reconnectingToHost => '호스트에 재연결 중...';
	@override String get currentPlayback => '현재 재생';
	@override String get joinCurrentPlayback => '현재 재생 참여';
	@override String get joinCurrentPlaybackDescription => '호스트가 현재 시청 중인 콘텐츠로 이동합니다';
	@override String get failedToOpenCurrentPlayback => '현재 재생을 열 수 없습니다';
	@override String participantJoined({required Object name}) => '${name}님이 참여했습니다';
	@override String participantLeft({required Object name}) => '${name}님이 나갔습니다';
	@override String participantPaused({required Object name}) => '${name}님이 일시정지했습니다';
	@override String participantResumed({required Object name}) => '${name}님이 재생했습니다';
	@override String participantSeeked({required Object name}) => '${name}님이 재생 위치를 변경했습니다';
	@override String participantBuffering({required Object name}) => '${name}님이 버퍼링 중입니다';
	@override String participantNeedsUpdate({required Object name}) => '${name}님이 이전 버전의 앱을 사용 중입니다 — 동기화를 사용할 수 없습니다';
	@override String resumingWithout({required Object name}) => '${name}님 없이 재생을 재개합니다';
	@override String get waitingForParticipants => '다른 참가자의 로딩을 기다리는 중...';
	@override String waitingForName({required Object name}) => '${name}님을 기다리는 중...';
	@override String get recentRooms => '최근 참여한 방';
	@override String get renameRoom => '방 이름 변경';
	@override String get removeRoom => '제거';
	@override String get guestSwitchUnavailable => '전환할 수 없음 — 동기화 서버를 사용할 수 없습니다';
	@override String get guestSwitchFailed => '전환할 수 없음 — 이 서버에서 콘텐츠를 찾을 수 없습니다';
	@override String get defaultDisplayName => '사용자';
	@override late final _Translations$watchTogether$errors$ko errors = _Translations$watchTogether$errors$ko._(_root);
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
	@override String get storageFull => '기기 저장 공간이 가득 차서 다운로드를 중지했습니다. 공간을 확보한 후 다시 시도하세요.';
	@override String episodesQueued({required Object count}) => '에피소드 ${count}개가 다운로드 대기열에 추가되었습니다';
	@override String get downloadDeleted => '다운로드 삭제됨';
	@override String deleteConfirm({required Object title}) => '이 기기에서 "${title}"을(를) 삭제할까요?';
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
	@override String get deleteAll => '모두 삭제';
	@override String get selectVersion => '버전 선택';
	@override String get allEpisodes => '모든 에피소드';
	@override String get unwatchedOnly => '시청하지 않은 것만';
	@override String nextNUnwatched({required Object count}) => '다음 ${count}개 미시청';
	@override String get customAmount => '직접 입력...';
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
	@override String get activeSyncRules => '동기화 규칙';
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
	@override String get syncRuleNotAvailableForProfile => '현재 프로필에서 사용할 수 없음';
	@override String get syncRuleUnknownServer => '알 수 없는 서버';
	@override String get syncRuleListCreated => '동기화 규칙이 생성되었습니다';
	@override late final _Translations$downloads$backgroundWarning$ko backgroundWarning = _Translations$downloads$backgroundWarning$ko._(_root);
	@override String get unknownShow => '알 수 없는 프로그램';
	@override String get unknownSeason => '알 수 없는 시즌';
	@override String get unknownAlbum => '알 수 없는 앨범';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} 완료';
	@override String get errorFileNotFound => '파일을 찾을 수 없음(404)';
	@override String get errorDownloadFailed => '다운로드 실패';
	@override String errorPostProcessing({required Object error}) => '후처리 실패: ${error}';
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
	@override String get performanceOverlay => '성능 오버레이';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => '서라운드';
	@override String get audioOutputSpatial => '공간 음향';
	@override String get audioOutputStereo => '스테레오';
	@override String get audioNormalization => '음량 정규화';
	@override String get audioDownmix => '스테레오로 다운믹스';
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
	@override String get notInitialized => '이 Seerr 인스턴스는 최초 실행 설정을 완료하지 않았습니다';
	@override String get noPlexTokenForReauth => '다시 로그인하는 데 사용할 수 있는 Plex 토큰이 없습니다';
	@override String get noStoredCredentials => '다시 로그인하는 데 사용할 수 있는 저장된 인증 정보가 없습니다';
	@override String get signInRejected => '로그인이 거부되었습니다';
	@override String get noSessionCookie => 'Seerr에서 세션 쿠키를 발급하지 않았습니다';
	@override String get freshCookieRejected => 'Seerr에서 새 세션 쿠키를 거부했습니다';
	@override String get noUserInformation => 'Seerr에서 사용자 정보를 반환하지 않았습니다';
	@override String get sessionRejectedAfterReauth => '다시 로그인한 후 세션이 거부되었습니다';
}

// Path: services
class _Translations$services$ko extends Translations$services$en {
	_Translations$services$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '서비스';
	@override String get hubSubtitle => '시청 진행률을 동기화하고 새 작품을 요청하세요.';
	@override String get notConnected => '연결되지 않음';
	@override String connectedAs({required Object username}) => '@${username}(으)로 연결됨';
	@override String get scrobble => '진행률 자동 추적';
	@override String get scrobbleDescription => '에피소드나 영화를 시청하면 목록을 업데이트합니다.';
	@override String disconnectConfirm({required Object service}) => '${service} 연결을 해제하시겠습니까?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy가 ${service} 업데이트를 중지합니다. 언제든 다시 연결할 수 있습니다.';
	@override String connectFailed({required Object service}) => '${service}에 연결할 수 없습니다. 다시 시도하세요.';
	@override late final _Translations$services$names$ko names = _Translations$services$names$ko._(_root);
	@override late final _Translations$services$deviceCode$ko deviceCode = _Translations$services$deviceCode$ko._(_root);
	@override late final _Translations$services$oauthProxy$ko oauthProxy = _Translations$services$oauthProxy$ko._(_root);
	@override late final _Translations$services$pendingAuth$ko pendingAuth = _Translations$services$pendingAuth$ko._(_root);
	@override late final _Translations$services$libraryFilter$ko libraryFilter = _Translations$services$libraryFilter$ko._(_root);
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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ko extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get critic => '평론가';
	@override String get audience => '관객';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes 평론가';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes 관객';
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
	@override String get shaderToggle => '셰이더 전환';
	@override String get skipMarker => '인트로/크레딧 건너뛰기';
	@override String get screenshot => '스크린샷 찍기';
	@override String get framePrevious => 'Previous Frame';
	@override String get frameNext => 'Next Frame';
}

// Path: videoControls.clip
class _Translations$videoControls$clip$ko extends Translations$videoControls$clip$en {
	_Translations$videoControls$clip$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Clip';
	@override String get vodOnly => 'Clips are available for on-demand video playback.';
	@override String get sourceUnavailable => 'Clip source is not available for this playback session.';
	@override String get playAtLeastOneSecond => 'Play at least 1 second before clipping.';
	@override String get startBeforeBeginning => 'Clip start cannot be before the beginning of the video.';
	@override String get endAfterStart => 'Clip end must be after the start.';
	@override String get minimumDuration => 'Clips must be at least 1 second long.';
	@override String get endPastVideo => 'Clip end is past the end of the video.';
	@override String get exportCanceled => 'Clip export canceled.';
	@override String get cacheUnavailable => 'The selected range could not be fully cached for Original export. Try a shorter clip or play the preview once before saving.';
	@override String get sourceCopyNoEncoder => 'Source-copy export does not use an encoder.';
	@override String get encodingDesktopOnly => 'H.264 and HEVC clip encoding is currently available on macOS and Windows.';
	@override String get hdrRequiresSource => 'HDR export requires a direct-play HDR10 or HLG-compatible source.';
	@override String get transcodeStartUnavailable => 'This clip starts before the active transcoded stream. Seek earlier and reopen clipping, or switch to original quality.';
	@override String get previewRequired => 'Clip preview must finish loading before it can be saved.';
	@override String get h264Failed => 'This source could not be encoded as an H.264 SDR MP4.';
	@override String get hevcSdrFailed => 'This source could not be encoded as an HEVC SDR MP4.';
	@override String get hevcHdrFailed => 'This source could not be encoded as an HEVC HDR MP4.';
	@override String get gifFailed => 'This source could not be encoded as a GIF.';
	@override String get originalFailed => 'This source could not be copied from the mpv cache.';
	@override String get previewUnavailable => 'Clip preview playback is not available in this build.';
	@override String get previewFailed => 'Clip preview playback failed.';
	@override String get previewLoadingScreenshot => 'The clip preview must finish loading before taking a screenshot.';
	@override String get screenshotInProgress => 'A screenshot is already being saved.';
	@override String get saveAsDialog => 'Save Clip As';
	@override String savedTo({required Object fileName}) => 'Saved to ${fileName}';
	@override String get openFolder => 'Open Folder';
	@override String get saveAs => 'Save As';
	@override String get cancelExport => 'Cancel Export';
	@override String get saving => 'Saving...';
	@override String savingProgress({required Object percent}) => 'Saving ${percent}%';
	@override String get mutePreview => 'Mute preview';
	@override String get unmutePreview => 'Unmute preview';
	@override String get formatHevcSdr => 'HEVC SDR';
	@override String get formatH264Sdr => 'H.264 SDR';
	@override String get formatHevcHdr => 'HEVC HDR';
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
		one: '${n} comment',
		other: '댓글 ${n}개',
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
		one: 'Recommended by ${n} user',
		other: '사용자 ${n}명이 추천',
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

// Path: watchTogether.errors
class _Translations$watchTogether$errors$ko extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get timedOut => '릴레이 서버가 제시간에 응답하지 않았습니다';
	@override String get connectionLost => '세션이 준비되기 전에 연결이 종료되었습니다';
	@override String get invalidRelayResponse => '릴레이 서버가 예기치 않은 응답을 보냈습니다';
	@override String get sessionEnded => '호스트가 세션을 종료했습니다';
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
	@override String get discoveryDescription => '같은 Plex 계정의 Plezy 기기가 여기에 표시됩니다';
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

// Path: services.deviceCode
class _Translations$services$deviceCode$ko extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service}에서 Plezy 활성화';
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
}

/// The flat map containing all translations for locale <ko>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsKo {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy Labs',
			'auth.signInWithPlex' => 'Plex 계정으로 로그인',
			'auth.showQRCode' => 'QR 코드 표시',
			'auth.authenticate' => '인증',
			'auth.authenticationTimeout' => '인증 시간이 초과되었습니다. 다시 시도해 주세요.',
			'auth.scanQRToSignIn' => '로그인하려면 이 QR 코드를 스캔하세요',
			'auth.waitingForAuth' => '인증 대기 중...\n브라우저에서 로그인하세요.',
			'auth.useBrowser' => '브라우저 사용',
			'auth.or' => '또는',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}에 연결',
			'auth.useQuickConnect' => 'Quick Connect 사용',
			'auth.quickConnectInstructions' => 'Jellyfin에서 Quick Connect를 열고 이 코드를 입력하세요.',
			'auth.quickConnectWaiting' => '승인 대기 중…',
			'auth.quickConnectCancel' => '취소',
			'auth.quickConnectExpired' => 'Quick Connect가 만료되었습니다. 다시 시도하세요.',
			'auth.localDataRecoveryRequired' => 'Plezy에서 로컬 로그인 정보와 대기 중인 재생 데이터를 안전하게 복구하지 못했습니다. 다시 로그인해 주세요.',
			'auth.pinCheckRejected' => 'Plex PIN 확인이 거부되었습니다',
			'common.cancel' => '취소',
			'common.save' => '저장',
			'common.close' => '닫기',
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
			'common.ratingSource.critic' => '평론가',
			'common.ratingSource.audience' => '관객',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes 평론가',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes 관객',
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
			'update.chooseChannelTitle' => 'Choose your update channel',
			'update.chooseChannelDescription' => 'Plezy Labs adds experimental features on top of published Plezy releases. You can use Labs updates or return to official Plezy.',
			'update.useLabs' => 'Use Plezy Labs',
			'update.returnToOfficial' => 'Return to Official Plezy',
			'update.returnToOfficialTitle' => 'Leave Plezy Labs?',
			'update.returnToOfficialWarning' => 'Labs-only features and preferences may no longer be available. Official Plezy cannot update back to Plezy Labs; reinstall Labs manually if you want to return.',
			'update.openOfficialRelease' => 'Open Official Release',
			'update.releaseNotes' => 'Release notes',
			'settings.title' => '설정',
			'settings.supportDeveloper' => 'Plezy 후원하기',
			'settings.supportDeveloperDescription' => 'Liberapay로 후원하여 개발 지원',
			'settings.language' => '언어',
			'settings.theme' => '테마',
			'settings.appearance' => '디자인',
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
			'settings.libraryDensity' => '라이브러리 표시 밀도',
			'settings.compact' => '조밀하게',
			'settings.comfortable' => '여유롭게',
			'settings.tvCornerSpotlightBackdrop' => '모서리 스포트라이트 배경',
			'settings.tvCornerSpotlightBackdropDescription' => '화면 전체를 채우는 대신 오른쪽 상단에 스포트라이트 아트워크를 표시합니다',
			'settings.viewMode' => '보기 모드',
			'settings.gridView' => '그리드 보기',
			'settings.listView' => '목록 보기',
			'settings.showHeroSection' => '주요 추천 영역 표시',
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
			'settings.packedStereoUi' => '3D Playback UI',
			'settings.bufferSize' => '버퍼 크기',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => '자동 (권장)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB 메모리를 사용할 수 있습니다. ${size}MB 버퍼는 재생에 영향을 줄 수 있습니다.',
			'settings.defaultQualityTitle' => '기본 화질',
			'settings.musicQualityTitle' => '음악 음질',
			'settings.subtitleStyling' => '자막 스타일',
			'settings.subtitleStylingDescription' => '자막 모양을 사용자 지정합니다',
			'settings.smallSkipDuration' => '짧은 건너뛰기 시간',
			'settings.largeSkipDuration' => '긴 건너뛰기 시간',
			'settings.rewindOnResume' => '재개 시 되감기',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds}초',
			'settings.defaultSleepTimer' => '기본 취침 타이머',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes}분',
			'settings.rememberTrackSelections' => '시리즈/영화별 트랙 선택 기억',
			'settings.rememberTrackSelectionsDescription' => '작품별 오디오 및 자막 선택 기억',
			'settings.followServerTrackSelections' => '서버의 에피소드별 트랙 선택 사용',
			'settings.followServerTrackSelectionsDescription' => '에피소드 전환 시 현재 선택을 유지하는 대신 서버에서 선택된 오디오와 자막을 적용합니다',
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
			'settings.watchTogetherRelayDescription' => '사용자 지정 릴레이를 설정합니다. 모두 같은 서버를 사용해야 합니다.',
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
			'settings.importSettingsInvalidFile' => '유효한 Plezy 설정 내보내기 파일이 아닙니다',
			'settings.importSettingsNoUser' => '설정을 가져오기 전에 로그인하세요',
			'settings.shortcutsReset' => '단축키가 기본값으로 재설정되었습니다',
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
			'settings.autoSkip' => '자동 건너뛰기',
			'settings.autoSkipIntro' => '자동으로 오프닝 건너뛰기',
			'settings.autoSkipIntroDescription' => '몇 초 후 오프닝을 자동으로 건너뛰기',
			'settings.autoSkipCredits' => '자동으로 엔딩 건너뛰기',
			'settings.autoSkipCreditsDescription' => '엔딩 크레딧 자동 건너뛰기 후 다음 에피소드 재생',
			'settings.forceSkipMarkerFallback' => '대체 마커 강제 사용',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex에 마커가 있어도 챕터 제목 패턴 사용',
			'settings.autoSkipDelay' => '자동 건너뛰기 지연',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '자동으로 건너뛰기 전 ${seconds}초 대기',
			'settings.introPattern' => '인트로 마커 패턴',
			'settings.introPatternDescription' => '챕터 제목에서 인트로 마커를 인식하는 정규식 패턴',
			'settings.creditsPattern' => '크레딧 마커 패턴',
			'settings.creditsPatternDescription' => '챕터 제목에서 크레딧 마커를 인식하는 정규식 패턴',
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
			'settings.downloadLocationSelectError' => 'Failed to select folder',
			'settings.mediaCapture' => 'Media Capture',
			'settings.clips' => 'Clips',
			'settings.screenshots' => 'Screenshots',
			'settings.captureLocationTitle' => ({required Object title}) => '${title} Location',
			'settings.clipLocationDescription' => 'Choose where clips are saved.',
			'settings.screenshotLocationDescription' => 'Choose where screenshots are saved.',
			'settings.clipLocationChanged' => 'Clip location changed',
			'settings.screenshotLocationChanged' => 'Screenshot location changed',
			'settings.clipLocationReset' => 'Clip location reset to Desktop',
			'settings.screenshotLocationReset' => 'Screenshot location reset to Desktop',
			'settings.downloadOnWifiOnly' => 'Wi-Fi 연결 시에만 다운로드',
			'settings.downloadOnWifiOnlyDescription' => '셀룰러 데이터 사용 중에는 다운로드하지 않습니다',
			'settings.autoRemoveWatchedDownloads' => '시청한 다운로드 항목 자동 삭제',
			'settings.autoRemoveWatchedDownloadsDescription' => '시청한 다운로드 항목을 자동으로 삭제합니다',
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
			'settings.tunneledPlaybackDescription' => '비디오 터널링을 사용합니다. HDR 재생 시 검은 화면이 보이면 비활성화하세요.',
			'settings.audioPassthrough' => '오디오 패스스루',
			'settings.audioPassthroughDescription' => 'Dolby/DTS 오디오를 재인코딩 없이 리시버나 TV로 전송하여 서라운드 사운드를 유지합니다. 소리가 나지 않으면 비활성화하세요.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Dolby Digital Plus(Atmos 포함)에 Apple의 기본 Dolby 디코더를 사용합니다. DTS와 TrueHD는 계속 멀티채널 PCM으로 재생됩니다. 소리가 나지 않으면 비활성화하세요.',
			'settings.audioDownmix' => '스테레오로 다운믹스',
			'settings.audioDownmixDescription' => '서라운드 오디오를 스테레오 스피커나 헤드폰용 2채널로 믹스합니다',
			'settings.downmixCenterBoost' => '센터 채널 부스트',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '부스트 (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '다운믹스 시 음량 정규화',
			'settings.audioDownmixNormalizeDescription' => '클리핑을 방지하기 위해 믹스 음량을 낮춥니다. 원래 음량을 유지하려면 끄세요(큰 소리 장면에서 왜곡될 수 있음).',
			'settings.dvConversionMode' => 'Dolby Vision 변환',
			'settings.dvConversionModeDescription' => 'ExoPlayer가 Dolby Vision Profile 7 파일을 처리하는 방식을 선택합니다.',
			'settings.dvConversionAuto' => '자동',
			'settings.dvConversionNative' => '네이티브 / 비활성화',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '기기 기능 감지와 일반 폴백 동작을 사용합니다',
			'settings.dvConversionNativeDescription' => '네이티브 DV7을 강제하고 DV 변환 재시도를 억제합니다',
			'settings.dvConversionDv81Description' => 'Dolby Vision 프로필 8.1로 인라인 RPU 변환을 강제합니다',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision RPU/EL 레이어를 제거하고 일반 HEVC로 제공합니다',
			'settings.demuxer' => '컨테이너 디먹서',
			'settings.demuxerDescription' => '다이렉트 재생 파일을 분석할 디먹서입니다. 파일이 제대로 재생되지 않으면 media3으로 전환하세요.',
			'settings.demuxerFfmpeg' => 'FFmpeg (권장)',
			'settings.demuxerMedia3' => 'media3',
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
			'settings.liveTvDefaultFavorites' => '즐겨찾기 채널 기본 설정',
			'settings.liveTvDefaultFavoritesDescription' => '라이브 TV를 열 때 즐겨찾기 채널만 표시',
			'settings.display' => '디스플레이',
			'settings.homeScreen' => '홈 화면',
			'settings.navigation' => '탐색',
			'settings.window' => '창',
			'settings.content' => '콘텐츠',
			'settings.player' => '플레이어',
			'settings.subtitlesAndConfig' => '자막 및 구성',
			'settings.seekAndTiming' => '탐색 및 타이밍',
			'settings.behavior' => '동작',
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
			'settings.exportDialogTitle' => 'Plezy 설정 내보내기',
			'settings.displayScale' => '표시 배율',
			'settings.playbackBuffer' => '재생 버퍼',
			'settings.playbackBufferAuto' => '자동 (권장)',
			'settings.playbackBufferLarge' => '대형',
			'settings.playbackBufferExtraLarge' => '초대형',
			'settings.playbackBufferDescription' => '불안정한 연결에 대비해 더 많은 버퍼를 사용합니다. 버퍼 크기에 의해서도 제한됩니다.',
			'settings.showExploreTab' => '둘러보기 탭 표시',
			'settings.showExploreTabDescription' => 'Plex Discover와 연결된 트래커의 콘텐츠가 포함된 둘러보기 탭을 표시합니다',
			'settings.officialPlezy' => 'Official Plezy',
			'settings.plezyLabs' => 'Plezy Labs',
			'settings.labsNotAvailable' => ({required Object version}) => 'Plezy Labs for Plezy ${version} is not available yet',
			'settings.latestLabsRelease' => ({required Object version}) => 'Latest Labs release: ${version}',
			'settings.latestOfficialRelease' => ({required Object version}) => 'Latest official release: ${version}',
			'settings.releaseStatusUnavailable' => 'Release status unavailable',
			'search.hint' => '영화, 시리즈, 음악 등을 검색하세요...',
			'search.tryDifferentTerm' => '다른 검색어를 시도해 보세요',
			'search.searchYourMedia' => '미디어 검색',
			'search.enterTitleActorOrKeyword' => '제목, 배우 또는 키워드를 입력하세요',
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
			'hotkeys.actions.shaderToggle' => '셰이더 전환',
			'hotkeys.actions.skipMarker' => '인트로/크레딧 건너뛰기',
			'hotkeys.actions.screenshot' => '스크린샷 찍기',
			'hotkeys.actions.framePrevious' => 'Previous Frame',
			'hotkeys.actions.frameNext' => 'Next Frame',
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
			_ => null,
		} ?? switch (path) {
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: 'This deletes all ${n} episode in it, and its file.', other: '포함된 에피소드 ${n}개와 해당 파일이 모두 삭제됩니다.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: 'This item is stored as ${n} file, which will be deleted.', other: '이 항목은 파일 ${n}개에 걸쳐 저장되어 있으며, 모든 파일이 삭제됩니다.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} other episode is stored in the same file and will be deleted too:', other: '같은 파일에 저장된 다른 에피소드 ${n}개도 함께 삭제됩니다:', ), 
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
			'tooltips.shufflePlay' => '무작위 재생',
			'tooltips.playTrailer' => '예고편 재생',
			'tooltips.markAsWatched' => '시청 완료로 표시',
			'tooltips.markAsUnwatched' => '미시청으로 표시',
			'audioTracks.track' => ({required Object n}) => '오디오 트랙 ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} frame', other: '${n} frames', ), 
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
			'videoControls.versionQualityButton' => '버전 및 화질',
			'videoControls.versionColumnHeader' => '버전',
			'videoControls.qualityColumnHeader' => '화질',
			'videoControls.qualityOriginal' => '원본',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => '트랜스코딩을 사용할 수 없음 — 원본 화질로 재생',
			'videoControls.subtitleUnavailableFallback' => '선택한 자막을 불러올 수 없어 자막 없이 재생을 계속합니다',
			'videoControls.pipButton' => '픽처 인 픽처 모드',
			'videoControls.aspectRatioButton' => '화면비율',
			'videoControls.packedStereoSizingLocked' => 'Cannot change while playing 3D source',
			'videoControls.ambientLighting' => '주변 조명',
			'videoControls.fullscreenButton' => '전체 화면',
			'videoControls.exitFullscreenButton' => '전체 화면 종료',
			'videoControls.alwaysOnTopButton' => '창 최상위 고정',
			'videoControls.rotationLockButton' => '회전 잠금',
			'videoControls.lockScreen' => '화면 잠금',
			'videoControls.screenLockButton' => '화면 잠금',
			'videoControls.longPressToUnlock' => '길게 눌러 잠금 해제',
			'videoControls.timelineSlider' => '타임라인',
			'videoControls.volumeSlider' => '볼륨 조절',
			'videoControls.endsAt' => ({required Object time}) => '${time}에 종료',
			'videoControls.pipActive' => '화면 속 화면으로 재생 중',
			'videoControls.pipFailed' => '화면 속 화면 모드를 시작할 수 없습니다',
			'videoControls.screenshotSaved' => '스크린샷 저장됨',
			'videoControls.clip.title' => 'Clip',
			'videoControls.clip.vodOnly' => 'Clips are available for on-demand video playback.',
			'videoControls.clip.sourceUnavailable' => 'Clip source is not available for this playback session.',
			'videoControls.clip.playAtLeastOneSecond' => 'Play at least 1 second before clipping.',
			'videoControls.clip.startBeforeBeginning' => 'Clip start cannot be before the beginning of the video.',
			'videoControls.clip.endAfterStart' => 'Clip end must be after the start.',
			'videoControls.clip.minimumDuration' => 'Clips must be at least 1 second long.',
			'videoControls.clip.endPastVideo' => 'Clip end is past the end of the video.',
			'videoControls.clip.exportCanceled' => 'Clip export canceled.',
			'videoControls.clip.cacheUnavailable' => 'The selected range could not be fully cached for Original export. Try a shorter clip or play the preview once before saving.',
			'videoControls.clip.sourceCopyNoEncoder' => 'Source-copy export does not use an encoder.',
			'videoControls.clip.encodingDesktopOnly' => 'H.264 and HEVC clip encoding is currently available on macOS and Windows.',
			'videoControls.clip.hdrRequiresSource' => 'HDR export requires a direct-play HDR10 or HLG-compatible source.',
			'videoControls.clip.transcodeStartUnavailable' => 'This clip starts before the active transcoded stream. Seek earlier and reopen clipping, or switch to original quality.',
			'videoControls.clip.previewRequired' => 'Clip preview must finish loading before it can be saved.',
			'videoControls.clip.h264Failed' => 'This source could not be encoded as an H.264 SDR MP4.',
			'videoControls.clip.hevcSdrFailed' => 'This source could not be encoded as an HEVC SDR MP4.',
			'videoControls.clip.hevcHdrFailed' => 'This source could not be encoded as an HEVC HDR MP4.',
			'videoControls.clip.gifFailed' => 'This source could not be encoded as a GIF.',
			'videoControls.clip.originalFailed' => 'This source could not be copied from the mpv cache.',
			'videoControls.clip.previewUnavailable' => 'Clip preview playback is not available in this build.',
			'videoControls.clip.previewFailed' => 'Clip preview playback failed.',
			'videoControls.clip.previewLoadingScreenshot' => 'The clip preview must finish loading before taking a screenshot.',
			'videoControls.clip.screenshotInProgress' => 'A screenshot is already being saved.',
			'videoControls.clip.saveAsDialog' => 'Save Clip As',
			'videoControls.clip.savedTo' => ({required Object fileName}) => 'Saved to ${fileName}',
			'videoControls.clip.openFolder' => 'Open Folder',
			'videoControls.clip.saveAs' => 'Save As',
			'videoControls.clip.cancelExport' => 'Cancel Export',
			'videoControls.clip.saving' => 'Saving...',
			'videoControls.clip.savingProgress' => ({required Object percent}) => 'Saving ${percent}%',
			'videoControls.clip.mutePreview' => 'Mute preview',
			'videoControls.clip.unmutePreview' => 'Unmute preview',
			'videoControls.clip.formatHevcSdr' => 'HEVC SDR',
			'videoControls.clip.formatH264Sdr' => 'H.264 SDR',
			'videoControls.clip.formatHevcHdr' => 'HEVC HDR',
			'videoControls.zoomPercent' => ({required Object percent}) => '확대/축소 ${percent}%',
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
			'messages.markedAsWatched' => '시청 완료로 표시됨',
			'messages.markedAsUnwatched' => '미시청으로 표시됨',
			'messages.markedAsWatchedOffline' => '시청 완료로 표시됨 (연결 시 동기화됨)',
			'messages.markedAsUnwatchedOffline' => '미시청으로 표시됨 (연결 시 동기화됨)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '자동 삭제됨: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: 'Auto-removed ${n} watched download', other: '시청한 다운로드 ${n}개를 자동 삭제했습니다', ), 
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
			'messages.logsUploaded' => '로그 업로드 완료',
			'messages.logsUploadFailed' => '로그 업로드 실패',
			'messages.logId' => '로그 ID',
			'messages.burnedSubtitlesUseMenu' => '자막이 이 스트림에 입혀져 있습니다. 자막 메뉴에서 변경하세요.',
			'messages.noVideoUrl' => '사용 가능한 비디오 URL이 없습니다',
			'messages.playbackNoMediaSources' => '서버에서 재생 가능한 미디어 소스를 반환하지 않았습니다',
			'messages.playbackDataNotPrepared' => '재생 데이터가 준비되기 전에 재생이 시작되었습니다',
			'messages.streamSelectionUnavailable' => '이 소스에서는 스트림을 선택할 수 없습니다',
			'messages.streamSelectionFailed' => '선택한 스트림을 적용할 수 없습니다',
			'messages.serverUnavailableForProfile' => '활성 프로필에 사용할 수 있는 서버가 없습니다',
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
			'subtitlingStyling.anchorToScreen' => '화면에 고정',
			'subtitlingStyling.anchorToScreenDescription' => '와이드스크린 비디오 아래의 검은 여백에 텍스트 자막을 표시합니다',
			'subtitlingStyling.bold' => '굵게',
			'subtitlingStyling.italic' => '기울임꼴',
			'subtitlingStyling.renderResolution' => '렌더링 해상도',
			'subtitlingStyling.renderResolutionScreen' => '화면 해상도',
			'subtitlingStyling.renderResolutionVideo' => '영상 해상도',
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
			'mpvConfig.embeddedVoHint' => 'Linux에서는 vo, gpu-context, gpu-api가 무시됩니다. 내장 동영상은 항상 비디오 평면에서 vo=libmpv로 렌더링되며, gpu-next(ArtCNN 같은 컴퓨트 셰이더에 필요)는 내장 방식으로 실행할 수 없습니다.',
			'dialog.confirmAction' => '작업 확인',
			'profiles.addPlezyProfile' => 'Plezy 프로필 추가',
			'profiles.switchingProfile' => '프로필 전환 중…',
			'profiles.deleteThisProfileTitle' => '이 프로필을 삭제하시겠습니까?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName}을(를) 제거합니다. 연결에는 영향이 없습니다.',
			'profiles.active' => '활성',
			'profiles.manage' => '관리',
			'profiles.delete' => '삭제',
			'profiles.signOut' => '로그아웃',
			'profiles.signOutPlexTitle' => 'Plex에서 로그아웃하시겠습니까?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} 및 모든 Plex Home 사용자를 제거할까요? 언제든 다시 로그인할 수 있습니다.',
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
			'profiles.borrowEmptySubtitle' => '먼저 다른 프로필에 Plex 또는 Jellyfin을 연결하세요.',
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
			'connections.sectionTitle' => '연결',
			'connections.addConnection' => '연결 추가',
			'connections.addConnectionSubtitleNoProfile' => 'Plex로 로그인하거나 Jellyfin 서버에 연결',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}에 추가: Plex, Jellyfin 또는 다른 프로필 연결',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name}의 세션이 만료되었습니다',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count}개 서버의 세션이 만료되었습니다',
			'connections.signInAgain' => '다시 로그인',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product} 연결 편집',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName}의 URL을 추가하거나 제거하세요. Plezy는 연결 가능한 URL 중 지연 시간이 가장 낮은 URL을 사용합니다.',
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
			'discover.extras' => '예고편 및 부가영상',
			'discover.studio' => '제작사',
			'discover.rating' => '연령 등급',
			'discover.director' => '감독',
			'discover.directors' => '감독',
			'discover.movie' => '영화',
			'discover.tvShow' => 'TV 시리즈',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes}분 남음',
			'discover.moreLikeThis' => '비슷한 콘텐츠',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} title', other: '${n}개 타이틀', ), 
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
			_ => null,
		} ?? switch (path) {
			'libraries.sortLabels.startDate' => '시작일',
			'libraries.sortLabels.airTime' => '방영 시간',
			'libraries.sortLabels.studio' => '스튜디오',
			'libraries.sortLabels.random' => '무작위',
			'libraries.sortLabels.dateShared' => '공유된 날짜',
			'libraries.sortLabels.latestEpisodeAirDate' => '최신 에피소드 방영일',
			'libraries.sortLabels.lastEpisodeDateAdded' => '최신 에피소드 추가일',
			'about.title' => '소개',
			'about.openSourceLicenses' => '오픈소스 라이선스',
			'about.versionLabel' => ({required Object version}) => '버전 ${version}',
			'about.appDescription' => 'Flutter로 만든 아름다운 Plex 및 Jellyfin 클라이언트',
			'about.viewLicensesDescription' => '타사 라이브러리 라이선스 보기',
			'about.labsDescription' => 'An experimental Plezy edition built only on published official releases',
			'about.labsModifiedNotice' => 'Plezy Labs is a modified GPL-3.0 build maintained by RyanTheTechMan, not an official Plezy release.',
			'about.labsSource' => 'Plezy Labs source code',
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
			'startup.quitPlezy' => 'Plezy 종료',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} episode', other: '${n}화', ), 
			'explore.cast' => '출연진',
			'explore.characters' => '캐릭터',
			'explore.addToWatchlist' => '관심 목록에 추가',
			'explore.removeFromWatchlist' => '관심 목록에서 제거',
			'explore.addedToWatchlist' => '관심 목록에 추가했습니다',
			'explore.removedFromWatchlist' => '관심 목록에서 삭제했습니다',
			'explore.watchlistUpdateFailed' => '관심 목록을 업데이트하지 못했습니다',
			'explore.watchlistNoMatch' => '이 항목을 관심 목록과 연결할 수 없습니다',
			'explore.openInLibrary' => '라이브러리에서 열기',
			'explore.notInLibrary' => '라이브러리에 없음',
			'explore.inTheseLibraries' => '이 라이브러리에 있음',
			'explore.checkingLibrary' => '라이브러리 확인 중...',
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} comment', other: '댓글 ${n}개', ), 
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: 'Recommended by ${n} user', other: '사용자 ${n}명이 추천', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} 추천',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who} 즐겨찾기',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '미방영 ${n}개',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '시청자의 ${percent} 추천',
			'explore.detail.relatedTitles' => '관련 작품',
			'explore.detail.background' => '배경',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} result', other: '결과 ${n}개', ), 
			'liveTv.title' => '실시간 TV',
			'liveTv.guide' => '편성표',
			'liveTv.noChannels' => '사용 가능한 채널이 없습니다',
			'liveTv.noDvr' => '서버에 DVR이 구성되어 있지 않습니다',
			'liveTv.serverUnavailable' => '라이브 TV 서버를 사용할 수 없습니다.',
			'liveTv.serverNotConnected' => '라이브 TV 서버에 연결되어 있지 않습니다.',
			'liveTv.noPrograms' => '프로그램 데이터가 없습니다',
			'liveTv.liveStreamFailed' => '라이브 스트림 실패',
			'liveTv.unknownProgram' => '알 수 없는 프로그램',
			'liveTv.unknownHub' => '알 수 없음',
			'liveTv.unknownError' => '알 수 없는 오류',
			'liveTv.channelNumber' => ({required Object number}) => '채널 ${number}',
			'liveTv.unknownChannel' => '알 수 없는 채널',
			'liveTv.live' => '실시간',
			'liveTv.reloadGuide' => '편성표 새로고침',
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
			'liveTv.rulesProcessRequested' => '규칙 재평가 요청됨',
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
			'playlists.itemCount' => ({required Object count}) => '${count}개 항목',
			'playlists.oneItem' => '1개 항목',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ko'))(n, one: '${n} track', other: '${n}곡', ), 
			'music.nowPlaying' => '재생 중',
			'music.playingFrom' => ({required Object title}) => '${title}에서 재생 중',
			'music.queue' => '재생 대기열',
			'music.clearQueue' => '대기열 비우기',
			'music.lyrics' => '가사',
			'music.noLyrics' => '가사 없음',
			'music.sleepTimer' => '취침 타이머',
			'music.sleepTimerEndOfTrack' => '곡 종료 시',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n}분',
			'music.stopPlayback' => '재생 중지',
			'music.previousTrack' => '이전 곡',
			'music.nextTrack' => '다음 곡',
			'music.repeat' => '반복',
			'music.repeatAll' => '전체 반복',
			'music.repeatOne' => '한 곡 반복',
			'music.instantMixNoServer' => '즉석 믹스에 사용할 수 있는 서버가 없습니다',
			'music.noAudioUrl' => ({required Object track}) => '${track}에 사용할 수 있는 오디오 URL이 없습니다',
			'music.discography.singlesAndEps' => '싱글 및 EP',
			'music.discography.live' => '라이브',
			'music.discography.compilations' => '컴필레이션',
			'watchTogether.title' => '함께 보기',
			'watchTogether.description' => '친구 및 가족과 콘텐츠를 동시에 시청하세요',
			'watchTogether.createSession' => '세션 생성',
			'watchTogether.creating' => '생성 중...',
			'watchTogether.joinSession' => '세션 참여',
			'watchTogether.joining' => '참가 중...',
			'watchTogether.controlMode' => '제어 모드',
			'watchTogether.controlModeQuestion' => '누가 재생을 제어할 수 있나요?',
			'watchTogether.hostOnly' => '호스트만',
			'watchTogether.anyone' => '누구나',
			'watchTogether.hostingSession' => '세션 호스팅 중',
			'watchTogether.inSession' => '세션 중',
			'watchTogether.sessionCode' => '세션 코드',
			'watchTogether.openSessionControls' => '함께 보기 세션 제어 열기',
			'watchTogether.copySessionCode' => '세션 코드 복사',
			'watchTogether.hostControlsPlayback' => '호스트 재생 제어',
			'watchTogether.anyoneCanControl' => '누구나 재생 제어 가능',
			'watchTogether.hostControls' => '호스트 제어',
			'watchTogether.anyoneControls' => '누구나 제어',
			'watchTogether.participants' => '참가자',
			'watchTogether.host' => '호스트',
			'watchTogether.hostBadge' => '호스트',
			'watchTogether.youAreHost' => '호스트입니다',
			'watchTogether.watchingWithOthers' => '다른 사람과 함께 시청 중',
			'watchTogether.endSession' => '세션 종료',
			'watchTogether.leaveSession' => '세션 나가기',
			'watchTogether.endSessionQuestion' => '세션을 종료하시겠습니까?',
			'watchTogether.leaveSessionQuestion' => '세션에서 나가시겠습니까?',
			'watchTogether.endSessionConfirm' => '모든 참가자의 세션이 종료됩니다.',
			'watchTogether.leaveSessionConfirm' => '세션에서 나가게 됩니다.',
			'watchTogether.endSessionConfirmOverlay' => '모든 참가자의 함께 보기 세션이 종료됩니다.',
			'watchTogether.leaveSessionConfirmOverlay' => '함께 보기 세션의 연결이 끊어집니다.',
			'watchTogether.end' => '종료',
			'watchTogether.leave' => '나가기',
			'watchTogether.syncing' => '동기화 중...',
			'watchTogether.joinWatchSession' => '시청 세션에 참여',
			'watchTogether.enterCodeHint' => '5자리 코드 입력',
			'watchTogether.pasteFromClipboard' => '클립보드에서 붙여넣기',
			'watchTogether.pleaseEnterCode' => '세션 코드를 입력하세요',
			'watchTogether.codeMustBe5Chars' => '세션 코드는 반드시 5자리여야 합니다',
			'watchTogether.joinInstructions' => '참여하려면 호스트의 세션 코드를 입력하세요.',
			'watchTogether.failedToCreate' => '세션 생성 실패',
			'watchTogether.failedToJoin' => '세션 참여 실패',
			'watchTogether.sessionCodeCopied' => '세션 코드가 클립보드에 복사되었습니다',
			'watchTogether.relayUnreachable' => '릴레이 서버에 연결할 수 없습니다. ISP 차단으로 함께 보기를 사용하지 못할 수 있습니다.',
			'watchTogether.reconnectingToHost' => '호스트에 재연결 중...',
			'watchTogether.currentPlayback' => '현재 재생',
			'watchTogether.joinCurrentPlayback' => '현재 재생 참여',
			'watchTogether.joinCurrentPlaybackDescription' => '호스트가 현재 시청 중인 콘텐츠로 이동합니다',
			'watchTogether.failedToOpenCurrentPlayback' => '현재 재생을 열 수 없습니다',
			'watchTogether.participantJoined' => ({required Object name}) => '${name}님이 참여했습니다',
			'watchTogether.participantLeft' => ({required Object name}) => '${name}님이 나갔습니다',
			'watchTogether.participantPaused' => ({required Object name}) => '${name}님이 일시정지했습니다',
			'watchTogether.participantResumed' => ({required Object name}) => '${name}님이 재생했습니다',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name}님이 재생 위치를 변경했습니다',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name}님이 버퍼링 중입니다',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name}님이 이전 버전의 앱을 사용 중입니다 — 동기화를 사용할 수 없습니다',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name}님 없이 재생을 재개합니다',
			'watchTogether.waitingForParticipants' => '다른 참가자의 로딩을 기다리는 중...',
			'watchTogether.waitingForName' => ({required Object name}) => '${name}님을 기다리는 중...',
			'watchTogether.recentRooms' => '최근 참여한 방',
			'watchTogether.renameRoom' => '방 이름 변경',
			'watchTogether.removeRoom' => '제거',
			'watchTogether.guestSwitchUnavailable' => '전환할 수 없음 — 동기화 서버를 사용할 수 없습니다',
			'watchTogether.guestSwitchFailed' => '전환할 수 없음 — 이 서버에서 콘텐츠를 찾을 수 없습니다',
			'watchTogether.defaultDisplayName' => '사용자',
			'watchTogether.errors.timedOut' => '릴레이 서버가 제시간에 응답하지 않았습니다',
			'watchTogether.errors.connectionLost' => '세션이 준비되기 전에 연결이 종료되었습니다',
			'watchTogether.errors.invalidRelayResponse' => '릴레이 서버가 예기치 않은 응답을 보냈습니다',
			'watchTogether.errors.sessionEnded' => '호스트가 세션을 종료했습니다',
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
			'downloads.storageFull' => '기기 저장 공간이 가득 차서 다운로드를 중지했습니다. 공간을 확보한 후 다시 시도하세요.',
			'downloads.episodesQueued' => ({required Object count}) => '에피소드 ${count}개가 다운로드 대기열에 추가되었습니다',
			'downloads.downloadDeleted' => '다운로드 삭제됨',
			'downloads.deleteConfirm' => ({required Object title}) => '이 기기에서 "${title}"을(를) 삭제할까요?',
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
			'downloads.deleteAll' => '모두 삭제',
			'downloads.selectVersion' => '버전 선택',
			'downloads.allEpisodes' => '모든 에피소드',
			'downloads.unwatchedOnly' => '시청하지 않은 것만',
			'downloads.nextNUnwatched' => ({required Object count}) => '다음 ${count}개 미시청',
			'downloads.customAmount' => '직접 입력...',
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
			'downloads.activeSyncRules' => '동기화 규칙',
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
			'downloads.syncRuleNotAvailableForProfile' => '현재 프로필에서 사용할 수 없음',
			'downloads.syncRuleUnknownServer' => '알 수 없는 서버',
			'downloads.syncRuleListCreated' => '동기화 규칙이 생성되었습니다',
			'downloads.backgroundWarning.bannerBlocked' => '앱에서 나가면 다운로드가 중지됩니다',
			'downloads.backgroundWarning.bannerDegraded' => '백그라운드 다운로드가 제한될 수 있습니다',
			'downloads.backgroundWarning.bannerAction' => '세부정보',
			'downloads.backgroundWarning.sheetTitle' => '백그라운드 다운로드가 차단됨',
			'downloads.backgroundWarning.sheetTitleDegraded' => '백그라운드 다운로드가 제한될 수 있음',
			_ => null,
		} ?? switch (path) {
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
			'downloads.unknownShow' => '알 수 없는 프로그램',
			'downloads.unknownSeason' => '알 수 없는 시즌',
			'downloads.unknownAlbum' => '알 수 없는 앨범',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} 완료',
			'downloads.errorFileNotFound' => '파일을 찾을 수 없음(404)',
			'downloads.errorDownloadFailed' => '다운로드 실패',
			'downloads.errorPostProcessing' => ({required Object error}) => '후처리 실패: ${error}',
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
			'companionRemote.pairing.discoveryDescription' => '같은 Plex 계정의 Plezy 기기가 여기에 표시됩니다',
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
			'videoSettings.performanceOverlay' => '성능 오버레이',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => '서라운드',
			'videoSettings.audioOutputSpatial' => '공간 음향',
			'videoSettings.audioOutputStereo' => '스테레오',
			'videoSettings.audioNormalization' => '음량 정규화',
			'videoSettings.audioDownmix' => '스테레오로 다운믹스',
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
			'seerr.notInitialized' => '이 Seerr 인스턴스는 최초 실행 설정을 완료하지 않았습니다',
			'seerr.noPlexTokenForReauth' => '다시 로그인하는 데 사용할 수 있는 Plex 토큰이 없습니다',
			'seerr.noStoredCredentials' => '다시 로그인하는 데 사용할 수 있는 저장된 인증 정보가 없습니다',
			'seerr.signInRejected' => '로그인이 거부되었습니다',
			'seerr.noSessionCookie' => 'Seerr에서 세션 쿠키를 발급하지 않았습니다',
			'seerr.freshCookieRejected' => 'Seerr에서 새 세션 쿠키를 거부했습니다',
			'seerr.noUserInformation' => 'Seerr에서 사용자 정보를 반환하지 않았습니다',
			'seerr.sessionRejectedAfterReauth' => '다시 로그인한 후 세션이 거부되었습니다',
			'services.title' => '서비스',
			'services.hubSubtitle' => '시청 진행률을 동기화하고 새 작품을 요청하세요.',
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
			'services.deviceCode.title' => ({required Object service}) => '${service}에서 Plezy 활성화',
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
			_ => null,
		};
	}
}
