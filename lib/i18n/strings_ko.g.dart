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
class TranslationsKo with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsKo({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ko>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsKo _root = this; // ignore: unused_field

	@override 
	TranslationsKo $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsKo(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppKo app = _TranslationsAppKo._(_root);
	@override late final _TranslationsAuthKo auth = _TranslationsAuthKo._(_root);
	@override late final _TranslationsCommonKo common = _TranslationsCommonKo._(_root);
	@override late final _TranslationsScreensKo screens = _TranslationsScreensKo._(_root);
	@override late final _TranslationsUpdateKo update = _TranslationsUpdateKo._(_root);
	@override late final _TranslationsSettingsKo settings = _TranslationsSettingsKo._(_root);
	@override late final _TranslationsSearchKo search = _TranslationsSearchKo._(_root);
	@override late final _TranslationsHotkeysKo hotkeys = _TranslationsHotkeysKo._(_root);
	@override late final _TranslationsFileInfoKo fileInfo = _TranslationsFileInfoKo._(_root);
	@override late final _TranslationsMediaMenuKo mediaMenu = _TranslationsMediaMenuKo._(_root);
	@override late final _TranslationsAccessibilityKo accessibility = _TranslationsAccessibilityKo._(_root);
	@override late final _TranslationsTooltipsKo tooltips = _TranslationsTooltipsKo._(_root);
	@override late final _TranslationsVideoControlsKo videoControls = _TranslationsVideoControlsKo._(_root);
	@override late final _TranslationsUserStatusKo userStatus = _TranslationsUserStatusKo._(_root);
	@override late final _TranslationsMessagesKo messages = _TranslationsMessagesKo._(_root);
	@override late final _TranslationsSubtitlingStylingKo subtitlingStyling = _TranslationsSubtitlingStylingKo._(_root);
	@override late final _TranslationsMpvConfigKo mpvConfig = _TranslationsMpvConfigKo._(_root);
	@override late final _TranslationsDialogKo dialog = _TranslationsDialogKo._(_root);
	@override late final _TranslationsDiscoverKo discover = _TranslationsDiscoverKo._(_root);
	@override late final _TranslationsErrorsKo errors = _TranslationsErrorsKo._(_root);
	@override late final _TranslationsLibrariesKo libraries = _TranslationsLibrariesKo._(_root);
	@override late final _TranslationsAboutKo about = _TranslationsAboutKo._(_root);
	@override late final _TranslationsServerSelectionKo serverSelection = _TranslationsServerSelectionKo._(_root);
	@override late final _TranslationsHubDetailKo hubDetail = _TranslationsHubDetailKo._(_root);
	@override late final _TranslationsLogsKo logs = _TranslationsLogsKo._(_root);
	@override late final _TranslationsLicensesKo licenses = _TranslationsLicensesKo._(_root);
	@override late final _TranslationsNavigationKo navigation = _TranslationsNavigationKo._(_root);
	@override late final _TranslationsLiveTvKo liveTv = _TranslationsLiveTvKo._(_root);
	@override late final _TranslationsCollectionsKo collections = _TranslationsCollectionsKo._(_root);
	@override late final _TranslationsPlaylistsKo playlists = _TranslationsPlaylistsKo._(_root);
	@override late final _TranslationsWatchTogetherKo watchTogether = _TranslationsWatchTogetherKo._(_root);
	@override late final _TranslationsDownloadsKo downloads = _TranslationsDownloadsKo._(_root);
	@override late final _TranslationsShadersKo shaders = _TranslationsShadersKo._(_root);
	@override late final _TranslationsCompanionRemoteKo companionRemote = _TranslationsCompanionRemoteKo._(_root);
	@override late final _TranslationsVideoSettingsKo videoSettings = _TranslationsVideoSettingsKo._(_root);
	@override late final _TranslationsExternalPlayerKo externalPlayer = _TranslationsExternalPlayerKo._(_root);
	@override late final _TranslationsMetadataEditKo metadataEdit = _TranslationsMetadataEditKo._(_root);
	@override late final _TranslationsMatchScreenKo matchScreen = _TranslationsMatchScreenKo._(_root);
	@override late final _TranslationsServerTasksKo serverTasks = _TranslationsServerTasksKo._(_root);
	@override late final _TranslationsTraktKo trakt = _TranslationsTraktKo._(_root);
	@override late final _TranslationsTrackersKo trackers = _TranslationsTrackersKo._(_root);
}

// Path: app
class _TranslationsAppKo implements TranslationsAppEn {
	_TranslationsAppKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthKo implements TranslationsAuthEn {
	_TranslationsAuthKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex 계정으로 로그인';
	@override String get showQRCode => 'QR 코드';
	@override String get authenticate => '인증';
	@override String get authenticationTimeout => '인증 시간이 초과되었습니다. 다시 시도해 주세요.';
	@override String get scanQRToSignIn => 'QR 코드를 스캔하여 로그인';
	@override String get waitingForAuth => '인증 대기 중... 브라우저에서 로그인을 완료해 주세요.';
	@override String get useBrowser => '브라우저 사용';
}

// Path: common
class _TranslationsCommonKo implements TranslationsCommonEn {
	_TranslationsCommonKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get cancel => '취소';
	@override String get save => '저장';
	@override String get close => '닫기';
	@override String get clear => '지우기';
	@override String get reset => '초기화';
	@override String get later => '나중에';
	@override String get submit => '보내기';
	@override String get confirm => '확인';
	@override String get retry => '재시도';
	@override String get logout => '로그아웃';
	@override String get unknown => '알 수 없는';
	@override String get refresh => '새로고침';
	@override String get yes => '예';
	@override String get no => '아니오';
	@override String get delete => '삭제';
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
	@override String get reconnect => '다시 연결';
	@override String get exitConfirmTitle => '앱을 종료하시겠습니까?';
	@override String get exitConfirmMessage => '정말 종료하시겠습니까?';
	@override String get dontAskAgain => '다시 묻지 않기';
	@override String get exit => '종료';
	@override String get viewAll => '모두 보기';
	@override String get checkingNetwork => '네트워크 확인 중...';
	@override String get refreshingServers => '서버 새로고침 중...';
	@override String get loadingServers => '서버 로딩 중...';
	@override String get connectingToServers => '서버 연결 중...';
	@override String get startingOfflineMode => '오프라인 모드 시작 중...';
	@override String get loading => '로딩 중...';
	@override String get fullscreen => '전체화면';
	@override String get exitFullscreen => '전체화면 종료';
}

// Path: screens
class _TranslationsScreensKo implements TranslationsScreensEn {
	_TranslationsScreensKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get licenses => '라이선스';
	@override String get switchProfile => '프로필 전환';
	@override String get subtitleStyling => '자막 스타일 설정';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => '로그';
}

// Path: update
class _TranslationsUpdateKo implements TranslationsUpdateEn {
	_TranslationsUpdateKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get available => '사용 가능한 업데이트';
	@override String versionAvailable({required Object version}) => '버전 ${version} 출시됨';
	@override String currentVersion({required Object version}) => '현재 버전: ${version}';
	@override String get skipVersion => '이 버전 건너뛰기';
	@override String get viewRelease => '릴리스 정보 보기';
	@override String get latestVersion => '최신 버전을 사용 중입니다';
	@override String get checkFailed => '업데이트 확인 실패';
}

// Path: settings
class _TranslationsSettingsKo implements TranslationsSettingsEn {
	_TranslationsSettingsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '설정';
	@override String get supportDeveloper => 'Plezy 후원하기';
	@override String get supportDeveloperDescription => 'Liberapay로 후원하여 개발 지원';
	@override String get language => '언어';
	@override String get theme => '테마';
	@override String get appearance => '외관';
	@override String get videoPlayback => '비디오 재생';
	@override String get videoPlaybackDescription => '재생 동작 구성';
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
	@override String get systemTheme => '시스템 설정';
	@override String get lightTheme => '라이트 모드';
	@override String get darkTheme => '다크 모드';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => '라이브러리 표시 밀도';
	@override String get compact => '좁게';
	@override String get comfortable => '넓게';
	@override String get viewMode => '보기 모드';
	@override String get gridView => '그리드 보기';
	@override String get listView => '목록 보기';
	@override String get showHeroSection => '주요 추천 영역 표시';
	@override String get useGlobalHubs => 'Plex 홈 레이아웃 사용';
	@override String get useGlobalHubsDescription => '공식 Plex 클라이언트처럼 홈 페이지 허브를 표시합니다. 끄면 라이브러리별 추천이 대신 표시됩니다.';
	@override String get showServerNameOnHubs => '허브에 서버 이름 표시';
	@override String get showServerNameOnHubsDescription => '허브 제목에 항상 서버 이름을 표시합니다. 끄면 중복된 허브 이름에만 표시됩니다.';
	@override String get alwaysKeepSidebarOpen => '사이드바 항상 열어두기';
	@override String get alwaysKeepSidebarOpenDescription => '사이드바가 확장된 상태로 유지되고 콘텐츠 영역이 맞춰집니다';
	@override String get showUnwatchedCount => '미시청 수 표시';
	@override String get showUnwatchedCountDescription => '시리즈 및 시즌에 미시청 에피소드 수 표시';
	@override String get showEpisodeNumberOnCards => '카드에 에피소드 번호 표시';
	@override String get showEpisodeNumberOnCardsDescription => '에피소드 카드에 시즌과 함께 에피소드 번호(예: S2 E3)를 표시합니다';
	@override String get hideSpoilers => '미시청 에피소드 스포일러 숨기기';
	@override String get hideSpoilersDescription => '아직 시청하지 않은 에피소드의 썸네일을 흐리게 하고 설명을 숨깁니다';
	@override String get playerBackend => '플레이어 백엔드';
	@override String get exoPlayer => 'ExoPlayer (권장)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => '하드웨어 디코딩';
	@override String get hardwareDecodingDescription => '가능한 경우 하드웨어 가속을 사용합니다';
	@override String get bufferSize => '버퍼 크기';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => '자동 (권장)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '기기 메모리가 ${heap}MB입니다. ${size}MB 버퍼는 재생 문제를 일으킬 수 있습니다.';
	@override String get defaultQualityTitle => '기본 화질';
	@override String get defaultQualityDescription => '재생 시작 시 사용됩니다. 낮은 값은 대역폭을 줄입니다.';
	@override String get subtitleStyling => '자막 스타일';
	@override String get subtitleStylingDescription => '자막의 외형을 사용자 설정';
	@override String get smallSkipDuration => '짧은 건너뛰기 시간';
	@override String get largeSkipDuration => '긴 건너뛰기 시간';
	@override String get rewindOnResume => '재개 시 되감기';
	@override String secondsUnit({required Object seconds}) => '${seconds}초';
	@override String get defaultSleepTimer => '기본 취침 타이머';
	@override String minutesUnit({required Object minutes}) => '${minutes}분';
	@override String get rememberTrackSelections => '에피소드/영화별 트랙 선택 기억';
	@override String get rememberTrackSelectionsDescription => '재생 중 트랙을 변경할 때 오디오 및 자막 언어 설정을 자동으로 저장합니다';
	@override String get clickVideoTogglesPlayback => '비디오를 클릭하여 재생/일시정지를 전환하세요.';
	@override String get clickVideoTogglesPlaybackDescription => '이 옵션이 활성화되어 있으면 비디오 플레이어를 클릭할 때 재생 또는 일시정지가 됩니다. 그렇지 않으면 클릭 시 재생 컨트롤이 표시되거나 숨겨집니다.';
	@override String get videoPlayerControls => '비디오 플레이어 컨트롤';
	@override String get keyboardShortcuts => '키보드 단축키';
	@override String get keyboardShortcutsDescription => '사용자 정의 키보드 단축키';
	@override String get videoPlayerNavigation => '비디오 플레이어 탐색';
	@override String get videoPlayerNavigationDescription => '방향 키를 사용하여 비디오 플레이어 컨트롤 탐색';
	@override String get watchTogetherRelay => '함께 보기 릴레이';
	@override String get watchTogetherRelayDescription => '함께 보기에 사용할 사용자 지정 릴레이 서버를 설정합니다. 모든 참가자가 동일한 서버를 사용해야 합니다.';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get crashReporting => '충돌 보고';
	@override String get crashReportingDescription => '앱 개선을 위해 충돌 보고서 전송';
	@override String get debugLogging => '디버그 로깅';
	@override String get debugLoggingDescription => '문제 해결을 위해 상세 로깅 활성화';
	@override String get viewLogs => '로그 보기';
	@override String get viewLogsDescription => '애플리케이션 로그 확인';
	@override String get clearCache => '캐시 삭제';
	@override String get clearCacheDescription => '모든 캐시된 이미지와 데이터를 지웁니다. 캐시를 지우면 애플리케이션 콘텐츠 로딩 속도가 느려질 수 있습니다.';
	@override String get clearCacheSuccess => '캐시 삭제 성공';
	@override String get resetSettings => '설정 재설정';
	@override String get resetSettingsDescription => '모든 설정을 기본값으로 재설정합니다. 이 작업은 되돌릴 수 없습니다.';
	@override String get resetSettingsSuccess => '설정 재설정 성공';
	@override String get backup => '백업';
	@override String get exportSettings => '설정 내보내기';
	@override String get exportSettingsDescription => '기본 설정을 파일로 저장';
	@override String get exportSettingsSuccess => '설정 내보내기 완료';
	@override String get exportSettingsFailed => '설정을 내보낼 수 없습니다';
	@override String get importSettings => '설정 가져오기';
	@override String get importSettingsDescription => '파일에서 기본 설정 복원';
	@override String get importSettingsConfirm => '현재 설정을 대체합니다. 계속하시겠습니까?';
	@override String get importSettingsSuccess => '설정 가져오기 완료';
	@override String get importSettingsFailed => '설정을 가져올 수 없습니다';
	@override String get importSettingsInvalidFile => '유효한 Plezy 설정 내보내기 파일이 아닙니다';
	@override String get importSettingsNoUser => '설정을 가져오기 전에 로그인하세요';
	@override String get shortcutsReset => '단축키가 기본값으로 재설정되었습니다';
	@override String get about => '정보';
	@override String get aboutDescription => '응용 프로그램 정보 및 라이선스';
	@override String get updates => '업데이트';
	@override String get updateAvailable => '사용 가능한 업데이트 있음';
	@override String get checkForUpdates => '업데이트 확인';
	@override String get autoCheckUpdatesOnStartup => '시작 시 자동으로 업데이트 확인';
	@override String get autoCheckUpdatesOnStartupDescription => '시작 시 새 버전이 있으면 알림 표시';
	@override String get validationErrorEnterNumber => '유효한 숫자를 입력하세요';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '기간은 ${min}과 ${max} ${unit} 사이여야 합니다';
	@override String shortcutAlreadyAssigned({required Object action}) => '단축키가 이미 ${action}에 할당 되었습니다';
	@override String shortcutUpdated({required Object action}) => '단축키가 ${action}에 대해 업데이트 되었습니다';
	@override String get autoSkip => '자동 건너뛰기';
	@override String get autoSkipIntro => '자동으로 오프닝 건너뛰기';
	@override String get autoSkipIntroDescription => '몇 초 후 오프닝을 자동으로 건너뛰기';
	@override String get autoSkipCredits => '자동으로 엔딩 건너뛰기';
	@override String get autoSkipCreditsDescription => '엔딩 크레딧 자동 건너뛰기 후 다음 에피소드 재생';
	@override String get autoSkipDelay => '자동 건너뛰기 지연';
	@override String autoSkipDelayDescription({required Object seconds}) => '자동 건너뛰기 전 ${seconds} 초 대기';
	@override String get introPattern => '인트로 마커 패턴';
	@override String get introPatternDescription => '챕터 제목에서 인트로 마커를 인식하는 정규식 패턴';
	@override String get creditsPattern => '크레딧 마커 패턴';
	@override String get creditsPatternDescription => '챕터 제목에서 크레딧 마커를 인식하는 정규식 패턴';
	@override String get invalidRegex => '잘못된 정규식';
	@override String get downloads => '다운로드';
	@override String get downloadLocationDescription => '다운로드 콘텐츠 저장 위치 선택';
	@override String get downloadLocationDefault => '기본값 (앱 저장소)';
	@override String get downloadLocationCustom => '사용자 지정 위치';
	@override String get selectFolder => '폴더 선택';
	@override String get resetToDefault => '기본값으로 재설정';
	@override String currentPath({required Object path}) => '현재: ${path}';
	@override String get downloadLocationChanged => '다운로드 위치가 변경 되었습니다';
	@override String get downloadLocationReset => '다운로드 위치가 기본값으로 재설정 되었습니다';
	@override String get downloadLocationInvalid => '선택한 폴더에 쓰기 권한이 없습니다';
	@override String get downloadLocationSelectError => '폴더 선택 실패';
	@override String get downloadOnWifiOnly => 'WiFi 연결 시에만 다운로드';
	@override String get downloadOnWifiOnlyDescription => '셀룰러 데이터 사용 시 다운로드 불가';
	@override String get autoRemoveWatchedDownloads => '시청한 다운로드 자동 삭제';
	@override String get autoRemoveWatchedDownloadsDescription => '시청 완료로 표시된 에피소드와 영화의 다운로드를 자동으로 삭제';
	@override String get cellularDownloadBlocked => '셀룰러 데이터에서 다운로드가 차단 되었습니다. WiFi에 연결하거나 설정을 변경하세요.';
	@override String get maxVolume => '최대 볼륨';
	@override String get maxVolumeDescription => '조용한 미디어를 위해 100% 이상의 볼륨 허용';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord에서 시청 중인 콘텐츠 표시';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Trakt와 시청 기록 동기화';
	@override String get trackers => '트래커';
	@override String get trackersDescription => 'Trakt, MyAnimeList, AniList 및 Simkl에 진행률 동기화';
	@override String get companionRemoteServer => '컴패니언 리모트 서버';
	@override String get companionRemoteServerDescription => '네트워크의 모바일 기기가 이 앱을 제어할 수 있도록 허용';
	@override String get autoPip => '자동 PIP 모드';
	@override String get autoPipDescription => '재생 중 앱을 나갈 때 자동으로 PIP 모드로 전환';
	@override String get matchContentFrameRate => '콘텐츠 프레임 레이트 맞춤';
	@override String get matchContentFrameRateDescription => '비디오 콘텐츠에 맞게 디스플레이 주사율을 조정하여 떨림을 줄이고 배터리를 절약합니다';
	@override String get matchRefreshRate => '주사율 맞춤';
	@override String get matchRefreshRateDescription => '전체 화면에서 비디오 콘텐츠에 맞게 디스플레이 주사율을 전환합니다';
	@override String get matchDynamicRange => '다이나믹 레인지 맞춤';
	@override String get matchDynamicRangeDescription => 'HDR 콘텐츠에 대해 자동으로 HDR을 활성화하고 플레이어를 나갈 때 SDR로 복원합니다';
	@override String get displaySwitchDelay => '디스플레이 전환 지연';
	@override String get tunneledPlayback => '터널 재생';
	@override String get tunneledPlaybackDescription => '하드웨어 가속 비디오 터널링을 사용합니다. HDR 콘텐츠에서 소리만 나고 검은 화면이 보이면 비활성화하세요';
	@override String get requireProfileSelectionOnOpen => '앱 실행 시 프로필 선택';
	@override String get requireProfileSelectionOnOpenDescription => '앱을 열 때마다 프로필 선택 화면을 표시합니다';
	@override String get confirmExitOnBack => '종료 전 확인';
	@override String get confirmExitOnBackDescription => '뒤로 버튼을 눌러 앱을 종료할 때 확인 대화상자를 표시합니다';
	@override String get forceTvMode => 'TV 모드 강제 사용';
	@override String get forceTvModeDescription => '자동 감지와 관계없이 TV 레이아웃을 사용합니다. leanback 기능을 보고하지 않는 Android TV 기기에 유용합니다. 변경 시 앱이 다시 시작됩니다.';
	@override String get autoHidePerformanceOverlay => '성능 오버레이 자동 숨기기';
	@override String get autoHidePerformanceOverlayDescription => '재생 컨트롤과 함께 성능 오버레이를 페이드 처리';
	@override String get showNavBarLabels => '내비게이션 바 라벨 표시';
	@override String get showNavBarLabelsDescription => '내비게이션 바 아이콘 아래에 텍스트 라벨을 표시합니다';
	@override String get liveTvDefaultFavorites => '즐겨찾기 채널 기본 설정';
	@override String get liveTvDefaultFavoritesDescription => '라이브 TV를 열 때 즐겨찾기 채널만 표시';
	@override String get display => 'Display';
	@override String get homeScreen => 'Home Screen';
	@override String get navigation => 'Navigation';
	@override String get content => 'Content';
	@override String get player => 'Player';
	@override String get subtitlesAndConfig => 'Subtitles & Configuration';
	@override String get seekAndTiming => 'Seek & Timing';
	@override String get behavior => 'Behavior';
}

// Path: search
class _TranslationsSearchKo implements TranslationsSearchEn {
	_TranslationsSearchKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get hint => '영화, 시리즈, 음악 등을 검색하세요...';
	@override String get tryDifferentTerm => '다른 검색어를 시도해 보세요';
	@override String get searchYourMedia => '미디어 검색';
	@override String get enterTitleActorOrKeyword => '제목, 배우 또는 키워드를 입력하세요';
}

// Path: hotkeys
class _TranslationsHotkeysKo implements TranslationsHotkeysEn {
	_TranslationsHotkeysKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName}에 대한 단축키 설정';
	@override String get clearShortcut => '단축키 삭제';
	@override late final _TranslationsHotkeysActionsKo actions = _TranslationsHotkeysActionsKo._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoKo implements TranslationsFileInfoEn {
	_TranslationsFileInfoKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '파일 정보';
	@override String get video => '비디오';
	@override String get audio => '오디오';
	@override String get file => '파일';
	@override String get advanced => '고급';
	@override String get codec => '코덱';
	@override String get resolution => '해상도';
	@override String get bitrate => '비트레이트';
	@override String get frameRate => '프레임 속도';
	@override String get aspectRatio => '종횡비';
	@override String get profile => '프로파일';
	@override String get bitDepth => '비트 심도';
	@override String get colorSpace => '색 공간';
	@override String get colorRange => '색 범위';
	@override String get colorPrimaries => '색상 원색';
	@override String get chromaSubsampling => '채도 서브샘플링';
	@override String get channels => '채널';
	@override String get subtitles => '자막';
	@override String get overallBitrate => '전체 비트레이트';
	@override String get path => '경로';
	@override String get size => '크기';
	@override String get container => '컨테이너';
	@override String get duration => '재생 시간';
	@override String get optimizedForStreaming => '스트리밍 최적화';
	@override String get has64bitOffsets => '64비트 오프셋';
}

// Path: mediaMenu
class _TranslationsMediaMenuKo implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '시청 완료로 표시';
	@override String get markAsUnwatched => '시청 안 함으로 표시';
	@override String get removeFromContinueWatching => '계속 보기에서 제거';
	@override String get goToSeries => '시리즈로 이동';
	@override String get goToSeason => '시즌으로 이동';
	@override String get shufflePlay => '무작위 재생';
	@override String get fileInfo => '파일 정보';
	@override String get deleteFromServer => '서버에서 삭제';
	@override String get confirmDelete => '이 미디어와 파일이 서버에서 영구적으로 삭제됩니다. 이 작업은 취소할 수 없습니다.';
	@override String get deleteMultipleWarning => '모든 에피소드와 파일이 포함됩니다.';
	@override String get mediaDeletedSuccessfully => '미디어 항목이 성공적으로 삭제되었습니다';
	@override String get mediaFailedToDelete => '미디어 항목 삭제 실패';
	@override String get rate => '평가';
	@override String get playFromBeginning => '처음부터 재생';
	@override String get playVersion => '버전 재생...';
}

// Path: accessibility
class _TranslationsAccessibilityKo implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 영화';
	@override String mediaCardShow({required Object title}) => '${title}, TV 프로그램';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '시청 완료';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} 퍼센트 시청 완료';
	@override String get mediaCardUnwatched => '미시청';
	@override String get tapToPlay => '터치 하여 재생';
}

