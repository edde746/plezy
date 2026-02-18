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
	@override late final _TranslationsPinEntryKo pinEntry = _TranslationsPinEntryKo._(_root);
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
	@override String get debugEnterToken => '디버깅을 위해 Plex 토큰을 입력하세요.';
	@override String get plexTokenLabel => 'Plex 인증 토큰';
	@override String get plexTokenHint => 'Plex.tv 토큰을 입력하세요';
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
	@override String get remove => '삭제';
	@override String get paste => '붙여넣기';
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
	@override String get loading => '로딩 중...';
	@override String get reconnect => '다시 연결';
	@override String get exitConfirmTitle => '앱을 종료하시겠습니까?';
	@override String get exitConfirmMessage => '정말 종료하시겠습니까?';
	@override String get dontAskAgain => '다시 묻지 않기';
	@override String get exit => '종료';
}

// Path: screens
class _TranslationsScreensKo implements TranslationsScreensEn {
	_TranslationsScreensKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get licenses => '라이선스';
	@override String get switchProfile => '프로필 전환';
	@override String get subtitleStyling => '자막 스타일 설정';
	@override String get mpvConfig => 'MPV 설정';
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
	@override String get language => '언어';
	@override String get theme => '테마';
	@override String get appearance => '외관';
	@override String get videoPlayback => '비디오 재생';
	@override String get advanced => '고급';
	@override String get episodePosterMode => '에피소드 포스터 스타일';
	@override String get seriesPoster => '시리즈 포스터';
	@override String get seriesPosterDescription => '모든 에피소드에 시리즈 포스터 표시';
	@override String get seasonPoster => '시즌 포스터';
	@override String get seasonPosterDescription => '에피소드에 시즌별 포스터 표시';
	@override String get episodeThumbnail => '에피소드 썸네일';
	@override String get episodeThumbnailDescription => '16:9 에피소드 스크린샷 썸네일 표시';
	@override String get showHeroSectionDescription => '홈 화면에 주요 콘텐츠 캐러셀(슬라이드) 표시';
	@override String get secondsLabel => '초';
	@override String get minutesLabel => '분';
	@override String get secondsShort => '초';
	@override String get minutesShort => '분';
	@override String durationHint({required Object min, required Object max}) => '기간 입력 (${min}-${max})';
	@override String get systemTheme => '시스템 설정';
	@override String get systemThemeDescription => '시스템 설정에 따름';
	@override String get lightTheme => '라이트 모드';
	@override String get darkTheme => '다크 모드';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'OLED 화면을 위한 순수 검정';
	@override String get libraryDensity => '라이브러리 표시 밀도';
	@override String get compact => '좁게';
	@override String get compactDescription => '카드를 작게 표시하여 더 많은 항목을 보여줍니다.';
	@override String get normal => '보통';
	@override String get normalDescription => '기본 크기';
	@override String get comfortable => '넓게';
	@override String get comfortableDescription => '카드를 크게 표시하여 더 적은 항목을 보여줍니다.';
	@override String get viewMode => '보기 모드';
	@override String get gridView => '그리드 보기';
	@override String get gridViewDescription => '항목을 그리드 레이아웃으로 표시합니다';
	@override String get listView => '목록 보기';
	@override String get listViewDescription => '항목을 목록 레이아웃으로 표시합니다';
	@override String get showHeroSection => '주요 추천 영역 표시';
	@override String get useGlobalHubs => 'Plex 홈 레이아웃 사용';
	@override String get useGlobalHubsDescription => '공식 Plex 클라이언트처럼 홈 페이지 허브를 표시합니다. 끄면 라이브러리별 추천이 대신 표시됩니다.';
	@override String get showServerNameOnHubs => '허브에 서버 이름 표시';
	@override String get showServerNameOnHubsDescription => '허브 제목에 항상 서버 이름을 표시합니다. 끄면 중복된 허브 이름에만 표시됩니다.';
	@override String get alwaysKeepSidebarOpen => '사이드바 항상 열어두기';
	@override String get alwaysKeepSidebarOpenDescription => '사이드바가 확장된 상태로 유지되고 콘텐츠 영역이 맞춰집니다';
	@override String get showUnwatchedCount => '미시청 수 표시';
	@override String get showUnwatchedCountDescription => '시리즈 및 시즌에 미시청 에피소드 수 표시';
	@override String get playerBackend => '플레이어 백엔드';
	@override String get exoPlayer => 'ExoPlayer (권장)';
	@override String get exoPlayerDescription => '더 나은 하드웨어 지원을 제공하는 Android 네이티브 플레이어';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => '더 많은 기능과 ASS 자막을 지원하는 고급 플레이어';
	@override String get hardwareDecoding => '하드웨어 디코딩';
	@override String get hardwareDecodingDescription => '가능한 경우 하드웨어 가속을 사용합니다';
	@override String get bufferSize => '버퍼 크기';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => '자막 스타일';
	@override String get subtitleStylingDescription => '자막의 외형을 사용자 설정';
	@override String get smallSkipDuration => '짧은 건너뛰기 시간';
	@override String get largeSkipDuration => '긴 건너뛰기 시간';
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
	@override String get shortcutsReset => '단축키가 기본값으로 재설정되었습니다';
	@override String get about => '정보';
	@override String get aboutDescription => '응용 프로그램 정보 및 라이선스';
	@override String get updates => '업데이트';
	@override String get updateAvailable => '사용 가능한 업데이트 있음';
	@override String get checkForUpdates => '업데이트 확인';
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
	@override String get cellularDownloadBlocked => '셀룰러 데이터에서 다운로드가 차단 되었습니다. WiFi에 연결하거나 설정을 변경하세요.';
	@override String get maxVolume => '최대 볼륨';
	@override String get maxVolumeDescription => '조용한 미디어를 위해 100% 이상의 볼륨 허용';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord에서 시청 중인 콘텐츠 표시';
	@override String get matchContentFrameRate => '콘텐츠 프레임 레이트 맞춤';
	@override String get matchContentFrameRateDescription => '비디오 콘텐츠에 맞게 디스플레이 주사율을 조정하여 떨림을 줄이고 배터리를 절약합니다';
	@override String get requireProfileSelectionOnOpen => '앱 실행 시 프로필 선택';
	@override String get requireProfileSelectionOnOpenDescription => '앱을 열 때마다 프로필 선택 화면을 표시합니다';
	@override String get confirmExitOnBack => '종료 전 확인';
	@override String get confirmExitOnBackDescription => '뒤로 버튼을 눌러 앱을 종료할 때 확인 대화상자를 표시합니다';
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

// Path: pinEntry
class _TranslationsPinEntryKo implements TranslationsPinEntryEn {
	_TranslationsPinEntryKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'PIN 입력';
	@override String get showPin => 'PIN 표시';
	@override String get hidePin => 'PIN 숨기기';
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
	@override String get confirmDelete => '파일 시스템에서 이 항목을 삭제하시겠습니까?';
	@override String get deleteMultipleWarning => '여러 항목이 삭제될 수 있습니다.';
	@override String get mediaDeletedSuccessfully => '미디어 항목이 성공적으로 삭제되었습니다';
	@override String get mediaFailedToDelete => '미디어 항목 삭제 실패';
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
	@override String get sleepTimerCompleted => '수면 타이머 완료됨 - 재생이 일시 중지되었습니다';
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
	@override String get audioTrackButton => '음원 트랙';
	@override String get subtitlesButton => '자막';
	@override String get chaptersButton => '챕터';
	@override String get versionsButton => '동영상 버전';
	@override String get pipButton => '픽처 인 픽처 모드';
	@override String get aspectRatioButton => '화면비율';
	@override String get fullscreenButton => '전체화면';
	@override String get exitFullscreenButton => '전체화면 종료';
	@override String get alwaysOnTopButton => '창 최상위 고정';
	@override String get rotationLockButton => '회전 잠금';
	@override String get timelineSlider => '타임라인';
	@override String get volumeSlider => '볼륨 조절';
	@override String endsAt({required Object time}) => '${time}에 종료';
	@override String get pipFailed => '화면 속 화면 모드를 시작할 수 없습니다';
	@override late final _TranslationsVideoControlsPipErrorsKo pipErrors = _TranslationsVideoControlsPipErrorsKo._(_root);
	@override String get chapters => '챕터';
	@override String get noChaptersAvailable => '사용 가능한 챕터가 없습니다';
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
	@override String get removedFromContinueWatching => '계속 시청 목록에서 제거됨';
	@override String errorLoading({required Object error}) => '오류: ${error}';
	@override String get fileInfoNotAvailable => '파일 정보가 없습니다';
	@override String errorLoadingFileInfo({required Object error}) => '파일 정보 로딩 중 오류: ${error}';
	@override String get errorLoadingSeries => '시리즈 로딩 중 오류';
	@override String get errorLoadingSeason => '시즌 로딩 중 오류';
	@override String get musicNotSupported => '음악 재생 미지원';
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
	@override String get logsUploaded => 'Logs uploaded';
	@override String get logsUploadFailed => 'Failed to upload logs';
	@override String get logId => 'Log ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingKo implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => '스타일 옵션';
	@override String get fontSize => '글자 크기';
	@override String get textColor => '텍스트 색상';
	@override String get borderSize => '테두리 크기';
	@override String get borderColor => '테두리 색상';
	@override String get backgroundOpacity => '배경 불투명도';
	@override String get backgroundColor => '배경색';
	@override String get position => 'Position';
}

// Path: mpvConfig
class _TranslationsMpvConfigKo implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV 설정';
	@override String get description => '고급 비디오 플레이어 설정';
	@override String get properties => '속성';
	@override String get presets => '사전 설정';
	@override String get noProperties => '설정된 속성이 없습니다';
	@override String get noPresets => '저장된 사전 설정이 없습니다';
	@override String get addProperty => '속성 추가';
	@override String get editProperty => '속성 편집';
	@override String get deleteProperty => '속성 삭제';
	@override String get propertyKey => '속성 키';
	@override String get propertyKeyHint => '예: hwdec, demuxer-max-bytes';
	@override String get propertyValue => '속성값';
	@override String get propertyValueHint => '예: auto, 256000000';
	@override String get saveAsPreset => '프리셋으로 저장...';
	@override String get presetName => '프리셋 이름';
	@override String get presetNameHint => '이 프리셋의 이름을 입력하세요';
	@override String get loadPreset => '로드';
	@override String get deletePreset => '삭제';
	@override String get presetSaved => '프리셋이 저장 되었습니다';
	@override String get presetLoaded => '프리셋이 로드 되었습니다';
	@override String get presetDeleted => '프리셋이 삭제 되었습니다';
	@override String get confirmDeletePreset => '이 프리셋을 삭제 하시겠습니까?';
	@override String get confirmDeleteProperty => '이 속성을 삭제 하시겠습니까?';
	@override String entriesCount({required Object count}) => '${count} 항목';
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
	@override String get seasons => '시즌 수';
	@override String get studio => '제작사';
	@override String get rating => '연령 등급';
	@override String episodeCount({required Object count}) => '${count} 편';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} 편 시청 완료';
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
	@override String get uploadLogs => 'Upload Logs';
	@override String get error => '오류:';
	@override String get stackTrace => '스택 추적 (Stack Trace):';
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
	@override String get channels => '채널';
	@override String get guide => '편성표';
	@override String get recordings => '녹화';
	@override String get subscriptions => '녹화 규칙';
	@override String get scheduled => '예약됨';
	@override String get noChannels => '사용 가능한 채널이 없습니다';
	@override String get noDvr => '서버에 DVR이 구성되어 있지 않습니다';
	@override String get tuneFailed => '채널 튜닝에 실패했습니다';
	@override String get loading => '채널 로딩 중...';
	@override String get nowPlaying => '현재 재생 중';
	@override String get record => '녹화';
	@override String get recordSeries => '시리즈 녹화';
	@override String get cancelRecording => '녹화 취소';
	@override String get deleteSubscription => '녹화 규칙 삭제';
	@override String get deleteSubscriptionConfirm => '이 녹화 규칙을 삭제하시겠습니까?';
	@override String get subscriptionDeleted => '녹화 규칙이 삭제되었습니다';
	@override String get noPrograms => '프로그램 데이터가 없습니다';
	@override String get noRecordings => '예약된 녹화가 없습니다';
	@override String get noSubscriptions => '녹화 규칙이 없습니다';
	@override String channelNumber({required Object number}) => '채널 ${number}';
	@override String get live => '실시간';
	@override String get hd => 'HD';
	@override String get premiere => '신규';
	@override String get reloadGuide => '편성표 새로고침';
	@override String get guideReloaded => '편성표 데이터가 새로고침되었습니다';
	@override String get allChannels => '전체 채널';
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
	@override String get createNewCollection => '새 컬렉션 생성';
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
	@override String get createNewPlaylist => '새 재생 목록 생성';
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
	@override String get enterCodeHint => '8자리 코드 입력';
	@override String get pasteFromClipboard => '클립보드에서 붙여넣기';
	@override String get pleaseEnterCode => '세션 코드를 입력하세요';
	@override String get codeMustBe8Chars => '세션 코드는 반드시 8자리여야 합니다';
	@override String get joinInstructions => '호스트가 공유한 세션 코드를 입력하여 시청 세션에 참여하세요.';
	@override String get failedToCreate => '세션 생성 실패';
	@override String get failedToJoin => '세션 참여 실패';
	@override String get sessionCodeCopied => '세션 코드가 클립보드에 복사되었습니다';
	@override String get relayUnreachable => '릴레이 서버에 연결할 수 없습니다. 인터넷 제공업체가 연결을 차단하고 있을 수 있습니다. 시도해 볼 수 있지만 함께 보기가 작동하지 않을 수 있습니다.';
	@override String get reconnectingToHost => '호스트에 재연결 중...';
	@override String participantJoined({required Object name}) => '${name}님이 참여했습니다';
	@override String participantLeft({required Object name}) => '${name}님이 나갔습니다';
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
	@override String episodesQueued({required Object count}) => '${count} 에피소드가 다운로드 대기열에 추가 되었습니다';
	@override String get downloadDeleted => '다운로드 삭제됨';
	@override String deleteConfirm({required Object title}) => '"${title}"를 삭제 하시겠습니까? 다운로드한 파일이 기기에서 삭제됩니다.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})';
	@override String get noDownloadsTree => '다운로드 없음';
	@override String get pauseAll => '모두 일시정지';
	@override String get resumeAll => '모두 재개';
	@override String get deleteAll => '모두 삭제';
	@override String get checkForNewEpisodes => 'Check for new episodes';
	@override String get noNewEpisodesFound => 'No new episodes found';
	@override String get downloadSettings => 'Download Settings';
	@override String get episodes => 'Episodes';
	@override String get downloadAllEpisodes => 'Download all episodes';
	@override String keepLastNUnwatched({required Object count}) => 'Keep last ${count} unwatched episodes';
	@override String get retention => 'Retention';
	@override String get retentionDescription => 'How long to keep watched episodes';
	@override String get onNextRefresh => 'On next refresh';
	@override String afterDays({required Object count}) => 'After ${count} days';
	@override String afterWeeks({required Object count}) => 'After ${count} weeks';
	@override String get quality => 'Quality';
	@override String get original => 'Original';
	@override String get settingsSaved => 'Download settings saved';
	@override String get qualityChangeWarning => 'Changing the quality will delete all downloaded episodes and re-download them at the new quality. This may take a while.';
	@override String get transcoding => '트랜스코딩';
	@override String get downloading => '다운로드 중';
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
}

// Path: companionRemote
class _TranslationsCompanionRemoteKo implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion Remote';
	@override String get connectToDevice => '기기에 연결';
	@override String get hostRemoteSession => '원격 세션 호스트';
	@override String get controlThisDevice => '휴대폰으로 이 기기를 제어하세요';
	@override String get remoteControl => '원격 제어';
	@override String get controlDesktop => '데스크톱 기기 제어';
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
	@override String get systemDefault => '시스템 기본값';
	@override String get addCustomPlayer => '사용자 정의 플레이어 추가';
	@override String get playerName => '플레이어 이름';
	@override String get playerCommand => '명령어';
	@override String get playerPackage => '패키지 이름';
	@override String get playerUrlScheme => 'URL 스킴';
	@override String get customPlayer => '사용자 정의 플레이어';
	@override String get off => '꺼짐';
	@override String get launchFailed => '외부 플레이어를 열 수 없습니다';
	@override String appNotInstalled({required Object name}) => '${name}이(가) 설치되어 있지 않습니다';
	@override String get playInExternalPlayer => '외부 플레이어에서 재생';
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
	@override String get permissionDisabled => '화면 속 화면 권한이 비활성화되어 있습니다. 설정 > 앱 > Plezy > 화면 속 화면에서 활성화하세요';
	@override String get notSupported => '이 기기는 화면 속 화면 모드를 지원하지 않습니다';
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
	@override String get creatingSession => '원격 세션 생성 중...';
	@override String get failedToCreate => '원격 세션 생성 실패:';
	@override String get noSession => '사용 가능한 세션이 없습니다';
	@override String get scanQrCode => 'QR 코드 스캔';
	@override String get orEnterManually => '또는 수동으로 입력';
	@override String get hostAddress => '호스트 주소';
	@override String get sessionId => '세션 ID';
	@override String get pin => 'PIN';
	@override String get connected => '연결됨';
	@override String get waitingForConnection => '연결 대기 중...';
	@override String get usePhoneToControl => '모바일 기기로 이 앱을 제어하세요';
	@override String copiedToClipboard({required Object label}) => '${label}이(가) 클립보드에 복사되었습니다';
	@override String get copyToClipboard => '클립보드에 복사';
	@override String get newSession => '새 세션';
	@override String get minimize => '최소화';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingKo implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingKo._(this._root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get recent => '최근';
	@override String get scan => '스캔';
	@override String get manual => '수동';
	@override String get recentConnections => '최근 연결';
	@override String get quickReconnect => '이전에 페어링한 기기에 빠르게 재연결';
	@override String get pairWithDesktop => '데스크톱과 페어링';
	@override String get enterSessionDetails => '데스크톱 기기에 표시된 세션 정보를 입력하세요';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => '8자리 세션 ID 입력';
	@override String get pinHint => '6자리 PIN 입력';
	@override String get connecting => '연결 중...';
	@override String get tips => '팁';
	@override String get tipDesktop => '데스크톱에서 Plezy를 열고 설정 또는 메뉴에서 Companion Remote를 활성화하세요';
	@override String get tipScan => '스캔 탭을 사용하여 데스크톱의 QR 코드를 스캔하면 빠르게 페어링할 수 있습니다';
	@override String get tipWifi => '두 기기가 동일한 WiFi 네트워크에 연결되어 있는지 확인하세요';
	@override String get cameraPermissionRequired => 'QR 코드를 스캔하려면 카메라 권한이 필요합니다.\n기기 설정에서 카메라 접근을 허용해 주세요.';
	@override String cameraError({required Object error}) => '카메라를 시작할 수 없습니다: ${error}';
	@override String get scanInstruction => '데스크톱에 표시된 QR 코드에 카메라를 향하세요';
	@override String get noRecentConnections => '최근 연결 없음';
	@override String get connectUsingManual => '수동 입력으로 기기에 연결하여 시작하세요';
	@override String get invalidQrCode => '유효하지 않은 QR 코드 형식';
	@override String get removeRecentConnection => '최근 연결 삭제';
	@override String removeConfirm({required Object name}) => '"${name}"을(를) 최근 연결에서 삭제하시겠습니까?';
	@override String get validationHostRequired => '호스트 주소를 입력하세요';
	@override String get validationHostFormat => 'IP:포트 형식이어야 합니다 (예: 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => '세션 ID를 입력하세요';
	@override String get validationSessionIdLength => '세션 ID는 8자리여야 합니다';
	@override String get validationPinRequired => 'PIN을 입력하세요';
	@override String get validationPinLength => 'PIN은 6자리여야 합니다';
	@override String get connectionTimedOut => '연결 시간이 초과되었습니다. 세션 ID와 PIN을 확인하세요.';
	@override String get sessionNotFound => '세션을 찾을 수 없습니다. 자격 증명을 확인하세요.';
	@override String failedToConnect({required Object error}) => '연결 실패: ${error}';
	@override String failedToLoadRecent({required Object error}) => '최근 세션 로드 실패: ${error}';
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
	@override String get connectionError => '연결 오류';
	@override String get notConnected => '연결되지 않음';
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
			'auth.debugEnterToken' => '디버깅을 위해 Plex 토큰을 입력하세요.',
			'auth.plexTokenLabel' => 'Plex 인증 토큰',
			'auth.plexTokenHint' => 'Plex.tv 토큰을 입력하세요',
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
			'common.remove' => '삭제',
			'common.paste' => '붙여넣기',
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
			'common.loading' => '로딩 중...',
			'common.reconnect' => '다시 연결',
			'common.exitConfirmTitle' => '앱을 종료하시겠습니까?',
			'common.exitConfirmMessage' => '정말 종료하시겠습니까?',
			'common.dontAskAgain' => '다시 묻지 않기',
			'common.exit' => '종료',
			'screens.licenses' => '라이선스',
			'screens.switchProfile' => '프로필 전환',
			'screens.subtitleStyling' => '자막 스타일 설정',
			'screens.mpvConfig' => 'MPV 설정',
			'screens.logs' => '로그',
			'update.available' => '사용 가능한 업데이트',
			'update.versionAvailable' => ({required Object version}) => '버전 ${version} 출시됨',
			'update.currentVersion' => ({required Object version}) => '현재 버전: ${version}',
			'update.skipVersion' => '이 버전 건너뛰기',
			'update.viewRelease' => '릴리스 정보 보기',
			'update.latestVersion' => '최신 버전을 사용 중입니다',
			'update.checkFailed' => '업데이트 확인 실패',
			'settings.title' => '설정',
			'settings.language' => '언어',
			'settings.theme' => '테마',
			'settings.appearance' => '외관',
			'settings.videoPlayback' => '비디오 재생',
			'settings.advanced' => '고급',
			'settings.episodePosterMode' => '에피소드 포스터 스타일',
			'settings.seriesPoster' => '시리즈 포스터',
			'settings.seriesPosterDescription' => '모든 에피소드에 시리즈 포스터 표시',
			'settings.seasonPoster' => '시즌 포스터',
			'settings.seasonPosterDescription' => '에피소드에 시즌별 포스터 표시',
			'settings.episodeThumbnail' => '에피소드 썸네일',
			'settings.episodeThumbnailDescription' => '16:9 에피소드 스크린샷 썸네일 표시',
			'settings.showHeroSectionDescription' => '홈 화면에 주요 콘텐츠 캐러셀(슬라이드) 표시',
			'settings.secondsLabel' => '초',
			'settings.minutesLabel' => '분',
			'settings.secondsShort' => '초',
			'settings.minutesShort' => '분',
			'settings.durationHint' => ({required Object min, required Object max}) => '기간 입력 (${min}-${max})',
			'settings.systemTheme' => '시스템 설정',
			'settings.systemThemeDescription' => '시스템 설정에 따름',
			'settings.lightTheme' => '라이트 모드',
			'settings.darkTheme' => '다크 모드',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'OLED 화면을 위한 순수 검정',
			'settings.libraryDensity' => '라이브러리 표시 밀도',
			'settings.compact' => '좁게',
			'settings.compactDescription' => '카드를 작게 표시하여 더 많은 항목을 보여줍니다.',
			'settings.normal' => '보통',
			'settings.normalDescription' => '기본 크기',
			'settings.comfortable' => '넓게',
			'settings.comfortableDescription' => '카드를 크게 표시하여 더 적은 항목을 보여줍니다.',
			'settings.viewMode' => '보기 모드',
			'settings.gridView' => '그리드 보기',
			'settings.gridViewDescription' => '항목을 그리드 레이아웃으로 표시합니다',
			'settings.listView' => '목록 보기',
			'settings.listViewDescription' => '항목을 목록 레이아웃으로 표시합니다',
			'settings.showHeroSection' => '주요 추천 영역 표시',
			'settings.useGlobalHubs' => 'Plex 홈 레이아웃 사용',
			'settings.useGlobalHubsDescription' => '공식 Plex 클라이언트처럼 홈 페이지 허브를 표시합니다. 끄면 라이브러리별 추천이 대신 표시됩니다.',
			'settings.showServerNameOnHubs' => '허브에 서버 이름 표시',
			'settings.showServerNameOnHubsDescription' => '허브 제목에 항상 서버 이름을 표시합니다. 끄면 중복된 허브 이름에만 표시됩니다.',
			'settings.alwaysKeepSidebarOpen' => '사이드바 항상 열어두기',
			'settings.alwaysKeepSidebarOpenDescription' => '사이드바가 확장된 상태로 유지되고 콘텐츠 영역이 맞춰집니다',
			'settings.showUnwatchedCount' => '미시청 수 표시',
			'settings.showUnwatchedCountDescription' => '시리즈 및 시즌에 미시청 에피소드 수 표시',
			'settings.playerBackend' => '플레이어 백엔드',
			'settings.exoPlayer' => 'ExoPlayer (권장)',
			'settings.exoPlayerDescription' => '더 나은 하드웨어 지원을 제공하는 Android 네이티브 플레이어',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => '더 많은 기능과 ASS 자막을 지원하는 고급 플레이어',
			'settings.hardwareDecoding' => '하드웨어 디코딩',
			'settings.hardwareDecodingDescription' => '가능한 경우 하드웨어 가속을 사용합니다',
			'settings.bufferSize' => '버퍼 크기',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => '자막 스타일',
			'settings.subtitleStylingDescription' => '자막의 외형을 사용자 설정',
			'settings.smallSkipDuration' => '짧은 건너뛰기 시간',
			'settings.largeSkipDuration' => '긴 건너뛰기 시간',
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
			'settings.shortcutsReset' => '단축키가 기본값으로 재설정되었습니다',
			'settings.about' => '정보',
			'settings.aboutDescription' => '응용 프로그램 정보 및 라이선스',
			'settings.updates' => '업데이트',
			'settings.updateAvailable' => '사용 가능한 업데이트 있음',
			'settings.checkForUpdates' => '업데이트 확인',
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
			'settings.cellularDownloadBlocked' => '셀룰러 데이터에서 다운로드가 차단 되었습니다. WiFi에 연결하거나 설정을 변경하세요.',
			'settings.maxVolume' => '최대 볼륨',
			'settings.maxVolumeDescription' => '조용한 미디어를 위해 100% 이상의 볼륨 허용',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord에서 시청 중인 콘텐츠 표시',
			'settings.matchContentFrameRate' => '콘텐츠 프레임 레이트 맞춤',
			'settings.matchContentFrameRateDescription' => '비디오 콘텐츠에 맞게 디스플레이 주사율을 조정하여 떨림을 줄이고 배터리를 절약합니다',
			'settings.requireProfileSelectionOnOpen' => '앱 실행 시 프로필 선택',
			'settings.requireProfileSelectionOnOpenDescription' => '앱을 열 때마다 프로필 선택 화면을 표시합니다',
			'settings.confirmExitOnBack' => '종료 전 확인',
			'settings.confirmExitOnBackDescription' => '뒤로 버튼을 눌러 앱을 종료할 때 확인 대화상자를 표시합니다',
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
			'hotkeys.actions.speedIncrease' => '속도 높이기',
			'hotkeys.actions.speedDecrease' => '속도 낮추기',
			'hotkeys.actions.speedReset' => '속도 초기화',
			'hotkeys.actions.subSeekNext' => '다음 자막으로 이동',
			'hotkeys.actions.subSeekPrev' => '이전 자막으로 이동',
			'hotkeys.actions.shaderToggle' => '셰이더 전환',
			'hotkeys.actions.skipMarker' => '인트로/크레딧 건너뛰기',
			'pinEntry.enterPin' => 'PIN 입력',
			'pinEntry.showPin' => 'PIN 표시',
			'pinEntry.hidePin' => 'PIN 숨기기',
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
			'mediaMenu.confirmDelete' => '파일 시스템에서 이 항목을 삭제하시겠습니까?',
			'mediaMenu.deleteMultipleWarning' => '여러 항목이 삭제될 수 있습니다.',
			'mediaMenu.mediaDeletedSuccessfully' => '미디어 항목이 성공적으로 삭제되었습니다',
			'mediaMenu.mediaFailedToDelete' => '미디어 항목 삭제 실패',
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
			'videoControls.sleepTimerCompleted' => '수면 타이머 완료됨 - 재생이 일시 중지되었습니다',
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
			'videoControls.audioTrackButton' => '음원 트랙',
			'videoControls.subtitlesButton' => '자막',
			'videoControls.chaptersButton' => '챕터',
			'videoControls.versionsButton' => '동영상 버전',
			'videoControls.pipButton' => '픽처 인 픽처 모드',
			'videoControls.aspectRatioButton' => '화면비율',
			'videoControls.fullscreenButton' => '전체화면',
			'videoControls.exitFullscreenButton' => '전체화면 종료',
			'videoControls.alwaysOnTopButton' => '창 최상위 고정',
			'videoControls.rotationLockButton' => '회전 잠금',
			'videoControls.timelineSlider' => '타임라인',
			'videoControls.volumeSlider' => '볼륨 조절',
			'videoControls.endsAt' => ({required Object time}) => '${time}에 종료',
			'videoControls.pipFailed' => '화면 속 화면 모드를 시작할 수 없습니다',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 이상이 필요합니다',
			'videoControls.pipErrors.permissionDisabled' => '화면 속 화면 권한이 비활성화되어 있습니다. 설정 > 앱 > Plezy > 화면 속 화면에서 활성화하세요',
			'videoControls.pipErrors.notSupported' => '이 기기는 화면 속 화면 모드를 지원하지 않습니다',
			'videoControls.pipErrors.failed' => '화면 속 화면 모드를 시작할 수 없습니다',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '오류가 발생했습니다: ${error}',
			'videoControls.chapters' => '챕터',
			'videoControls.noChaptersAvailable' => '사용 가능한 챕터가 없습니다',
			'userStatus.admin' => '관리자',
			'userStatus.restricted' => '제한됨',
			'userStatus.protected' => '보호됨',
			'userStatus.current' => '현재',
			'messages.markedAsWatched' => '시청 완료로 표시됨',
			'messages.markedAsUnwatched' => '시청 안 함으로 표시됨',
			'messages.markedAsWatchedOffline' => '시청 완료로 표시됨 (연결 시 동기화됨)',
			'messages.markedAsUnwatchedOffline' => '미시청으로 표시됨 (연결 시 동기화됨)',
			'messages.removedFromContinueWatching' => '계속 시청 목록에서 제거됨',
			'messages.errorLoading' => ({required Object error}) => '오류: ${error}',
			'messages.fileInfoNotAvailable' => '파일 정보가 없습니다',
			'messages.errorLoadingFileInfo' => ({required Object error}) => '파일 정보 로딩 중 오류: ${error}',
			'messages.errorLoadingSeries' => '시리즈 로딩 중 오류',
			'messages.errorLoadingSeason' => '시즌 로딩 중 오류',
			'messages.musicNotSupported' => '음악 재생 미지원',
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
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => '스타일 옵션',
			'subtitlingStyling.fontSize' => '글자 크기',
			'subtitlingStyling.textColor' => '텍스트 색상',
			'subtitlingStyling.borderSize' => '테두리 크기',
			'subtitlingStyling.borderColor' => '테두리 색상',
			'subtitlingStyling.backgroundOpacity' => '배경 불투명도',
			'subtitlingStyling.backgroundColor' => '배경색',
			'subtitlingStyling.position' => 'Position',
			'mpvConfig.title' => 'MPV 설정',
			'mpvConfig.description' => '고급 비디오 플레이어 설정',
			'mpvConfig.properties' => '속성',
			'mpvConfig.presets' => '사전 설정',
			'mpvConfig.noProperties' => '설정된 속성이 없습니다',
			'mpvConfig.noPresets' => '저장된 사전 설정이 없습니다',
			'mpvConfig.addProperty' => '속성 추가',
			'mpvConfig.editProperty' => '속성 편집',
			'mpvConfig.deleteProperty' => '속성 삭제',
			'mpvConfig.propertyKey' => '속성 키',
			'mpvConfig.propertyKeyHint' => '예: hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => '속성값',
			'mpvConfig.propertyValueHint' => '예: auto, 256000000',
			'mpvConfig.saveAsPreset' => '프리셋으로 저장...',
			'mpvConfig.presetName' => '프리셋 이름',
			'mpvConfig.presetNameHint' => '이 프리셋의 이름을 입력하세요',
			'mpvConfig.loadPreset' => '로드',
			'mpvConfig.deletePreset' => '삭제',
			'mpvConfig.presetSaved' => '프리셋이 저장 되었습니다',
			'mpvConfig.presetLoaded' => '프리셋이 로드 되었습니다',
			'mpvConfig.presetDeleted' => '프리셋이 삭제 되었습니다',
			'mpvConfig.confirmDeletePreset' => '이 프리셋을 삭제 하시겠습니까?',
			'mpvConfig.confirmDeleteProperty' => '이 속성을 삭제 하시겠습니까?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} 항목',
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
			'discover.seasons' => '시즌 수',
			'discover.studio' => '제작사',
			'discover.rating' => '연령 등급',
			'discover.episodeCount' => ({required Object count}) => '${count} 편',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} 편 시청 완료',
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
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => '오류:',
			'logs.stackTrace' => '스택 추적 (Stack Trace):',
			'licenses.relatedPackages' => '관련 소프트웨어 패키지',
			'licenses.license' => '라이선스',
			'licenses.licenseNumber' => ({required Object number}) => '라이선스 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 개의 라이선스',
			'navigation.libraries' => '미디어 라이브러리',
			'navigation.downloads' => '다운로드',
			'navigation.liveTv' => '실시간 TV',
			'liveTv.title' => '실시간 TV',
			'liveTv.channels' => '채널',
			'liveTv.guide' => '편성표',
			'liveTv.recordings' => '녹화',
			'liveTv.subscriptions' => '녹화 규칙',
			'liveTv.scheduled' => '예약됨',
			'liveTv.noChannels' => '사용 가능한 채널이 없습니다',
			'liveTv.noDvr' => '서버에 DVR이 구성되어 있지 않습니다',
			'liveTv.tuneFailed' => '채널 튜닝에 실패했습니다',
			'liveTv.loading' => '채널 로딩 중...',
			'liveTv.nowPlaying' => '현재 재생 중',
			'liveTv.record' => '녹화',
			'liveTv.recordSeries' => '시리즈 녹화',
			'liveTv.cancelRecording' => '녹화 취소',
			'liveTv.deleteSubscription' => '녹화 규칙 삭제',
			'liveTv.deleteSubscriptionConfirm' => '이 녹화 규칙을 삭제하시겠습니까?',
			'liveTv.subscriptionDeleted' => '녹화 규칙이 삭제되었습니다',
			'liveTv.noPrograms' => '프로그램 데이터가 없습니다',
			'liveTv.noRecordings' => '예약된 녹화가 없습니다',
			'liveTv.noSubscriptions' => '녹화 규칙이 없습니다',
			'liveTv.channelNumber' => ({required Object number}) => '채널 ${number}',
			'liveTv.live' => '실시간',
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => '신규',
			'liveTv.reloadGuide' => '편성표 새로고침',
			'liveTv.guideReloaded' => '편성표 데이터가 새로고침되었습니다',
			'liveTv.allChannels' => '전체 채널',
			'liveTv.now' => '지금',
			'liveTv.today' => '오늘',
			'liveTv.midnight' => '자정',
			'liveTv.overnight' => '심야',
			'liveTv.morning' => '아침',
			'liveTv.daytime' => '낮',
			'liveTv.evening' => '저녁',
			'liveTv.lateNight' => '심야 방송',
			'liveTv.whatsOn' => '지금 방송 중',
			_ => null,
		} ?? switch (path) {
			'liveTv.watchChannel' => '채널 시청',
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
			'collections.createNewCollection' => '새 컬렉션 생성',
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
			'playlists.createNewPlaylist' => '새 재생 목록 생성',
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
			'watchTogether.enterCodeHint' => '8자리 코드 입력',
			'watchTogether.pasteFromClipboard' => '클립보드에서 붙여넣기',
			'watchTogether.pleaseEnterCode' => '세션 코드를 입력하세요',
			'watchTogether.codeMustBe8Chars' => '세션 코드는 반드시 8자리여야 합니다',
			'watchTogether.joinInstructions' => '호스트가 공유한 세션 코드를 입력하여 시청 세션에 참여하세요.',
			'watchTogether.failedToCreate' => '세션 생성 실패',
			'watchTogether.failedToJoin' => '세션 참여 실패',
			'watchTogether.sessionCodeCopied' => '세션 코드가 클립보드에 복사되었습니다',
			'watchTogether.relayUnreachable' => '릴레이 서버에 연결할 수 없습니다. 인터넷 제공업체가 연결을 차단하고 있을 수 있습니다. 시도해 볼 수 있지만 함께 보기가 작동하지 않을 수 있습니다.',
			'watchTogether.reconnectingToHost' => '호스트에 재연결 중...',
			'watchTogether.participantJoined' => ({required Object name}) => '${name}님이 참여했습니다',
			'watchTogether.participantLeft' => ({required Object name}) => '${name}님이 나갔습니다',
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} 에피소드가 다운로드 대기열에 추가 되었습니다',
			'downloads.downloadDeleted' => '다운로드 삭제됨',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}"를 삭제 하시겠습니까? 다운로드한 파일이 기기에서 삭제됩니다.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})',
			'downloads.noDownloadsTree' => '다운로드 없음',
			'downloads.pauseAll' => '모두 일시정지',
			'downloads.resumeAll' => '모두 재개',
			'downloads.deleteAll' => '모두 삭제',
			'downloads.checkForNewEpisodes' => 'Check for new episodes',
			'downloads.noNewEpisodesFound' => 'No new episodes found',
			'downloads.downloadSettings' => 'Download Settings',
			'downloads.episodes' => 'Episodes',
			'downloads.downloadAllEpisodes' => 'Download all episodes',
			'downloads.keepLastNUnwatched' => ({required Object count}) => 'Keep last ${count} unwatched episodes',
			'downloads.retention' => 'Retention',
			'downloads.retentionDescription' => 'How long to keep watched episodes',
			'downloads.onNextRefresh' => 'On next refresh',
			'downloads.afterDays' => ({required Object count}) => 'After ${count} days',
			'downloads.afterWeeks' => ({required Object count}) => 'After ${count} weeks',
			'downloads.quality' => 'Quality',
			'downloads.original' => 'Original',
			'downloads.settingsSaved' => 'Download settings saved',
			'downloads.qualityChangeWarning' => 'Changing the quality will delete all downloaded episodes and re-download them at the new quality. This may take a while.',
			'downloads.transcoding' => '트랜스코딩',
			'downloads.downloading' => '다운로드 중',
			'shaders.title' => '셰이더',
			'shaders.noShaderDescription' => '비디오 향상 없음',
			'shaders.nvscalerDescription' => '더 선명한 비디오를 위한 NVIDIA 이미지 스케일링',
			'shaders.qualityFast' => '빠름',
			'shaders.qualityHQ' => '고품질',
			'shaders.mode' => '모드',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectToDevice' => '기기에 연결',
			'companionRemote.hostRemoteSession' => '원격 세션 호스트',
			'companionRemote.controlThisDevice' => '휴대폰으로 이 기기를 제어하세요',
			'companionRemote.remoteControl' => '원격 제어',
			'companionRemote.controlDesktop' => '데스크톱 기기 제어',
			'companionRemote.connectedTo' => ({required Object name}) => '${name}에 연결됨',
			'companionRemote.session.creatingSession' => '원격 세션 생성 중...',
			'companionRemote.session.failedToCreate' => '원격 세션 생성 실패:',
			'companionRemote.session.noSession' => '사용 가능한 세션이 없습니다',
			'companionRemote.session.scanQrCode' => 'QR 코드 스캔',
			'companionRemote.session.orEnterManually' => '또는 수동으로 입력',
			'companionRemote.session.hostAddress' => '호스트 주소',
			'companionRemote.session.sessionId' => '세션 ID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => '연결됨',
			'companionRemote.session.waitingForConnection' => '연결 대기 중...',
			'companionRemote.session.usePhoneToControl' => '모바일 기기로 이 앱을 제어하세요',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label}이(가) 클립보드에 복사되었습니다',
			'companionRemote.session.copyToClipboard' => '클립보드에 복사',
			'companionRemote.session.newSession' => '새 세션',
			'companionRemote.session.minimize' => '최소화',
			'companionRemote.pairing.recent' => '최근',
			'companionRemote.pairing.scan' => '스캔',
			'companionRemote.pairing.manual' => '수동',
			'companionRemote.pairing.recentConnections' => '최근 연결',
			'companionRemote.pairing.quickReconnect' => '이전에 페어링한 기기에 빠르게 재연결',
			'companionRemote.pairing.pairWithDesktop' => '데스크톱과 페어링',
			'companionRemote.pairing.enterSessionDetails' => '데스크톱 기기에 표시된 세션 정보를 입력하세요',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => '8자리 세션 ID 입력',
			'companionRemote.pairing.pinHint' => '6자리 PIN 입력',
			'companionRemote.pairing.connecting' => '연결 중...',
			'companionRemote.pairing.tips' => '팁',
			'companionRemote.pairing.tipDesktop' => '데스크톱에서 Plezy를 열고 설정 또는 메뉴에서 Companion Remote를 활성화하세요',
			'companionRemote.pairing.tipScan' => '스캔 탭을 사용하여 데스크톱의 QR 코드를 스캔하면 빠르게 페어링할 수 있습니다',
			'companionRemote.pairing.tipWifi' => '두 기기가 동일한 WiFi 네트워크에 연결되어 있는지 확인하세요',
			'companionRemote.pairing.cameraPermissionRequired' => 'QR 코드를 스캔하려면 카메라 권한이 필요합니다.\n기기 설정에서 카메라 접근을 허용해 주세요.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => '카메라를 시작할 수 없습니다: ${error}',
			'companionRemote.pairing.scanInstruction' => '데스크톱에 표시된 QR 코드에 카메라를 향하세요',
			'companionRemote.pairing.noRecentConnections' => '최근 연결 없음',
			'companionRemote.pairing.connectUsingManual' => '수동 입력으로 기기에 연결하여 시작하세요',
			'companionRemote.pairing.invalidQrCode' => '유효하지 않은 QR 코드 형식',
			'companionRemote.pairing.removeRecentConnection' => '최근 연결 삭제',
			'companionRemote.pairing.removeConfirm' => ({required Object name}) => '"${name}"을(를) 최근 연결에서 삭제하시겠습니까?',
			'companionRemote.pairing.validationHostRequired' => '호스트 주소를 입력하세요',
			'companionRemote.pairing.validationHostFormat' => 'IP:포트 형식이어야 합니다 (예: 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => '세션 ID를 입력하세요',
			'companionRemote.pairing.validationSessionIdLength' => '세션 ID는 8자리여야 합니다',
			'companionRemote.pairing.validationPinRequired' => 'PIN을 입력하세요',
			'companionRemote.pairing.validationPinLength' => 'PIN은 6자리여야 합니다',
			'companionRemote.pairing.connectionTimedOut' => '연결 시간이 초과되었습니다. 세션 ID와 PIN을 확인하세요.',
			'companionRemote.pairing.sessionNotFound' => '세션을 찾을 수 없습니다. 자격 증명을 확인하세요.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '연결 실패: ${error}',
			'companionRemote.pairing.failedToLoadRecent' => ({required Object error}) => '최근 세션 로드 실패: ${error}',
			'companionRemote.remote.disconnectConfirm' => '원격 세션 연결을 해제하시겠습니까?',
			'companionRemote.remote.reconnecting' => '재연결 중...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '${current}/5 시도 중',
			'companionRemote.remote.retryNow' => '지금 재시도',
			'companionRemote.remote.connectionError' => '연결 오류',
			'companionRemote.remote.notConnected' => '연결되지 않음',
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
			'externalPlayer.title' => '외부 플레이어',
			'externalPlayer.useExternalPlayer' => '외부 플레이어 사용',
			'externalPlayer.useExternalPlayerDescription' => '내장 플레이어 대신 외부 앱에서 동영상 열기',
			'externalPlayer.selectPlayer' => '플레이어 선택',
			'externalPlayer.systemDefault' => '시스템 기본값',
			'externalPlayer.addCustomPlayer' => '사용자 정의 플레이어 추가',
			'externalPlayer.playerName' => '플레이어 이름',
			'externalPlayer.playerCommand' => '명령어',
			'externalPlayer.playerPackage' => '패키지 이름',
			'externalPlayer.playerUrlScheme' => 'URL 스킴',
			'externalPlayer.customPlayer' => '사용자 정의 플레이어',
			'externalPlayer.off' => '꺼짐',
			'externalPlayer.launchFailed' => '외부 플레이어를 열 수 없습니다',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name}이(가) 설치되어 있지 않습니다',
			'externalPlayer.playInExternalPlayer' => '외부 플레이어에서 재생',
			_ => null,
		};
	}
}