// Path: tooltips
class _TranslationsTooltipsKo implements TranslationsTooltipsEn {
	_TranslationsTooltipsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '무작위 재생';
	@override String get playTrailer => '예고편 재생';
	@override String get markAsWatched => '시청 완료로 표시';
	@override String get markAsUnwatched => '시청 안 함으로 표시';
}

// Path: videoControls
class _TranslationsVideoControlsKo implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '오디오';
	@override String get subtitlesLabel => '자막';
	@override String get resetToZero => '0ms로 재설정';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} 나중에 재생됨';
	@override String playsEarlier({required Object label}) => '${label} 더 먼저 재생됨';
	@override String get noOffset => '오프셋 없음';
	@override String get letterbox => '레터박스 모드';
	@override String get fillScreen => '화면 채우기';
	@override String get stretch => '확장';
	@override String get lockRotation => '회전 잠금';
	@override String get unlockRotation => '회전 잠금 해제';
	@override String get timerActive => '타이머 활성화됨';
	@override String playbackWillPauseIn({required Object duration}) => '재생이 ${duration} 후에 일시 중지 됩니다';
	@override String get stillWatching => '아직 시청 중이신가요?';
	@override String pausingIn({required Object seconds}) => '${seconds}초 후 일시 정지';
	@override String get continueWatching => '계속';
	@override String get autoPlayNext => '다음 자동 재생';
	@override String get playNext => '다음 재생';
	@override String get playButton => '재생';
	@override String get pauseButton => '일시정지';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} 초 뒤로';
	@override String seekForwardButton({required Object seconds}) => '${seconds} 초 앞으로';
	@override String get previousButton => '이전 에피소드';
	@override String get nextButton => '다음 에피소드';
	@override String get previousChapterButton => '이전 챕터';
	@override String get nextChapterButton => '다음 챕터';
	@override String get muteButton => '음소거';
	@override String get unmuteButton => '음소거 해제';
	@override String get settingsButton => '동영상 설정';
	@override String get tracksButton => '오디오 및 자막';
	@override String get chaptersButton => '챕터';
	@override String get versionsButton => '동영상 버전';
	@override String get versionQualityButton => '버전 및 화질';
	@override String get versionColumnHeader => '버전';
	@override String get qualityColumnHeader => '화질';
	@override String get qualityOriginal => '원본';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => '트랜스코딩을 사용할 수 없음 — 원본 화질로 재생';
	@override String get pipButton => '픽처 인 픽처 모드';
	@override String get aspectRatioButton => '화면비율';
	@override String get ambientLighting => '주변 조명';
	@override String get fullscreenButton => '전체화면';
	@override String get exitFullscreenButton => '전체화면 종료';
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
	@override late final _TranslationsVideoControlsPipErrorsKo pipErrors = _TranslationsVideoControlsPipErrorsKo._(_root);
	@override String get chapters => '챕터';
	@override String get noChaptersAvailable => '사용 가능한 챕터가 없습니다';
	@override String get queue => '재생 대기열';
	@override String get noQueueItems => '대기열에 항목이 없습니다';
	@override String get searchSubtitles => '자막 검색';
	@override String get language => '언어';
	@override String get noSubtitlesFound => '자막을 찾을 수 없습니다';
	@override String get subtitleDownloaded => '자막이 다운로드되었습니다';
	@override String get subtitleDownloadFailed => '자막 다운로드에 실패했습니다';
	@override String get searchLanguages => '언어 검색...';
}

// Path: userStatus
class _TranslationsUserStatusKo implements TranslationsUserStatusEn {
	_TranslationsUserStatusKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get admin => '관리자';
	@override String get restricted => '제한됨';
	@override String get protected => '보호됨';
	@override String get current => '현재';
}

// Path: messages
class _TranslationsMessagesKo implements TranslationsMessagesEn {
	_TranslationsMessagesKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '시청 완료로 표시됨';
	@override String get markedAsUnwatched => '시청 안 함으로 표시됨';
	@override String get markedAsWatchedOffline => '시청 완료로 표시됨 (연결 시 동기화됨)';
	@override String get markedAsUnwatchedOffline => '미시청으로 표시됨 (연결 시 동기화됨)';
	@override String autoRemovedWatchedDownload({required Object title}) => '자동 삭제됨: ${title}';
	@override String get removedFromContinueWatching => '계속 시청 목록에서 제거됨';
	@override String errorLoading({required Object error}) => '오류: ${error}';
	@override String get fileInfoNotAvailable => '파일 정보가 없습니다';
	@override String errorLoadingFileInfo({required Object error}) => '파일 정보 로딩 중 오류: ${error}';
	@override String get errorLoadingSeries => '시리즈 로딩 중 오류';
	@override String get errorLoadingSeason => '시즌 로딩 중 오류';
	@override String get musicNotSupported => '음악 재생 미지원';
	@override String get noDescriptionAvailable => '설명이 없습니다';
	@override String get noProfilesAvailable => '사용 가능한 프로필이 없습니다';
	@override String get contactAdminForProfiles => '프로필을 추가하려면 Plex 관리자에게 문의하세요';
	@override String get unableToDetermineLibrarySection => '이 항목의 라이브러리 섹션을 확인할 수 없습니다';
	@override String get logsCleared => '로그가 삭제 되었습니다';
	@override String get logsCopied => '로그가 클립보드에 복사 되었습니다';
	@override String get noLogsAvailable => '사용 가능한 로그가 없습니다';
	@override String libraryScanning({required Object title}) => '"${title}"을(를) 스캔 중입니다...';
	@override String libraryScanStarted({required Object title}) => '"${title}" 미디어 라이브러리 스캔 시작';
	@override String libraryScanFailed({required Object error}) => '미디어 라이브러리 스캔 실패: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" 메타데이터 새로고침 중...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" 메타데이터 새로고침 시작됨';
	@override String metadataRefreshFailed({required Object error}) => '메타데이터 새로고침 실패: ${error}';
	@override String get logoutConfirm => '로그아웃 하시겠습니까?';
	@override String get noSeasonsFound => '시즌을 찾을 수 없음';
	@override String get noEpisodesFound => '시즌 1에서 에피소드를 찾을 수 없습니다';
	@override String get noEpisodesFoundGeneral => '에피소드를 찾을 수 없습니다';
	@override String get noResultsFound => '결과를 찾을 수 없습니다';
	@override String sleepTimerSet({required Object label}) => '수면 타이머가 ${label}로 설정 되었습니다';
	@override String get noItemsAvailable => '사용 가능한 항목이 없습니다';
	@override String get failedToCreatePlayQueueNoItems => '재생 대기열 생성 실패 - 항목 없음';
	@override String failedPlayback({required Object action, required Object error}) => '${action}을(를) 수행할 수 없습니다: ${error}';
	@override String get switchingToCompatiblePlayer => '호환되는 플레이어로 전환 중...';
	@override String get serverLimitTitle => '재생 실패';
	@override String get serverLimitBody => '서버에서 오류를 반환했습니다 (HTTP 500). 일반적으로 이는 서버 소유자가 대역폭 또는 트랜스코딩 제한을 설정하여 세션을 거부하고 있다는 의미입니다. 클라이언트에서 할 수 있는 일은 없습니다 — 서버 소유자가 설정을 조정해야 합니다.';
	@override String get logsUploaded => '로그 업로드 완료';
	@override String get logsUploadFailed => '로그 업로드 실패';
	@override String get logId => '로그 ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingKo implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingKo._(this._root);

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
	@override String get bold => '굵게';
	@override String get italic => '기울임꼴';
}

// Path: mpvConfig
class _TranslationsMpvConfigKo implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv 설정';
	@override String get description => '고급 비디오 플레이어 설정';
	@override String get presets => '사전 설정';
	@override String get noPresets => '저장된 사전 설정이 없습니다';
	@override String get saveAsPreset => '프리셋으로 저장...';
	@override String get presetName => '프리셋 이름';
	@override String get presetNameHint => '이 프리셋의 이름을 입력하세요';
	@override String get loadPreset => '로드';
	@override String get deletePreset => '삭제';
	@override String get presetSaved => '프리셋이 저장 되었습니다';
	@override String get presetLoaded => '프리셋이 로드 되었습니다';
	@override String get presetDeleted => '프리셋이 삭제 되었습니다';
	@override String get confirmDeletePreset => '이 프리셋을 삭제 하시겠습니까?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogKo implements TranslationsDialogEn {
	_TranslationsDialogKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '확인';
}

// Path: discover
class _TranslationsDiscoverKo implements TranslationsDiscoverEn {
	_TranslationsDiscoverKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '발견';
	@override String get switchProfile => '사용자 전환';
	@override String get noContentAvailable => '사용 가능한 콘텐츠가 없습니다';
	@override String get addMediaToLibraries => '미디어 라이브러리에 미디어를 추가해 주세요';
	@override String get continueWatching => '계속 시청';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => '개요';
	@override String get cast => '출연진';
	@override String get extras => '예고편 및 부가영상';
	@override String get studio => '제작사';
	@override String get rating => '연령 등급';
	@override String get movie => '영화';
	@override String get tvShow => 'TV 시리즈';
	@override String minutesLeft({required Object minutes}) => '${minutes}분 남음';
}

// Path: errors
class _TranslationsErrorsKo implements TranslationsErrorsEn {
	_TranslationsErrorsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '검색 실패: ${error}';
	@override String connectionTimeout({required Object context}) => '${context} 로드 중 연결 시간 초과';
	@override String get connectionFailed => 'Plex 서버에 연결할 수 없음';
	@override String failedToLoad({required Object context, required Object error}) => '${context} 로드 실패: ${error}';
	@override String get noClientAvailable => '사용 가능한 클라이언트가 없습니다';
	@override String authenticationFailed({required Object error}) => '인증 실패: ${error}';
	@override String get couldNotLaunchUrl => '인증 URL을 열 수 없습니다';
	@override String get pleaseEnterToken => '토큰을 입력해 주세요';
	@override String get invalidToken => '토큰이 유효하지 않습니다';
	@override String failedToVerifyToken({required Object error}) => '토큰을 확인할 수 없습니다: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName}으로 전환할 수 없습니다';
}

// Path: libraries
class _TranslationsLibrariesKo implements TranslationsLibrariesEn {
	_TranslationsLibrariesKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '미디어 라이브러리';
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
	@override String get thisLibraryIsEmpty => '이 미디어 라이브러리는 비어 있습니다';
	@override String get all => '전체';
	@override String get clearAll => '모두 삭제';
	@override String scanLibraryConfirm({required Object title}) => '「${title}」를 스캔 하시겠습니까?';
	@override String analyzeLibraryConfirm({required Object title}) => '「${title}」를 분석 하시겠습니까?';
	@override String refreshMetadataConfirm({required Object title}) => '「${title}」의 메타데이터를 새로고침 하시겠습니까?';
	@override String emptyTrashConfirm({required Object title}) => '${title}의 휴지통을 비우시겠습니까?';
	@override String get manageLibraries => '미디어 라이브러리 관리';
	@override String get sort => '정렬';
	@override String get sortBy => '정렬 기준';
	@override String get filters => '필터';
	@override String get confirmActionMessage => '이 작업을 실행 하시겠습니까?';
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
	@override late final _TranslationsLibrariesTabsKo tabs = _TranslationsLibrariesTabsKo._(_root);
	@override late final _TranslationsLibrariesGroupingsKo groupings = _TranslationsLibrariesGroupingsKo._(_root);
}

// Path: about
class _TranslationsAboutKo implements TranslationsAboutEn {
	_TranslationsAboutKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '소개';
	@override String get openSourceLicenses => '오픈소스 라이선스';
	@override String versionLabel({required Object version}) => '버전 ${version}';
	@override String get appDescription => '아름다운 Flutter Plex 클라이언트';
	@override String get viewLicensesDescription => '타사 라이브러리 라이선스 보기';
}

// Path: serverSelection
class _TranslationsServerSelectionKo implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => '어떤 서버에도 연결할 수 없습니다. 네트워크를 확인하고 다시 시도하세요.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})의 서버를 찾을 수 없습니다.';
	@override String failedToLoadServers({required Object error}) => '서버를 로드할 수 없습니다: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailKo implements TranslationsHubDetailEn {
	_TranslationsHubDetailKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '제목';
	@override String get releaseYear => '출시 연도';
	@override String get dateAdded => '추가 날짜';
	@override String get rating => '평점';
	@override String get noItemsFound => '항목이 없습니다';
}

// Path: logs
class _TranslationsLogsKo implements TranslationsLogsEn {
	_TranslationsLogsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '로그 지우기';
	@override String get copyLogs => '로그 복사';
	@override String get uploadLogs => '로그 업로드';
}

// Path: licenses
class _TranslationsLicensesKo implements TranslationsLicensesEn {
	_TranslationsLicensesKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '관련 소프트웨어 패키지';
	@override String get license => '라이선스';
	@override String licenseNumber({required Object number}) => '라이선스 ${number}';
	@override String licensesCount({required Object count}) => '${count} 개의 라이선스';
}

// Path: navigation
class _TranslationsNavigationKo implements TranslationsNavigationEn {
	_TranslationsNavigationKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get libraries => '미디어 라이브러리';
	@override String get downloads => '다운로드';
	@override String get liveTv => '실시간 TV';
}

// Path: liveTv
class _TranslationsLiveTvKo implements TranslationsLiveTvEn {
	_TranslationsLiveTvKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '실시간 TV';
	@override String get guide => '편성표';
	@override String get noChannels => '사용 가능한 채널이 없습니다';
	@override String get noDvr => '서버에 DVR이 구성되어 있지 않습니다';
	@override String get noPrograms => '프로그램 데이터가 없습니다';
	@override String get live => '실시간';
	@override String get reloadGuide => '편성표 새로고침';
	@override String get now => '지금';
	@override String get today => '오늘';
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
	@override String get joinSession => '진행 중인 세션 참여';
	@override String watchFromStart({required Object minutes}) => '처음부터 시청 (${minutes}분 전 시작)';
	@override String get watchLive => '실시간 시청';
	@override String get goToLive => '실시간으로 이동';
}

// Path: collections
class _TranslationsCollectionsKo implements TranslationsCollectionsEn {
	_TranslationsCollectionsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '컬렉션';
	@override String get collection => '컬렉션';
	@override String get empty => '컬렉션이 비어 있습니다';
	@override String get unknownLibrarySection => '삭제할 수 없습니다: 알 수 없는 미디어 라이브러리 섹션입니다';
	@override String get deleteCollection => '컬렉션 삭제';
	@override String deleteConfirm({required Object title}) => '"${title}"을(를) 삭제 하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
	@override String get deleted => '컬렉션 삭제됨';
	@override String get deleteFailed => '컬렉션 삭제 실패';
	@override String deleteFailedWithError({required Object error}) => '컬렉션 삭제 실패: ${error}';
	@override String failedToLoadItems({required Object error}) => '컬렉션 항목 로드 실패: ${error}';
	@override String get selectCollection => '컬렉션 선택';
	@override String get collectionName => '컬렉션 이름';
	@override String get enterCollectionName => '컬렉션 이름 입력';
	@override String get addedToCollection => '컬렉션에 추가됨';
	@override String get errorAddingToCollection => '컬렉션에 추가 실패';
	@override String get created => '컬렉션 생성됨';
	@override String get removeFromCollection => '컬렉션에서 제거';
	@override String removeFromCollectionConfirm({required Object title}) => '${title}을/를 이 컬렉션에서 제거 하시겠습니까?';
	@override String get removedFromCollection => '컬렉션에서 제거됨';
	@override String get removeFromCollectionFailed => '컬렉션에서 제거 실패';
	@override String removeFromCollectionError({required Object error}) => '컬렉션에서 제거 중 오류 발생: ${error}';
	@override String get searchCollections => '컬렉션 검색...';
}

// Path: playlists
class _TranslationsPlaylistsKo implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsKo._(this._root);

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
	@override String get deleteConfirm => '재생 목록을 삭제 하시겠습니까?';
	@override String deleteMessage({required Object name}) => '"${name}"을(를) 삭제 하시겠습니까?';
	@override String get created => '재생 목록이 생성 되었습니다';
	@override String get deleted => '재생 목록이 삭제 되었습니다';
	@override String get itemAdded => '재생 목록에 추가 되었습니다';
	@override String get itemRemoved => '재생 목록에서 제거됨';
	@override String get selectPlaylist => '재생 목록 선택';
	@override String get errorCreating => '재생 목록 생성 실패';
	@override String get errorDeleting => '재생 목록 삭제 실패';
	@override String get errorLoading => '재생 목록 로드 실패';
	@override String get errorAdding => '재생 목록에 추가 실패';
	@override String get errorReordering => '재생 목록 항목 재정렬 실패';
	@override String get errorRemoving => '재생 목록에서 제거 실패';
}

// Path: watchTogether
class _TranslationsWatchTogetherKo implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherKo._(this._root);

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
	@override String get hostingSession => '세션 호스팅';
	@override String get inSession => '세션 중';
	@override String get sessionCode => '세션 코드';
	@override String get hostControlsPlayback => '호스트 재생 제어';
	@override String get anyoneCanControl => '누구나 재생 제어 가능';
	@override String get hostControls => '호스트 제어';
	@override String get anyoneControls => '누구나 제어';
	@override String get participants => '참가자';
	@override String get host => '호스트';
	@override String get hostBadge => '호스트';
	@override String get youAreHost => '당신은 호스트 입니다';
	@override String get watchingWithOthers => '다른 사람과 함께 시청 중';
	@override String get endSession => '세션 종료';
	@override String get leaveSession => '세션 탈퇴';
	@override String get endSessionQuestion => '세션을 종료 하시겠습니까?';
	@override String get leaveSessionQuestion => '세션을 탈퇴 하시겠습니까?';
	@override String get endSessionConfirm => '이 작업은 모든 참가자의 세션을 종료합니다.';
	@override String get leaveSessionConfirm => '당신은 세션에서 제거됩니다.';
	@override String get endSessionConfirmOverlay => '이것은 모든 참가자의 시청 세션을 종료합니다.';
	@override String get leaveSessionConfirmOverlay => '시청 세션 연결이 끊어집니다.';
	@override String get end => '종료';
	@override String get leave => '이탈';
	@override String get syncing => '동기화 중...';
	@override String get joinWatchSession => '시청 세션에 참여';
	@override String get enterCodeHint => '5자리 코드 입력';
	@override String get pasteFromClipboard => '클립보드에서 붙여넣기';
	@override String get pleaseEnterCode => '세션 코드를 입력하세요';
	@override String get codeMustBe5Chars => '세션 코드는 반드시 5자리여야 합니다';
	@override String get joinInstructions => '호스트가 공유한 세션 코드를 입력하여 시청 세션에 참여하세요.';
	@override String get failedToCreate => '세션 생성 실패';
	@override String get failedToJoin => '세션 참여 실패';
	@override String get sessionCodeCopied => '세션 코드가 클립보드에 복사되었습니다';
	@override String get relayUnreachable => '릴레이 서버에 연결할 수 없습니다. 인터넷 제공업체가 연결을 차단하고 있을 수 있습니다. 시도해 볼 수 있지만 함께 보기가 작동하지 않을 수 있습니다.';
	@override String get reconnectingToHost => '호스트에 재연결 중...';
	@override String get currentPlayback => '현재 재생';
	@override String get joinCurrentPlayback => '현재 재생 참여';
	@override String get joinCurrentPlaybackDescription => '호스트가 현재 보고 있는 항목으로 돌아갑니다';
	@override String get failedToOpenCurrentPlayback => '현재 재생을 열 수 없습니다';
	@override String participantJoined({required Object name}) => '${name}님이 참여했습니다';
	@override String participantLeft({required Object name}) => '${name}님이 나갔습니다';
	@override String participantPaused({required Object name}) => '${name}님이 일시정지했습니다';
	@override String participantResumed({required Object name}) => '${name}님이 재생했습니다';
	@override String participantSeeked({required Object name}) => '${name}님이 탐색했습니다';
	@override String participantBuffering({required Object name}) => '${name}님이 버퍼링 중입니다';
	@override String get waitingForParticipants => '다른 참가자의 로딩을 기다리는 중...';
	@override String get recentRooms => '최근 방';
	@override String get renameRoom => '방 이름 변경';
	@override String get removeRoom => '제거';
}

// Path: downloads
class _TranslationsDownloadsKo implements TranslationsDownloadsEn {
	_TranslationsDownloadsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '다운로드';
	@override String get manage => '관리';
	@override String get tvShows => 'TV 프로그램';
	@override String get movies => '영화';
	@override String get noDownloads => '다운로드 없음';
	@override String get noDownloadsDescription => '다운로드한 콘텐츠는 오프라인 시청을 위해 여기에 표시됩니다';
	@override String get downloadNow => '다운로드';
	@override String get deleteDownload => '다운로드 삭제';
	@override String get retryDownload => '다운로드 재시도';
	@override String get downloadQueued => '다운로드 대기 중';
	@override String get serverErrorBitrate => '서버 오류 — 파일이 원격 스트리밍 비트레이트 제한을 초과할 수 있습니다';
	@override String episodesQueued({required Object count}) => '${count} 에피소드가 다운로드 대기열에 추가 되었습니다';
	@override String get downloadDeleted => '다운로드 삭제됨';
	@override String deleteConfirm({required Object title}) => '"${title}"를 삭제 하시겠습니까? 다운로드한 파일이 기기에서 삭제됩니다.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})';
	@override String get noDownloadsTree => '다운로드 없음';
	@override String get pauseAll => '모두 일시정지';
	@override String get resumeAll => '모두 재개';
	@override String get deleteAll => '모두 삭제';
	@override String get selectVersion => '버전 선택';
	@override String get allEpisodes => '모든 에피소드';
	@override String get unwatchedOnly => '시청하지 않은 것만';
	@override String nextNUnwatched({required Object count}) => '다음 ${count}개 미시청';
	@override String get customAmount => '직접 입력...';
	@override String get howManyEpisodes => '몇 개의 에피소드?';
	@override String itemsQueued({required Object count}) => '${count}개 항목이 다운로드 대기열에 추가됨';
	@override String get keepSynced => '동기화 유지';
	@override String get downloadOnce => '한 번만 다운로드';
	@override String keepNUnwatched({required Object count}) => '미시청 ${count}개 유지';
	@override String get editSyncRule => '동기화 규칙 편집';
	@override String get removeSyncRule => '동기화 규칙 제거';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" 동기화를 중단하시겠습니까? 다운로드된 에피소드는 유지됩니다.';
	@override String syncRuleCreated({required Object count}) => '동기화 규칙 생성됨 — 미시청 에피소드 ${count}개 유지';
	@override String get syncRuleUpdated => '동기화 규칙 업데이트됨';
	@override String get syncRuleRemoved => '동기화 규칙 제거됨';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title}의 새 에피소드 ${count}개 동기화됨';
	@override String get activeSyncRules => '동기화 규칙';
	@override String get noSyncRules => '동기화 규칙 없음';
	@override String get manageSyncRule => '동기화 관리';
	@override String get editEpisodeCount => '에피소드 수';
	@override String get editSyncFilter => '동기화 필터';
	@override String get syncAllItems => '모든 항목 동기화 중';
	@override String get syncUnwatchedItems => '시청하지 않은 항목 동기화 중';
	@override String get syncRuleListCreated => '동기화 규칙이 생성되었습니다';
}

// Path: shaders
class _TranslationsShadersKo implements TranslationsShadersEn {
	_TranslationsShadersKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '셰이더';
	@override String get noShaderDescription => '비디오 향상 없음';
	@override String get nvscalerDescription => '더 선명한 비디오를 위한 NVIDIA 이미지 스케일링';
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
class _TranslationsCompanionRemoteKo implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '컴패니언 리모컨';
	@override String connectedTo({required Object name}) => '${name}에 연결됨';
	@override late final _TranslationsCompanionRemoteSessionKo session = _TranslationsCompanionRemoteSessionKo._(_root);
	@override late final _TranslationsCompanionRemotePairingKo pairing = _TranslationsCompanionRemotePairingKo._(_root);
	@override late final _TranslationsCompanionRemoteRemoteKo remote = _TranslationsCompanionRemoteRemoteKo._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsKo implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => '재생 설정';
	@override String get playbackSpeed => '재생 속도';
	@override String get sleepTimer => '취침 타이머';
	@override String get audioSync => '오디오 동기화';
	@override String get subtitleSync => '자막 동기화';
	@override String get hdr => 'HDR';
	@override String get audioOutput => '오디오 출력';
	@override String get performanceOverlay => '성능 오버레이';
	@override String get audioPassthrough => '오디오 패스스루';
	@override String get audioNormalization => '음량 정규화';
}

// Path: externalPlayer
class _TranslationsExternalPlayerKo implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '외부 플레이어';
	@override String get useExternalPlayer => '외부 플레이어 사용';
	@override String get useExternalPlayerDescription => '내장 플레이어 대신 외부 앱에서 동영상 열기';
	@override String get selectPlayer => '플레이어 선택';
	@override String get customPlayers => '사용자 정의 플레이어';
	@override String get systemDefault => '시스템 기본값';
	@override String get addCustomPlayer => '사용자 정의 플레이어 추가';
	@override String get playerName => '플레이어 이름';
	@override String get playerCommand => '명령어';
	@override String get playerPackage => '패키지 이름';
	@override String get playerUrlScheme => 'URL 스킴';
	@override String get off => '꺼짐';
	@override String get launchFailed => '외부 플레이어를 열 수 없습니다';
	@override String appNotInstalled({required Object name}) => '${name}이(가) 설치되어 있지 않습니다';
	@override String get playInExternalPlayer => '외부 플레이어에서 재생';
}

// Path: metadataEdit
class _TranslationsMetadataEditKo implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditKo._(this._root);

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
	@override String get style => '스타일';
	@override String get mood => '분위기';
}

// Path: matchScreen
class _TranslationsMatchScreenKo implements TranslationsMatchScreenEn {
	_TranslationsMatchScreenKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get match => '일치...';
	@override String get fixMatch => '일치 수정...';
	@override String get unmatch => '일치 해제';
	@override String get unmatchConfirm => '이 항목의 현재 일치를 해제하시겠습니까? 다시 일치시킬 때까지 Plex는 일치되지 않은 것으로 처리합니다.';
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
class _TranslationsServerTasksKo implements TranslationsServerTasksEn {
	_TranslationsServerTasksKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '서버 작업';
	@override String get failedToLoad => '작업을 불러올 수 없습니다';
	@override String get noTasks => '실행 중인 작업 없음';
}

// Path: trakt
class _TranslationsTraktKo implements TranslationsTraktEn {
	_TranslationsTraktKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '연결됨';
	@override String connectedAs({required Object username}) => '@${username}(으)로 연결됨';
	@override String get disconnectConfirm => 'Trakt 계정 연결을 끊으시겠습니까?';
	@override String get disconnectConfirmBody => 'Plezy가 Trakt로 재생 이벤트를 보내지 않습니다. 언제든지 다시 연결할 수 있습니다.';
	@override String get scrobble => '실시간 스크로블';
	@override String get scrobbleDescription => '재생 중 재생, 일시정지, 정지 이벤트를 Trakt로 전송합니다.';
	@override String get watchedSync => '시청 상태 동기화';
	@override String get watchedSyncDescription => 'Plezy에서 시청 완료로 표시한 항목이 Trakt에도 시청 완료로 표시됩니다.';
	@override String get connectFailed => 'Trakt에 연결할 수 없습니다. 다시 시도하세요.';
}

// Path: trackers
class _TranslationsTrackersKo implements TranslationsTrackersEn {
	_TranslationsTrackersKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '트래커';
	@override String get hubSubtitle => '시청 진행률을 Trakt 및 기타 서비스와 동기화하세요.';
	@override String get notConnected => '연결되지 않음';
	@override String connectedAs({required Object username}) => '@${username} 로 연결됨';
	@override String get scrobble => '진행률 자동 추적';
	@override String get scrobbleDescription => '에피소드나 영화를 시청하면 목록을 업데이트합니다.';
	@override String disconnectConfirm({required Object service}) => '${service} 연결을 해제하시겠습니까?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy가 ${service} 목록 업데이트를 중지합니다. 언제든지 다시 연결할 수 있습니다.';
	@override String connectFailed({required Object service}) => '${service}에 연결할 수 없습니다. 다시 시도하세요.';
	@override late final _TranslationsTrackersServicesKo services = _TranslationsTrackersServicesKo._(_root);
	@override late final _TranslationsTrackersDeviceCodeKo deviceCode = _TranslationsTrackersDeviceCodeKo._(_root);
	@override late final _TranslationsTrackersOauthProxyKo oauthProxy = _TranslationsTrackersOauthProxyKo._(_root);
	@override late final _TranslationsTrackersLibraryFilterKo libraryFilter = _TranslationsTrackersLibraryFilterKo._(_root);
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsKo implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsKo._(this._root);

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
	@override String get subSeekNext => '다음 자막으로 이동';
	@override String get subSeekPrev => '이전 자막으로 이동';
	@override String get shaderToggle => '셰이더 전환';
	@override String get skipMarker => '인트로/크레딧 건너뛰기';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsKo implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 이상이 필요합니다';
	@override String get iosVersion => 'iOS 15.0 이상이 필요합니다';
	@override String get permissionDisabled => '화면 속 화면 권한이 비활성화되어 있습니다. 설정 > 앱 > Plezy > 화면 속 화면에서 활성화하세요';
	@override String get notSupported => '이 기기는 화면 속 화면 모드를 지원하지 않습니다';
	@override String get voSwitchFailed => '화면 속 화면을 위한 비디오 출력 전환에 실패했습니다';
	@override String get failed => '화면 속 화면 모드를 시작할 수 없습니다';
	@override String unknown({required Object error}) => '오류가 발생했습니다: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsKo implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get recommended => '추천';
	@override String get browse => '찾아보기';
	@override String get collections => '컬렉션';
	@override String get playlists => '재생 목록';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsKo implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '그룹';
	@override String get all => '전체';
	@override String get movies => '영화';
	@override String get shows => 'TV 프로그램';
	@override String get seasons => '시즌';
	@override String get episodes => '화';
	@override String get folders => '폴더';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionKo implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get startingServer => '원격 서버 시작 중...';
	@override String get failedToCreate => '원격 서버를 시작하지 못했습니다:';
	@override String get hostAddress => '호스트 주소';
	@override String get connected => '연결됨';
	@override String get serverRunning => '원격 서버 활성';
	@override String get serverStopped => '원격 서버 중지됨';
	@override String get serverRunningDescription => '네트워크의 모바일 기기가 이 앱을 검색하고 연결할 수 있습니다';
	@override String get serverStoppedDescription => '모바일 기기의 연결을 허용하려면 서버를 시작하세요';
	@override String get usePhoneToControl => '모바일 기기로 이 앱을 제어하세요';
	@override String get startServer => '서버 시작';
	@override String get stopServer => '서버 중지';
	@override String get minimize => '최소화';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingKo implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '같은 Plex 계정으로 Plezy를 실행 중인 네트워크의 기기가 자동으로 표시됩니다';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '연결 중...';
	@override String get searchingForDevices => '기기 검색 중...';
	@override String get noDevicesFound => '네트워크에서 기기를 찾을 수 없습니다';
	@override String get noDevicesHint => '데스크톱에서 Plezy가 열려 있고 두 기기가 같은 WiFi 네트워크에 있는지 확인하세요';
	@override String get availableDevices => '사용 가능한 기기';
	@override String get manualConnection => '수동 연결';
	@override String get cryptoInitFailed => '보안 연결을 초기화할 수 없습니다. Plex 계정에 로그인되어 있는지 확인하세요.';
	@override String get validationHostRequired => '호스트 주소를 입력하세요';
	@override String get validationHostFormat => '형식은 IP:포트여야 합니다 (예: 192.168.1.100:48632)';
	@override String get connectionTimedOut => '연결 시간이 초과되었습니다. 두 기기가 같은 네트워크에 있는지 확인하세요.';
	@override String get sessionNotFound => '기기를 찾을 수 없습니다. 호스트에서 Plezy가 실행 중인지 확인하세요.';
	@override String get authFailed => '인증에 실패했습니다. 두 기기가 같은 Plex 계정을 사용하는지 확인하세요.';
	@override String failedToConnect({required Object error}) => '연결 실패: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteKo implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteKo._(this._root);

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
	@override String get tabDiscover => '발견';
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

// Path: trackers.services
class _TranslationsTrackersServicesKo implements TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodeKo implements TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodeKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service}에서 Plezy 활성화';
	@override String body({required Object url}) => '${url}을 방문하여 이 코드를 입력하세요:';
	@override String openToActivate({required Object service}) => '활성화하려면 ${service} 열기';
	@override String get waitingForAuthorization => '인증을 기다리는 중…';
	@override String get codeCopied => '코드가 복사되었습니다';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxyKo implements TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxyKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service}에 로그인';
	@override String get body => '휴대전화로 이 QR 코드를 스캔하거나 아래 URL을 브라우저가 있는 기기에서 여세요.';
	@override String openToSignIn({required Object service}) => '로그인하려면 ${service} 열기';
	@override String get urlCopied => 'URL이 복사되었습니다';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterKo implements TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterKo._(this._root);

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
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Plex 계정으로 로그인',
			'auth.showQRCode' => 'QR 코드',
			'auth.authenticate' => '인증',
			'auth.authenticationTimeout' => '인증 시간이 초과되었습니다. 다시 시도해 주세요.',
			'auth.scanQRToSignIn' => 'QR 코드를 스캔하여 로그인',
			'auth.waitingForAuth' => '인증 대기 중... 브라우저에서 로그인을 완료해 주세요.',
			'auth.useBrowser' => '브라우저 사용',
			'common.cancel' => '취소',
			'common.save' => '저장',
			'common.close' => '닫기',
			'common.clear' => '지우기',
			'common.reset' => '초기화',
			'common.later' => '나중에',
			'common.submit' => '보내기',
			'common.confirm' => '확인',
			'common.retry' => '재시도',
			'common.logout' => '로그아웃',
			'common.unknown' => '알 수 없는',
			'common.refresh' => '새로고침',
			'common.yes' => '예',
			'common.no' => '아니오',
			'common.delete' => '삭제',
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
			'common.reconnect' => '다시 연결',
			'common.exitConfirmTitle' => '앱을 종료하시겠습니까?',
			'common.exitConfirmMessage' => '정말 종료하시겠습니까?',
			'common.dontAskAgain' => '다시 묻지 않기',
			'common.exit' => '종료',
			'common.viewAll' => '모두 보기',
			'common.checkingNetwork' => '네트워크 확인 중...',
			'common.refreshingServers' => '서버 새로고침 중...',
			'common.loadingServers' => '서버 로딩 중...',
			'common.connectingToServers' => '서버 연결 중...',
			'common.startingOfflineMode' => '오프라인 모드 시작 중...',
			'common.loading' => '로딩 중...',
			'common.fullscreen' => '전체화면',
			'common.exitFullscreen' => '전체화면 종료',
			'screens.licenses' => '라이선스',
			'screens.switchProfile' => '프로필 전환',
			'screens.subtitleStyling' => '자막 스타일 설정',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => '로그',
			'update.available' => '사용 가능한 업데이트',
			'update.versionAvailable' => ({required Object version}) => '버전 ${version} 출시됨',
			'update.currentVersion' => ({required Object version}) => '현재 버전: ${version}',
			'update.skipVersion' => '이 버전 건너뛰기',
			'update.viewRelease' => '릴리스 정보 보기',
			'update.latestVersion' => '최신 버전을 사용 중입니다',
			'update.checkFailed' => '업데이트 확인 실패',
			'settings.title' => '설정',
			'settings.supportDeveloper' => 'Plezy 후원하기',
			'settings.supportDeveloperDescription' => 'Liberapay로 후원하여 개발 지원',
			'settings.language' => '언어',
			'settings.theme' => '테마',
			'settings.appearance' => '외관',
			'settings.videoPlayback' => '비디오 재생',
			'settings.videoPlaybackDescription' => '재생 동작 구성',
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
			'settings.systemTheme' => '시스템 설정',
			'settings.lightTheme' => '라이트 모드',
			'settings.darkTheme' => '다크 모드',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => '라이브러리 표시 밀도',
			'settings.compact' => '좁게',
			'settings.comfortable' => '넓게',
			'settings.viewMode' => '보기 모드',
			'settings.gridView' => '그리드 보기',
			'settings.listView' => '목록 보기',
			'settings.showHeroSection' => '주요 추천 영역 표시',
			'settings.useGlobalHubs' => 'Plex 홈 레이아웃 사용',
			'settings.useGlobalHubsDescription' => '공식 Plex 클라이언트처럼 홈 페이지 허브를 표시합니다. 끄면 라이브러리별 추천이 대신 표시됩니다.',
			'settings.showServerNameOnHubs' => '허브에 서버 이름 표시',
			'settings.showServerNameOnHubsDescription' => '허브 제목에 항상 서버 이름을 표시합니다. 끄면 중복된 허브 이름에만 표시됩니다.',
			'settings.alwaysKeepSidebarOpen' => '사이드바 항상 열어두기',
			'settings.alwaysKeepSidebarOpenDescription' => '사이드바가 확장된 상태로 유지되고 콘텐츠 영역이 맞춰집니다',
			'settings.showUnwatchedCount' => '미시청 수 표시',
			'settings.showUnwatchedCountDescription' => '시리즈 및 시즌에 미시청 에피소드 수 표시',
			'settings.showEpisodeNumberOnCards' => '카드에 에피소드 번호 표시',
			'settings.showEpisodeNumberOnCardsDescription' => '에피소드 카드에 시즌과 함께 에피소드 번호(예: S2 E3)를 표시합니다',
			'settings.hideSpoilers' => '미시청 에피소드 스포일러 숨기기',
			'settings.hideSpoilersDescription' => '아직 시청하지 않은 에피소드의 썸네일을 흐리게 하고 설명을 숨깁니다',
			'settings.playerBackend' => '플레이어 백엔드',
			'settings.exoPlayer' => 'ExoPlayer (권장)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => '하드웨어 디코딩',
			'settings.hardwareDecodingDescription' => '가능한 경우 하드웨어 가속을 사용합니다',
			'settings.bufferSize' => '버퍼 크기',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => '자동 (권장)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '기기 메모리가 ${heap}MB입니다. ${size}MB 버퍼는 재생 문제를 일으킬 수 있습니다.',
			'settings.defaultQualityTitle' => '기본 화질',
			'settings.defaultQualityDescription' => '재생 시작 시 사용됩니다. 낮은 값은 대역폭을 줄입니다.',
			'settings.subtitleStyling' => '자막 스타일',
			'settings.subtitleStylingDescription' => '자막의 외형을 사용자 설정',
			'settings.smallSkipDuration' => '짧은 건너뛰기 시간',
			'settings.largeSkipDuration' => '긴 건너뛰기 시간',
			'settings.rewindOnResume' => '재개 시 되감기',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds}초',
			'settings.defaultSleepTimer' => '기본 취침 타이머',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes}분',
			'settings.rememberTrackSelections' => '에피소드/영화별 트랙 선택 기억',
			'settings.rememberTrackSelectionsDescription' => '재생 중 트랙을 변경할 때 오디오 및 자막 언어 설정을 자동으로 저장합니다',
			'settings.clickVideoTogglesPlayback' => '비디오를 클릭하여 재생/일시정지를 전환하세요.',
			'settings.clickVideoTogglesPlaybackDescription' => '이 옵션이 활성화되어 있으면 비디오 플레이어를 클릭할 때 재생 또는 일시정지가 됩니다. 그렇지 않으면 클릭 시 재생 컨트롤이 표시되거나 숨겨집니다.',
			'settings.videoPlayerControls' => '비디오 플레이어 컨트롤',
			'settings.keyboardShortcuts' => '키보드 단축키',
			'settings.keyboardShortcutsDescription' => '사용자 정의 키보드 단축키',
			'settings.videoPlayerNavigation' => '비디오 플레이어 탐색',
			'settings.videoPlayerNavigationDescription' => '방향 키를 사용하여 비디오 플레이어 컨트롤 탐색',
			'settings.watchTogetherRelay' => '함께 보기 릴레이',
			'settings.watchTogetherRelayDescription' => '함께 보기에 사용할 사용자 지정 릴레이 서버를 설정합니다. 모든 참가자가 동일한 서버를 사용해야 합니다.',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.crashReporting' => '충돌 보고',
			'settings.crashReportingDescription' => '앱 개선을 위해 충돌 보고서 전송',
			'settings.debugLogging' => '디버그 로깅',
			'settings.debugLoggingDescription' => '문제 해결을 위해 상세 로깅 활성화',
			'settings.viewLogs' => '로그 보기',
			'settings.viewLogsDescription' => '애플리케이션 로그 확인',
			'settings.clearCache' => '캐시 삭제',
			'settings.clearCacheDescription' => '모든 캐시된 이미지와 데이터를 지웁니다. 캐시를 지우면 애플리케이션 콘텐츠 로딩 속도가 느려질 수 있습니다.',
			'settings.clearCacheSuccess' => '캐시 삭제 성공',
			'settings.resetSettings' => '설정 재설정',
			'settings.resetSettingsDescription' => '모든 설정을 기본값으로 재설정합니다. 이 작업은 되돌릴 수 없습니다.',
			'settings.resetSettingsSuccess' => '설정 재설정 성공',
			'settings.backup' => '백업',
			'settings.exportSettings' => '설정 내보내기',
			'settings.exportSettingsDescription' => '기본 설정을 파일로 저장',
			'settings.exportSettingsSuccess' => '설정 내보내기 완료',
			'settings.exportSettingsFailed' => '설정을 내보낼 수 없습니다',
			'settings.importSettings' => '설정 가져오기',
			'settings.importSettingsDescription' => '파일에서 기본 설정 복원',
			'settings.importSettingsConfirm' => '현재 설정을 대체합니다. 계속하시겠습니까?',
			'settings.importSettingsSuccess' => '설정 가져오기 완료',
			'settings.importSettingsFailed' => '설정을 가져올 수 없습니다',
			'settings.importSettingsInvalidFile' => '유효한 Plezy 설정 내보내기 파일이 아닙니다',
			'settings.importSettingsNoUser' => '설정을 가져오기 전에 로그인하세요',
			'settings.shortcutsReset' => '단축키가 기본값으로 재설정되었습니다',
			'settings.about' => '정보',
			'settings.aboutDescription' => '응용 프로그램 정보 및 라이선스',
			'settings.updates' => '업데이트',
			'settings.updateAvailable' => '사용 가능한 업데이트 있음',
			'settings.checkForUpdates' => '업데이트 확인',
			'settings.autoCheckUpdatesOnStartup' => '시작 시 자동으로 업데이트 확인',
			'settings.autoCheckUpdatesOnStartupDescription' => '시작 시 새 버전이 있으면 알림 표시',
			'settings.validationErrorEnterNumber' => '유효한 숫자를 입력하세요',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '기간은 ${min}과 ${max} ${unit} 사이여야 합니다',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => '단축키가 이미 ${action}에 할당 되었습니다',
			'settings.shortcutUpdated' => ({required Object action}) => '단축키가 ${action}에 대해 업데이트 되었습니다',
			'settings.autoSkip' => '자동 건너뛰기',
			'settings.autoSkipIntro' => '자동으로 오프닝 건너뛰기',
			'settings.autoSkipIntroDescription' => '몇 초 후 오프닝을 자동으로 건너뛰기',
			'settings.autoSkipCredits' => '자동으로 엔딩 건너뛰기',
			'settings.autoSkipCreditsDescription' => '엔딩 크레딧 자동 건너뛰기 후 다음 에피소드 재생',
			'settings.autoSkipDelay' => '자동 건너뛰기 지연',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '자동 건너뛰기 전 ${seconds} 초 대기',
			'settings.introPattern' => '인트로 마커 패턴',
			'settings.introPatternDescription' => '챕터 제목에서 인트로 마커를 인식하는 정규식 패턴',
			'settings.creditsPattern' => '크레딧 마커 패턴',
			'settings.creditsPatternDescription' => '챕터 제목에서 크레딧 마커를 인식하는 정규식 패턴',
			'settings.invalidRegex' => '잘못된 정규식',
			'settings.downloads' => '다운로드',
			'settings.downloadLocationDescription' => '다운로드 콘텐츠 저장 위치 선택',
			'settings.downloadLocationDefault' => '기본값 (앱 저장소)',
			'settings.downloadLocationCustom' => '사용자 지정 위치',
			'settings.selectFolder' => '폴더 선택',
			'settings.resetToDefault' => '기본값으로 재설정',
			'settings.currentPath' => ({required Object path}) => '현재: ${path}',
			'settings.downloadLocationChanged' => '다운로드 위치가 변경 되었습니다',
			'settings.downloadLocationReset' => '다운로드 위치가 기본값으로 재설정 되었습니다',
			'settings.downloadLocationInvalid' => '선택한 폴더에 쓰기 권한이 없습니다',
			'settings.downloadLocationSelectError' => '폴더 선택 실패',
			'settings.downloadOnWifiOnly' => 'WiFi 연결 시에만 다운로드',
			'settings.downloadOnWifiOnlyDescription' => '셀룰러 데이터 사용 시 다운로드 불가',
			'settings.autoRemoveWatchedDownloads' => '시청한 다운로드 자동 삭제',
			'settings.autoRemoveWatchedDownloadsDescription' => '시청 완료로 표시된 에피소드와 영화의 다운로드를 자동으로 삭제',
			'settings.cellularDownloadBlocked' => '셀룰러 데이터에서 다운로드가 차단 되었습니다. WiFi에 연결하거나 설정을 변경하세요.',
			'settings.maxVolume' => '최대 볼륨',
			'settings.maxVolumeDescription' => '조용한 미디어를 위해 100% 이상의 볼륨 허용',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord에서 시청 중인 콘텐츠 표시',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Trakt와 시청 기록 동기화',
			'settings.trackers' => '트래커',
			'settings.trackersDescription' => 'Trakt, MyAnimeList, AniList 및 Simkl에 진행률 동기화',
			'settings.companionRemoteServer' => '컴패니언 리모트 서버',
			'settings.companionRemoteServerDescription' => '네트워크의 모바일 기기가 이 앱을 제어할 수 있도록 허용',
			'settings.autoPip' => '자동 PIP 모드',
			'settings.autoPipDescription' => '재생 중 앱을 나갈 때 자동으로 PIP 모드로 전환',
			'settings.matchContentFrameRate' => '콘텐츠 프레임 레이트 맞춤',
			'settings.matchContentFrameRateDescription' => '비디오 콘텐츠에 맞게 디스플레이 주사율을 조정하여 떨림을 줄이고 배터리를 절약합니다',
			'settings.matchRefreshRate' => '주사율 맞춤',
			'settings.matchRefreshRateDescription' => '전체 화면에서 비디오 콘텐츠에 맞게 디스플레이 주사율을 전환합니다',
			'settings.matchDynamicRange' => '다이나믹 레인지 맞춤',
			'settings.matchDynamicRangeDescription' => 'HDR 콘텐츠에 대해 자동으로 HDR을 활성화하고 플레이어를 나갈 때 SDR로 복원합니다',
			'settings.displaySwitchDelay' => '디스플레이 전환 지연',
			'settings.tunneledPlayback' => '터널 재생',
			'settings.tunneledPlaybackDescription' => '하드웨어 가속 비디오 터널링을 사용합니다. HDR 콘텐츠에서 소리만 나고 검은 화면이 보이면 비활성화하세요',
			'settings.requireProfileSelectionOnOpen' => '앱 실행 시 프로필 선택',
			'settings.requireProfileSelectionOnOpenDescription' => '앱을 열 때마다 프로필 선택 화면을 표시합니다',
			'settings.confirmExitOnBack' => '종료 전 확인',
			'settings.confirmExitOnBackDescription' => '뒤로 버튼을 눌러 앱을 종료할 때 확인 대화상자를 표시합니다',
			'settings.forceTvMode' => 'TV 모드 강제 사용',
			'settings.forceTvModeDescription' => '자동 감지와 관계없이 TV 레이아웃을 사용합니다. leanback 기능을 보고하지 않는 Android TV 기기에 유용합니다. 변경 시 앱이 다시 시작됩니다.',
			'settings.autoHidePerformanceOverlay' => '성능 오버레이 자동 숨기기',
			'settings.autoHidePerformanceOverlayDescription' => '재생 컨트롤과 함께 성능 오버레이를 페이드 처리',
			'settings.showNavBarLabels' => '내비게이션 바 라벨 표시',
			'settings.showNavBarLabelsDescription' => '내비게이션 바 아이콘 아래에 텍스트 라벨을 표시합니다',
			'settings.liveTvDefaultFavorites' => '즐겨찾기 채널 기본 설정',
			'settings.liveTvDefaultFavoritesDescription' => '라이브 TV를 열 때 즐겨찾기 채널만 표시',
			'settings.display' => 'Display',
			'settings.homeScreen' => 'Home Screen',
			'settings.navigation' => 'Navigation',
			'settings.content' => 'Content',
			'settings.player' => 'Player',
			'settings.subtitlesAndConfig' => 'Subtitles & Configuration',
			'settings.seekAndTiming' => 'Seek & Timing',
			'settings.behavior' => 'Behavior',
			'search.hint' => '영화, 시리즈, 음악 등을 검색하세요...',
			'search.tryDifferentTerm' => '다른 검색어를 시도해 보세요',
			'search.searchYourMedia' => '미디어 검색',
			'search.enterTitleActorOrKeyword' => '제목, 배우 또는 키워드를 입력하세요',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName}에 대한 단축키 설정',
			'hotkeys.clearShortcut' => '단축키 삭제',
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
			'hotkeys.actions.subSeekNext' => '다음 자막으로 이동',
			'hotkeys.actions.subSeekPrev' => '이전 자막으로 이동',
			'hotkeys.actions.shaderToggle' => '셰이더 전환',
			'hotkeys.actions.skipMarker' => '인트로/크레딧 건너뛰기',
			'fileInfo.title' => '파일 정보',
			'fileInfo.video' => '비디오',
			'fileInfo.audio' => '오디오',
			'fileInfo.file' => '파일',
			'fileInfo.advanced' => '고급',
			'fileInfo.codec' => '코덱',
			'fileInfo.resolution' => '해상도',
			'fileInfo.bitrate' => '비트레이트',
			'fileInfo.frameRate' => '프레임 속도',
			'fileInfo.aspectRatio' => '종횡비',
			'fileInfo.profile' => '프로파일',
			'fileInfo.bitDepth' => '비트 심도',
			'fileInfo.colorSpace' => '색 공간',
			'fileInfo.colorRange' => '색 범위',
			'fileInfo.colorPrimaries' => '색상 원색',
			'fileInfo.chromaSubsampling' => '채도 서브샘플링',
			'fileInfo.channels' => '채널',
			'fileInfo.subtitles' => '자막',
			'fileInfo.overallBitrate' => '전체 비트레이트',
			'fileInfo.path' => '경로',
			'fileInfo.size' => '크기',
			'fileInfo.container' => '컨테이너',
			'fileInfo.duration' => '재생 시간',
			'fileInfo.optimizedForStreaming' => '스트리밍 최적화',
			'fileInfo.has64bitOffsets' => '64비트 오프셋',
			'mediaMenu.markAsWatched' => '시청 완료로 표시',
			'mediaMenu.markAsUnwatched' => '시청 안 함으로 표시',
			'mediaMenu.removeFromContinueWatching' => '계속 보기에서 제거',
			'mediaMenu.goToSeries' => '시리즈로 이동',
			'mediaMenu.goToSeason' => '시즌으로 이동',
			'mediaMenu.shufflePlay' => '무작위 재생',
			'mediaMenu.fileInfo' => '파일 정보',
			'mediaMenu.deleteFromServer' => '서버에서 삭제',
			'mediaMenu.confirmDelete' => '이 미디어와 파일이 서버에서 영구적으로 삭제됩니다. 이 작업은 취소할 수 없습니다.',
			'mediaMenu.deleteMultipleWarning' => '모든 에피소드와 파일이 포함됩니다.',
			'mediaMenu.mediaDeletedSuccessfully' => '미디어 항목이 성공적으로 삭제되었습니다',
			'mediaMenu.mediaFailedToDelete' => '미디어 항목 삭제 실패',
			'mediaMenu.rate' => '평가',
			'mediaMenu.playFromBeginning' => '처음부터 재생',
			'mediaMenu.playVersion' => '버전 재생...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, 영화',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV 프로그램',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => '시청 완료',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} 퍼센트 시청 완료',
			'accessibility.mediaCardUnwatched' => '미시청',
			'accessibility.tapToPlay' => '터치 하여 재생',
			'tooltips.shufflePlay' => '무작위 재생',
			'tooltips.playTrailer' => '예고편 재생',
			'tooltips.markAsWatched' => '시청 완료로 표시',
			'tooltips.markAsUnwatched' => '시청 안 함으로 표시',
			'videoControls.audioLabel' => '오디오',
			'videoControls.subtitlesLabel' => '자막',
			'videoControls.resetToZero' => '0ms로 재설정',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} 나중에 재생됨',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} 더 먼저 재생됨',
			'videoControls.noOffset' => '오프셋 없음',
			'videoControls.letterbox' => '레터박스 모드',
			'videoControls.fillScreen' => '화면 채우기',
			'videoControls.stretch' => '확장',
			'videoControls.lockRotation' => '회전 잠금',
			'videoControls.unlockRotation' => '회전 잠금 해제',
			'videoControls.timerActive' => '타이머 활성화됨',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => '재생이 ${duration} 후에 일시 중지 됩니다',
			'videoControls.stillWatching' => '아직 시청 중이신가요?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}초 후 일시 정지',
			'videoControls.continueWatching' => '계속',
			'videoControls.autoPlayNext' => '다음 자동 재생',
			'videoControls.playNext' => '다음 재생',
			'videoControls.playButton' => '재생',
			'videoControls.pauseButton' => '일시정지',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} 초 뒤로',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} 초 앞으로',
			'videoControls.previousButton' => '이전 에피소드',
			'videoControls.nextButton' => '다음 에피소드',
			'videoControls.previousChapterButton' => '이전 챕터',
			'videoControls.nextChapterButton' => '다음 챕터',
			'videoControls.muteButton' => '음소거',
			'videoControls.unmuteButton' => '음소거 해제',
			'videoControls.settingsButton' => '동영상 설정',
			'videoControls.tracksButton' => '오디오 및 자막',
			'videoControls.chaptersButton' => '챕터',
			'videoControls.versionsButton' => '동영상 버전',
			'videoControls.versionQualityButton' => '버전 및 화질',
			'videoControls.versionColumnHeader' => '버전',
			'videoControls.qualityColumnHeader' => '화질',
			'videoControls.qualityOriginal' => '원본',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => '트랜스코딩을 사용할 수 없음 — 원본 화질로 재생',
			'videoControls.pipButton' => '픽처 인 픽처 모드',
			'videoControls.aspectRatioButton' => '화면비율',
			'videoControls.ambientLighting' => '주변 조명',
			'videoControls.fullscreenButton' => '전체화면',
			'videoControls.exitFullscreenButton' => '전체화면 종료',
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
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 이상이 필요합니다',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 이상이 필요합니다',
			'videoControls.pipErrors.permissionDisabled' => '화면 속 화면 권한이 비활성화되어 있습니다. 설정 > 앱 > Plezy > 화면 속 화면에서 활성화하세요',
			'videoControls.pipErrors.notSupported' => '이 기기는 화면 속 화면 모드를 지원하지 않습니다',
			'videoControls.pipErrors.voSwitchFailed' => '화면 속 화면을 위한 비디오 출력 전환에 실패했습니다',
			'videoControls.pipErrors.failed' => '화면 속 화면 모드를 시작할 수 없습니다',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '오류가 발생했습니다: ${error}',
			'videoControls.chapters' => '챕터',
			'videoControls.noChaptersAvailable' => '사용 가능한 챕터가 없습니다',
			'videoControls.queue' => '재생 대기열',
			'videoControls.noQueueItems' => '대기열에 항목이 없습니다',
			'videoControls.searchSubtitles' => '자막 검색',
			'videoControls.language' => '언어',
			'videoControls.noSubtitlesFound' => '자막을 찾을 수 없습니다',
			'videoControls.subtitleDownloaded' => '자막이 다운로드되었습니다',
			'videoControls.subtitleDownloadFailed' => '자막 다운로드에 실패했습니다',
			'videoControls.searchLanguages' => '언어 검색...',
			'userStatus.admin' => '관리자',
			'userStatus.restricted' => '제한됨',
			'userStatus.protected' => '보호됨',
			'userStatus.current' => '현재',
			'messages.markedAsWatched' => '시청 완료로 표시됨',
			'messages.markedAsUnwatched' => '시청 안 함으로 표시됨',
			'messages.markedAsWatchedOffline' => '시청 완료로 표시됨 (연결 시 동기화됨)',
			'messages.markedAsUnwatchedOffline' => '미시청으로 표시됨 (연결 시 동기화됨)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '자동 삭제됨: ${title}',
			'messages.removedFromContinueWatching' => '계속 시청 목록에서 제거됨',
			'messages.errorLoading' => ({required Object error}) => '오류: ${error}',
			'messages.fileInfoNotAvailable' => '파일 정보가 없습니다',
			'messages.errorLoadingFileInfo' => ({required Object error}) => '파일 정보 로딩 중 오류: ${error}',
			'messages.errorLoadingSeries' => '시리즈 로딩 중 오류',
			'messages.errorLoadingSeason' => '시즌 로딩 중 오류',
			'messages.musicNotSupported' => '음악 재생 미지원',
			'messages.noDescriptionAvailable' => '설명이 없습니다',
			'messages.noProfilesAvailable' => '사용 가능한 프로필이 없습니다',
			'messages.contactAdminForProfiles' => '프로필을 추가하려면 Plex 관리자에게 문의하세요',
			'messages.unableToDetermineLibrarySection' => '이 항목의 라이브러리 섹션을 확인할 수 없습니다',
			'messages.logsCleared' => '로그가 삭제 되었습니다',
			'messages.logsCopied' => '로그가 클립보드에 복사 되었습니다',
			'messages.noLogsAvailable' => '사용 가능한 로그가 없습니다',
			'messages.libraryScanning' => ({required Object title}) => '"${title}"을(를) 스캔 중입니다...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}" 미디어 라이브러리 스캔 시작',
			'messages.libraryScanFailed' => ({required Object error}) => '미디어 라이브러리 스캔 실패: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" 메타데이터 새로고침 중...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" 메타데이터 새로고침 시작됨',
			'messages.metadataRefreshFailed' => ({required Object error}) => '메타데이터 새로고침 실패: ${error}',
			'messages.logoutConfirm' => '로그아웃 하시겠습니까?',
			'messages.noSeasonsFound' => '시즌을 찾을 수 없음',
			'messages.noEpisodesFound' => '시즌 1에서 에피소드를 찾을 수 없습니다',
			'messages.noEpisodesFoundGeneral' => '에피소드를 찾을 수 없습니다',
			'messages.noResultsFound' => '결과를 찾을 수 없습니다',
			'messages.sleepTimerSet' => ({required Object label}) => '수면 타이머가 ${label}로 설정 되었습니다',
			'messages.noItemsAvailable' => '사용 가능한 항목이 없습니다',
			'messages.failedToCreatePlayQueueNoItems' => '재생 대기열 생성 실패 - 항목 없음',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action}을(를) 수행할 수 없습니다: ${error}',
			'messages.switchingToCompatiblePlayer' => '호환되는 플레이어로 전환 중...',
			'messages.serverLimitTitle' => '재생 실패',
			'messages.serverLimitBody' => '서버에서 오류를 반환했습니다 (HTTP 500). 일반적으로 이는 서버 소유자가 대역폭 또는 트랜스코딩 제한을 설정하여 세션을 거부하고 있다는 의미입니다. 클라이언트에서 할 수 있는 일은 없습니다 — 서버 소유자가 설정을 조정해야 합니다.',
			'messages.logsUploaded' => '로그 업로드 완료',
			'messages.logsUploadFailed' => '로그 업로드 실패',
			'messages.logId' => '로그 ID',
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
			'subtitlingStyling.bold' => '굵게',
			'subtitlingStyling.italic' => '기울임꼴',
			'mpvConfig.title' => 'mpv 설정',
			'mpvConfig.description' => '고급 비디오 플레이어 설정',
			'mpvConfig.presets' => '사전 설정',
			'mpvConfig.noPresets' => '저장된 사전 설정이 없습니다',
			'mpvConfig.saveAsPreset' => '프리셋으로 저장...',
			'mpvConfig.presetName' => '프리셋 이름',
			'mpvConfig.presetNameHint' => '이 프리셋의 이름을 입력하세요',
			'mpvConfig.loadPreset' => '로드',
			'mpvConfig.deletePreset' => '삭제',
			'mpvConfig.presetSaved' => '프리셋이 저장 되었습니다',
			'mpvConfig.presetLoaded' => '프리셋이 로드 되었습니다',
			'mpvConfig.presetDeleted' => '프리셋이 삭제 되었습니다',
			'mpvConfig.confirmDeletePreset' => '이 프리셋을 삭제 하시겠습니까?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => '확인',
			'discover.title' => '발견',
			'discover.switchProfile' => '사용자 전환',
			'discover.noContentAvailable' => '사용 가능한 콘텐츠가 없습니다',
			'discover.addMediaToLibraries' => '미디어 라이브러리에 미디어를 추가해 주세요',
			'discover.continueWatching' => '계속 시청',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => '개요',
			'discover.cast' => '출연진',
			'discover.extras' => '예고편 및 부가영상',
			'discover.studio' => '제작사',
			'discover.rating' => '연령 등급',
			'discover.movie' => '영화',
			'discover.tvShow' => 'TV 시리즈',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes}분 남음',
			'errors.searchFailed' => ({required Object error}) => '검색 실패: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => '${context} 로드 중 연결 시간 초과',
			'errors.connectionFailed' => 'Plex 서버에 연결할 수 없음',
			'errors.failedToLoad' => ({required Object context, required Object error}) => '${context} 로드 실패: ${error}',
			'errors.noClientAvailable' => '사용 가능한 클라이언트가 없습니다',
			'errors.authenticationFailed' => ({required Object error}) => '인증 실패: ${error}',
			'errors.couldNotLaunchUrl' => '인증 URL을 열 수 없습니다',
			'errors.pleaseEnterToken' => '토큰을 입력해 주세요',
			'errors.invalidToken' => '토큰이 유효하지 않습니다',
			'errors.failedToVerifyToken' => ({required Object error}) => '토큰을 확인할 수 없습니다: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName}으로 전환할 수 없습니다',
			'libraries.title' => '미디어 라이브러리',
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
			'libraries.thisLibraryIsEmpty' => '이 미디어 라이브러리는 비어 있습니다',
			'libraries.all' => '전체',
			'libraries.clearAll' => '모두 삭제',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '「${title}」를 스캔 하시겠습니까?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '「${title}」를 분석 하시겠습니까?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '「${title}」의 메타데이터를 새로고침 하시겠습니까?',
			_ => null,
		} ?? switch (path) {
			'libraries.emptyTrashConfirm' => ({required Object title}) => '${title}의 휴지통을 비우시겠습니까?',
			'libraries.manageLibraries' => '미디어 라이브러리 관리',
			'libraries.sort' => '정렬',
			'libraries.sortBy' => '정렬 기준',
			'libraries.filters' => '필터',
			'libraries.confirmActionMessage' => '이 작업을 실행 하시겠습니까?',
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
			'libraries.groupings.folders' => '폴더',
			'about.title' => '소개',
			'about.openSourceLicenses' => '오픈소스 라이선스',
			'about.versionLabel' => ({required Object version}) => '버전 ${version}',
			'about.appDescription' => '아름다운 Flutter Plex 클라이언트',
			'about.viewLicensesDescription' => '타사 라이브러리 라이선스 보기',
			'serverSelection.allServerConnectionsFailed' => '어떤 서버에도 연결할 수 없습니다. 네트워크를 확인하고 다시 시도하세요.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email})의 서버를 찾을 수 없습니다.',
			'serverSelection.failedToLoadServers' => ({required Object error}) => '서버를 로드할 수 없습니다: ${error}',
			'hubDetail.title' => '제목',
			'hubDetail.releaseYear' => '출시 연도',
			'hubDetail.dateAdded' => '추가 날짜',
			'hubDetail.rating' => '평점',
			'hubDetail.noItemsFound' => '항목이 없습니다',
			'logs.clearLogs' => '로그 지우기',
			'logs.copyLogs' => '로그 복사',
			'logs.uploadLogs' => '로그 업로드',
			'licenses.relatedPackages' => '관련 소프트웨어 패키지',
			'licenses.license' => '라이선스',
			'licenses.licenseNumber' => ({required Object number}) => '라이선스 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 개의 라이선스',
			'navigation.libraries' => '미디어 라이브러리',
			'navigation.downloads' => '다운로드',
			'navigation.liveTv' => '실시간 TV',
			'liveTv.title' => '실시간 TV',
			'liveTv.guide' => '편성표',
			'liveTv.noChannels' => '사용 가능한 채널이 없습니다',
			'liveTv.noDvr' => '서버에 DVR이 구성되어 있지 않습니다',
			'liveTv.noPrograms' => '프로그램 데이터가 없습니다',
			'liveTv.live' => '실시간',
			'liveTv.reloadGuide' => '편성표 새로고침',
			'liveTv.now' => '지금',
			'liveTv.today' => '오늘',
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
			'liveTv.joinSession' => '진행 중인 세션 참여',
			'liveTv.watchFromStart' => ({required Object minutes}) => '처음부터 시청 (${minutes}분 전 시작)',
			'liveTv.watchLive' => '실시간 시청',
			'liveTv.goToLive' => '실시간으로 이동',
			'collections.title' => '컬렉션',
			'collections.collection' => '컬렉션',
			'collections.empty' => '컬렉션이 비어 있습니다',
			'collections.unknownLibrarySection' => '삭제할 수 없습니다: 알 수 없는 미디어 라이브러리 섹션입니다',
			'collections.deleteCollection' => '컬렉션 삭제',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}"을(를) 삭제 하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
			'collections.deleted' => '컬렉션 삭제됨',
			'collections.deleteFailed' => '컬렉션 삭제 실패',
			'collections.deleteFailedWithError' => ({required Object error}) => '컬렉션 삭제 실패: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => '컬렉션 항목 로드 실패: ${error}',
			'collections.selectCollection' => '컬렉션 선택',
			'collections.collectionName' => '컬렉션 이름',
			'collections.enterCollectionName' => '컬렉션 이름 입력',
			'collections.addedToCollection' => '컬렉션에 추가됨',
			'collections.errorAddingToCollection' => '컬렉션에 추가 실패',
			'collections.created' => '컬렉션 생성됨',
			'collections.removeFromCollection' => '컬렉션에서 제거',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '${title}을/를 이 컬렉션에서 제거 하시겠습니까?',
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
			'playlists.deleteConfirm' => '재생 목록을 삭제 하시겠습니까?',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}"을(를) 삭제 하시겠습니까?',
			'playlists.created' => '재생 목록이 생성 되었습니다',
			'playlists.deleted' => '재생 목록이 삭제 되었습니다',
			'playlists.itemAdded' => '재생 목록에 추가 되었습니다',
			'playlists.itemRemoved' => '재생 목록에서 제거됨',
			'playlists.selectPlaylist' => '재생 목록 선택',
			'playlists.errorCreating' => '재생 목록 생성 실패',
			'playlists.errorDeleting' => '재생 목록 삭제 실패',
			'playlists.errorLoading' => '재생 목록 로드 실패',
			'playlists.errorAdding' => '재생 목록에 추가 실패',
			'playlists.errorReordering' => '재생 목록 항목 재정렬 실패',
			'playlists.errorRemoving' => '재생 목록에서 제거 실패',
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
			'watchTogether.hostingSession' => '세션 호스팅',
			'watchTogether.inSession' => '세션 중',
			'watchTogether.sessionCode' => '세션 코드',
			'watchTogether.hostControlsPlayback' => '호스트 재생 제어',
			'watchTogether.anyoneCanControl' => '누구나 재생 제어 가능',
			'watchTogether.hostControls' => '호스트 제어',
			'watchTogether.anyoneControls' => '누구나 제어',
			'watchTogether.participants' => '참가자',
			'watchTogether.host' => '호스트',
			'watchTogether.hostBadge' => '호스트',
			'watchTogether.youAreHost' => '당신은 호스트 입니다',
			'watchTogether.watchingWithOthers' => '다른 사람과 함께 시청 중',
			'watchTogether.endSession' => '세션 종료',
			'watchTogether.leaveSession' => '세션 탈퇴',
			'watchTogether.endSessionQuestion' => '세션을 종료 하시겠습니까?',
			'watchTogether.leaveSessionQuestion' => '세션을 탈퇴 하시겠습니까?',
			'watchTogether.endSessionConfirm' => '이 작업은 모든 참가자의 세션을 종료합니다.',
			'watchTogether.leaveSessionConfirm' => '당신은 세션에서 제거됩니다.',
			'watchTogether.endSessionConfirmOverlay' => '이것은 모든 참가자의 시청 세션을 종료합니다.',
			'watchTogether.leaveSessionConfirmOverlay' => '시청 세션 연결이 끊어집니다.',
			'watchTogether.end' => '종료',
			'watchTogether.leave' => '이탈',
			'watchTogether.syncing' => '동기화 중...',
			'watchTogether.joinWatchSession' => '시청 세션에 참여',
			'watchTogether.enterCodeHint' => '5자리 코드 입력',
			'watchTogether.pasteFromClipboard' => '클립보드에서 붙여넣기',
			'watchTogether.pleaseEnterCode' => '세션 코드를 입력하세요',
			'watchTogether.codeMustBe5Chars' => '세션 코드는 반드시 5자리여야 합니다',
			'watchTogether.joinInstructions' => '호스트가 공유한 세션 코드를 입력하여 시청 세션에 참여하세요.',
			'watchTogether.failedToCreate' => '세션 생성 실패',
			'watchTogether.failedToJoin' => '세션 참여 실패',
			'watchTogether.sessionCodeCopied' => '세션 코드가 클립보드에 복사되었습니다',
			'watchTogether.relayUnreachable' => '릴레이 서버에 연결할 수 없습니다. 인터넷 제공업체가 연결을 차단하고 있을 수 있습니다. 시도해 볼 수 있지만 함께 보기가 작동하지 않을 수 있습니다.',
			'watchTogether.reconnectingToHost' => '호스트에 재연결 중...',
			'watchTogether.currentPlayback' => '현재 재생',
			'watchTogether.joinCurrentPlayback' => '현재 재생 참여',
			'watchTogether.joinCurrentPlaybackDescription' => '호스트가 현재 보고 있는 항목으로 돌아갑니다',
			'watchTogether.failedToOpenCurrentPlayback' => '현재 재생을 열 수 없습니다',
			'watchTogether.participantJoined' => ({required Object name}) => '${name}님이 참여했습니다',
			'watchTogether.participantLeft' => ({required Object name}) => '${name}님이 나갔습니다',
			'watchTogether.participantPaused' => ({required Object name}) => '${name}님이 일시정지했습니다',
			'watchTogether.participantResumed' => ({required Object name}) => '${name}님이 재생했습니다',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name}님이 탐색했습니다',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name}님이 버퍼링 중입니다',
			'watchTogether.waitingForParticipants' => '다른 참가자의 로딩을 기다리는 중...',
			'watchTogether.recentRooms' => '최근 방',
			'watchTogether.renameRoom' => '방 이름 변경',
			'watchTogether.removeRoom' => '제거',
			'downloads.title' => '다운로드',
			'downloads.manage' => '관리',
			'downloads.tvShows' => 'TV 프로그램',
			'downloads.movies' => '영화',
			'downloads.noDownloads' => '다운로드 없음',
			'downloads.noDownloadsDescription' => '다운로드한 콘텐츠는 오프라인 시청을 위해 여기에 표시됩니다',
			'downloads.downloadNow' => '다운로드',
			'downloads.deleteDownload' => '다운로드 삭제',
			'downloads.retryDownload' => '다운로드 재시도',
			'downloads.downloadQueued' => '다운로드 대기 중',
			'downloads.serverErrorBitrate' => '서버 오류 — 파일이 원격 스트리밍 비트레이트 제한을 초과할 수 있습니다',
			'downloads.episodesQueued' => ({required Object count}) => '${count} 에피소드가 다운로드 대기열에 추가 되었습니다',
			'downloads.downloadDeleted' => '다운로드 삭제됨',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}"를 삭제 하시겠습니까? 다운로드한 파일이 기기에서 삭제됩니다.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})',
			'downloads.noDownloadsTree' => '다운로드 없음',
			'downloads.pauseAll' => '모두 일시정지',
			'downloads.resumeAll' => '모두 재개',
			'downloads.deleteAll' => '모두 삭제',
			'downloads.selectVersion' => '버전 선택',
			'downloads.allEpisodes' => '모든 에피소드',
			'downloads.unwatchedOnly' => '시청하지 않은 것만',
			'downloads.nextNUnwatched' => ({required Object count}) => '다음 ${count}개 미시청',
			'downloads.customAmount' => '직접 입력...',
			'downloads.howManyEpisodes' => '몇 개의 에피소드?',
			'downloads.itemsQueued' => ({required Object count}) => '${count}개 항목이 다운로드 대기열에 추가됨',
			'downloads.keepSynced' => '동기화 유지',
			'downloads.downloadOnce' => '한 번만 다운로드',
			'downloads.keepNUnwatched' => ({required Object count}) => '미시청 ${count}개 유지',
			'downloads.editSyncRule' => '동기화 규칙 편집',
			'downloads.removeSyncRule' => '동기화 규칙 제거',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" 동기화를 중단하시겠습니까? 다운로드된 에피소드는 유지됩니다.',
			'downloads.syncRuleCreated' => ({required Object count}) => '동기화 규칙 생성됨 — 미시청 에피소드 ${count}개 유지',
			'downloads.syncRuleUpdated' => '동기화 규칙 업데이트됨',
			'downloads.syncRuleRemoved' => '동기화 규칙 제거됨',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title}의 새 에피소드 ${count}개 동기화됨',
			'downloads.activeSyncRules' => '동기화 규칙',
			'downloads.noSyncRules' => '동기화 규칙 없음',
			'downloads.manageSyncRule' => '동기화 관리',
			'downloads.editEpisodeCount' => '에피소드 수',
			'downloads.editSyncFilter' => '동기화 필터',
			'downloads.syncAllItems' => '모든 항목 동기화 중',
			'downloads.syncUnwatchedItems' => '시청하지 않은 항목 동기화 중',
			'downloads.syncRuleListCreated' => '동기화 규칙이 생성되었습니다',
			'shaders.title' => '셰이더',
			'shaders.noShaderDescription' => '비디오 향상 없음',
			'shaders.nvscalerDescription' => '더 선명한 비디오를 위한 NVIDIA 이미지 스케일링',
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
			'companionRemote.session.startingServer' => '원격 서버 시작 중...',
			'companionRemote.session.failedToCreate' => '원격 서버를 시작하지 못했습니다:',
			'companionRemote.session.hostAddress' => '호스트 주소',
			'companionRemote.session.connected' => '연결됨',
			'companionRemote.session.serverRunning' => '원격 서버 활성',
			'companionRemote.session.serverStopped' => '원격 서버 중지됨',
			'companionRemote.session.serverRunningDescription' => '네트워크의 모바일 기기가 이 앱을 검색하고 연결할 수 있습니다',
			'companionRemote.session.serverStoppedDescription' => '모바일 기기의 연결을 허용하려면 서버를 시작하세요',
			'companionRemote.session.usePhoneToControl' => '모바일 기기로 이 앱을 제어하세요',
			'companionRemote.session.startServer' => '서버 시작',
			'companionRemote.session.stopServer' => '서버 중지',
			'companionRemote.session.minimize' => '최소화',
			'companionRemote.pairing.discoveryDescription' => '같은 Plex 계정으로 Plezy를 실행 중인 네트워크의 기기가 자동으로 표시됩니다',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '연결 중...',
			'companionRemote.pairing.searchingForDevices' => '기기 검색 중...',
			'companionRemote.pairing.noDevicesFound' => '네트워크에서 기기를 찾을 수 없습니다',
			'companionRemote.pairing.noDevicesHint' => '데스크톱에서 Plezy가 열려 있고 두 기기가 같은 WiFi 네트워크에 있는지 확인하세요',
			'companionRemote.pairing.availableDevices' => '사용 가능한 기기',
			'companionRemote.pairing.manualConnection' => '수동 연결',
			'companionRemote.pairing.cryptoInitFailed' => '보안 연결을 초기화할 수 없습니다. Plex 계정에 로그인되어 있는지 확인하세요.',
			'companionRemote.pairing.validationHostRequired' => '호스트 주소를 입력하세요',
			'companionRemote.pairing.validationHostFormat' => '형식은 IP:포트여야 합니다 (예: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => '연결 시간이 초과되었습니다. 두 기기가 같은 네트워크에 있는지 확인하세요.',
			'companionRemote.pairing.sessionNotFound' => '기기를 찾을 수 없습니다. 호스트에서 Plezy가 실행 중인지 확인하세요.',
			'companionRemote.pairing.authFailed' => '인증에 실패했습니다. 두 기기가 같은 Plex 계정을 사용하는지 확인하세요.',
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
			'companionRemote.remote.tabDiscover' => '발견',
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
			'videoSettings.playbackSettings' => '재생 설정',
			'videoSettings.playbackSpeed' => '재생 속도',
			'videoSettings.sleepTimer' => '취침 타이머',
			'videoSettings.audioSync' => '오디오 동기화',
			'videoSettings.subtitleSync' => '자막 동기화',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => '오디오 출력',
			'videoSettings.performanceOverlay' => '성능 오버레이',
			'videoSettings.audioPassthrough' => '오디오 패스스루',
			'videoSettings.audioNormalization' => '음량 정규화',
			'externalPlayer.title' => '외부 플레이어',
			'externalPlayer.useExternalPlayer' => '외부 플레이어 사용',
			'externalPlayer.useExternalPlayerDescription' => '내장 플레이어 대신 외부 앱에서 동영상 열기',
			'externalPlayer.selectPlayer' => '플레이어 선택',
			'externalPlayer.customPlayers' => '사용자 정의 플레이어',
			'externalPlayer.systemDefault' => '시스템 기본값',
			'externalPlayer.addCustomPlayer' => '사용자 정의 플레이어 추가',
			'externalPlayer.playerName' => '플레이어 이름',
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
			'metadataEdit.style' => '스타일',
			'metadataEdit.mood' => '분위기',
			'matchScreen.match' => '일치...',
			'matchScreen.fixMatch' => '일치 수정...',
			'matchScreen.unmatch' => '일치 해제',
			'matchScreen.unmatchConfirm' => '이 항목의 현재 일치를 해제하시겠습니까? 다시 일치시킬 때까지 Plex는 일치되지 않은 것으로 처리합니다.',
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
			'trakt.disconnectConfirmBody' => 'Plezy가 Trakt로 재생 이벤트를 보내지 않습니다. 언제든지 다시 연결할 수 있습니다.',
			'trakt.scrobble' => '실시간 스크로블',
			'trakt.scrobbleDescription' => '재생 중 재생, 일시정지, 정지 이벤트를 Trakt로 전송합니다.',
			'trakt.watchedSync' => '시청 상태 동기화',
			'trakt.watchedSyncDescription' => 'Plezy에서 시청 완료로 표시한 항목이 Trakt에도 시청 완료로 표시됩니다.',
			'trakt.connectFailed' => 'Trakt에 연결할 수 없습니다. 다시 시도하세요.',
			'trackers.title' => '트래커',
			'trackers.hubSubtitle' => '시청 진행률을 Trakt 및 기타 서비스와 동기화하세요.',
			'trackers.notConnected' => '연결되지 않음',
			'trackers.connectedAs' => ({required Object username}) => '@${username} 로 연결됨',
			'trackers.scrobble' => '진행률 자동 추적',
			'trackers.scrobbleDescription' => '에피소드나 영화를 시청하면 목록을 업데이트합니다.',
			'trackers.disconnectConfirm' => ({required Object service}) => '${service} 연결을 해제하시겠습니까?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy가 ${service} 목록 업데이트를 중지합니다. 언제든지 다시 연결할 수 있습니다.',
			'trackers.connectFailed' => ({required Object service}) => '${service}에 연결할 수 없습니다. 다시 시도하세요.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => '${service}에서 Plezy 활성화',
			'trackers.deviceCode.body' => ({required Object url}) => '${url}을 방문하여 이 코드를 입력하세요:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => '활성화하려면 ${service} 열기',
			'trackers.deviceCode.waitingForAuthorization' => '인증을 기다리는 중…',
			'trackers.deviceCode.codeCopied' => '코드가 복사되었습니다',
			'trackers.oauthProxy.title' => ({required Object service}) => '${service}에 로그인',
			'trackers.oauthProxy.body' => '휴대전화로 이 QR 코드를 스캔하거나 아래 URL을 브라우저가 있는 기기에서 여세요.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => '로그인하려면 ${service} 열기',
			'trackers.oauthProxy.urlCopied' => 'URL이 복사되었습니다',
			'trackers.libraryFilter.title' => '라이브러리 필터',
			'trackers.libraryFilter.subtitleAllSyncing' => '모든 라이브러리 동기화 중',
			'trackers.libraryFilter.subtitleNoneSyncing' => '동기화 안 함',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count}개 차단됨',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count}개 허용됨',
			'trackers.libraryFilter.mode' => '필터 모드',
			'trackers.libraryFilter.modeBlacklist' => '차단 목록',
			'trackers.libraryFilter.modeWhitelist' => '허용 목록',
			'trackers.libraryFilter.modeHintBlacklist' => '아래에 선택한 라이브러리를 제외한 모든 라이브러리를 동기화합니다.',
			'trackers.libraryFilter.modeHintWhitelist' => '아래에 선택한 라이브러리만 동기화합니다.',
			'trackers.libraryFilter.libraries' => '라이브러리',
			'trackers.libraryFilter.noLibraries' => '사용 가능한 라이브러리가 없습니다',
			_ => null,
		};
	}
}
