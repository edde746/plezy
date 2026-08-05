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
class TranslationsTr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsTr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.tr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <tr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsTr _root = this; // ignore: unused_field

	@override 
	TranslationsTr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsTr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$tr app = _Translations$app$tr._(_root);
	@override late final _Translations$auth$tr auth = _Translations$auth$tr._(_root);
	@override late final _Translations$common$tr common = _Translations$common$tr._(_root);
	@override late final _Translations$screens$tr screens = _Translations$screens$tr._(_root);
	@override late final _Translations$update$tr update = _Translations$update$tr._(_root);
	@override late final _Translations$settings$tr settings = _Translations$settings$tr._(_root);
	@override late final _Translations$search$tr search = _Translations$search$tr._(_root);
	@override late final _Translations$hotkeys$tr hotkeys = _Translations$hotkeys$tr._(_root);
	@override late final _Translations$fileInfo$tr fileInfo = _Translations$fileInfo$tr._(_root);
	@override late final _Translations$mediaMenu$tr mediaMenu = _Translations$mediaMenu$tr._(_root);
	@override late final _Translations$rateSheet$tr rateSheet = _Translations$rateSheet$tr._(_root);
	@override late final _Translations$accessibility$tr accessibility = _Translations$accessibility$tr._(_root);
	@override late final _Translations$tooltips$tr tooltips = _Translations$tooltips$tr._(_root);
	@override late final _Translations$audioTracks$tr audioTracks = _Translations$audioTracks$tr._(_root);
	@override late final _Translations$videoControls$tr videoControls = _Translations$videoControls$tr._(_root);
	@override late final _Translations$messages$tr messages = _Translations$messages$tr._(_root);
	@override late final _Translations$subtitlingStyling$tr subtitlingStyling = _Translations$subtitlingStyling$tr._(_root);
	@override late final _Translations$mpvConfig$tr mpvConfig = _Translations$mpvConfig$tr._(_root);
	@override late final _Translations$dialog$tr dialog = _Translations$dialog$tr._(_root);
	@override late final _Translations$profiles$tr profiles = _Translations$profiles$tr._(_root);
	@override late final _Translations$connections$tr connections = _Translations$connections$tr._(_root);
	@override late final _Translations$discover$tr discover = _Translations$discover$tr._(_root);
	@override late final _Translations$errors$tr errors = _Translations$errors$tr._(_root);
	@override late final _Translations$libraries$tr libraries = _Translations$libraries$tr._(_root);
	@override late final _Translations$about$tr about = _Translations$about$tr._(_root);
	@override late final _Translations$serverSelection$tr serverSelection = _Translations$serverSelection$tr._(_root);
	@override late final _Translations$hubDetail$tr hubDetail = _Translations$hubDetail$tr._(_root);
	@override late final _Translations$logs$tr logs = _Translations$logs$tr._(_root);
	@override late final _Translations$licenses$tr licenses = _Translations$licenses$tr._(_root);
	@override late final _Translations$navigation$tr navigation = _Translations$navigation$tr._(_root);
	@override late final _Translations$explore$tr explore = _Translations$explore$tr._(_root);
	@override late final _Translations$liveTv$tr liveTv = _Translations$liveTv$tr._(_root);
	@override late final _Translations$collections$tr collections = _Translations$collections$tr._(_root);
	@override late final _Translations$playlists$tr playlists = _Translations$playlists$tr._(_root);
	@override late final _Translations$music$tr music = _Translations$music$tr._(_root);
	@override late final _Translations$watchTogether$tr watchTogether = _Translations$watchTogether$tr._(_root);
	@override late final _Translations$downloads$tr downloads = _Translations$downloads$tr._(_root);
	@override late final _Translations$shaders$tr shaders = _Translations$shaders$tr._(_root);
	@override late final _Translations$companionRemote$tr companionRemote = _Translations$companionRemote$tr._(_root);
	@override late final _Translations$videoSettings$tr videoSettings = _Translations$videoSettings$tr._(_root);
	@override late final _Translations$performanceOverlay$tr performanceOverlay = _Translations$performanceOverlay$tr._(_root);
	@override late final _Translations$externalPlayer$tr externalPlayer = _Translations$externalPlayer$tr._(_root);
	@override late final _Translations$metadataEdit$tr metadataEdit = _Translations$metadataEdit$tr._(_root);
	@override late final _Translations$matchScreen$tr matchScreen = _Translations$matchScreen$tr._(_root);
	@override late final _Translations$serverTasks$tr serverTasks = _Translations$serverTasks$tr._(_root);
	@override late final _Translations$trakt$tr trakt = _Translations$trakt$tr._(_root);
	@override late final _Translations$seerr$tr seerr = _Translations$seerr$tr._(_root);
	@override late final _Translations$services$tr services = _Translations$services$tr._(_root);
	@override late final _Translations$addServer$tr addServer = _Translations$addServer$tr._(_root);
}

// Path: app
class _Translations$app$tr extends Translations$app$en {
	_Translations$app$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$tr extends Translations$auth$en {
	_Translations$auth$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex ile Giriş Yap';
	@override String get showQRCode => 'QR Kodunu Göster';
	@override String get authenticate => 'Doğrula';
	@override String get authenticationTimeout => 'Doğrulama zaman aşımına uğradı. Lütfen tekrar deneyin.';
	@override String get scanQRToSignIn => 'Giriş yapmak için bu QR kodunu tarayın';
	@override String get waitingForAuth => 'Doğrulama bekleniyor...\nTarayıcınızdan giriş yapın.';
	@override String get useBrowser => 'Tarayıcı kullan';
	@override String get or => 'veya';
	@override String get useQuickConnect => 'Hızlı Bağlantıyı Kullan';
	@override String get quickConnectInstructions => 'Jellyfin\'de Hızlı Bağlantı\'yı açın ve bu kodu girin.';
	@override String get quickConnectWaiting => 'Onay bekleniyor…';
	@override String get quickConnectCancel => 'İptal';
	@override String get quickConnectExpired => 'Hızlı Bağlantı süresi doldu. Tekrar deneyin.';
	@override String get localDataRecoveryRequired => 'Plezy yerel giriş ve bekleyen oynatma verilerini güvenli bir şekilde kurtaramadı. Lütfen tekrar giriş yapın.';
}

// Path: common
class _Translations$common$tr extends Translations$common$en {
	_Translations$common$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'İptal';
	@override String get save => 'Kaydet';
	@override String get close => 'Kapat';
	@override String get clear => 'Temizle';
	@override String get reset => 'Sıfırla';
	@override String get later => 'Daha Sonra';
	@override String get submit => 'Gönder';
	@override String get confirm => 'Onayla';
	@override String get retry => 'Tekrar Dene';
	@override String get logout => 'Çıkış Yap';
	@override String get unknown => 'Bilinmiyor';
	@override String get refresh => 'Yenile';
	@override String get yes => 'Evet';
	@override String get no => 'Hayır';
	@override String get delete => 'Sil';
	@override String get edit => 'Düzenle';
	@override String get shuffle => 'Karıştır';
	@override String get addTo => 'Ekle...';
	@override String get createNew => 'Yeni Oluştur';
	@override String get connect => 'Bağlan';
	@override String get disconnect => 'Bağlantıyı Kes';
	@override String get play => 'Oynat';
	@override String get pause => 'Duraklat';
	@override String get resume => 'Devam Et';
	@override String get error => 'Hata';
	@override String get search => 'Ara';
	@override String get home => 'Ana Sayfa';
	@override String get back => 'Geri';
	@override String get settings => 'Ayarlar';
	@override String get mute => 'Sesi Kapat';
	@override String get ok => 'Tamam';
	@override String get off => 'Kapalı';
	@override String seasonNumber({required Object number}) => 'Sezon ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Bölüm ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Kısım ${number}';
	@override String get reconnect => 'Yeniden Bağlan';
	@override String get viewAll => 'Tümünü Gör';
	@override String get checkingNetwork => 'Ağ kontrol ediliyor...';
	@override String get loadingServers => 'Sunucular yükleniyor...';
	@override String get connectingToServers => 'Sunuculara bağlanılıyor...';
	@override String get startingOfflineMode => 'Çevrimdışı mod başlatılıyor...';
	@override String get loading => 'Yükleniyor...';
	@override String get fullscreen => 'Tam Ekran';
	@override String get exitFullscreen => 'Tam Ekrandan Çık';
	@override String get pressBackAgainToExit => 'Çıkmak için tekrar geri tuşuna basın';
}

// Path: screens
class _Translations$screens$tr extends Translations$screens$en {
	_Translations$screens$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lisanslar';
	@override String get switchProfile => 'Profil Değiştir';
	@override String get subtitleStyling => 'Altyazı Biçimlendirmesi';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Günlükler';
}

// Path: update
class _Translations$update$tr extends Translations$update$en {
	_Translations$update$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get available => 'Güncelleme Mevcut';
	@override String versionAvailable({required Object version}) => 'Sürüm ${version} kullanılabilir';
	@override String currentVersion({required Object version}) => 'Mevcut: ${version}';
	@override String get skipVersion => 'Bu Sürümü Atla';
	@override String get viewRelease => 'Sürümü Görüntüle';
	@override String get latestVersion => 'En son sürümü kullanıyorsunuz';
	@override String get checkFailed => 'Güncellemeler kontrol edilemedi';
}

// Path: settings
class _Translations$settings$tr extends Translations$settings$en {
	_Translations$settings$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ayarlar';
	@override String get supportDeveloper => 'Plezy\'yi Destekleyin';
	@override String get supportDeveloperDescription => 'Geliştirmeyi fonlamak için Liberapay üzerinden bağış yapın';
	@override String get language => 'Dil';
	@override String get theme => 'Tema';
	@override String get appearance => 'Görünüm';
	@override String get videoPlayback => 'Video Oynatma';
	@override String get videoPlaybackDescription => 'Oynatma davranışını yapılandırın';
	@override String get advanced => 'Gelişmiş';
	@override String get episodePosterMode => 'Bölüm Afiş Stili';
	@override String get seriesPoster => 'Dizi Afişi';
	@override String get seasonPoster => 'Sezon Afişi';
	@override String get episodeThumbnail => 'Küçük Resim';
	@override String get showHeroSectionDescription => 'Ana ekranda öne çıkan içerik atlıkarıncasını göster';
	@override String get secondsLabel => 'Saniye';
	@override String get minutesLabel => 'Dakika';
	@override String get secondsShort => 'sn';
	@override String get minutesShort => 'dk';
	@override String durationHint({required Object min, required Object max}) => 'Süre girin (${min}-${max})';
	@override String get systemTheme => 'Sistem';
	@override String get lightTheme => 'Açık';
	@override String get darkTheme => 'Koyu';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Kitaplık Yoğunluğu';
	@override String get compact => 'Sıkışık';
	@override String get comfortable => 'Rahat';
	@override String get tvCornerSpotlightBackdrop => 'Köşe Öne Çıkan Arka Plan';
	@override String get tvCornerSpotlightBackdropDescription => 'Arka planı ekranı kaplamak yerine sağ üst köşede göster';
	@override String get viewMode => 'Görünüm Modu';
	@override String get gridView => 'Izgara';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Öne Çıkan Bölümünü Göster';
	@override String get continueWatchingAction => 'İzlemeye Devam Et Eylemi';
	@override String get continueWatchingPlay => 'Oynat';
	@override String get continueWatchingDetails => 'Detayları Aç';
	@override String get episodeAction => 'Bölüm Eylemi';
	@override String get episodePlay => 'Oynat';
	@override String get episodeDetails => 'Detayları Aç';
	@override String get useGlobalHubs => 'Ana Sayfa Düzenini Kullan';
	@override String get useGlobalHubsDescription => 'Birleştirilmiş ana sayfa bölümlerini göster. Aksi takdirde kitaplık önerilerini kullanır.';
	@override String get showServerNameOnHubs => 'Bölümlerde Sunucu Adını Göster';
	@override String get showServerNameOnHubsDescription => 'Bölüm başlıklarında her zaman sunucu adlarını göster.';
	@override String get groupLibrariesByServer => 'Kitaplıkları Sunucuya Göre Grupla';
	@override String get groupLibrariesByServerDescription => 'Yan menü kitaplıklarını her medya sunucusunun altında grupla.';
	@override String get alwaysKeepSidebarOpen => 'Yan Menüyü Her Zaman Açık Tut';
	@override String get alwaysKeepSidebarOpenDescription => 'Yan menü genişletilmiş kalır ve içerik alanı buna göre ayarlanır';
	@override String get showUnwatchedCount => 'İzlenmemiş Sayısını Göster';
	@override String get showUnwatchedCountDescription => 'Dizilerde ve sezonlarda izlenmemiş bölüm sayısını göster';
	@override String get showEpisodeNumberOnCards => 'Kartlarda Bölüm Numarasını Göster';
	@override String get showEpisodeNumberOnCardsDescription => 'Bölüm kartlarında sezon ve bölüm numarasını göster';
	@override String get showSeasonPostersOnTabs => 'Sekmelerde Sezon Afişlerini Göster';
	@override String get showSeasonPostersOnTabsDescription => 'Her sezonun afişini sekmesinin üzerinde göster';
	@override String get tvFullCardLayout => 'Tam TV Kartları';
	@override String get tvFullCardLayoutDescription => 'Oyuncu isimleri üzerinde katmanlanmış yalnızca görsel içeren TV kartları kullan';
	@override String get focusGlow => 'Odak Parıltısı';
	@override String get focusGlowDescription => 'Odaklanılan kartın etrafına hafif bir parıltı çiz';
	@override String get visualEffects => 'Görsel Efektler';
	@override String get visualEffectsAuto => 'Otomatik';
	@override String get visualEffectsAutoDescription => 'Düşük güçlü cihazlarda efektleri otomatik olarak azalt';
	@override String get visualEffectsFull => 'Tam';
	@override String get visualEffectsReduced => 'Azaltılmış';
	@override String get visualEffectsReducedDescription => 'Daha az animasyon ve daha düşük çözünürlüklü görseller';
	@override String get hideSpoilers => 'İzlenmeyen Bölümler İçin Sürpriz Bozanları Gizle';
	@override String get hideSpoilersDescription => 'İzlenmeyen bölümler için küçük resimleri ve açıklamaları bulanıklaştır';
	@override String get playerBackend => 'Oynatıcı Altyapısı';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Donanım Çözme';
	@override String get hardwareDecodingDescription => 'Mümkün olduğunda donanım hızlandırmasını kullan';
	@override String get bufferSize => 'Arabellek Boyutu';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Otomatik (Önerilen)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB bellek mevcut. ${size}MB arabellek oynatmayı etkileyebilir.';
	@override String get defaultQualityTitle => 'Varsayılan Kalite';
	@override String get musicQualityTitle => 'Müzik Kalitesi';
	@override String get subtitleStyling => 'Altyazı Biçimlendirmesi';
	@override String get subtitleStylingDescription => 'Altyazı görünümünü özelleştirin';
	@override String get smallSkipDuration => 'Küçük Atlama Süresi';
	@override String get largeSkipDuration => 'Büyük Atlama Süresi';
	@override String get rewindOnResume => 'Devam Ederken Geri Sar';
	@override String secondsUnit({required Object seconds}) => '${seconds} saniye';
	@override String get defaultSleepTimer => 'Varsayılan Uyku Zamanlayıcısı';
	@override String minutesUnit({required Object minutes}) => '${minutes} dakika';
	@override String get rememberTrackSelections => 'Dizi/film başına ses/altyazı seçimlerini hatırla';
	@override String get rememberTrackSelectionsDescription => 'İçerik başına ses ve altyazı tercihlerini hatırla';
	@override String get followServerTrackSelections => 'Sunucunun bölüm başına parça seçimlerini kullan';
	@override String get followServerTrackSelectionsDescription => 'Bölüm değiştiğinde geçerli seçimi taşımak yerine sunucuda seçilen ses ve altyazıyı uygula';
	@override String get showChapterMarkersOnTimeline => 'Zaman çubuğunda kısım işaretçilerini göster';
	@override String get showChapterMarkersOnTimelineDescription => 'Zaman çubuğunu kısım sınırlarına göre böl';
	@override String get clickVideoTogglesPlayback => 'Oynat/duraklat için videoya tıkla';
	@override String get clickVideoTogglesPlaybackDescription => 'Kontrolleri göstermek yerine oynatmak/duraklatmak için videoya tıkla.';
	@override String get videoPlayerControls => 'Video Oynatıcı Kontrolleri';
	@override String get keyboardShortcuts => 'Klavye Kısayolları';
	@override String get keyboardShortcutsDescription => 'Klavye kısayollarını özelleştirin';
	@override String get videoPlayerNavigation => 'Video Oynatıcı Gezinmesi';
	@override String get videoPlayerNavigationDescription => 'Video oynatıcı kontrollerinde gezinmek için yön tuşlarını kullanın';
	@override String get watchTogetherRelay => 'Birlikte İzle Aktarıcısı (Relay)';
	@override String get watchTogetherRelayDescription => 'Özel bir aktarıcı ayarlayın. Herkes aynı sunucuyu kullanmalıdır.';
	@override String get watchTogetherRelayHint => 'https://ornek-aktarici.com';
	@override String get watchTogetherRelayInvalid => 'Geçerli bir HTTP veya HTTPS aktarıcı adresi girin.';
	@override String get crashReporting => 'Çökme Bildirimi';
	@override String get crashReportingDescription => 'Uygulamanın geliştirilmesine yardımcı olmak için çökme raporları gönder';
	@override String get debugLogging => 'Hata Ayıklama Günlüğü';
	@override String get debugLoggingDescription => 'Sorun giderme için ayrıntılı günlük kaydını etkinleştir';
	@override String get viewLogs => 'Günlükleri Görüntüle';
	@override String get viewLogsDescription => 'Uygulama günlüklerini görüntüle';
	@override String get clearImageCache => 'Görsel Önbelleğini Temizle';
	@override String get clearImageCacheDescription => 'Önbelleğe alınan görselleri ve küçük resimleri temizler. Tekrar indirilene kadar görseller daha yavaş yüklenebilir.';
	@override String get clearImageCacheSuccess => 'Görsel önbelleği başarıyla temizlendi';
	@override String get resetSettings => 'Ayarları Sıfırla';
	@override String get resetSettingsDescription => 'Varsayılan ayarları geri yükler. Bu işlem geri alınamaz.';
	@override String get resetSettingsSuccess => 'Ayarlar başarıyla sıfırlandı';
	@override String get backup => 'Yedekle';
	@override String get exportSettings => 'Ayarları Dışa Aktar';
	@override String get exportSettingsDescription => 'Tercihlerinizi bir dosyaya kaydedin';
	@override String get exportSettingsSuccess => 'Ayarlar dışa aktarıldı';
	@override String get importSettings => 'Ayarları İçe Aktar';
	@override String get importSettingsDescription => 'Tercihleri bir dosyadan geri yükleyin';
	@override String get importSettingsConfirm => 'Bu işlem mevcut ayarlarınızın üzerine yazacak. Devam edilsin mi?';
	@override String get importSettingsSuccess => 'Ayarlar içe aktarıldı';
	@override String get importSettingsInvalidFile => 'Bu dosya geçerli bir Plezy ayar dosyası değil';
	@override String get importSettingsNoUser => 'Ayarları içe aktarmadan önce giriş yapın';
	@override String get shortcutsReset => 'Kısayollar varsayılana sıfırlandı';
	@override String get about => 'Hakkında';
	@override String get aboutDescription => 'Uygulama bilgileri ve lisanslar';
	@override String get updates => 'Güncellemeler';
	@override String get updateAvailable => 'Güncelleme Mevcut';
	@override String get checkForUpdates => 'Güncellemeleri Kontrol Et';
	@override String get autoCheckUpdatesOnStartup => 'Açılışta güncellemeleri otomatik kontrol et';
	@override String get autoCheckUpdatesOnStartupDescription => 'Açılışta bir güncelleme olduğunda bildir';
	@override String get validationErrorEnterNumber => 'Lütfen geçerli bir sayı girin';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Süre ${min} ile ${max} ${unit} arasında olmalıdır';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Kısayol zaten ${action} eylemine atanmış';
	@override String shortcutUpdated({required Object action}) => '${action} için kısayol güncellendi';
	@override String get saveFailed => 'Değişiklikler kaydedilemedi. Tekrar deneyin.';
	@override String get autoSkip => 'Otomatik Atla';
	@override String get autoSkipIntro => 'Jeneriği Otomatik Atla';
	@override String get autoSkipIntroDescription => 'Kaç saniye sonra jenerik işaretçilerini otomatik atla';
	@override String get autoSkipCredits => 'Emeği Geçenleri Otomatik Atla';
	@override String get autoSkipCreditsDescription => 'Emeği geçenleri otomatik atla ve sonraki bölümü oynat';
	@override String get forceSkipMarkerFallback => 'Yedek İşaretçileri Zorla';
	@override String get forceSkipMarkerFallbackDescription => 'Plex işaretçileri olsa bile kısım başlığı kalıplarını kullan';
	@override String get autoSkipDelay => 'Otomatik Atlama Gecikmesi';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Otomatik atlamadan önce ${seconds} saniye bekle';
	@override String get introPattern => 'Jenerik İşaretçi Kalıbı';
	@override String get introPatternDescription => 'Kısım başlıklarındaki jenerik işaretçilerini eşleştirmek için Regex kalıbı';
	@override String get creditsPattern => 'Emeği Geçenler İşaretçi Kalıbı';
	@override String get creditsPatternDescription => 'Kısım başlıklarındaki emeği geçenler işaretçilerini eşleştirmek için Regex kalıbı';
	@override String get invalidRegex => 'Geçersiz düzenli ifade (Regex)';
	@override String get regex => 'Düzenli ifade (Regex)';
	@override String get downloads => 'İndirmeler';
	@override String get downloadLocationDescription => 'İndirilen içeriğin nerede saklanacağını seçin';
	@override String get downloadLocationDefault => 'Varsayılan (Uygulama Depolaması)';
	@override String get downloadLocationCustom => 'Özel Konum';
	@override String get selectFolder => 'Klasör Seç';
	@override String get resetToDefault => 'Varsayılana Sıfırla';
	@override String currentPath({required Object path}) => 'Mevcut: ${path}';
	@override String get downloadLocationChanged => 'İndirme konumu değiştirildi';
	@override String get downloadLocationReset => 'İndirme konumu varsayılana sıfırlandı';
	@override String get downloadLocationInvalid => 'Seçilen klasöre yazılamıyor';
	@override String get downloadLocationPickerUnavailable => 'Klasör seçimi bu cihazda kullanılamıyor';
	@override String get downloadOnWifiOnly => 'Yalnızca Wi-Fi üzerinden indir';
	@override String get downloadOnWifiOnlyDescription => 'Hücresel verideyken indirmeleri engelle';
	@override String get autoRemoveWatchedDownloads => 'İzlenen indirmeleri otomatik kaldır';
	@override String get autoRemoveWatchedDownloadsDescription => 'İzlenen indirmeleri otomatik olarak sil';
	@override String get cellularDownloadBlocked => 'Hücresel veride indirmeler engellendi. Wi-Fi kullanın veya ayarı değiştirin.';
	@override String get maxVolume => 'Maksimum Ses';
	@override String get maxVolumeDescription => 'Kısık sesli medyalar için %100\'ün üzerinde ses yükseltmeye izin ver';
	@override String maxVolumePercent({required Object percent}) => '%${percent}';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord\'da ne izlediğinizi gösterin';
	@override String get services => 'Servisler';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr ve daha fazlasını bağlayın';
	@override String get manageLibrariesDescription => 'Kitaplıkları yeniden sıralayın ve gizleyin';
	@override String get companionRemoteServer => 'Yardımcı Uzaktan Kumanda Sunucusu';
	@override String get companionRemoteServerDescription => 'Ağınızdaki mobil cihazların bu uygulamayı kontrol etmesine izin verin';
	@override String get autoPip => 'Otomatik Pencere İçinde Pencere (PiP)';
	@override String get autoPipDescription => 'Oynatma sırasında uygulamadan çıktığınızda otomatik olarak pencere içinde pencere moduna geç';
	@override String get matchContentFrameRate => 'İçerik Kare Hızını Eşitle';
	@override String get matchContentFrameRateDescription => 'Ekran yenileme hızını video içeriğiyle eşitle';
	@override String get matchRefreshRate => 'Yenileme Hızını Eşitle';
	@override String get matchRefreshRateDescription => 'Tam ekranda ekran yenileme hızını eşitle';
	@override String get matchDynamicRange => 'Dinamik Aralığı Eşitle';
	@override String get matchDynamicRangeDescription => 'HDR içerik için HDR\'yi aç, ardından SDR\'ye geri dön';
	@override String get displaySwitchDelay => 'Ekran Değiştirme Gecikmesi';
	@override String get tunneledPlayback => 'Tünelli Oynatma';
	@override String get tunneledPlaybackDescription => 'Video tünellemeyi kullan. HDR oynatmada siyah ekran görünüyorsa devre dışı bırakın.';
	@override String get audioPassthrough => 'Ses Doğrudan Geçişi (Passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS sesleri yeniden kodlamadan alıcınıza veya TV\'nize göndererek çevreleyen sesi korur. Ses gelmiyorsa kapatın.';
	@override String get audioPassthroughDescriptionAppleTv => 'Atmos dahil Dolby Digital Plus için Apple\'ın yerel Dolby çözücüsünü kullanın. DTS ve TrueHD yine çok kanallı PCM olarak oynatılır. Ses gelmiyorsa kapatın.';
	@override String get audioDownmix => 'Stereo\'ya Dönüştür (Downmix)';
	@override String get audioDownmixDescription => 'Çevreleyen sesi stereo hoparlörler veya kulaklıklar için iki kanala dönüştürür';
	@override String get downmixCenterBoost => 'Merkez Kanal Yükseltme';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Yükseltme (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Dönüştürmede Sesi Normalleştir';
	@override String get audioDownmixNormalizeDescription => 'Ses patlamalarını önlemek için karışımı düşürün. Orijinal sesi korumak için kapatın (yüksek sesli sahnelerde bozulma yapabilir).';
	@override String get atmosDiagnostics => 'Atmos Çıkış Testi';
	@override String get atmosDiagnosticsDescription => 'Sistem oynatıcısı üzerinden test sinyalleri çalarak Dolby Atmos çıkışını teşhis edin';
	@override String get atmosTestHlsAtmos => 'Apple Atmos akışı';
	@override String get atmosTestHlsAtmosDescription => 'Düzgün çalıştığı bilinen Dolby Atmos akışı. Alıcıda Dolby Atmos görünmelidir.';
	@override String get atmosTestHlsControl => 'Apple çevreleyen ses akışı';
	@override String get atmosTestHlsControlDescription => 'Atmos olmayan kontrol akışı. Alıcıda Atmos olmadan çevreleyen ses görünmelidir.';
	@override String get atmosTestRawStream => 'Ham EAC3 akışı';
	@override String get atmosTestRawStreamDescription => 'Test dosyasını aynen oynatıcı içi Atmos oynatımı gibi akış yapar. Test dosyası URL\'si gerektirir.';
	@override String get atmosTestRawFile => 'Ham EAC3 dosyası';
	@override String get atmosTestRawFileDescription => 'Test dosyasını bilinen bir uzunlukta oynatır. Test dosyası URL\'si gerektirir.';
	@override String get atmosTestAsbarNative => 'Örnek arabellek işleyicisi (yerel)';
	@override String get atmosTestAsbarNativeDescription => 'Dosyanın değiştirilmemiş sıkıştırılmış sesini doğrudan sistem işleyicisine iletir. Test dosyası URL\'si gerektirir.';
	@override String get atmosTestAsbarGenerated => 'Örnek arabellek işleyicisi (yeniden oluşturulmuş)';
	@override String get atmosTestAsbarGeneratedDescription => 'Aynısı, ancak ses tanımı oynatmanın oluşturduğu biçimde yeniden oluşturulur. Test dosyası URL\'si gerektirir.';
	@override String get atmosTestSessionMode => 'Film oynatma oturumu modunu kullan';
	@override String get atmosTestSessionModeDescription => 'Kapalı, Dolby\'nin belgelediği modu kullanır. Açık, oynatmanın daha önce kullandığı modu kullanır.';
	@override String get atmosTestShowRoutePicker => 'AirPlay çıkışını seç';
	@override String get atmosTestHideRoutePicker => 'AirPlay çıkış seçicisini gizle';
	@override String get atmosTestRoutePickerDescription => 'Testi bir AirPlay alıcısına gönderir. Çözümlenen ses modunu yalnızca AirPlay bildirir.';
	@override String get atmosTestStop => 'Testi durdur';
	@override String get atmosTestUrl => 'Test dosyası URL\'si';
	@override String get atmosTestUrlDescription => 'Ham bir .ec3 Dolby Atmos dosyasının HTTP URL\'si (ör. ffmpeg ile ayıklanmış)';
	@override String get atmosTestUrlMissing => 'Önce test dosyası URL\'sini ayarlayın';
	@override String get atmosTestStatus => 'Durum';
	@override String get dvConversionMode => 'Dolby Vision Dönüştürme';
	@override String get dvConversionModeDescription => 'ExoPlayer\'ın Dolby Vision Profile 7 dosyalarını nasıl işleyeceğini seçin.';
	@override String get dvConversionAuto => 'Otomatik';
	@override String get dvConversionNative => 'Yerel / Devre Dışı';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Cihaz yeteneği algılamasını ve normal geri çekilme davranışını kullan';
	@override String get dvConversionNativeDescription => 'Yerel DV7\'yi zorla ve DV dönüştürme yeniden denemesini engelle';
	@override String get dvConversionDv81Description => 'Dolby Vision profile 8.1\'e satır içi RPU dönüştürmeyi zorla';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision RPU/EL katmanlarını soy ve düz HEVC olarak sun';
	@override String get requireProfileSelectionOnOpen => 'Uygulama açılışında profil sor';
	@override String get requireProfileSelectionOnOpenDescription => 'Uygulama her açıldığında profil seçimini göster';
	@override String get forceTvMode => 'TV modunu zorla';
	@override String get forceTvModeDescription => 'TV düzenini zorla. Otomatik algılamayan cihazlar içindir. Yeniden başlatma gerektirir.';
	@override String get startInFullscreen => 'Tam ekranda başlat';
	@override String get startInFullscreenDescription => 'Plezy\'yi açılışta tam ekran modunda aç';
	@override String get exitFullscreenOnPlayerClose => 'Oynatıcı kapandığında tam ekrandan çık';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Video oynatıcıyı kapatırken otomatik olarak tam ekrandan çık';
	@override String get autoHidePerformanceOverlay => 'Performans Katmanını Otomatik Gizle';
	@override String get autoHidePerformanceOverlayDescription => 'Performans katmanını oynatma kontrolleriyle birlikte soluklaştır';
	@override String get showNavBarLabels => 'Gezinme Çubuğu Etiketlerini Göster';
	@override String get showNavBarLabelsDescription => 'Gezinme çubuğu simgelerinin altında metin etiketlerini göster';
	@override String get startupSection => 'Başlangıç Bölümü';
	@override String get liveTvDefaultFavorites => 'Canlı TV\'de Favorileri Varsayılan Yap';
	@override String get liveTvDefaultFavoritesDescription => 'Canlı TV açıldığında yalnızca favori kanalları göster';
	@override String get display => 'Ekran';
	@override String get homeScreen => 'Ana Ekran';
	@override String get navigation => 'Gezinme';
	@override String get window => 'Pencere';
	@override String get content => 'İçerik';
	@override String get player => 'Oynatıcı';
	@override String get subtitlesAndConfig => 'Altyazılar ve Yapılandırma';
	@override String get seekAndTiming => 'Sarılma ve Zamanlama';
	@override String get behavior => 'Davranış';
}

// Path: search
class _Translations$search$tr extends Translations$search$en {
	_Translations$search$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Film, dizi, müzik ara...';
	@override String get tryDifferentTerm => 'Farklı bir arama terimi deneyin';
	@override String get searchYourMedia => 'Medyanızda arayın';
	@override String get enterTitleActorOrKeyword => 'Başlık, oyuncu veya anahtar kelime girin';
}

// Path: hotkeys
class _Translations$hotkeys$tr extends Translations$hotkeys$en {
	_Translations$hotkeys$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName} için Kısayol Ayarla';
	@override String get clearShortcut => 'Kısayolu temizle';
	@override String get noShortcutSet => 'Kısayol ayarlanmadı';
	@override String get currentShortcut => 'Mevcut kısayol:';
	@override String get pressToRecord => 'Kısayol kaydetmek için seçin';
	@override String get recordingShortcut => 'Şimdi kısayol tuşuna basın';
	@override late final _Translations$hotkeys$actions$tr actions = _Translations$hotkeys$actions$tr._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$tr extends Translations$fileInfo$en {
	_Translations$fileInfo$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dosya Bilgisi';
	@override String get video => 'Video';
	@override String get audio => 'Ses';
	@override String get subtitles => 'Altyazılar';
	@override String get file => 'Dosya';
	@override String get codec => 'Kodek';
	@override String get resolution => 'Çözünürlük';
	@override String get bitrate => 'Bit Hızı (Bitrate)';
	@override String get frameRate => 'Kare Hızı';
	@override String get aspectRatio => 'En Boy Oranı';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Bit Derinliği';
	@override String get colorSpace => 'Renk Alanı';
	@override String get colorRange => 'Renk Aralığı';
	@override String get colorPrimaries => 'Ana Renkler';
	@override String get chromaSubsampling => 'Renk Alt Örneklemesi';
	@override String get channels => 'Kanallar';
	@override String get overallBitrate => 'Genel Bit Hızı';
	@override String get path => 'Yol';
	@override String get size => 'Boyut';
	@override String get container => 'Kapsayıcı';
	@override String get duration => 'Süre';
	@override String get optimizedForStreaming => 'Akış İçin Optimize Edilmiş';
	@override String get has64bitOffsets => '64-bit Ofsetler';
}

// Path: mediaMenu
class _Translations$mediaMenu$tr extends Translations$mediaMenu$en {
	_Translations$mediaMenu$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'İzlendi Olarak İşaretle';
	@override String get markAsUnwatched => 'İzlenmedi Olarak İşaretle';
	@override String get removeFromContinueWatching => 'İzlemeye Devam Et\'ten Kaldır';
	@override String get viewDetails => 'Detayları görüntüle';
	@override String get goToSeries => 'Diziye git';
	@override String get shufflePlay => 'Karışık Oynat';
	@override String get shuffleNotAvailableOffline => 'Karışık oynatma çevrimdışıyken kullanılamaz';
	@override String get fileInfo => 'Dosya Bilgisi';
	@override String get deleteFromServer => 'Sunucudan sil';
	@override String get confirmDelete => 'Bu medya ve dosyaları sunucunuzdan silinsin mi?';
	@override String get deleteMultipleWarning => 'Bu işlem tüm bölümleri ve dosyalarını içerir.';
	@override String get mediaDeletedSuccessfully => 'Medya ögesi başarıyla silindi';
	@override String get mediaFailedToDelete => 'Medya ögesi silinemedi';
	@override String get rate => 'Oyla';
	@override String get playFromBeginning => 'Baştan Oynat';
	@override String get playVersion => 'Sürümü Oynat...';
}

// Path: rateSheet
class _Translations$rateSheet$tr extends Translations$rateSheet$en {
	_Translations$rateSheet$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oyla';
	@override String get server => 'Sunucu';
	@override String get favorite => 'Favori';
	@override String get favorited => 'Favorilere Eklendi';
	@override String get saved => 'Kaydedildi';
	@override String get notAvailable => 'Eşleşme bulunamadı';
	@override String get noConnectedServices => 'Orada oylamak için Ayarlar\'dan bir servis bağlayın.';
}

// Path: accessibility
class _Translations$accessibility$tr extends Translations$accessibility$en {
	_Translations$accessibility$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV dizisi';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'izlendi';
	@override String mediaCardPartiallyWatched({required Object percent}) => '%${percent} izlendi';
	@override String get mediaCardUnwatched => 'izlenmedi';
	@override String get tapToPlay => 'Oynatmak için dokunun';
	@override String get decrease => 'Azalt';
	@override String get increase => 'Artır';
	@override String decreaseValue({required Object label}) => '${label} değerini azalt';
	@override String increaseValue({required Object label}) => '${label} değerini artır';
	@override String get hue => 'Renk Tonu';
	@override String get saturation => 'Doygunluk';
	@override String get brightness => 'Parlaklık';
	@override String get hexColor => 'Hex rengi';
	@override String get expandText => 'Metni genişlet';
	@override String get collapseText => 'Metni daralt';
	@override String get alphabetNavigation => 'Alfabe gezinmesi';
	@override String get alphabetScrollHint => 'Harfe göre gitmek için yukarı veya aşağı kaydırın';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Satır ${row} / ${rowCount}, sütun ${column} / ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Satır ${row} / ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$tr extends Translations$tooltips$en {
	_Translations$tooltips$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Karışık oynat';
	@override String get playTrailer => 'Fragmanı oynat';
	@override String get markAsWatched => 'İzlendi olarak işaretle';
	@override String get markAsUnwatched => 'İzlenmedi olarak işaretle';
}

// Path: audioTracks
class _Translations$audioTracks$tr extends Translations$audioTracks$en {
	_Translations$audioTracks$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Ses Parçası ${n}';
}

// Path: videoControls
class _Translations$videoControls$tr extends Translations$videoControls$en {
	_Translations$videoControls$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Ses';
	@override String get subtitlesLabel => 'Altyazı';
	@override String get resetToZero => '0ms\'ye Sıfırla';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} daha sonra oynatılır';
	@override String playsEarlier({required Object label}) => '${label} daha önce oynatılır';
	@override String get noOffset => 'Ofset yok';
	@override String get letterbox => 'Geniş Ekran (Letterbox)';
	@override String get fillScreen => 'Ekrana Doldur';
	@override String get stretch => 'Uzat';
	@override String get lockRotation => 'Döndürmeyi kilitle';
	@override String get unlockRotation => 'Döndürme kilidini aç';
	@override String get timerActive => 'Zamanlayıcı Aktif';
	@override String playbackWillPauseIn({required Object duration}) => 'Oynatma ${duration} sonra duraklatılacak';
	@override String get sleepTimerEndOfVideo => 'Mevcut videonun sonu';
	@override String get sleepTimerStopAtHeader => 'Durma zamanı';
	@override String get sleepTimerDurationHeader => 'Zamanlayıcı';
	@override String get playbackWillPauseAtEnd => 'Oynatma bu videonun sonunda duraklatılacak';
	@override String get stillWatching => 'Hâlâ izliyor musunuz?';
	@override String pausingIn({required Object seconds}) => '${seconds}sn içinde duraklatılıyor';
	@override String get continueWatching => 'Devam Et';
	@override String get autoPlayNext => 'Sonrakini Otomatik Oynat';
	@override String get playNext => 'Sonrakini Oynat';
	@override String get playButton => 'Oynat';
	@override String get pauseButton => 'Duraklat';
	@override String get showPlaybackControls => 'Oynatma kontrollerini göster';
	@override String get hidePlaybackControls => 'Oynatma kontrollerini gizle';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} saniye geri sar';
	@override String seekForwardButton({required Object seconds}) => '${seconds} saniye ileri sar';
	@override String get previousButton => 'Önceki bölüm';
	@override String get nextButton => 'Sonraki bölüm';
	@override String get previousChapterButton => 'Önceki kısım';
	@override String get nextChapterButton => 'Sonraki kısım';
	@override String get muteButton => 'Sesi Kıs';
	@override String get unmuteButton => 'Sesi Aç';
	@override String get settingsButton => 'Oynatma Ayarları';
	@override String get tracksButton => 'Ses ve Altyazı';
	@override String get chaptersButton => 'Kısımlar';
	@override String get versionQualityButton => 'Sürüm ve Kalite';
	@override String get versionColumnHeader => 'Sürüm';
	@override String get qualityColumnHeader => 'Kalite';
	@override String get qualityOriginal => 'Orijinal';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Kod dönüştürme kullanılamıyor — orijinal kalitede oynatılıyor';
	@override String get subtitleUnavailableFallback => 'Seçilen altyazı yüklenemedi — altyazısız devam ediliyor';
	@override String get pipButton => 'Pencere İçinde Pencere modu';
	@override String get aspectRatioButton => 'En boy oranı';
	@override String get ambientLighting => 'Ortam aydınlatması';
	@override String get fullscreenButton => 'Tam ekrana geç';
	@override String get exitFullscreenButton => 'Tam ekrandan çık';
	@override String get alwaysOnTopButton => 'Her zaman üstte';
	@override String get rotationLockButton => 'Döndürme kilidi';
	@override String get lockScreen => 'Ekranı kilitle';
	@override String get screenLockButton => 'Ekran kilidi';
	@override String get longPressToUnlock => 'Kilidi açmak için uzun basın';
	@override String get timelineSlider => 'Video zaman çubuğu';
	@override String get volumeSlider => 'Ses seviyesi';
	@override String endsAt({required Object time}) => 'Bitiş saati: ${time}';
	@override String get pipActive => 'Pencere İçinde Pencere modunda oynatılıyor';
	@override String get pipFailed => 'Pencere içinde pencere modu başlatılamadı';
	@override String get screenshotSaved => 'Ekran görüntüsü kaydedildi';
	@override String zoomPercent({required Object percent}) => 'Yakınlaştırma %${percent}';
	@override late final _Translations$videoControls$pipErrors$tr pipErrors = _Translations$videoControls$pipErrors$tr._(_root);
	@override String get chapters => 'Kısımlar';
	@override String get noChaptersAvailable => 'Kısım bulunmuyor';
	@override String get queue => 'Kuyruk';
	@override String get noQueueItems => 'Kuyrukta öge yok';
	@override String get searchSubtitles => 'Altyazı Ara';
	@override String get language => 'Dil';
	@override String get noSubtitlesFound => 'Altyazı bulunamadı';
	@override String get subtitleDownloaded => 'Altyazı indirildi';
	@override String get subtitleDownloadedNotApplied => 'Altyazı indirildi ancak seçilemedi';
	@override String get subtitleDownloadFailed => 'Altyazı indirilemedi';
	@override String get searchLanguages => 'Dillerde ara...';
}

// Path: messages
class _Translations$messages$tr extends Translations$messages$en {
	_Translations$messages$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'İzlendi olarak işaretlendi';
	@override String get markedAsUnwatched => 'İzlenmedi olarak işaretlendi';
	@override String get markedAsWatchedOffline => 'İzlendi olarak işaretlendi (çevrimiçi olunca senkronize edilecek)';
	@override String get markedAsUnwatchedOffline => 'İzlenmedi olarak işaretlendi (çevrimiçi olunca senkronize edilecek)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Otomatik kaldırıldı: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n,
		one: 'İzlenen ${n} indirme otomatik kaldırıldı',
		other: 'İzlenen ${n} indirme otomatik kaldırıldı',
	);
	@override String get removedFromContinueWatching => 'İzlemeye Devam Et\'ten kaldırıldı';
	@override String errorLoading({required Object error}) => 'Hata: ${error}';
	@override String get searchPartialResults => 'Bazı medya sunucularında arama yapılamadı. Kullanılabilir sonuçlar gösteriliyor.';
	@override String get streamInterrupted => 'Akış kesintiye uğradı. Tekrar denemek için oynatın veya sarın.';
	@override String get liveStreamInterrupted => 'Canlı akış kesintiye uğradı. Tekrar denemek için oynatın.';
	@override String get fileInfoNotAvailable => 'Dosya bilgisi mevcut değil';
	@override String get playbackAuthenticationRequired => 'Bu ögeyi oynatmak için medya sunucusuna tekrar giriş yapın.';
	@override String get playbackServerUnavailable => 'Medya sunucusu kullanılabilir değil. Daha sonra tekrar deneyin.';
	@override String get playbackDataInvalid => 'Sunucu geçersiz oynatma bilgisi döndürdü.';
	@override String get playbackCancelled => 'Oynatma iptal edildi.';
	@override String get playbackFailed => 'Oynatma başlatılamadı.';
	@override String errorLoadingFileInfo({required Object error}) => 'Dosya bilgisi yüklenirken hata: ${error}';
	@override String get errorLoadingSeries => 'Dizi yüklenirken hata';
	@override String get musicNotSupported => 'Müzik oynatma henüz desteklenmiyor';
	@override String get noDescriptionAvailable => 'Açıklama mevcut değil';
	@override String get noProfilesAvailable => 'Profil bulunmuyor';
	@override String get contactAdminForProfiles => 'Profil eklemek için sunucu yöneticinizle iletişime geçin';
	@override String get unableToDetermineLibrarySection => 'Bu öge için kitaplık bölümü belirlenemedi';
	@override String get logsCleared => 'Günlükler temizlendi';
	@override String get logsCopied => 'Günlükler panoya kopyalandı';
	@override String get noLogsAvailable => 'Günlük yok';
	@override String libraryScanning({required Object title}) => '"${title}" taranıyor...';
	@override String libraryScanStarted({required Object title}) => '"${title}" için kitaplık taraması başladı';
	@override String libraryScanFailed({required Object error}) => 'Kitaplık taranamadı: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" için meta veriler yenileniyor...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" için meta veri yenilemesi başladı';
	@override String metadataRefreshFailed({required Object error}) => 'Meta veriler yenilenemedi: ${error}';
	@override String get logoutConfirm => 'Çıkış yapmak istediğinizden emin misiniz?';
	@override String get noSeasonsFound => 'Sezon bulunamadı';
	@override String get seasonsLoadFailed => 'Sezonlar yüklenemedi';
	@override String get noEpisodesFound => 'İlk sezonda bölüm bulunamadı';
	@override String get noEpisodesFoundGeneral => 'Bölüm bulunamadı';
	@override String get episodesLoadFailed => 'Bölümler yüklenemedi';
	@override String get noResultsFound => 'Sonuç bulunamadı';
	@override String sleepTimerSet({required Object label}) => 'Uyku zamanlayıcısı ${label} için ayarlandı';
	@override String get noItemsAvailable => 'Öge bulunmuyor';
	@override String get failedToCreatePlayQueueNoItems => 'Oynatma kuyruğu oluşturulamadı — öge yok';
	@override String failedPlayback({required Object action, required Object error}) => '${action} başarısız oldu: ${error}';
	@override String get switchingToCompatiblePlayer => 'Uyumlu oynatıcıya geçiliyor...';
	@override String get serverLimitTitle => 'Oynatma başarısız oldu';
	@override String get serverLimitBody => 'Sunucu hatası (HTTP 500). Muhtemelen bir bant genişliği/kod dönüştürme sınırı bu oturumu reddetti. Sunucu sahibinden bunu ayarlamasını isteyin.';
	@override String get logsUploaded => 'Günlükler yüklendi';
	@override String get logsUploadFailed => 'Günlükler yüklenemedi';
	@override String get logId => 'Günlük Kimliği (ID)';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$tr extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get text => 'Metin';
	@override String get border => 'Kenarlık';
	@override String get background => 'Arka Plan';
	@override String get fontSize => 'Yazı Boyutu';
	@override String get textColor => 'Metin Rengi';
	@override String get borderSize => 'Kenarlık Boyutu';
	@override String get borderColor => 'Kenarlık Rengi';
	@override String get backgroundOpacity => 'Arka Plan Saydamlığı';
	@override String get backgroundColor => 'Arka Plan Rengi';
	@override String get position => 'Konum';
	@override String get assOverride => 'ASS Geçersiz Kılma';
	@override String get overrideScale => 'Ölçekle';
	@override String get overrideForce => 'Zorla';
	@override String get overrideStrip => 'Biçimlendirmeyi kaldır';
	@override String get positionTop => 'Üst';
	@override String get positionBottom => 'Alt';
	@override String get bold => 'Kalın';
	@override String get italic => 'İtalik';
	@override String get renderResolution => 'İşleme Çözünürlüğü';
	@override String get renderResolutionScreen => 'Ekran çözünürlüğü';
	@override String get renderResolutionVideo => 'Video çözünürlüğü';
}

// Path: mpvConfig
class _Translations$mpvConfig$tr extends Translations$mpvConfig$en {
	_Translations$mpvConfig$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Gelişmiş video oynatıcı ayarları';
	@override String get presets => 'Önayarlar';
	@override String get noPresets => 'Kayıtlı önayar yok';
	@override String get saveAsPreset => 'Önayar Olarak Kaydet...';
	@override String get presetName => 'Önayar Adı';
	@override String get presetNameHint => 'Bu önayar için bir isim girin';
	@override String get loadPreset => 'Yükle';
	@override String get deletePreset => 'Sil';
	@override String get presetSaved => 'Önayar kaydedildi';
	@override String get presetLoaded => 'Önayar yüklendi';
	@override String get presetDeleted => 'Önayar silindi';
	@override String get confirmDeletePreset => 'Bu önayarı silmek istediğinizden emin misiniz?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# yorum';
}

// Path: dialog
class _Translations$dialog$tr extends Translations$dialog$en {
	_Translations$dialog$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Eylemi Onayla';
}

// Path: profiles
class _Translations$profiles$tr extends Translations$profiles$en {
	_Translations$profiles$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Plezy profili ekle';
	@override String get switchingProfile => 'Profil değiştiriliyor…';
	@override String get deleteThisProfileTitle => 'Bu profil silinsin mi?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} kişisi kaldırılacak. Bağlantılar etkilenmez.';
	@override String get active => 'Aktif';
	@override String get manage => 'Yönet';
	@override String get delete => 'Sil';
	@override String get signOut => 'Çıkış Yap';
	@override String get signOutPlexTitle => 'Plex\'ten çıkış yapılsın mı?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} ve tüm Plex Ev kullanıcıları kaldırılsın mı? İstediğiniz zaman tekrar giriş yapabilirsiniz.';
	@override String get signedOutPlex => 'Plex\'ten çıkış yapıldı.';
	@override String get signOutFailed => 'Çıkış yapılamadı.';
	@override String get sectionTitle => 'Profiller';
	@override String get summarySingle => 'Yönetilen kullanıcıları ve yerel kimlikleri karıştırmak için profiller ekleyin';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · aktif: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profil';
	@override String get removeConnectionTitle => 'Bağlantı kaldırılsın mı?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} kullanıcısının ${connectionLabel} erişimi kaldırılacak. Diğer profiller bunu tutar.';
	@override String get deleteProfileTitle => 'Profil silinsin mi?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} ve bağlantıları kaldırılacak. Sunucular kullanılabilir kalır.';
	@override String get profileNameLabel => 'Profil adı';
	@override String get pinProtectionLabel => 'PIN koruması';
	@override String get pinManagedByPlex => 'PIN, Plex tarafından yönetiliyor. plex.tv üzerinden düzenleyin.';
	@override String get noPinSetEditOnPlex => 'PIN ayarlanmadı. Bir tane gerekli kılmak için plex.tv\'de ev kullanıcısını düzenleyin.';
	@override String get setPin => 'PIN Ayarla';
	@override String get setPinTitle => 'PIN Ayarla';
	@override String get confirmPinTitle => 'PIN\'i Onayla';
	@override String get pinSet => 'PIN ayarlandı';
	@override String get changePin => 'Değiştir';
	@override String get removePin => 'Kaldır';
	@override String get connectionsLabel => 'Bağlantılar';
	@override String get add => 'Ekle';
	@override String get deleteProfileButton => 'Profili sil';
	@override String get noConnectionsHint => 'Bağlantı yok — bu profili kullanmak için bir tane ekleyin.';
	@override String get noConnections => 'Bağlantı yok';
	@override String get plexHomeAccount => 'Plex Ev hesabı';
	@override String plexAccountChip({required Object account}) => 'Plex hesabı: ${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} hesabı üzerinden ${user}';
	@override String get connectionDefault => 'Varsayılan';
	@override String connectionAs({required Object displayName}) => '${displayName} olarak';
	@override String get makeDefault => 'Varsayılan yap';
	@override String get removeConnection => 'Kaldır';
	@override String get profileRenamed => 'Profil yeniden adlandırıldı.';
	@override String borrowAddTo({required Object displayName}) => '${displayName} profiline ekle';
	@override String get borrowExplain => 'Başka bir profilin bağlantısını ödünç alın. PIN korumalı profiller bir PIN gerektirir.';
	@override String get borrowEmpty => 'Henüz ödünç alınacak bir şey yok.';
	@override String get borrowEmptySubtitle => 'Önce başka bir profile Plex veya Jellyfin bağlayın.';
	@override String get borrowLoadFailed => 'Mevcut bağlantılar yüklenemedi. Tekrar deneyin.';
	@override String borrowFromProfile({required Object displayName}) => '${displayName} profilinden';
	@override String get borrowConnectionBorrowed => 'Bağlantı ödünç alındı.';
	@override String get borrowFailed => 'Bağlantı ödünç alınamadı.';
	@override String get incorrectPin => 'Yanlış PIN.';
	@override String get incorrectPinTryAgain => 'Yanlış PIN. Lütfen tekrar deneyin.';
	@override String get sourceProfileMissingParentAccount => 'Kaynak profilin üst hesabı eksik.';
	@override String get failedToLoadHomeUsers => 'Plex Ev kullanıcılarınız yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
	@override String get failedToVerifyPin => 'PIN doğrulanamadı.';
	@override String get newProfile => 'Yeni profil';
	@override String get profileNameHint => 'ör. Misafirler, Çocuklar, Oturma Odası';
	@override String get pinProtectionOptional => 'PIN koruması (isteğe bağlı)';
	@override String get pinExplain => 'Profiller arasında geçiş yapmak için 4 haneli PIN gereklidir.';
	@override String get continueButton => 'Devam Et';
	@override String get pinsDontMatch => 'PIN\'ler eşleşmiyor';
}

// Path: connections
class _Translations$connections$tr extends Translations$connections$en {
	_Translations$connections$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Bağlantılar';
	@override String get addConnection => 'Bağlantı ekle';
	@override String get addConnectionSubtitleNoProfile => 'Plex ile giriş yapın veya bir Jellyfin sunucusu bağlayın';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName} profiline ekle: Plex, Jellyfin veya başka bir profil bağlantısı';
	@override String sessionExpiredOne({required Object name}) => '${name} için oturum süresi doldu';
	@override String sessionExpiredMany({required Object count}) => '${count} sunucu için oturum süresi doldu';
	@override String get signInAgain => 'Tekrar giriş yap';
}

// Path: discover
class _Translations$discover$tr extends Translations$discover$en {
	_Translations$discover$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Keşfet';
	@override String get noContentAvailable => 'İçerik bulunmuyor';
	@override String get addMediaToLibraries => 'Kitaplıklarınıza biraz medya ekleyin';
	@override String get continueWatching => 'İzlemeye Devam Et';
	@override String continueWatchingIn({required Object library}) => '${library} içinde İzlemeye Devam Et';
	@override String get nextUp => 'Sıradaki';
	@override String nextUpIn({required Object library}) => '${library} içinde Sıradaki';
	@override String get recentlyAdded => 'Son Eklenenler';
	@override String recentlyAddedIn({required Object library}) => '${library} içinde Son Eklenenler';
	@override String latestAlbumsIn({required Object library}) => '${library} içinde Son Albümler';
	@override String recentlyPlayedIn({required Object library}) => '${library} içinde Son Oynatılanlar';
	@override String mostPlayedIn({required Object library}) => '${library} içinde En Çok Oynatılanlar';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}B${episode}';
	@override String get overview => 'Genel Bakış';
	@override String get cast => 'Oyuncular';
	@override String get extras => 'Fragmanlar ve Ekstralar';
	@override String get studio => 'Stüdyo';
	@override String get rating => 'Derecelendirme';
	@override String get director => 'Yönetmen';
	@override String get directors => 'Yönetmenler';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV Dizisi';
	@override String minutesLeft({required Object minutes}) => '${minutes} dk kaldı';
	@override String get moreLikeThis => 'Buna Benzerler';
}

// Path: errors
class _Translations$errors$tr extends Translations$errors$en {
	_Translations$errors$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Arama başarısız: ${error}';
	@override String get searchUnavailable => 'Arama hiçbir medya sunucusuna ulaşamadı.';
	@override String connectionTimeout({required Object context}) => '${context} yüklenirken bağlantı zaman aşımına uğradı';
	@override String get connectionFailed => 'Medya sunucusuna bağlanılamıyor';
	@override String unableToLoad({required Object context}) => '${context} yüklenemedi. Lütfen tekrar deneyin.';
	@override String get noClientAvailable => 'Kullanılabilir istemci yok';
	@override String get pleaseEnterToken => 'Lütfen bir belirteç (token) girin';
	@override String get invalidToken => 'Geçersiz belirteç';
	@override String failedToVerifyToken({required Object error}) => 'Belirteç doğrulanamadı: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName} profiline geçilemedi';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName} profili silinemedi';
	@override String get failedToRate => 'Puan güncellenemedi';
}

// Path: libraries
class _Translations$libraries$tr extends Translations$libraries$en {
	_Translations$libraries$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kitaplıklar';
	@override String get fallbackTitle => 'Kitaplık';
	@override String get scanLibraryFiles => 'Kitaplık Dosyalarını Tarayınız';
	@override String get scanLibrary => 'Kitaplığı Taramak';
	@override String get analyze => 'Analiz Et';
	@override String get analyzeLibrary => 'Kitaplığı Analiz Et';
	@override String get refreshMetadata => 'Meta Verileri Yenile';
	@override String get emptyTrash => 'Çöpü Boşalt';
	@override String emptyingTrash({required Object title}) => '"${title}" için çöp boşaltılıyor...';
	@override String trashEmptied({required Object title}) => '"${title}" için çöp boşaltıldı';
	@override String failedToEmptyTrash({required Object error}) => 'Çöp boşaltılamadı: ${error}';
	@override String analyzing({required Object title}) => '"${title}" analiz ediliyor...';
	@override String analysisStarted({required Object title}) => '"${title}" için analiz başladı';
	@override String failedToAnalyze({required Object error}) => 'Kitaplık analiz edilemedi: ${error}';
	@override String get noLibrariesFound => 'Kitaplık bulunamadı';
	@override String get allLibrariesHidden => 'Tüm kitaplıklar gizli';
	@override String hiddenLibrariesCount({required Object count}) => 'Gizli kitaplıklar (${count})';
	@override String get thisLibraryIsEmpty => 'Bu kitaplık boş';
	@override String get noItemsMatchFilters => 'Etkin filtrelerle eşleşen öge yok';
	@override String get resetFilters => 'Filtreleri sıfırla';
	@override String get all => 'Tümü';
	@override String get clearAll => 'Tümünü Temizle';
	@override String scanLibraryConfirm({required Object title}) => '"${title}" kitaplığını taramak istediğinizden emin misiniz?';
	@override String analyzeLibraryConfirm({required Object title}) => '"${title}" kitaplığını analiz etmek istediğinizden emin misiniz?';
	@override String refreshMetadataConfirm({required Object title}) => '"${title}" kitaplığı için meta verileri yenilemek istediğinizden emin misiniz?';
	@override String emptyTrashConfirm({required Object title}) => '"${title}" için çöpü boşaltmak istediğinizden emin misiniz?';
	@override String get manageLibraries => 'Kitaplıkları Yönet';
	@override String get sort => 'Sırala';
	@override String get sortBy => 'Sıralama Ölçütü';
	@override String get filters => 'Filtreler';
	@override String get confirmActionMessage => 'Bu eylemi gerçekleştirmek istediğinizden emin misiniz?';
	@override String get showLibrary => 'Kitaplığı göster';
	@override String get hideLibrary => 'Kitaplığı gizle';
	@override String get libraryOptions => 'Kitaplık seçenekleri';
	@override String get content => 'kitaplık içeriği';
	@override String get selectLibrary => 'Kitaplık seç';
	@override String filtersWithCount({required Object count}) => 'Filtreler (${count})';
	@override String get noRecommendations => 'Öneri bulunmuyor';
	@override String get noCollections => 'Bu kitaplıkta koleksiyon yok';
	@override String get noFoldersFound => 'Klasör bulunamadı';
	@override String get folders => 'klasörler';
	@override late final _Translations$libraries$tabs$tr tabs = _Translations$libraries$tabs$tr._(_root);
	@override late final _Translations$libraries$groupings$tr groupings = _Translations$libraries$groupings$tr._(_root);
	@override late final _Translations$libraries$filterCategories$tr filterCategories = _Translations$libraries$filterCategories$tr._(_root);
	@override late final _Translations$libraries$sortLabels$tr sortLabels = _Translations$libraries$sortLabels$tr._(_root);
}

// Path: about
class _Translations$about$tr extends Translations$about$en {
	_Translations$about$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hakkında';
	@override String get openSourceLicenses => 'Açık Kaynak Lisansları';
	@override String versionLabel({required Object version}) => 'Sürüm ${version}';
	@override String get appDescription => 'Flutter için şık bir Plex ve Jellyfin istemcisi';
	@override String get viewLicensesDescription => 'Üçüncü taraf kütüphanelerin lisanslarını görüntüleyin';
}

// Path: serverSelection
class _Translations$serverSelection$tr extends Translations$serverSelection$en {
	_Translations$serverSelection$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email}) için sunucu bulunamadı';
	@override String failedToLoadServers({required Object error}) => 'Sunucular yüklenemedi: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$tr extends Translations$hubDetail$en {
	_Translations$hubDetail$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Başlık';
	@override String get releaseYear => 'Yayın Yılı';
	@override String get dateAdded => 'Ekleme Tarihi';
	@override String get rating => 'Puan';
	@override String get noItemsFound => 'Öge bulunamadı';
}

// Path: logs
class _Translations$logs$tr extends Translations$logs$en {
	_Translations$logs$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Günlükleri Temizle';
	@override String get copyLogs => 'Günlükleri Kopyala';
	@override String get uploadLogs => 'Günlükleri Yükle';
}

// Path: licenses
class _Translations$licenses$tr extends Translations$licenses$en {
	_Translations$licenses$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'İlgili Paketler';
	@override String get license => 'Lisans';
	@override String licenseNumber({required Object number}) => 'Lisans ${number}';
	@override String licensesCount({required Object count}) => '${count} lisans';
}

// Path: navigation
class _Translations$navigation$tr extends Translations$navigation$en {
	_Translations$navigation$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Kitaplıklar';
	@override String get downloads => 'İndirmeler';
	@override String get liveTv => 'Canlı TV';
	@override String get explore => 'Keşfet';
}

// Path: explore
class _Translations$explore$tr extends Translations$explore$en {
	_Translations$explore$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Keşfet';
	@override String get selectSource => 'Kaynak seçin';
	@override late final _Translations$explore$rows$tr rows = _Translations$explore$rows$tr._(_root);
	@override late final _Translations$explore$status$tr status = _Translations$explore$status$tr._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n,
		one: '${n} bölüm',
		other: '${n} bölüm',
	);
	@override String get cast => 'Oyuncular';
	@override String get characters => 'Karakterler';
	@override String get addToWatchlist => 'İzleme Listesine Ekle';
	@override String get removeFromWatchlist => 'İzleme Listesinden Kaldır';
	@override String get watchlistUpdateFailed => 'İzleme listesi güncellenemedi';
	@override String get notInLibrary => 'Kitaplığınızda yok';
	@override String get inTheseLibraries => 'Bu kitaplıklarda var';
	@override String get checkingLibrary => 'Kitaplığınız kontrol ediliyor...';
	@override String get emptyTitle => 'Henüz burada bir şey yok';
	@override String emptyMessage({required Object source}) => '${source} kaynağındaki satırlar içerik bulunduğunda burada görünecektir.';
	@override String searchHint({required Object source}) => '${source} üzerinde ara';
	@override String searchEmpty({required Object query}) => '"${query}" için sonuç bulunamadı';
	@override String searchPrompt({required Object source}) => '${source} üzerinde film ve dizileri arayın.';
	@override String get searchFailed => 'Arama başarısız. Bağlantınızı kontrol edip tekrar deneyin.';
}

// Path: liveTv
class _Translations$liveTv$tr extends Translations$liveTv$en {
	_Translations$liveTv$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Canlı TV';
	@override String get guide => 'Rehber';
	@override String get noChannels => 'Kullanılabilir kanal yok';
	@override String get noDvr => 'Hiçbir sunucuda DVR yapılandırılmadı';
	@override String get serverUnavailable => 'Canlı TV sunucusu kullanılabilir değil.';
	@override String get serverNotConnected => 'Canlı TV sunucusu bağlı değil.';
	@override String get noPrograms => 'Program verisi bulunmuyor';
	@override String get liveStreamFailed => 'Canlı akış başarısız oldu';
	@override String get unknownProgram => 'Bilinmeyen Program';
	@override String get unknownHub => 'Bilinmiyor';
	@override String get unknownError => 'Bilinmeyen hata';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Bilinmeyen kanal';
	@override String get live => 'CANLI';
	@override String get reloadGuide => 'Rehberi Yeniden Yükle';
	@override String get now => 'Şimdi';
	@override String get today => 'Bugün';
	@override String get tomorrow => 'Yarın';
	@override String get midnight => 'Gece Yarısı';
	@override String get overnight => 'Gece Boyunca';
	@override String get morning => 'Sabah';
	@override String get daytime => 'Gündüz';
	@override String get evening => 'Akşam';
	@override String get lateNight => 'Gece Geç Saatler';
	@override String get whatsOn => 'Şimdi Ne Var?';
	@override String get watchChannel => 'Kanalı İzle';
	@override String get favorites => 'Favoriler';
	@override String get reorderFavorites => 'Favorileri Yeniden Sırala';
	@override String get favoritesLoadFailed => 'Favoriler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
	@override String get favoritesUpdateFailed => 'Favoriler güncellenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
	@override String get joinSession => 'Devam Eden Oturuma Katıl';
	@override String watchFromStart({required Object minutes}) => 'Baştan izle (${minutes} dk önce)';
	@override String get watchLive => 'Canlı İzle';
	@override String get goToLive => 'Canlıya Git';
	@override String get record => 'Kaydet';
	@override String get recordEpisode => 'Bölümü Kaydet';
	@override String get recordSeries => 'Diziyi Kaydet';
	@override String get recordOptions => 'Kayıt Seçenekleri';
	@override String get saveTo => 'Şuraya kaydet';
	@override String get recordings => 'Kayıtlar';
	@override String get scheduledRecordings => 'Planlananlar';
	@override String get recordingRules => 'Kayıt Kuralları';
	@override String get noScheduledRecordings => 'Kaydedilecek planlanmış bir şey yok';
	@override String get manageRecording => 'Kaydı yönet';
	@override String get cancelRecording => 'Kaydı iptal et';
	@override String get cancelRecordingTitle => 'Bu kayıt iptal edilsin mi?';
	@override String cancelRecordingMessage({required Object title}) => '${title} artık kaydedilmeyecek.';
	@override String get deleteRule => 'Kuralı sil';
	@override String get deleteRuleTitle => 'Kayıt kuralı silinsin mi?';
	@override String deleteRuleMessage({required Object title}) => '${title} dizisinin gelecek bölümleri kaydedilmeyecek.';
	@override String get recordingScheduled => 'Kayıt planlandı';
	@override String get alreadyScheduled => 'Bu program zaten planlanmış';
	@override String get dvrAdminRequired => 'DVR ayarları bir yönetici hesabı gerektirir';
	@override String get recordingFailed => 'Kayıt planlanamadı';
	@override String get recordingTargetMissing => 'Kayıt kitaplığı belirlenemedi';
	@override String get recordNotAvailable => 'Bu program için kayıt kullanılamıyor';
	@override String get recordingCancelled => 'Kayıt iptal edildi';
	@override String get recordingRuleDeleted => 'Kayıt kuralı silindi';
	@override String get processRecordingRules => 'Kuralları yeniden değerlendir';
	@override String get recordingInProgress => 'Şimdi kaydediliyor';
	@override String recordingsCount({required Object count}) => '${count} planlandı';
	@override String get editRule => 'Kuralı düzenle';
	@override String get editRuleAction => 'Düzenle';
	@override String get recordingRuleUpdated => 'Kayıt kuralı güncellendi';
	@override String get guideReloadRequested => 'Rehber yenilemesi istendi';
	@override String get rulesProcessRequested => 'Kuralın yeniden değerlendirilmesi istendi';
	@override String get recordShow => 'Programı kaydet';
}

// Path: collections
class _Translations$collections$tr extends Translations$collections$en {
	_Translations$collections$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Koleksiyonlar';
	@override String get collection => 'Koleksiyon';
	@override String get empty => 'Koleksiyon boş';
	@override String get deleteCollection => 'Koleksiyonu Sil';
	@override String deleteConfirm({required Object title}) => '"${title}" silinsin mi? Bu işlem geri alınamaz.';
	@override String get deleted => 'Koleksiyon silindi';
	@override String get deleteFailed => 'Koleksiyon silinemedi';
	@override String deleteFailedWithError({required Object error}) => 'Koleksiyon silinemedi: ${error}';
	@override String get selectCollection => 'Koleksiyon Seç';
	@override String get collectionName => 'Koleksiyon Adı';
	@override String get enterCollectionName => 'Koleksiyon adını girin';
	@override String get addedToCollection => 'Koleksiyona eklendi';
	@override String get errorAddingToCollection => 'Koleksiyona eklenemedi';
	@override String get created => 'Koleksiyon oluşturuldu';
	@override String get removeFromCollection => 'Koleksiyondan kaldır';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" bu koleksiyondan kaldırılsın mı?';
	@override String get removedFromCollection => 'Koleksiyondan kaldırıldı';
	@override String get removeFromCollectionFailed => 'Koleksiyondan kaldırılamadı';
	@override String removeFromCollectionError({required Object error}) => 'Koleksiyondan kaldırılırken hata: ${error}';
	@override String get searchCollections => 'Koleksiyonlarda ara...';
}

// Path: playlists
class _Translations$playlists$tr extends Translations$playlists$en {
	_Translations$playlists$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oynatma Listeleri';
	@override String get playlist => 'Oynatma Listesi';
	@override String get noPlaylists => 'Oynatma listesi bulunamadı';
	@override String get create => 'Oynatma Listesi Oluştur';
	@override String get playlistName => 'Oynatma Listesi Adı';
	@override String get enterPlaylistName => 'Oynatma listesi adını girin';
	@override String get delete => 'Oynatma Listesini Sil';
	@override String get removeItem => 'Oynatma Listesinden Kaldır';
	@override String get smartPlaylist => 'Akıllı Oynatma Listesi';
	@override String itemCount({required Object count}) => '${count} öge';
	@override String get oneItem => '1 öge';
	@override String get emptyPlaylist => 'Bu oynatma listesi boş';
	@override String get deleteConfirm => 'Oynatma Listesi Silinsin mi?';
	@override String deleteMessage({required Object name}) => '"${name}" listesini silmek istediğinizden emin misiniz?';
	@override String get created => 'Oynatma listesi oluşturuldu';
	@override String get deleted => 'Oynatma listesi silindi';
	@override String get itemAdded => 'Oynatma listesine eklendi';
	@override String get itemRemoved => 'Oynatma listesinden kaldırıldı';
	@override String get selectPlaylist => 'Oynatma Listesi Seç';
	@override String get searchPlaylists => 'Oynatma listelerinde ara...';
	@override String get errorCreating => 'Oynatma listesi oluşturulamadı';
	@override String get errorDeleting => 'Oynatma listesi silinemedi';
	@override String get errorLoading => 'Oynatma listeleri yüklenemedi';
	@override String get errorAdding => 'Oynatma listesine eklenemedi';
	@override String get errorReordering => 'Oynatma listesi ögesi yeniden sıralanamadı';
	@override String get errorRemoving => 'Oynatma listesinden kaldırılamadı';
}

// Path: music
class _Translations$music$tr extends Translations$music$en {
	_Translations$music$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Albüme git';
	@override String get goToArtist => 'Sanatçıya git';
	@override String get instantMix => 'Anında Karışım';
	@override String get playNext => 'Sonrakini oynat';
	@override String get addToQueue => 'Kuyruğa ekle';
	@override String discNumber({required Object n}) => 'Disk ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n,
		one: '${n} parça',
		other: '${n} parça',
	);
	@override String get nowPlaying => 'Şimdi Oynatılıyor';
	@override String playingFrom({required Object title}) => '${title} kaynağından oynatılıyor';
	@override String get queue => 'Kuyruk';
	@override String get clearQueue => 'Kuyruğu temizle';
	@override String get lyrics => 'Şarkı Sözleri';
	@override String get noLyrics => 'Şarkı sözü bulunmuyor';
	@override String get sleepTimer => 'Uyku zamanlayıcısı';
	@override String get sleepTimerEndOfTrack => 'Parçanın sonu';
	@override String sleepTimerMinutes({required Object n}) => '${n} dakika';
	@override String get stopPlayback => 'Oynatmayı durdur';
	@override String get previousTrack => 'Önceki parça';
	@override String get nextTrack => 'Sonraki parça';
	@override String get repeat => 'Tekrarla';
	@override String get repeatAll => 'Tümünü tekrarla';
	@override String get repeatOne => 'Tekini tekrarla';
}

// Path: watchTogether
class _Translations$watchTogether$tr extends Translations$watchTogether$en {
	_Translations$watchTogether$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Birlikte İzle';
	@override String get description => 'Arkadaşlarınızla ve ailenizle eş zamanlı içerik izleyin';
	@override String get createSession => 'Oturum Oluştur';
	@override String get creating => 'Oluşturuluyor...';
	@override String get joinSession => 'Oturuma Katıl';
	@override String get joining => 'Katılınıyor...';
	@override String get controlMode => 'Kontrol Modu';
	@override String get controlModeQuestion => 'Oynatmayı kimler kontrol edebilir?';
	@override String get hostOnly => 'Yalnızca Kurucu';
	@override String get anyone => 'Herkes';
	@override String get hostingSession => 'Oturum Sunuluyor';
	@override String get inSession => 'Oturumda';
	@override String get sessionCode => 'Oturum Kodu';
	@override String get openSessionControls => 'Birlikte İzle oturum kontrollerini aç';
	@override String get copySessionCode => 'Oturum kodunu kopyala';
	@override String get hostControlsPlayback => 'Oynatmayı kurucu kontrol eder';
	@override String get anyoneCanControl => 'Oynatmayı herkes kontrol edebilir';
	@override String get hostControls => 'Kurucu kontrol eder';
	@override String get anyoneControls => 'Herkes kontrol eder';
	@override String get participants => 'Katılımcılar';
	@override String get host => 'Kurucu';
	@override String get hostBadge => 'KURUCU';
	@override String get youAreHost => 'Kurucu sizsiniz';
	@override String get watchingWithOthers => 'Başkalarıyla birlikte izleniyor';
	@override String get endSession => 'Oturumu Bitir';
	@override String get leaveSession => 'Oturumdan Ayrıl';
	@override String get endSessionQuestion => 'Oturum Bitirilsin mi?';
	@override String get leaveSessionQuestion => 'Oturumdan Ayrılınsın mı?';
	@override String get endSessionConfirm => 'Bu işlem tüm katılımcılar için oturumu bitirecektir.';
	@override String get leaveSessionConfirm => 'Oturumdan çıkarılacaksınız.';
	@override String get endSessionConfirmOverlay => 'Bu işlem tüm katılımcılar için izleme oturumunu bitirecektir.';
	@override String get leaveSessionConfirmOverlay => 'İzleme oturumuyla bağlantınız kesilecek.';
	@override String get end => 'Bitir';
	@override String get leave => 'Ayrıl';
	@override String get syncing => 'Eşitleniyor...';
	@override String get joinWatchSession => 'İzleme Oturumuna Katıl';
	@override String get enterCodeHint => '5 karakterlik kodu girin';
	@override String get pasteFromClipboard => 'Panodan yapıştır';
	@override String get pleaseEnterCode => 'Lütfen bir oturum kodu girin';
	@override String get codeMustBe5Chars => 'Oturum kodu 5 karakter olmalıdır';
	@override String get joinInstructions => 'Katılmak için kurucunun oturum kodunu girin.';
	@override String get failedToCreate => 'Oturum oluşturulamadı';
	@override String get failedToJoin => 'Oturuma katılınamadı';
	@override String get sessionCodeCopied => 'Oturum kodu panoya kopyalandı';
	@override String get relayUnreachable => 'Aktarıcı sunucusuna ulaşılamıyor. İSS engellemesi Birlikte İzle\'yi önleyebilir.';
	@override String get reconnectingToHost => 'Kurucuya yeniden bağlanılıyor...';
	@override String get currentPlayback => 'Mevcut Oynatma';
	@override String get joinCurrentPlayback => 'Mevcut Oynatmaya Katıl';
	@override String get joinCurrentPlaybackDescription => 'Kurucunun şu anda izlediği şeye doğrudan atlayın';
	@override String get failedToOpenCurrentPlayback => 'Mevcut oynatma açılamadı';
	@override String participantJoined({required Object name}) => '${name} katıldı';
	@override String participantLeft({required Object name}) => '${name} ayrıldı';
	@override String participantPaused({required Object name}) => '${name} duraklattı';
	@override String participantResumed({required Object name}) => '${name} devam ettirdi';
	@override String participantSeeked({required Object name}) => '${name} oynatma konumunu değiştirdi';
	@override String participantBuffering({required Object name}) => '${name} arabelleğe alıyor';
	@override String participantNeedsUpdate({required Object name}) => '${name} eski bir uygulama sürümünde — eşitleme kullanılamıyor';
	@override String resumingWithout({required Object name}) => '${name} olmadan devam ediliyor';
	@override String get waitingForParticipants => 'Diğerlerinin yüklemesi bekleniyor...';
	@override String waitingForName({required Object name}) => '${name} bekleniyor...';
	@override String get recentRooms => 'Son Odalar';
	@override String get renameRoom => 'Odayı Yeniden Adlandır';
	@override String get removeRoom => 'Kaldır';
	@override String get guestSwitchUnavailable => 'Geçiş yapılamadı — eşitleme için sunucu mevcut değil';
	@override String get guestSwitchFailed => 'Geçiş yapılamadı — içerik bu sunucuda bulunamadı';
}

// Path: downloads
class _Translations$downloads$tr extends Translations$downloads$en {
	_Translations$downloads$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'İndirmeler';
	@override String get manage => 'Yönet';
	@override String get tvShows => 'TV Dizileri';
	@override String get movies => 'Filmler';
	@override String get music => 'Müzik';
	@override String tracksQueued({required Object count}) => 'İndirmek için ${count} parça kuyruğa alındı';
	@override String get noDownloads => 'Henüz indirme yok';
	@override String get noDownloadsDescription => 'İndirilen içerik çevrimdışı izlemek için burada görünecektir';
	@override String get downloadNow => 'İndir';
	@override String get deleteDownload => 'İndirmeyi sil';
	@override String get retryDownload => 'İndirmeyi tekrar dene';
	@override String get downloadQueued => 'İndirme kuyruğa alındı';
	@override String get downloadResumed => 'İndirme devam ettirildi';
	@override String get serverErrorBitrate => 'Sunucu hatası: dosya uzak bit hızı sınırını aşıyor olabilir';
	@override String get storageFull => 'Cihaz depolama alanı dolu olduğu için indirmeler durduruldu. Biraz alan boşaltıp tekrar deneyin.';
	@override String episodesQueued({required Object count}) => 'İndirmek için ${count} bölüm kuyruğa alındı';
	@override String get downloadDeleted => 'İndirme silindi';
	@override String deleteConfirm({required Object title}) => '"${title}" bu cihazdan silinsin mi?';
	@override String get cancelledDownloadTitle => 'İptal Edilen İndirme';
	@override String get cancelledDownloadMessage => 'Bu indirme iptal edildi. Ne yapmak istersiniz?';
	@override String get allEpisodesAlreadyDownloaded => 'Tüm bölümler zaten indirildi';
	@override String get resumeDownload => 'İndirmeyi devam ettir';
	@override String get cancelledDownload => 'İptal edilen indirme';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} eşitleniyor)';
	@override String downloadedFileClickToComplete({required Object file}) => 'İndirildi ${file} - Tamamlamak için tıklayın';
	@override String get partialDownloadClickToComplete => 'Kısmen indirildi - Tamamlamak için tıklayın';
	@override String get deleting => 'Siliniyor...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} siliniyor... (${current} / ${total})';
	@override String get queuedTooltip => 'Kuyrukta';
	@override String queuedFilesTooltip({required Object files}) => 'Kuyruğa alınan dosyalar: ${files}';
	@override String get downloadingTooltip => 'İndiriliyor...';
	@override String downloadingFilesTooltip({required Object files}) => 'İndirilen dosyalar: ${files}';
	@override String get noDownloadsTree => 'İndirme yok';
	@override String get pauseAll => 'Tümünü duraklat';
	@override String get resumeAll => 'Tümünü devam ettir';
	@override String get deleteAll => 'Tümünü sil';
	@override String get selectVersion => 'Sürüm Seç';
	@override String get allEpisodes => 'Tüm bölümler';
	@override String get unwatchedOnly => 'Yalnızca izlenmeyenler';
	@override String nextNUnwatched({required Object count}) => 'Sonraki ${count} izlenmeyen';
	@override String get customAmount => 'Özel miktar...';
	@override String get includeSpecials => 'Özel Bölümleri Dahil Et';
	@override String get howManyEpisodes => 'Kaç bölüm?';
	@override String get invalidEpisodeCount => 'Geçerli bir bölüm sayısı girin.';
	@override String get keepSynced => 'Eşitlenmiş tut';
	@override String get downloadOnce => 'Bir kez indir';
	@override String keepNUnwatched({required Object count}) => '${count} izlenmeyen bölümü tut';
	@override String get editSyncRule => 'Eşitleme kuralını düzenle';
	@override String get removeSyncRule => 'Eşitleme kuralını kaldır';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" eşitlemesi durdurulsun mu? İndirilen bölümler saklanacaktır.';
	@override String removeListSyncRuleConfirm({required Object title}) => '"${title}" eşitlemesi durdurulsun mu?';
	@override String get deleteSyncRuleDownloads => 'İlişkili indirmeleri de sil';
	@override String get deleteSyncRuleDownloadsDescription => 'Başka bir eşitleme kuralı veya profil tarafından kullanılan indirmeler saklanır.';
	@override String syncRuleCreated({required Object count}) => 'Eşitleme kuralı oluşturuldu — ${count} izlenmeyen bölüm saklanıyor';
	@override String get syncRuleUpdated => 'Eşitleme kuralı güncellendi';
	@override String get syncRuleRemoved => 'Eşitleme kuralı kaldırıldı';
	@override String get syncRuleAndDownloadsRemoved => 'Eşitleme kuralı ve ilişkili indirmeler kaldırıldı';
	@override String get syncRuleCleanupBusy => 'Eşitleme kuralları şu anda güncelleniyor. Birazdan tekrar deneyin.';
	@override String get syncRuleCleanupUnavailable => 'İlişkili indirmeler güvenli biçimde belirlenemedi. Sunucuya yeniden bağlanıp tekrar deneyin veya kuralı indirmeleri silmeden kaldırın.';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title} için ${count} yeni bölüm eşitlendi';
	@override String get activeSyncRules => 'Eşitleme kuralları';
	@override String get noSyncRules => 'Eşitleme kuralı yok';
	@override String get manageSyncRule => 'Eşitlemeyi yönet';
	@override String get editEpisodeCount => 'Bölüm sayısı';
	@override String get editSyncFilter => 'Eşitleme filtresi';
	@override String get syncAllItems => 'Tüm ögeler eşitleniyor';
	@override String get syncUnwatchedItems => 'İzlenmeyen ögeler eşitleniyor';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Sunucu: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Kullanılabilir';
	@override String get syncRuleOffline => 'Çevrimdışı';
	@override String get syncRuleSignInRequired => 'Giriş gerekli';
	@override String get syncRuleNotAvailableForProfile => 'Mevcut profil için kullanılamaz';
	@override String get syncRuleUnknownServer => 'Bilinmeyen sunucu';
	@override String get syncRuleListCreated => 'Eşitleme kuralı oluşturuldu';
	@override late final _Translations$downloads$backgroundWarning$tr backgroundWarning = _Translations$downloads$backgroundWarning$tr._(_root);
}

// Path: shaders
class _Translations$shaders$tr extends Translations$shaders$en {
	_Translations$shaders$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gölgelendiriciler';
	@override String get noShaderDescription => 'Video iyileştirmesi yok';
	@override String get nvscalerDescription => 'Daha keskin video için NVIDIA görsel ölçekleme';
	@override String get artcnnVariantNeutral => 'Nötr';
	@override String get artcnnVariantDenoise => 'Parazit Giderme';
	@override String get artcnnVariantDenoiseSharpen => 'Parazit Giderme + Keskinleştirme';
	@override String get qualityFast => 'Hızlı';
	@override String get qualityHQ => 'Yüksek Kalite';
	@override String get mode => 'Mod';
	@override String get importShader => 'Gölgelendirici İçe Aktar';
	@override String get customShaderDescription => 'Özel GLSL gölgelendirici';
	@override String get shaderImported => 'Gölgelendirici içe aktarıldı';
	@override String get shaderImportFailed => 'Gölgelendirici içe aktarılamadı';
	@override String get deleteShader => 'Gölgelendiriciyi Sil';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" silinsin mi?';
}

// Path: companionRemote
class _Translations$companionRemote$tr extends Translations$companionRemote$en {
	_Translations$companionRemote$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Yardımcı Kumanda';
	@override String connectedTo({required Object name}) => '${name} cihazına bağlandı';
	@override String get unknownDevice => 'Bilinmeyen Cihaz';
	@override late final _Translations$companionRemote$session$tr session = _Translations$companionRemote$session$tr._(_root);
	@override late final _Translations$companionRemote$pairing$tr pairing = _Translations$companionRemote$pairing$tr._(_root);
	@override late final _Translations$companionRemote$remote$tr remote = _Translations$companionRemote$remote$tr._(_root);
	@override late final _Translations$companionRemote$errors$tr errors = _Translations$companionRemote$errors$tr._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$tr extends Translations$videoSettings$en {
	_Translations$videoSettings$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Oynatma Hızı';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktif (${duration})';
	@override String get zoom => 'Yakınlaştırma';
	@override String get sleepTimer => 'Uyku Zamanlayıcısı';
	@override String get audioSync => 'Ses Senkronizasyonu';
	@override String get subtitleSync => 'Altyazı Senkronizasyonu';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Ses Çıkışı';
	@override String get performanceOverlay => 'Performans Katmanı';
	@override String get audioPassthrough => 'Ses Doğrudan Geçişi';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Çevreleyen Ses';
	@override String get audioOutputSpatial => 'Uzamsal Ses';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioNormalization => 'Ses Yüksekliğini Normalleştir';
	@override String get audioDownmix => 'Stereo\'ya Dönüştür';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$tr extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get color => 'Renk';
	@override String get performance => 'Performans';
	@override String get buffer => 'Arabellek';
	@override String get app => 'Uygulama';
	@override String get decoder => 'Çözücü';
	@override String get rawDecoder => 'Ham Çözücü';
	@override String get tunneling => 'Tünelleme';
	@override String get aspect => 'Oran';
	@override String get rotation => 'Döndürme';
	@override String get dvSource => 'DV Kaynağı';
	@override String get dvPath => 'DV Yolu';
	@override String get p7Conversion => 'P7 Dönüştürme';
	@override String get sampleRate => 'Örnekleme Hızı';
	@override String get pixelFormat => 'Piksel Biçimi';
	@override String get hwFormat => 'HW Biçimi';
	@override String get matrix => 'Matris';
	@override String get primaries => 'Ana Renkler';
	@override String get transfer => 'Aktarım';
	@override String get renderFps => 'İşleme FPS';
	@override String get displayFps => 'Ekran FPS';
	@override String get avSync => 'A/V Eşitleme';
	@override String get dropped => 'Kare Kaybı';
	@override String get dvRpus => 'DV RPU\'ları';
	@override String get dvRpuAverage => 'DV RPU Ort.';
	@override String get dvSampleAverage => 'DV Örnek Ort.';
	@override String get maxLuma => 'Maks Luma';
	@override String get minLuma => 'Min Luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Kullanılan Önbellek';
	@override String get cacheLimit => 'Önbellek Sınırı';
	@override String get speed => 'Hız';
	@override String get player => 'Oynatıcı';
	@override String get memory => 'Bellek';
	@override String get uiFps => 'Arayüz (UI) FPS';
}

// Path: externalPlayer
class _Translations$externalPlayer$tr extends Translations$externalPlayer$en {
	_Translations$externalPlayer$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Harici Oynatıcı';
	@override String get useExternalPlayer => 'Harici Oynatıcı Kullan';
	@override String get useExternalPlayerDescription => 'Videoları başka bir uygulamada açın';
	@override String get selectPlayer => 'Oynatıcı Seç';
	@override String get customPlayers => 'Özel Oynatıcılar';
	@override String get systemDefault => 'Sistem Varsayılanı';
	@override String get addCustomPlayer => 'Özel Oynatıcı Ekle';
	@override String get playerName => 'Oynatıcı Adı';
	@override String get playerNameHint => 'Oynatıcım';
	@override String get playerCommand => 'Komut';
	@override String get playerPackage => 'Paket Adı';
	@override String get playerUrlScheme => 'URL Şeması';
	@override String get off => 'Kapalı';
	@override String get launchFailed => 'Harici oynatıcı açılamadı';
	@override String appNotInstalled({required Object name}) => '${name} yüklü değil';
	@override String get playInExternalPlayer => 'Harici Oynatıcıda Oynat';
}

// Path: metadataEdit
class _Translations$metadataEdit$tr extends Translations$metadataEdit$en {
	_Translations$metadataEdit$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Düzenle...';
	@override String get screenTitle => 'Meta Verileri Düzenle';
	@override String get basicInfo => 'Temel Bilgiler';
	@override String get artwork => 'Görseller';
	@override String get advancedSettings => 'Gelişmiş Ayarlar';
	@override String get title => 'Başlık';
	@override String get sortTitle => 'Sıralama Başlığı';
	@override String get originalTitle => 'Orijinal Başlık';
	@override String get releaseDate => 'Yayınlanma Tarihi';
	@override String get contentRating => 'İçerik Derecelendirmesi';
	@override String get studio => 'Stüdyo';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Özet';
	@override String get poster => 'Afiş';
	@override String get background => 'Arka Plan';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Kare Görsel';
	@override String get selectPoster => 'Afiş Seç';
	@override String get selectBackground => 'Arka Plan Seç';
	@override String get selectLogo => 'Logo Seç';
	@override String get selectSquareArt => 'Kare Görsel Seç';
	@override String get fromUrl => 'URL\'den';
	@override String get uploadFile => 'Dosya Yükle';
	@override String get enterImageUrl => 'Görsel URL\'si girin';
	@override String get imageUrl => 'Görsel URL\'si';
	@override String get metadataUpdated => 'Meta veriler güncellendi';
	@override String get metadataUpdateFailed => 'Meta veriler güncellenemedi';
	@override String get artworkUpdated => 'Görseller güncellendi';
	@override String get artworkUpdateFailed => 'Görseller güncellenemedi';
	@override String get noArtworkAvailable => 'Görsel bulunmuyor';
	@override String artworkOption({required Object index}) => 'Görsel seçeneği ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Görsel seçeneği ${index}, seçildi';
	@override String get notSet => 'Ayarlanmadı';
	@override String get libraryDefault => 'Kitaplık varsayılanı';
	@override String get accountDefault => 'Hesap varsayılanı';
	@override String get seriesDefault => 'Dizi varsayılanı';
	@override String get episodeSorting => 'Bölüm Sıralaması';
	@override String get oldestFirst => 'Önce en eski';
	@override String get newestFirst => 'Önce en yeni';
	@override String get keep => 'Sakla';
	@override String get allEpisodes => 'Tüm bölümler';
	@override String latestEpisodes({required Object count}) => 'En son ${count} bölüm';
	@override String get latestEpisode => 'En son bölüm';
	@override String episodesAddedPastDays({required Object count}) => 'Son ${count} günde eklenen bölümler';
	@override String get deleteAfterPlaying => 'Oynatıldıktan Sonra Bölümleri Sil';
	@override String get never => 'Asla';
	@override String get afterADay => 'Bir gün sonra';
	@override String get afterAWeek => 'Bir hafta sonra';
	@override String get afterAMonth => 'Bir ay sonra';
	@override String get onNextRefresh => 'Sonraki yenilemede';
	@override String get seasons => 'Sezonlar';
	@override String get show => 'Göster';
	@override String get hide => 'Gizle';
	@override String get episodeOrdering => 'Bölüm Düzeni';
	@override String get tmdbAiring => 'The Movie Database (Yayınlanma)';
	@override String get tvdbAiring => 'TheTVDB (Yayınlanma)';
	@override String get tvdbAbsolute => 'TheTVDB (Mutlak)';
	@override String get metadataLanguage => 'Meta Veri Dili';
	@override String get useOriginalTitle => 'Orijinal Başlığı Kullan';
	@override String get preferredAudioLanguage => 'Tercih Edilen Ses Dili';
	@override String get preferredSubtitleLanguage => 'Tercih Edilen Altyazı Dili';
	@override String get subtitleMode => 'Otomatik Altyazı Seçim Modu';
	@override String get manuallySelected => 'Manuel seçilen';
	@override String get shownWithForeignAudio => 'Yabancı sesle gösterilen';
	@override String get alwaysEnabled => 'Her zaman etkin';
	@override String get tags => 'Etiketler';
	@override String get addTag => 'Etiket ekle';
	@override String get genre => 'Tür';
	@override String get director => 'Yönetmen';
	@override String get writer => 'Yazar';
	@override String get producer => 'Yapımcı';
	@override String get country => 'Ülke';
	@override String get collection => 'Koleksiyon';
	@override String get label => 'Etiket';
	@override String get style => 'Tarz';
	@override String get mood => 'Ruh Hali';
}

// Path: matchScreen
class _Translations$matchScreen$tr extends Translations$matchScreen$en {
	_Translations$matchScreen$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get match => 'Eşleştir...';
	@override String get fixMatch => 'Eşleşmeyi Düzelt...';
	@override String get unmatch => 'Eşleşmeyi Kaldır';
	@override String get unmatchConfirm => 'Bu eşleşme temizlensin mi? Plex, tekrar eşleştirilene kadar bunu eşleşmemiş sayacaktır.';
	@override String get unmatchSuccess => 'Öge eşleşmesi kaldırıldı';
	@override String get unmatchFailed => 'Eşleşme kaldırılamadı';
	@override String get matchApplied => 'Eşleşme uygulandı';
	@override String get matchFailed => 'Eşleşme uygulanamadı';
	@override String get titleHint => 'Başlık';
	@override String get yearHint => 'Yıl';
	@override String get search => 'Ara';
	@override String get noMatchesFound => 'Eşleşme bulunamadı';
}

// Path: serverTasks
class _Translations$serverTasks$tr extends Translations$serverTasks$en {
	_Translations$serverTasks$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sunucu Görevleri';
	@override String get failedToLoad => 'Görevler yüklenemedi';
	@override String get noTasks => 'Çalışan görev yok';
}

// Path: trakt
class _Translations$trakt$tr extends Translations$trakt$en {
	_Translations$trakt$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Bağlandı';
	@override String connectedAs({required Object username}) => '@${username} olarak bağlandı';
	@override String get disconnectConfirm => 'Trakt hesabının bağlantısı kesilsin mi?';
	@override String get disconnectConfirmBody => 'Plezy, Trakt\'a olay göndermeyi durduracak. İstediğiniz zaman yeniden bağlanabilirsiniz.';
	@override String get scrobble => 'Gerçek zamanlı scrobble';
	@override String get scrobbleDescription => 'Oynatma sırasında Trakt\'a oynatma, duraklatma ve durdurma olayları gönderin.';
	@override String get watchedSync => 'İzleme durumunu eşitle';
	@override String get watchedSyncDescription => 'Plezy\'de ögeleri izlendi olarak işaretlediğinizde, Trakt üzerinde de izlendi olarak işaretlenir.';
}

// Path: seerr
class _Translations$seerr$tr extends Translations$seerr$en {
	_Translations$seerr$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr Bağla';
	@override String get serverUrl => 'Sunucu URL\'si';
	@override String get serverUrlHelper => 'Seerr örneğinizin adresi';
	@override String get checkServer => 'Devam Et';
	@override String get signInWithJellyfin => 'Jellyfin ile Giriş Yap';
	@override String get signInWithEmby => 'Emby ile Giriş Yap';
	@override String get signInWithLocal => 'Yerel hesap kullan';
	@override String get email => 'E-posta';
	@override String get noSignInMethods => 'Bu Seerr örneği Plezy\'nin desteklediği bir giriş yöntemi sunmuyor.';
	@override String get instance => 'Örnek (Instance)';
	@override String get disconnectConfirm => 'Seerr bağlantısı kesilsin mi?';
	@override String get disconnectConfirmBody => 'Plezy bu Seerr örneğini unutacak. İstediğiniz zaman yeniden bağlanabilirsiniz.';
	@override String get request => 'İstek Gönder';
	@override String get request4k => '4K İstek Gönder';
	@override String get seasons => 'Sezonlar';
	@override String get allSeasons => 'Tüm sezonlar';
	@override String get advancedOptions => 'Gelişmiş';
	@override String get destinationServer => 'Hedef sunucu';
	@override String get qualityProfile => 'Kalite profili';
	@override String get rootFolder => 'Kök klasör';
	@override String get languageProfile => 'Dil profili';
	@override String get requestSubmitted => 'İstek gönderildi';
	@override String requestFailed({required Object error}) => 'İstek başarısız oldu: ${error}';
	@override String get requestsLoadFailed => 'İstek seçenekleri yüklenemedi';
	@override String get nothingToRequest => 'Her şey zaten mevcut veya istendi.';
	@override String get statusAvailable => 'Mevcut';
	@override String get statusPartiallyAvailable => 'Kısmen mevcut';
	@override String get statusRequested => 'İstendi';
	@override String get statusProcessing => 'İşleniyor';
}

// Path: services
class _Translations$services$tr extends Translations$services$en {
	_Translations$services$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Servisler';
	@override String get hubSubtitle => 'İzleme ilerlemesini eşitleyin ve yeni başlıklar isteyin.';
	@override String get notConnected => 'Bağlı değil';
	@override String connectedAs({required Object username}) => '@${username} olarak bağlandı';
	@override String get scrobble => 'İlerlemeyi otomatik takip et';
	@override String get scrobbleDescription => 'Bir bölümü veya filmi bitirdiğinizde listenizi güncelleyin.';
	@override String disconnectConfirm({required Object service}) => '${service} bağlantısı kesilsin mi?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy, ${service} güncellemeyi durduracak. İstediğiniz zaman yeniden bağlanabilirsiniz.';
	@override String connectFailed({required Object service}) => '${service} ile bağlantı kurulamadı. Tekrar deneyin.';
	@override late final _Translations$services$names$tr names = _Translations$services$names$tr._(_root);
	@override late final _Translations$services$deviceCode$tr deviceCode = _Translations$services$deviceCode$tr._(_root);
	@override late final _Translations$services$oauthProxy$tr oauthProxy = _Translations$services$oauthProxy$tr._(_root);
	@override late final _Translations$services$libraryFilter$tr libraryFilter = _Translations$services$libraryFilter$tr._(_root);
}

// Path: addServer
class _Translations$addServer$tr extends Translations$addServer$en {
	_Translations$addServer$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get serverUrls => 'Sunucu URL\'leri';
	@override String get serverUrlsHelper => 'Virgülle ayrılmış birden fazla URL\'ye izin verilir.';
	@override String get findServer => 'Sunucu bul';
	@override String get username => 'Kullanıcı adı';
	@override String get password => 'Şifre';
	@override String get signIn => 'Giriş Yap';
	@override String get change => 'Değiştir';
	@override String get required => 'Gerekli';
	@override String couldNotReachServer({required Object error}) => 'Sunucuya ulaşılamadı: ${error}';
	@override String signInFailed({required Object error}) => 'Giriş başarısız: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Hızlı Bağlantı başarısız: ${error}';
	@override String get addPlexTitle => 'Plex ile Giriş Yap';
	@override String get pinExpired => 'Giriş yapmadan önce PIN süresi doldu. Lütfen tekrar deneyin.';
	@override String failedToRegisterAccount({required Object error}) => 'Hesap kaydı başarısız oldu: ${error}';
	@override String get addConnectionTitle => 'Bağlantı ekle';
	@override String addConnectionTitleScoped({required Object name}) => '${name} profiline ekle';
	@override String get signInWithPlexCard => 'Plex ile Giriş Yap';
	@override String get signInWithPlexCardSubtitle => 'Bu cihazı yetkilendirin. Paylaşılan sunucular eklenir.';
	@override String get signInWithPlexCardSubtitleScoped => 'Bir Plex hesabını yetkilendirin. Ev kullanıcıları profile dönüşür.';
	@override String get borrowFromAnotherProfile => 'Başka bir profilden ödünç al';
	@override String get borrowFromAnotherProfileSubtitle => 'Başka bir profilin bağlantısını yeniden kullanın. PIN korumalı profiller bir PIN gerektirir.';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$tr extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Oynat/Duraklat';
	@override String get volumeUp => 'Sesi Yükselt';
	@override String get volumeDown => 'Sesi Kıs';
	@override String seekForward({required Object seconds}) => 'İleri Sar (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Geri Sar (${seconds}s)';
	@override String get fullscreenToggle => 'Tam Ekranı Aç/Kapat';
	@override String get muteToggle => 'Sesi Aç/Kapat';
	@override String get subtitleToggle => 'Altyazıyı Aç/Kapat';
	@override String get audioTrackNext => 'Sonraki Ses Parçası';
	@override String get subtitleTrackNext => 'Sonraki Altyazı Parçası';
	@override String get chapterNext => 'Sonraki Kısım';
	@override String get chapterPrevious => 'Önceki Kısım';
	@override String get episodeNext => 'Sonraki Bölüm';
	@override String get episodePrevious => 'Önceki Bölüm';
	@override String get speedIncrease => 'Hızı Artır';
	@override String get speedDecrease => 'Hızı Azalt';
	@override String get speedReset => 'Hızı Sıfırla';
	@override String get zoomIn => 'Yakınlaştır';
	@override String get zoomOut => 'Uzaklaştır';
	@override String get zoomReset => 'Yakınlaştırmayı Sıfırla';
	@override String get subSeekNext => 'Sonraki Altyazıya Sar';
	@override String get subSeekPrev => 'Önceki Altyazıya Sar';
	@override String get shaderToggle => 'Gölgelendiricileri Aç/Kapat';
	@override String get skipMarker => 'Jenerik/Emeği Geçenleri Atla';
	@override String get screenshot => 'Ekran Görüntüsü Al';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$tr extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 veya daha yenisini gerektirir';
	@override String get iosVersion => 'iOS 15.0 veya daha yenisini gerektirir';
	@override String get permissionDisabled => 'Pencere içinde pencere devre dışı. Sistem ayarlarından etkinleştirin.';
	@override String get notSupported => 'Cihaz pencere içinde pencere modunu desteklemiyor';
	@override String get voSwitchFailed => 'Pencere içinde pencere için video çıkışı değiştirilemedi';
	@override String get failed => 'Pencere içinde pencere başlatılamadı';
	@override String unknown({required Object error}) => 'Bir hata oluştu: ${error}';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$tr extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Önerilenler';
	@override String get browse => 'Göz At';
	@override String get collections => 'Koleksiyonlar';
	@override String get playlists => 'Oynatma Listeleri';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$tr extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruplama';
	@override String get all => 'Tümü';
	@override String get movies => 'Filmler';
	@override String get shows => 'TV Dizileri';
	@override String get seasons => 'Sezonlar';
	@override String get episodes => 'Bölümler';
	@override String get artists => 'Sanatçılar';
	@override String get albums => 'Albümler';
	@override String get tracks => 'Parçalar';
	@override String get folders => 'Klasörler';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$tr extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Tür';
	@override String get year => 'Yıl';
	@override String get contentRating => 'İçerik Derecelendirmesi';
	@override String get tag => 'Etiket';
	@override String get unwatched => 'İzlenmemiş';
	@override String get unplayed => 'Oynatılmamış';
	@override String get favorites => 'Favoriler';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$tr extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Başlık';
	@override String get dateAdded => 'Ekleme Tarihi';
	@override String get releaseDate => 'Yayınlanma Tarihi';
	@override String get rating => 'Puan';
	@override String get communityRating => 'Topluluk Puanı';
	@override String get criticRating => 'Eleştirmen Puanı';
	@override String get userRating => 'Kullanıcı Puanı';
	@override String get datePlayed => 'Oynatılma Tarihi';
	@override String get playCount => 'Oynatma Sayısı';
	@override String get productionYear => 'Yapım Yılı';
	@override String get runtime => 'Çalışma Süresi';
	@override String get officialRating => 'Resmi Puan';
	@override String get premiereDate => 'Prömiyer Tarihi';
	@override String get startDate => 'Başlangıç Tarihi';
	@override String get airTime => 'Yayın Zamanı';
	@override String get studio => 'Stüdyo';
	@override String get random => 'Rastgele';
	@override String get dateShared => 'Paylaşılma Tarihi';
	@override String get latestEpisodeAirDate => 'Son Bölüm Yayın Tarihi';
	@override String get lastEpisodeDateAdded => 'Eklenen Son Bölüm Tarihi';
}

// Path: explore.rows
class _Translations$explore$rows$tr extends Translations$explore$rows$en {
	_Translations$explore$rows$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'İzleme Listesi';
	@override String get recommendedMovies => 'Önerilen Filmler';
	@override String get recommendedShows => 'Önerilen Diziler';
	@override String get trendingMovies => 'Trend Filmler';
	@override String get trendingShows => 'Trend Diziler';
	@override String get popularMovies => 'Popüler Filmler';
	@override String get popularShows => 'Popüler Diziler';
	@override String get trendingAnime => 'Trend Animeler';
	@override String get suggestedAnime => 'Önerilen Animeler';
	@override String get airingAnime => 'En İyi Yayınlanan Animeler';
	@override String get popularAnime => 'En Popüler Animeler';
	@override String get trending => 'Trendler';
	@override String get upcomingMovies => 'Gelecek Filmler';
	@override String get upcomingShows => 'Gelecek Diziler';
}

// Path: explore.status
class _Translations$explore$status$tr extends Translations$explore$status$en {
	_Translations$explore$status$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Yayınlanıyor';
	@override String get ended => 'Bitti';
	@override String get canceled => 'İptal Edildi';
	@override String get upcoming => 'Gelecek';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$tr extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Uygulamadan çıktığınızda indirmeler duracak';
	@override String get bannerDegraded => 'Arka plan indirmeleri sınırlı olabilir';
	@override String get bannerAction => 'Detaylar';
	@override String get sheetTitle => 'Arka plan indirmeleri engellendi';
	@override String get sheetTitleDegraded => 'Arka plan indirmeleri sınırlı olabilir';
	@override String get sheetIntro => 'Android, Plezy\'nin arka planda güvenilir şekilde indirme yapmasını engelliyor.';
	@override String get sheetIntroDegraded => 'Cihazınız, Plezy\'nin arka planda ne zaman indirme yapabileceğini sınırlıyor.';
	@override String get reasonBackgroundRestricted => 'Plezy\'nin arka plan kullanımı kısıtlanmış. Pil veya arka plan kullanımını "Kısıtlanmamış" olarak ayarlayın.';
	@override String get reasonStandbyRestricted => 'Android, Plezy\'yi kısıtlı bekleme durumuna aldı. Pil kullanımını "Kısıtlanmamış" olarak ayarlayın.';
	@override String get reasonDownloadChannelBlocked => 'İndirme bildirimleri kapalı; bu nedenle ilerleme ve kontroller kullanılamayabilir.';
	@override String get reasonNotificationsDisabled => 'Bildirimler kapalı. Android 13 ve sonraki sürümlerde uzun arka plan indirmeleri için gereklidir.';
	@override String get reasonDataSaver => 'Veri Tasarrufu açık; bu, mobil veride arka plan indirmelerini engeller. Wi-Fi üzerinde indirmeler yine de çalışır.';
	@override String get reasonOemUnknown => 'Plezy arka plandayken indirmeler tekrar tekrar durdu. Plezy\'nin pil veya arka plan kullanım ayarlarını kontrol edin.';
	@override String get openSettings => 'Ayarları aç';
	@override String get stillNotWorking => 'Cihaza özel yardım';
	@override String get stillNotWorkingDescription => 'Cihazınıza yönelik adımlara bakın veya sorun sürerse Ayarlar › Günlükleri Görüntüle bölümünden bir günlük gönderin.';
	@override String get dialogTitle => 'İndirmeler tamamlanmayabilir';
	@override String get dialogDownloadAnyway => 'Yine de indir';
	@override String get dialogFixFirst => 'Önce bunu düzelt';
	@override String get statusTile => 'Arka plan indirmeleri';
	@override String get statusOk => 'Arka planda çalışmasına izin veriliyor';
	@override String get statusBlocked => 'Sistem ayarları tarafından engellendi';
	@override String get statusDegraded => 'Sistem ayarları tarafından sınırlandırıldı';
	@override String get statusUnknown => 'Henüz kontrol edilmedi';
	@override String get settingsUnavailable => 'Bu cihazda sistem ayarları açılamadı';
	@override String get linkUnavailable => 'Bu cihazda dontkillmyapp.com açılamadı';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$tr extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Uzaktan kumanda sunucusu başlatılıyor...';
	@override String get hostAddress => 'Ana Bilgisayar Adresi';
	@override String get connected => 'Bağlandı';
	@override String get serverRunning => 'Uzaktan kumanda sunucusu aktif';
	@override String get serverStopped => 'Uzaktan kumanda sunucusu durduruldu';
	@override String get serverRunningDescription => 'Ağınızdaki mobil cihazlar bu uygulamaya bağlanabilir';
	@override String get serverStoppedDescription => 'Mobil cihazların bağlanmasına izin vermek için sunucuyu başlatın';
	@override String get usePhoneToControl => 'Bu uygulamayı kontrol etmek için mobil cihazınızı kullanın';
	@override String get startServer => 'Sunucuyu Başlat';
	@override String get stopServer => 'Sunucuyu Durdur';
	@override String get minimize => 'Küçült';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$tr extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Aynı Plex hesabına sahip Plezy cihazları burada görünür';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Bağlanılıyor...';
	@override String get searchingForDevices => 'Cihazlar aranıyor...';
	@override String get noDevicesFound => 'Ağınızda cihaz bulunamadı';
	@override String get noDevicesHint => 'Masaüstünde Plezy\'yi açın ve aynı Wi-Fi ağını kullanın';
	@override String get availableDevices => 'Kullanılabilir Cihazlar';
	@override String get manualConnection => 'Manuel Bağlantı';
	@override String get cryptoInitFailed => 'Güvenli bağlantı başlatılamadı. Önce Plex\'e giriş yapın.';
	@override String get validationHostRequired => 'Lütfen ana bilgisayar adresini girin';
	@override String get validationHostFormat => 'Biçim IP:port şeklinde olmalıdır (ör. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Bağlantı zaman aşımına uğradı. Her iki cihazda da aynı ağı kullanın.';
	@override String get sessionNotFound => 'Cihaz bulunamadı. Plezy\'nin ana bilgisayarda çalıştığından emin olun.';
	@override String get authFailed => 'Kimlik doğrulama başarısız oldu. Her iki cihazın da aynı Plex hesabına ihtiyacı var.';
	@override String failedToConnect({required Object error}) => 'Bağlantı başarısız: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$tr extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Uzaktan kumanda oturumundan ayrılmak istiyor musunuz?';
	@override String get reconnecting => 'Yeniden bağlanılıyor...';
	@override String attemptOf({required Object current}) => 'Deneme ${current} / 5';
	@override String get retryNow => 'Şimdi Tekrar Dene';
	@override String get tabRemote => 'Kumanda';
	@override String get tabPlay => 'Oynat';
	@override String get tabMore => 'Daha Fazla';
	@override String get menu => 'Menü';
	@override String get tabNavigation => 'Sekme Gezinmesi';
	@override String get tabDiscover => 'Keşfet';
	@override String get tabLibraries => 'Kitaplıklar';
	@override String get tabSearch => 'Ara';
	@override String get tabDownloads => 'İndirmeler';
	@override String get tabSettings => 'Ayarlar';
	@override String get previous => 'Önceki';
	@override String get playPause => 'Oynat/Duraklat';
	@override String get next => 'Sonraki';
	@override String get seekBack => 'Geri Sar';
	@override String get stop => 'Durdur';
	@override String get seekForward => 'İleri Sar';
	@override String get volume => 'Ses';
	@override String get volumeDown => 'Kıs';
	@override String get volumeUp => 'Aç';
	@override String get fullscreen => 'Tam Ekran';
	@override String get subtitles => 'Altyazılar';
	@override String get audio => 'Ses';
	@override String get searchHint => 'Masaüstünde ara...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$tr extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Ağ arabirimi bulunamadı';
	@override String get authenticationFailed => 'Kimlik doğrulama başarısız oldu';
	@override String serverStartFailed({required Object error}) => 'Uzaktan kumanda sunucusu başlatılamadı: ${error}';
	@override String commandFailed({required Object error}) => 'Uzaktan komut gönderilemedi: ${error}';
	@override String get joinTimedOut => 'Oturuma katılma zaman aşımına uğradı';
	@override String get failedToConnectAnyAddress => 'Hiçbir adrese bağlanılamadı';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts} denemeden sonra bağlantı kesildi';
	@override String get connectionLost => 'Bağlantı kesildi';
}

// Path: services.names
class _Translations$services$names$tr extends Translations$services$names$en {
	_Translations$services$names$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$tr extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy\'yi ${service} üzerinde etkinleştirin';
	@override String body({required Object url}) => '${url} adresini ziyaret edin ve bu kodu girin:';
	@override String openToActivate({required Object service}) => 'Etkinleştirmek için ${service} servisini açın';
	@override String get copyCode => 'Etkinleştirme kodunu kopyala';
	@override String get waitingForAuthorization => 'Yetkilendirme bekleniyor…';
	@override String get codeCopied => 'Kod kopyalandı';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$tr extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} servisine giriş yapın';
	@override String get body => 'Bu QR kodunu tarayın veya URL\'yi herhangi bir cihazda açın.';
	@override String openToSignIn({required Object service}) => 'Giriş yapmak için ${service} servisini açın';
	@override String get copyUrl => 'Giriş URL\'sini kopyala';
	@override String get urlCopied => 'URL kopyalandı';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$tr extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kitaplık filtresi';
	@override String get subtitleAllSyncing => 'Tüm kitaplıklar eşitleniyor';
	@override String get subtitleNoneSyncing => 'Hiçbir şey eşitlenmiyor';
	@override String subtitleBlocked({required Object count}) => '${count} engellendi';
	@override String subtitleAllowed({required Object count}) => '${count} izin verildi';
	@override String get mode => 'Filtre modu';
	@override String get modeBlacklist => 'Kara Liste';
	@override String get modeWhitelist => 'Beyaz Liste';
	@override String get modeHintBlacklist => 'Aşağıda işaretlenenler dışındaki tüm kitaplıkları eşitle.';
	@override String get modeHintWhitelist => 'Yalnızca aşağıda işaretlenen kitaplıkları eşitle.';
	@override String get libraries => 'Kitaplıklar';
	@override String get noLibraries => 'Kitaplık bulunmuyor';
}

/// The flat map containing all translations for locale <tr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsTr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Plex ile Giriş Yap',
			'auth.showQRCode' => 'QR Kodunu Göster',
			'auth.authenticate' => 'Doğrula',
			'auth.authenticationTimeout' => 'Doğrulama zaman aşımına uğradı. Lütfen tekrar deneyin.',
			'auth.scanQRToSignIn' => 'Giriş yapmak için bu QR kodunu tarayın',
			'auth.waitingForAuth' => 'Doğrulama bekleniyor...\nTarayıcınızdan giriş yapın.',
			'auth.useBrowser' => 'Tarayıcı kullan',
			'auth.or' => 'veya',
			'auth.useQuickConnect' => 'Hızlı Bağlantıyı Kullan',
			'auth.quickConnectInstructions' => 'Jellyfin\'de Hızlı Bağlantı\'yı açın ve bu kodu girin.',
			'auth.quickConnectWaiting' => 'Onay bekleniyor…',
			'auth.quickConnectCancel' => 'İptal',
			'auth.quickConnectExpired' => 'Hızlı Bağlantı süresi doldu. Tekrar deneyin.',
			'auth.localDataRecoveryRequired' => 'Plezy yerel giriş ve bekleyen oynatma verilerini güvenli bir şekilde kurtaramadı. Lütfen tekrar giriş yapın.',
			'common.cancel' => 'İptal',
			'common.save' => 'Kaydet',
			'common.close' => 'Kapat',
			'common.clear' => 'Temizle',
			'common.reset' => 'Sıfırla',
			'common.later' => 'Daha Sonra',
			'common.submit' => 'Gönder',
			'common.confirm' => 'Onayla',
			'common.retry' => 'Tekrar Dene',
			'common.logout' => 'Çıkış Yap',
			'common.unknown' => 'Bilinmiyor',
			'common.refresh' => 'Yenile',
			'common.yes' => 'Evet',
			'common.no' => 'Hayır',
			'common.delete' => 'Sil',
			'common.edit' => 'Düzenle',
			'common.shuffle' => 'Karıştır',
			'common.addTo' => 'Ekle...',
			'common.createNew' => 'Yeni Oluştur',
			'common.connect' => 'Bağlan',
			'common.disconnect' => 'Bağlantıyı Kes',
			'common.play' => 'Oynat',
			'common.pause' => 'Duraklat',
			'common.resume' => 'Devam Et',
			'common.error' => 'Hata',
			'common.search' => 'Ara',
			'common.home' => 'Ana Sayfa',
			'common.back' => 'Geri',
			'common.settings' => 'Ayarlar',
			'common.mute' => 'Sesi Kapat',
			'common.ok' => 'Tamam',
			'common.off' => 'Kapalı',
			'common.seasonNumber' => ({required Object number}) => 'Sezon ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Bölüm ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Kısım ${number}',
			'common.reconnect' => 'Yeniden Bağlan',
			'common.viewAll' => 'Tümünü Gör',
			'common.checkingNetwork' => 'Ağ kontrol ediliyor...',
			'common.loadingServers' => 'Sunucular yükleniyor...',
			'common.connectingToServers' => 'Sunuculara bağlanılıyor...',
			'common.startingOfflineMode' => 'Çevrimdışı mod başlatılıyor...',
			'common.loading' => 'Yükleniyor...',
			'common.fullscreen' => 'Tam Ekran',
			'common.exitFullscreen' => 'Tam Ekrandan Çık',
			'common.pressBackAgainToExit' => 'Çıkmak için tekrar geri tuşuna basın',
			'screens.licenses' => 'Lisanslar',
			'screens.switchProfile' => 'Profil Değiştir',
			'screens.subtitleStyling' => 'Altyazı Biçimlendirmesi',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Günlükler',
			'update.available' => 'Güncelleme Mevcut',
			'update.versionAvailable' => ({required Object version}) => 'Sürüm ${version} kullanılabilir',
			'update.currentVersion' => ({required Object version}) => 'Mevcut: ${version}',
			'update.skipVersion' => 'Bu Sürümü Atla',
			'update.viewRelease' => 'Sürümü Görüntüle',
			'update.latestVersion' => 'En son sürümü kullanıyorsunuz',
			'update.checkFailed' => 'Güncellemeler kontrol edilemedi',
			'settings.title' => 'Ayarlar',
			'settings.supportDeveloper' => 'Plezy\'yi Destekleyin',
			'settings.supportDeveloperDescription' => 'Geliştirmeyi fonlamak için Liberapay üzerinden bağış yapın',
			'settings.language' => 'Dil',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Görünüm',
			'settings.videoPlayback' => 'Video Oynatma',
			'settings.videoPlaybackDescription' => 'Oynatma davranışını yapılandırın',
			'settings.advanced' => 'Gelişmiş',
			'settings.episodePosterMode' => 'Bölüm Afiş Stili',
			'settings.seriesPoster' => 'Dizi Afişi',
			'settings.seasonPoster' => 'Sezon Afişi',
			'settings.episodeThumbnail' => 'Küçük Resim',
			'settings.showHeroSectionDescription' => 'Ana ekranda öne çıkan içerik atlıkarıncasını göster',
			'settings.secondsLabel' => 'Saniye',
			'settings.minutesLabel' => 'Dakika',
			'settings.secondsShort' => 'sn',
			'settings.minutesShort' => 'dk',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Süre girin (${min}-${max})',
			'settings.systemTheme' => 'Sistem',
			'settings.lightTheme' => 'Açık',
			'settings.darkTheme' => 'Koyu',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Kitaplık Yoğunluğu',
			'settings.compact' => 'Sıkışık',
			'settings.comfortable' => 'Rahat',
			'settings.tvCornerSpotlightBackdrop' => 'Köşe Öne Çıkan Arka Plan',
			'settings.tvCornerSpotlightBackdropDescription' => 'Arka planı ekranı kaplamak yerine sağ üst köşede göster',
			'settings.viewMode' => 'Görünüm Modu',
			'settings.gridView' => 'Izgara',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Öne Çıkan Bölümünü Göster',
			'settings.continueWatchingAction' => 'İzlemeye Devam Et Eylemi',
			'settings.continueWatchingPlay' => 'Oynat',
			'settings.continueWatchingDetails' => 'Detayları Aç',
			'settings.episodeAction' => 'Bölüm Eylemi',
			'settings.episodePlay' => 'Oynat',
			'settings.episodeDetails' => 'Detayları Aç',
			'settings.useGlobalHubs' => 'Ana Sayfa Düzenini Kullan',
			'settings.useGlobalHubsDescription' => 'Birleştirilmiş ana sayfa bölümlerini göster. Aksi takdirde kitaplık önerilerini kullanır.',
			'settings.showServerNameOnHubs' => 'Bölümlerde Sunucu Adını Göster',
			'settings.showServerNameOnHubsDescription' => 'Bölüm başlıklarında her zaman sunucu adlarını göster.',
			'settings.groupLibrariesByServer' => 'Kitaplıkları Sunucuya Göre Grupla',
			'settings.groupLibrariesByServerDescription' => 'Yan menü kitaplıklarını her medya sunucusunun altında grupla.',
			'settings.alwaysKeepSidebarOpen' => 'Yan Menüyü Her Zaman Açık Tut',
			'settings.alwaysKeepSidebarOpenDescription' => 'Yan menü genişletilmiş kalır ve içerik alanı buna göre ayarlanır',
			'settings.showUnwatchedCount' => 'İzlenmemiş Sayısını Göster',
			'settings.showUnwatchedCountDescription' => 'Dizilerde ve sezonlarda izlenmemiş bölüm sayısını göster',
			'settings.showEpisodeNumberOnCards' => 'Kartlarda Bölüm Numarasını Göster',
			'settings.showEpisodeNumberOnCardsDescription' => 'Bölüm kartlarında sezon ve bölüm numarasını göster',
			'settings.showSeasonPostersOnTabs' => 'Sekmelerde Sezon Afişlerini Göster',
			'settings.showSeasonPostersOnTabsDescription' => 'Her sezonun afişini sekmesinin üzerinde göster',
			'settings.tvFullCardLayout' => 'Tam TV Kartları',
			'settings.tvFullCardLayoutDescription' => 'Oyuncu isimleri üzerinde katmanlanmış yalnızca görsel içeren TV kartları kullan',
			'settings.focusGlow' => 'Odak Parıltısı',
			'settings.focusGlowDescription' => 'Odaklanılan kartın etrafına hafif bir parıltı çiz',
			'settings.visualEffects' => 'Görsel Efektler',
			'settings.visualEffectsAuto' => 'Otomatik',
			'settings.visualEffectsAutoDescription' => 'Düşük güçlü cihazlarda efektleri otomatik olarak azalt',
			'settings.visualEffectsFull' => 'Tam',
			'settings.visualEffectsReduced' => 'Azaltılmış',
			'settings.visualEffectsReducedDescription' => 'Daha az animasyon ve daha düşük çözünürlüklü görseller',
			'settings.hideSpoilers' => 'İzlenmeyen Bölümler İçin Sürpriz Bozanları Gizle',
			'settings.hideSpoilersDescription' => 'İzlenmeyen bölümler için küçük resimleri ve açıklamaları bulanıklaştır',
			'settings.playerBackend' => 'Oynatıcı Altyapısı',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Donanım Çözme',
			'settings.hardwareDecodingDescription' => 'Mümkün olduğunda donanım hızlandırmasını kullan',
			'settings.bufferSize' => 'Arabellek Boyutu',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Otomatik (Önerilen)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB bellek mevcut. ${size}MB arabellek oynatmayı etkileyebilir.',
			'settings.defaultQualityTitle' => 'Varsayılan Kalite',
			'settings.musicQualityTitle' => 'Müzik Kalitesi',
			'settings.subtitleStyling' => 'Altyazı Biçimlendirmesi',
			'settings.subtitleStylingDescription' => 'Altyazı görünümünü özelleştirin',
			'settings.smallSkipDuration' => 'Küçük Atlama Süresi',
			'settings.largeSkipDuration' => 'Büyük Atlama Süresi',
			'settings.rewindOnResume' => 'Devam Ederken Geri Sar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} saniye',
			'settings.defaultSleepTimer' => 'Varsayılan Uyku Zamanlayıcısı',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} dakika',
			'settings.rememberTrackSelections' => 'Dizi/film başına ses/altyazı seçimlerini hatırla',
			'settings.rememberTrackSelectionsDescription' => 'İçerik başına ses ve altyazı tercihlerini hatırla',
			'settings.followServerTrackSelections' => 'Sunucunun bölüm başına parça seçimlerini kullan',
			'settings.followServerTrackSelectionsDescription' => 'Bölüm değiştiğinde geçerli seçimi taşımak yerine sunucuda seçilen ses ve altyazıyı uygula',
			'settings.showChapterMarkersOnTimeline' => 'Zaman çubuğunda kısım işaretçilerini göster',
			'settings.showChapterMarkersOnTimelineDescription' => 'Zaman çubuğunu kısım sınırlarına göre böl',
			'settings.clickVideoTogglesPlayback' => 'Oynat/duraklat için videoya tıkla',
			'settings.clickVideoTogglesPlaybackDescription' => 'Kontrolleri göstermek yerine oynatmak/duraklatmak için videoya tıkla.',
			'settings.videoPlayerControls' => 'Video Oynatıcı Kontrolleri',
			'settings.keyboardShortcuts' => 'Klavye Kısayolları',
			'settings.keyboardShortcutsDescription' => 'Klavye kısayollarını özelleştirin',
			'settings.videoPlayerNavigation' => 'Video Oynatıcı Gezinmesi',
			'settings.videoPlayerNavigationDescription' => 'Video oynatıcı kontrollerinde gezinmek için yön tuşlarını kullanın',
			'settings.watchTogetherRelay' => 'Birlikte İzle Aktarıcısı (Relay)',
			'settings.watchTogetherRelayDescription' => 'Özel bir aktarıcı ayarlayın. Herkes aynı sunucuyu kullanmalıdır.',
			'settings.watchTogetherRelayHint' => 'https://ornek-aktarici.com',
			'settings.watchTogetherRelayInvalid' => 'Geçerli bir HTTP veya HTTPS aktarıcı adresi girin.',
			'settings.crashReporting' => 'Çökme Bildirimi',
			'settings.crashReportingDescription' => 'Uygulamanın geliştirilmesine yardımcı olmak için çökme raporları gönder',
			'settings.debugLogging' => 'Hata Ayıklama Günlüğü',
			'settings.debugLoggingDescription' => 'Sorun giderme için ayrıntılı günlük kaydını etkinleştir',
			'settings.viewLogs' => 'Günlükleri Görüntüle',
			'settings.viewLogsDescription' => 'Uygulama günlüklerini görüntüle',
			'settings.clearImageCache' => 'Görsel Önbelleğini Temizle',
			'settings.clearImageCacheDescription' => 'Önbelleğe alınan görselleri ve küçük resimleri temizler. Tekrar indirilene kadar görseller daha yavaş yüklenebilir.',
			'settings.clearImageCacheSuccess' => 'Görsel önbelleği başarıyla temizlendi',
			'settings.resetSettings' => 'Ayarları Sıfırla',
			'settings.resetSettingsDescription' => 'Varsayılan ayarları geri yükler. Bu işlem geri alınamaz.',
			'settings.resetSettingsSuccess' => 'Ayarlar başarıyla sıfırlandı',
			'settings.backup' => 'Yedekle',
			'settings.exportSettings' => 'Ayarları Dışa Aktar',
			'settings.exportSettingsDescription' => 'Tercihlerinizi bir dosyaya kaydedin',
			'settings.exportSettingsSuccess' => 'Ayarlar dışa aktarıldı',
			'settings.importSettings' => 'Ayarları İçe Aktar',
			'settings.importSettingsDescription' => 'Tercihleri bir dosyadan geri yükleyin',
			'settings.importSettingsConfirm' => 'Bu işlem mevcut ayarlarınızın üzerine yazacak. Devam edilsin mi?',
			'settings.importSettingsSuccess' => 'Ayarlar içe aktarıldı',
			'settings.importSettingsInvalidFile' => 'Bu dosya geçerli bir Plezy ayar dosyası değil',
			'settings.importSettingsNoUser' => 'Ayarları içe aktarmadan önce giriş yapın',
			'settings.shortcutsReset' => 'Kısayollar varsayılana sıfırlandı',
			'settings.about' => 'Hakkında',
			'settings.aboutDescription' => 'Uygulama bilgileri ve lisanslar',
			'settings.updates' => 'Güncellemeler',
			'settings.updateAvailable' => 'Güncelleme Mevcut',
			'settings.checkForUpdates' => 'Güncellemeleri Kontrol Et',
			'settings.autoCheckUpdatesOnStartup' => 'Açılışta güncellemeleri otomatik kontrol et',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Açılışta bir güncelleme olduğunda bildir',
			'settings.validationErrorEnterNumber' => 'Lütfen geçerli bir sayı girin',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Süre ${min} ile ${max} ${unit} arasında olmalıdır',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Kısayol zaten ${action} eylemine atanmış',
			'settings.shortcutUpdated' => ({required Object action}) => '${action} için kısayol güncellendi',
			'settings.saveFailed' => 'Değişiklikler kaydedilemedi. Tekrar deneyin.',
			'settings.autoSkip' => 'Otomatik Atla',
			'settings.autoSkipIntro' => 'Jeneriği Otomatik Atla',
			'settings.autoSkipIntroDescription' => 'Kaç saniye sonra jenerik işaretçilerini otomatik atla',
			'settings.autoSkipCredits' => 'Emeği Geçenleri Otomatik Atla',
			'settings.autoSkipCreditsDescription' => 'Emeği geçenleri otomatik atla ve sonraki bölümü oynat',
			'settings.forceSkipMarkerFallback' => 'Yedek İşaretçileri Zorla',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex işaretçileri olsa bile kısım başlığı kalıplarını kullan',
			'settings.autoSkipDelay' => 'Otomatik Atlama Gecikmesi',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Otomatik atlamadan önce ${seconds} saniye bekle',
			'settings.introPattern' => 'Jenerik İşaretçi Kalıbı',
			'settings.introPatternDescription' => 'Kısım başlıklarındaki jenerik işaretçilerini eşleştirmek için Regex kalıbı',
			'settings.creditsPattern' => 'Emeği Geçenler İşaretçi Kalıbı',
			'settings.creditsPatternDescription' => 'Kısım başlıklarındaki emeği geçenler işaretçilerini eşleştirmek için Regex kalıbı',
			'settings.invalidRegex' => 'Geçersiz düzenli ifade (Regex)',
			'settings.regex' => 'Düzenli ifade (Regex)',
			'settings.downloads' => 'İndirmeler',
			'settings.downloadLocationDescription' => 'İndirilen içeriğin nerede saklanacağını seçin',
			'settings.downloadLocationDefault' => 'Varsayılan (Uygulama Depolaması)',
			'settings.downloadLocationCustom' => 'Özel Konum',
			'settings.selectFolder' => 'Klasör Seç',
			'settings.resetToDefault' => 'Varsayılana Sıfırla',
			'settings.currentPath' => ({required Object path}) => 'Mevcut: ${path}',
			'settings.downloadLocationChanged' => 'İndirme konumu değiştirildi',
			'settings.downloadLocationReset' => 'İndirme konumu varsayılana sıfırlandı',
			'settings.downloadLocationInvalid' => 'Seçilen klasöre yazılamıyor',
			'settings.downloadLocationPickerUnavailable' => 'Klasör seçimi bu cihazda kullanılamıyor',
			'settings.downloadOnWifiOnly' => 'Yalnızca Wi-Fi üzerinden indir',
			'settings.downloadOnWifiOnlyDescription' => 'Hücresel verideyken indirmeleri engelle',
			'settings.autoRemoveWatchedDownloads' => 'İzlenen indirmeleri otomatik kaldır',
			'settings.autoRemoveWatchedDownloadsDescription' => 'İzlenen indirmeleri otomatik olarak sil',
			'settings.cellularDownloadBlocked' => 'Hücresel veride indirmeler engellendi. Wi-Fi kullanın veya ayarı değiştirin.',
			'settings.maxVolume' => 'Maksimum Ses',
			'settings.maxVolumeDescription' => 'Kısık sesli medyalar için %100\'ün üzerinde ses yükseltmeye izin ver',
			'settings.maxVolumePercent' => ({required Object percent}) => '%${percent}',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord\'da ne izlediğinizi gösterin',
			'settings.services' => 'Servisler',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr ve daha fazlasını bağlayın',
			'settings.manageLibrariesDescription' => 'Kitaplıkları yeniden sıralayın ve gizleyin',
			'settings.companionRemoteServer' => 'Yardımcı Uzaktan Kumanda Sunucusu',
			'settings.companionRemoteServerDescription' => 'Ağınızdaki mobil cihazların bu uygulamayı kontrol etmesine izin verin',
			'settings.autoPip' => 'Otomatik Pencere İçinde Pencere (PiP)',
			'settings.autoPipDescription' => 'Oynatma sırasında uygulamadan çıktığınızda otomatik olarak pencere içinde pencere moduna geç',
			'settings.matchContentFrameRate' => 'İçerik Kare Hızını Eşitle',
			'settings.matchContentFrameRateDescription' => 'Ekran yenileme hızını video içeriğiyle eşitle',
			'settings.matchRefreshRate' => 'Yenileme Hızını Eşitle',
			'settings.matchRefreshRateDescription' => 'Tam ekranda ekran yenileme hızını eşitle',
			'settings.matchDynamicRange' => 'Dinamik Aralığı Eşitle',
			'settings.matchDynamicRangeDescription' => 'HDR içerik için HDR\'yi aç, ardından SDR\'ye geri dön',
			'settings.displaySwitchDelay' => 'Ekran Değiştirme Gecikmesi',
			'settings.tunneledPlayback' => 'Tünelli Oynatma',
			'settings.tunneledPlaybackDescription' => 'Video tünellemeyi kullan. HDR oynatmada siyah ekran görünüyorsa devre dışı bırakın.',
			'settings.audioPassthrough' => 'Ses Doğrudan Geçişi (Passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS sesleri yeniden kodlamadan alıcınıza veya TV\'nize göndererek çevreleyen sesi korur. Ses gelmiyorsa kapatın.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Atmos dahil Dolby Digital Plus için Apple\'ın yerel Dolby çözücüsünü kullanın. DTS ve TrueHD yine çok kanallı PCM olarak oynatılır. Ses gelmiyorsa kapatın.',
			'settings.audioDownmix' => 'Stereo\'ya Dönüştür (Downmix)',
			'settings.audioDownmixDescription' => 'Çevreleyen sesi stereo hoparlörler veya kulaklıklar için iki kanala dönüştürür',
			'settings.downmixCenterBoost' => 'Merkez Kanal Yükseltme',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Yükseltme (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Dönüştürmede Sesi Normalleştir',
			'settings.audioDownmixNormalizeDescription' => 'Ses patlamalarını önlemek için karışımı düşürün. Orijinal sesi korumak için kapatın (yüksek sesli sahnelerde bozulma yapabilir).',
			'settings.atmosDiagnostics' => 'Atmos Çıkış Testi',
			'settings.atmosDiagnosticsDescription' => 'Sistem oynatıcısı üzerinden test sinyalleri çalarak Dolby Atmos çıkışını teşhis edin',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos akışı',
			'settings.atmosTestHlsAtmosDescription' => 'Düzgün çalıştığı bilinen Dolby Atmos akışı. Alıcıda Dolby Atmos görünmelidir.',
			'settings.atmosTestHlsControl' => 'Apple çevreleyen ses akışı',
			'settings.atmosTestHlsControlDescription' => 'Atmos olmayan kontrol akışı. Alıcıda Atmos olmadan çevreleyen ses görünmelidir.',
			'settings.atmosTestRawStream' => 'Ham EAC3 akışı',
			'settings.atmosTestRawStreamDescription' => 'Test dosyasını aynen oynatıcı içi Atmos oynatımı gibi akış yapar. Test dosyası URL\'si gerektirir.',
			'settings.atmosTestRawFile' => 'Ham EAC3 dosyası',
			'settings.atmosTestRawFileDescription' => 'Test dosyasını bilinen bir uzunlukta oynatır. Test dosyası URL\'si gerektirir.',
			'settings.atmosTestAsbarNative' => 'Örnek arabellek işleyicisi (yerel)',
			'settings.atmosTestAsbarNativeDescription' => 'Dosyanın değiştirilmemiş sıkıştırılmış sesini doğrudan sistem işleyicisine iletir. Test dosyası URL\'si gerektirir.',
			'settings.atmosTestAsbarGenerated' => 'Örnek arabellek işleyicisi (yeniden oluşturulmuş)',
			'settings.atmosTestAsbarGeneratedDescription' => 'Aynısı, ancak ses tanımı oynatmanın oluşturduğu biçimde yeniden oluşturulur. Test dosyası URL\'si gerektirir.',
			'settings.atmosTestSessionMode' => 'Film oynatma oturumu modunu kullan',
			'settings.atmosTestSessionModeDescription' => 'Kapalı, Dolby\'nin belgelediği modu kullanır. Açık, oynatmanın daha önce kullandığı modu kullanır.',
			'settings.atmosTestShowRoutePicker' => 'AirPlay çıkışını seç',
			'settings.atmosTestHideRoutePicker' => 'AirPlay çıkış seçicisini gizle',
			'settings.atmosTestRoutePickerDescription' => 'Testi bir AirPlay alıcısına gönderir. Çözümlenen ses modunu yalnızca AirPlay bildirir.',
			'settings.atmosTestStop' => 'Testi durdur',
			'settings.atmosTestUrl' => 'Test dosyası URL\'si',
			'settings.atmosTestUrlDescription' => 'Ham bir .ec3 Dolby Atmos dosyasının HTTP URL\'si (ör. ffmpeg ile ayıklanmış)',
			'settings.atmosTestUrlMissing' => 'Önce test dosyası URL\'sini ayarlayın',
			'settings.atmosTestStatus' => 'Durum',
			'settings.dvConversionMode' => 'Dolby Vision Dönüştürme',
			'settings.dvConversionModeDescription' => 'ExoPlayer\'ın Dolby Vision Profile 7 dosyalarını nasıl işleyeceğini seçin.',
			'settings.dvConversionAuto' => 'Otomatik',
			'settings.dvConversionNative' => 'Yerel / Devre Dışı',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Cihaz yeteneği algılamasını ve normal geri çekilme davranışını kullan',
			'settings.dvConversionNativeDescription' => 'Yerel DV7\'yi zorla ve DV dönüştürme yeniden denemesini engelle',
			'settings.dvConversionDv81Description' => 'Dolby Vision profile 8.1\'e satır içi RPU dönüştürmeyi zorla',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision RPU/EL katmanlarını soy ve düz HEVC olarak sun',
			'settings.requireProfileSelectionOnOpen' => 'Uygulama açılışında profil sor',
			'settings.requireProfileSelectionOnOpenDescription' => 'Uygulama her açıldığında profil seçimini göster',
			'settings.forceTvMode' => 'TV modunu zorla',
			'settings.forceTvModeDescription' => 'TV düzenini zorla. Otomatik algılamayan cihazlar içindir. Yeniden başlatma gerektirir.',
			'settings.startInFullscreen' => 'Tam ekranda başlat',
			'settings.startInFullscreenDescription' => 'Plezy\'yi açılışta tam ekran modunda aç',
			'settings.exitFullscreenOnPlayerClose' => 'Oynatıcı kapandığında tam ekrandan çık',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Video oynatıcıyı kapatırken otomatik olarak tam ekrandan çık',
			'settings.autoHidePerformanceOverlay' => 'Performans Katmanını Otomatik Gizle',
			'settings.autoHidePerformanceOverlayDescription' => 'Performans katmanını oynatma kontrolleriyle birlikte soluklaştır',
			'settings.showNavBarLabels' => 'Gezinme Çubuğu Etiketlerini Göster',
			'settings.showNavBarLabelsDescription' => 'Gezinme çubuğu simgelerinin altında metin etiketlerini göster',
			'settings.startupSection' => 'Başlangıç Bölümü',
			'settings.liveTvDefaultFavorites' => 'Canlı TV\'de Favorileri Varsayılan Yap',
			'settings.liveTvDefaultFavoritesDescription' => 'Canlı TV açıldığında yalnızca favori kanalları göster',
			'settings.display' => 'Ekran',
			'settings.homeScreen' => 'Ana Ekran',
			'settings.navigation' => 'Gezinme',
			'settings.window' => 'Pencere',
			'settings.content' => 'İçerik',
			'settings.player' => 'Oynatıcı',
			'settings.subtitlesAndConfig' => 'Altyazılar ve Yapılandırma',
			'settings.seekAndTiming' => 'Sarılma ve Zamanlama',
			'settings.behavior' => 'Davranış',
			'search.hint' => 'Film, dizi, müzik ara...',
			'search.tryDifferentTerm' => 'Farklı bir arama terimi deneyin',
			'search.searchYourMedia' => 'Medyanızda arayın',
			'search.enterTitleActorOrKeyword' => 'Başlık, oyuncu veya anahtar kelime girin',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName} için Kısayol Ayarla',
			'hotkeys.clearShortcut' => 'Kısayolu temizle',
			'hotkeys.noShortcutSet' => 'Kısayol ayarlanmadı',
			'hotkeys.currentShortcut' => 'Mevcut kısayol:',
			'hotkeys.pressToRecord' => 'Kısayol kaydetmek için seçin',
			'hotkeys.recordingShortcut' => 'Şimdi kısayol tuşuna basın',
			'hotkeys.actions.playPause' => 'Oynat/Duraklat',
			'hotkeys.actions.volumeUp' => 'Sesi Yükselt',
			'hotkeys.actions.volumeDown' => 'Sesi Kıs',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'İleri Sar (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Geri Sar (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Tam Ekranı Aç/Kapat',
			'hotkeys.actions.muteToggle' => 'Sesi Aç/Kapat',
			'hotkeys.actions.subtitleToggle' => 'Altyazıyı Aç/Kapat',
			'hotkeys.actions.audioTrackNext' => 'Sonraki Ses Parçası',
			'hotkeys.actions.subtitleTrackNext' => 'Sonraki Altyazı Parçası',
			'hotkeys.actions.chapterNext' => 'Sonraki Kısım',
			'hotkeys.actions.chapterPrevious' => 'Önceki Kısım',
			'hotkeys.actions.episodeNext' => 'Sonraki Bölüm',
			'hotkeys.actions.episodePrevious' => 'Önceki Bölüm',
			'hotkeys.actions.speedIncrease' => 'Hızı Artır',
			'hotkeys.actions.speedDecrease' => 'Hızı Azalt',
			'hotkeys.actions.speedReset' => 'Hızı Sıfırla',
			'hotkeys.actions.zoomIn' => 'Yakınlaştır',
			'hotkeys.actions.zoomOut' => 'Uzaklaştır',
			'hotkeys.actions.zoomReset' => 'Yakınlaştırmayı Sıfırla',
			'hotkeys.actions.subSeekNext' => 'Sonraki Altyazıya Sar',
			'hotkeys.actions.subSeekPrev' => 'Önceki Altyazıya Sar',
			'hotkeys.actions.shaderToggle' => 'Gölgelendiricileri Aç/Kapat',
			'hotkeys.actions.skipMarker' => 'Jenerik/Emeği Geçenleri Atla',
			'hotkeys.actions.screenshot' => 'Ekran Görüntüsü Al',
			'fileInfo.title' => 'Dosya Bilgisi',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Ses',
			'fileInfo.subtitles' => 'Altyazılar',
			'fileInfo.file' => 'Dosya',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.resolution' => 'Çözünürlük',
			'fileInfo.bitrate' => 'Bit Hızı (Bitrate)',
			'fileInfo.frameRate' => 'Kare Hızı',
			'fileInfo.aspectRatio' => 'En Boy Oranı',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Bit Derinliği',
			'fileInfo.colorSpace' => 'Renk Alanı',
			'fileInfo.colorRange' => 'Renk Aralığı',
			'fileInfo.colorPrimaries' => 'Ana Renkler',
			'fileInfo.chromaSubsampling' => 'Renk Alt Örneklemesi',
			'fileInfo.channels' => 'Kanallar',
			'fileInfo.overallBitrate' => 'Genel Bit Hızı',
			'fileInfo.path' => 'Yol',
			'fileInfo.size' => 'Boyut',
			'fileInfo.container' => 'Kapsayıcı',
			'fileInfo.duration' => 'Süre',
			'fileInfo.optimizedForStreaming' => 'Akış İçin Optimize Edilmiş',
			'fileInfo.has64bitOffsets' => '64-bit Ofsetler',
			'mediaMenu.markAsWatched' => 'İzlendi Olarak İşaretle',
			'mediaMenu.markAsUnwatched' => 'İzlenmedi Olarak İşaretle',
			'mediaMenu.removeFromContinueWatching' => 'İzlemeye Devam Et\'ten Kaldır',
			'mediaMenu.viewDetails' => 'Detayları görüntüle',
			'mediaMenu.goToSeries' => 'Diziye git',
			'mediaMenu.shufflePlay' => 'Karışık Oynat',
			'mediaMenu.shuffleNotAvailableOffline' => 'Karışık oynatma çevrimdışıyken kullanılamaz',
			'mediaMenu.fileInfo' => 'Dosya Bilgisi',
			'mediaMenu.deleteFromServer' => 'Sunucudan sil',
			'mediaMenu.confirmDelete' => 'Bu medya ve dosyaları sunucunuzdan silinsin mi?',
			'mediaMenu.deleteMultipleWarning' => 'Bu işlem tüm bölümleri ve dosyalarını içerir.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Medya ögesi başarıyla silindi',
			'mediaMenu.mediaFailedToDelete' => 'Medya ögesi silinemedi',
			'mediaMenu.rate' => 'Oyla',
			'mediaMenu.playFromBeginning' => 'Baştan Oynat',
			'mediaMenu.playVersion' => 'Sürümü Oynat...',
			'rateSheet.title' => 'Oyla',
			'rateSheet.server' => 'Sunucu',
			'rateSheet.favorite' => 'Favori',
			'rateSheet.favorited' => 'Favorilere Eklendi',
			'rateSheet.saved' => 'Kaydedildi',
			'rateSheet.notAvailable' => 'Eşleşme bulunamadı',
			'rateSheet.noConnectedServices' => 'Orada oylamak için Ayarlar\'dan bir servis bağlayın.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV dizisi',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'izlendi',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '%${percent} izlendi',
			'accessibility.mediaCardUnwatched' => 'izlenmedi',
			'accessibility.tapToPlay' => 'Oynatmak için dokunun',
			'accessibility.decrease' => 'Azalt',
			'accessibility.increase' => 'Artır',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} değerini azalt',
			'accessibility.increaseValue' => ({required Object label}) => '${label} değerini artır',
			'accessibility.hue' => 'Renk Tonu',
			'accessibility.saturation' => 'Doygunluk',
			'accessibility.brightness' => 'Parlaklık',
			'accessibility.hexColor' => 'Hex rengi',
			'accessibility.expandText' => 'Metni genişlet',
			'accessibility.collapseText' => 'Metni daralt',
			'accessibility.alphabetNavigation' => 'Alfabe gezinmesi',
			'accessibility.alphabetScrollHint' => 'Harfe göre gitmek için yukarı veya aşağı kaydırın',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Satır ${row} / ${rowCount}, sütun ${column} / ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Satır ${row} / ${rowCount}',
			'tooltips.shufflePlay' => 'Karışık oynat',
			'tooltips.playTrailer' => 'Fragmanı oynat',
			'tooltips.markAsWatched' => 'İzlendi olarak işaretle',
			'tooltips.markAsUnwatched' => 'İzlenmedi olarak işaretle',
			'audioTracks.track' => ({required Object n}) => 'Ses Parçası ${n}',
			'videoControls.audioLabel' => 'Ses',
			'videoControls.subtitlesLabel' => 'Altyazı',
			'videoControls.resetToZero' => '0ms\'ye Sıfırla',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} daha sonra oynatılır',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} daha önce oynatılır',
			'videoControls.noOffset' => 'Ofset yok',
			'videoControls.letterbox' => 'Geniş Ekran (Letterbox)',
			'videoControls.fillScreen' => 'Ekrana Doldur',
			'videoControls.stretch' => 'Uzat',
			'videoControls.lockRotation' => 'Döndürmeyi kilitle',
			'videoControls.unlockRotation' => 'Döndürme kilidini aç',
			'videoControls.timerActive' => 'Zamanlayıcı Aktif',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Oynatma ${duration} sonra duraklatılacak',
			'videoControls.sleepTimerEndOfVideo' => 'Mevcut videonun sonu',
			'videoControls.sleepTimerStopAtHeader' => 'Durma zamanı',
			'videoControls.sleepTimerDurationHeader' => 'Zamanlayıcı',
			'videoControls.playbackWillPauseAtEnd' => 'Oynatma bu videonun sonunda duraklatılacak',
			'videoControls.stillWatching' => 'Hâlâ izliyor musunuz?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}sn içinde duraklatılıyor',
			'videoControls.continueWatching' => 'Devam Et',
			'videoControls.autoPlayNext' => 'Sonrakini Otomatik Oynat',
			'videoControls.playNext' => 'Sonrakini Oynat',
			'videoControls.playButton' => 'Oynat',
			'videoControls.pauseButton' => 'Duraklat',
			'videoControls.showPlaybackControls' => 'Oynatma kontrollerini göster',
			'videoControls.hidePlaybackControls' => 'Oynatma kontrollerini gizle',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} saniye geri sar',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} saniye ileri sar',
			'videoControls.previousButton' => 'Önceki bölüm',
			'videoControls.nextButton' => 'Sonraki bölüm',
			'videoControls.previousChapterButton' => 'Önceki kısım',
			'videoControls.nextChapterButton' => 'Sonraki kısım',
			'videoControls.muteButton' => 'Sesi Kıs',
			'videoControls.unmuteButton' => 'Sesi Aç',
			'videoControls.settingsButton' => 'Oynatma Ayarları',
			'videoControls.tracksButton' => 'Ses ve Altyazı',
			'videoControls.chaptersButton' => 'Kısımlar',
			'videoControls.versionQualityButton' => 'Sürüm ve Kalite',
			'videoControls.versionColumnHeader' => 'Sürüm',
			'videoControls.qualityColumnHeader' => 'Kalite',
			'videoControls.qualityOriginal' => 'Orijinal',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Kod dönüştürme kullanılamıyor — orijinal kalitede oynatılıyor',
			'videoControls.subtitleUnavailableFallback' => 'Seçilen altyazı yüklenemedi — altyazısız devam ediliyor',
			'videoControls.pipButton' => 'Pencere İçinde Pencere modu',
			'videoControls.aspectRatioButton' => 'En boy oranı',
			'videoControls.ambientLighting' => 'Ortam aydınlatması',
			'videoControls.fullscreenButton' => 'Tam ekrana geç',
			'videoControls.exitFullscreenButton' => 'Tam ekrandan çık',
			'videoControls.alwaysOnTopButton' => 'Her zaman üstte',
			'videoControls.rotationLockButton' => 'Döndürme kilidi',
			'videoControls.lockScreen' => 'Ekranı kilitle',
			'videoControls.screenLockButton' => 'Ekran kilidi',
			'videoControls.longPressToUnlock' => 'Kilidi açmak için uzun basın',
			'videoControls.timelineSlider' => 'Video zaman çubuğu',
			'videoControls.volumeSlider' => 'Ses seviyesi',
			'videoControls.endsAt' => ({required Object time}) => 'Bitiş saati: ${time}',
			'videoControls.pipActive' => 'Pencere İçinde Pencere modunda oynatılıyor',
			'videoControls.pipFailed' => 'Pencere içinde pencere modu başlatılamadı',
			'videoControls.screenshotSaved' => 'Ekran görüntüsü kaydedildi',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Yakınlaştırma %${percent}',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 veya daha yenisini gerektirir',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 veya daha yenisini gerektirir',
			'videoControls.pipErrors.permissionDisabled' => 'Pencere içinde pencere devre dışı. Sistem ayarlarından etkinleştirin.',
			'videoControls.pipErrors.notSupported' => 'Cihaz pencere içinde pencere modunu desteklemiyor',
			'videoControls.pipErrors.voSwitchFailed' => 'Pencere içinde pencere için video çıkışı değiştirilemedi',
			'videoControls.pipErrors.failed' => 'Pencere içinde pencere başlatılamadı',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Bir hata oluştu: ${error}',
			'videoControls.chapters' => 'Kısımlar',
			'videoControls.noChaptersAvailable' => 'Kısım bulunmuyor',
			'videoControls.queue' => 'Kuyruk',
			'videoControls.noQueueItems' => 'Kuyrukta öge yok',
			'videoControls.searchSubtitles' => 'Altyazı Ara',
			_ => null,
		} ?? switch (path) {
			'videoControls.language' => 'Dil',
			'videoControls.noSubtitlesFound' => 'Altyazı bulunamadı',
			'videoControls.subtitleDownloaded' => 'Altyazı indirildi',
			'videoControls.subtitleDownloadedNotApplied' => 'Altyazı indirildi ancak seçilemedi',
			'videoControls.subtitleDownloadFailed' => 'Altyazı indirilemedi',
			'videoControls.searchLanguages' => 'Dillerde ara...',
			'messages.markedAsWatched' => 'İzlendi olarak işaretlendi',
			'messages.markedAsUnwatched' => 'İzlenmedi olarak işaretlendi',
			'messages.markedAsWatchedOffline' => 'İzlendi olarak işaretlendi (çevrimiçi olunca senkronize edilecek)',
			'messages.markedAsUnwatchedOffline' => 'İzlenmedi olarak işaretlendi (çevrimiçi olunca senkronize edilecek)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Otomatik kaldırıldı: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n, one: 'İzlenen ${n} indirme otomatik kaldırıldı', other: 'İzlenen ${n} indirme otomatik kaldırıldı', ), 
			'messages.removedFromContinueWatching' => 'İzlemeye Devam Et\'ten kaldırıldı',
			'messages.errorLoading' => ({required Object error}) => 'Hata: ${error}',
			'messages.searchPartialResults' => 'Bazı medya sunucularında arama yapılamadı. Kullanılabilir sonuçlar gösteriliyor.',
			'messages.streamInterrupted' => 'Akış kesintiye uğradı. Tekrar denemek için oynatın veya sarın.',
			'messages.liveStreamInterrupted' => 'Canlı akış kesintiye uğradı. Tekrar denemek için oynatın.',
			'messages.fileInfoNotAvailable' => 'Dosya bilgisi mevcut değil',
			'messages.playbackAuthenticationRequired' => 'Bu ögeyi oynatmak için medya sunucusuna tekrar giriş yapın.',
			'messages.playbackServerUnavailable' => 'Medya sunucusu kullanılabilir değil. Daha sonra tekrar deneyin.',
			'messages.playbackDataInvalid' => 'Sunucu geçersiz oynatma bilgisi döndürdü.',
			'messages.playbackCancelled' => 'Oynatma iptal edildi.',
			'messages.playbackFailed' => 'Oynatma başlatılamadı.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Dosya bilgisi yüklenirken hata: ${error}',
			'messages.errorLoadingSeries' => 'Dizi yüklenirken hata',
			'messages.musicNotSupported' => 'Müzik oynatma henüz desteklenmiyor',
			'messages.noDescriptionAvailable' => 'Açıklama mevcut değil',
			'messages.noProfilesAvailable' => 'Profil bulunmuyor',
			'messages.contactAdminForProfiles' => 'Profil eklemek için sunucu yöneticinizle iletişime geçin',
			'messages.unableToDetermineLibrarySection' => 'Bu öge için kitaplık bölümü belirlenemedi',
			'messages.logsCleared' => 'Günlükler temizlendi',
			'messages.logsCopied' => 'Günlükler panoya kopyalandı',
			'messages.noLogsAvailable' => 'Günlük yok',
			'messages.libraryScanning' => ({required Object title}) => '"${title}" taranıyor...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}" için kitaplık taraması başladı',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kitaplık taranamadı: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" için meta veriler yenileniyor...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" için meta veri yenilemesi başladı',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Meta veriler yenilenemedi: ${error}',
			'messages.logoutConfirm' => 'Çıkış yapmak istediğinizden emin misiniz?',
			'messages.noSeasonsFound' => 'Sezon bulunamadı',
			'messages.seasonsLoadFailed' => 'Sezonlar yüklenemedi',
			'messages.noEpisodesFound' => 'İlk sezonda bölüm bulunamadı',
			'messages.noEpisodesFoundGeneral' => 'Bölüm bulunamadı',
			'messages.episodesLoadFailed' => 'Bölümler yüklenemedi',
			'messages.noResultsFound' => 'Sonuç bulunamadı',
			'messages.sleepTimerSet' => ({required Object label}) => 'Uyku zamanlayıcısı ${label} için ayarlandı',
			'messages.noItemsAvailable' => 'Öge bulunmuyor',
			'messages.failedToCreatePlayQueueNoItems' => 'Oynatma kuyruğu oluşturulamadı — öge yok',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action} başarısız oldu: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Uyumlu oynatıcıya geçiliyor...',
			'messages.serverLimitTitle' => 'Oynatma başarısız oldu',
			'messages.serverLimitBody' => 'Sunucu hatası (HTTP 500). Muhtemelen bir bant genişliği/kod dönüştürme sınırı bu oturumu reddetti. Sunucu sahibinden bunu ayarlamasını isteyin.',
			'messages.logsUploaded' => 'Günlükler yüklendi',
			'messages.logsUploadFailed' => 'Günlükler yüklenemedi',
			'messages.logId' => 'Günlük Kimliği (ID)',
			'subtitlingStyling.text' => 'Metin',
			'subtitlingStyling.border' => 'Kenarlık',
			'subtitlingStyling.background' => 'Arka Plan',
			'subtitlingStyling.fontSize' => 'Yazı Boyutu',
			'subtitlingStyling.textColor' => 'Metin Rengi',
			'subtitlingStyling.borderSize' => 'Kenarlık Boyutu',
			'subtitlingStyling.borderColor' => 'Kenarlık Rengi',
			'subtitlingStyling.backgroundOpacity' => 'Arka Plan Saydamlığı',
			'subtitlingStyling.backgroundColor' => 'Arka Plan Rengi',
			'subtitlingStyling.position' => 'Konum',
			'subtitlingStyling.assOverride' => 'ASS Geçersiz Kılma',
			'subtitlingStyling.overrideScale' => 'Ölçekle',
			'subtitlingStyling.overrideForce' => 'Zorla',
			'subtitlingStyling.overrideStrip' => 'Biçimlendirmeyi kaldır',
			'subtitlingStyling.positionTop' => 'Üst',
			'subtitlingStyling.positionBottom' => 'Alt',
			'subtitlingStyling.bold' => 'Kalın',
			'subtitlingStyling.italic' => 'İtalik',
			'subtitlingStyling.renderResolution' => 'İşleme Çözünürlüğü',
			'subtitlingStyling.renderResolutionScreen' => 'Ekran çözünürlüğü',
			'subtitlingStyling.renderResolutionVideo' => 'Video çözünürlüğü',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Gelişmiş video oynatıcı ayarları',
			'mpvConfig.presets' => 'Önayarlar',
			'mpvConfig.noPresets' => 'Kayıtlı önayar yok',
			'mpvConfig.saveAsPreset' => 'Önayar Olarak Kaydet...',
			'mpvConfig.presetName' => 'Önayar Adı',
			'mpvConfig.presetNameHint' => 'Bu önayar için bir isim girin',
			'mpvConfig.loadPreset' => 'Yükle',
			'mpvConfig.deletePreset' => 'Sil',
			'mpvConfig.presetSaved' => 'Önayar kaydedildi',
			'mpvConfig.presetLoaded' => 'Önayar yüklendi',
			'mpvConfig.presetDeleted' => 'Önayar silindi',
			'mpvConfig.confirmDeletePreset' => 'Bu önayarı silmek istediğinizden emin misiniz?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# yorum',
			'dialog.confirmAction' => 'Eylemi Onayla',
			'profiles.addPlezyProfile' => 'Plezy profili ekle',
			'profiles.switchingProfile' => 'Profil değiştiriliyor…',
			'profiles.deleteThisProfileTitle' => 'Bu profil silinsin mi?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} kişisi kaldırılacak. Bağlantılar etkilenmez.',
			'profiles.active' => 'Aktif',
			'profiles.manage' => 'Yönet',
			'profiles.delete' => 'Sil',
			'profiles.signOut' => 'Çıkış Yap',
			'profiles.signOutPlexTitle' => 'Plex\'ten çıkış yapılsın mı?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} ve tüm Plex Ev kullanıcıları kaldırılsın mı? İstediğiniz zaman tekrar giriş yapabilirsiniz.',
			'profiles.signedOutPlex' => 'Plex\'ten çıkış yapıldı.',
			'profiles.signOutFailed' => 'Çıkış yapılamadı.',
			'profiles.sectionTitle' => 'Profiller',
			'profiles.summarySingle' => 'Yönetilen kullanıcıları ve yerel kimlikleri karıştırmak için profiller ekleyin',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · aktif: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profil',
			'profiles.removeConnectionTitle' => 'Bağlantı kaldırılsın mı?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} kullanıcısının ${connectionLabel} erişimi kaldırılacak. Diğer profiller bunu tutar.',
			'profiles.deleteProfileTitle' => 'Profil silinsin mi?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} ve bağlantıları kaldırılacak. Sunucular kullanılabilir kalır.',
			'profiles.profileNameLabel' => 'Profil adı',
			'profiles.pinProtectionLabel' => 'PIN koruması',
			'profiles.pinManagedByPlex' => 'PIN, Plex tarafından yönetiliyor. plex.tv üzerinden düzenleyin.',
			'profiles.noPinSetEditOnPlex' => 'PIN ayarlanmadı. Bir tane gerekli kılmak için plex.tv\'de ev kullanıcısını düzenleyin.',
			'profiles.setPin' => 'PIN Ayarla',
			'profiles.setPinTitle' => 'PIN Ayarla',
			'profiles.confirmPinTitle' => 'PIN\'i Onayla',
			'profiles.pinSet' => 'PIN ayarlandı',
			'profiles.changePin' => 'Değiştir',
			'profiles.removePin' => 'Kaldır',
			'profiles.connectionsLabel' => 'Bağlantılar',
			'profiles.add' => 'Ekle',
			'profiles.deleteProfileButton' => 'Profili sil',
			'profiles.noConnectionsHint' => 'Bağlantı yok — bu profili kullanmak için bir tane ekleyin.',
			'profiles.noConnections' => 'Bağlantı yok',
			'profiles.plexHomeAccount' => 'Plex Ev hesabı',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex hesabı: ${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} hesabı üzerinden ${user}',
			'profiles.connectionDefault' => 'Varsayılan',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName} olarak',
			'profiles.makeDefault' => 'Varsayılan yap',
			'profiles.removeConnection' => 'Kaldır',
			'profiles.profileRenamed' => 'Profil yeniden adlandırıldı.',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName} profiline ekle',
			'profiles.borrowExplain' => 'Başka bir profilin bağlantısını ödünç alın. PIN korumalı profiller bir PIN gerektirir.',
			'profiles.borrowEmpty' => 'Henüz ödünç alınacak bir şey yok.',
			'profiles.borrowEmptySubtitle' => 'Önce başka bir profile Plex veya Jellyfin bağlayın.',
			'profiles.borrowLoadFailed' => 'Mevcut bağlantılar yüklenemedi. Tekrar deneyin.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName} profilinden',
			'profiles.borrowConnectionBorrowed' => 'Bağlantı ödünç alındı.',
			'profiles.borrowFailed' => 'Bağlantı ödünç alınamadı.',
			'profiles.incorrectPin' => 'Yanlış PIN.',
			'profiles.incorrectPinTryAgain' => 'Yanlış PIN. Lütfen tekrar deneyin.',
			'profiles.sourceProfileMissingParentAccount' => 'Kaynak profilin üst hesabı eksik.',
			'profiles.failedToLoadHomeUsers' => 'Plex Ev kullanıcılarınız yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.',
			'profiles.failedToVerifyPin' => 'PIN doğrulanamadı.',
			'profiles.newProfile' => 'Yeni profil',
			'profiles.profileNameHint' => 'ör. Misafirler, Çocuklar, Oturma Odası',
			'profiles.pinProtectionOptional' => 'PIN koruması (isteğe bağlı)',
			'profiles.pinExplain' => 'Profiller arasında geçiş yapmak için 4 haneli PIN gereklidir.',
			'profiles.continueButton' => 'Devam Et',
			'profiles.pinsDontMatch' => 'PIN\'ler eşleşmiyor',
			'connections.sectionTitle' => 'Bağlantılar',
			'connections.addConnection' => 'Bağlantı ekle',
			'connections.addConnectionSubtitleNoProfile' => 'Plex ile giriş yapın veya bir Jellyfin sunucusu bağlayın',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName} profiline ekle: Plex, Jellyfin veya başka bir profil bağlantısı',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} için oturum süresi doldu',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} sunucu için oturum süresi doldu',
			'connections.signInAgain' => 'Tekrar giriş yap',
			'discover.title' => 'Keşfet',
			'discover.noContentAvailable' => 'İçerik bulunmuyor',
			'discover.addMediaToLibraries' => 'Kitaplıklarınıza biraz medya ekleyin',
			'discover.continueWatching' => 'İzlemeye Devam Et',
			'discover.continueWatchingIn' => ({required Object library}) => '${library} içinde İzlemeye Devam Et',
			'discover.nextUp' => 'Sıradaki',
			'discover.nextUpIn' => ({required Object library}) => '${library} içinde Sıradaki',
			'discover.recentlyAdded' => 'Son Eklenenler',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library} içinde Son Eklenenler',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} içinde Son Albümler',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library} içinde Son Oynatılanlar',
			'discover.mostPlayedIn' => ({required Object library}) => '${library} içinde En Çok Oynatılanlar',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}B${episode}',
			'discover.overview' => 'Genel Bakış',
			'discover.cast' => 'Oyuncular',
			'discover.extras' => 'Fragmanlar ve Ekstralar',
			'discover.studio' => 'Stüdyo',
			'discover.rating' => 'Derecelendirme',
			'discover.director' => 'Yönetmen',
			'discover.directors' => 'Yönetmenler',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV Dizisi',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} dk kaldı',
			'discover.moreLikeThis' => 'Buna Benzerler',
			'errors.searchFailed' => ({required Object error}) => 'Arama başarısız: ${error}',
			'errors.searchUnavailable' => 'Arama hiçbir medya sunucusuna ulaşamadı.',
			'errors.connectionTimeout' => ({required Object context}) => '${context} yüklenirken bağlantı zaman aşımına uğradı',
			'errors.connectionFailed' => 'Medya sunucusuna bağlanılamıyor',
			'errors.unableToLoad' => ({required Object context}) => '${context} yüklenemedi. Lütfen tekrar deneyin.',
			'errors.noClientAvailable' => 'Kullanılabilir istemci yok',
			'errors.pleaseEnterToken' => 'Lütfen bir belirteç (token) girin',
			'errors.invalidToken' => 'Geçersiz belirteç',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Belirteç doğrulanamadı: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName} profiline geçilemedi',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName} profili silinemedi',
			'errors.failedToRate' => 'Puan güncellenemedi',
			'libraries.title' => 'Kitaplıklar',
			'libraries.fallbackTitle' => 'Kitaplık',
			'libraries.scanLibraryFiles' => 'Kitaplık Dosyalarını Tarayınız',
			'libraries.scanLibrary' => 'Kitaplığı Taramak',
			'libraries.analyze' => 'Analiz Et',
			'libraries.analyzeLibrary' => 'Kitaplığı Analiz Et',
			'libraries.refreshMetadata' => 'Meta Verileri Yenile',
			'libraries.emptyTrash' => 'Çöpü Boşalt',
			'libraries.emptyingTrash' => ({required Object title}) => '"${title}" için çöp boşaltılıyor...',
			'libraries.trashEmptied' => ({required Object title}) => '"${title}" için çöp boşaltıldı',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Çöp boşaltılamadı: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" analiz ediliyor...',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" için analiz başladı',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kitaplık analiz edilemedi: ${error}',
			'libraries.noLibrariesFound' => 'Kitaplık bulunamadı',
			'libraries.allLibrariesHidden' => 'Tüm kitaplıklar gizli',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Gizli kitaplıklar (${count})',
			'libraries.thisLibraryIsEmpty' => 'Bu kitaplık boş',
			'libraries.noItemsMatchFilters' => 'Etkin filtrelerle eşleşen öge yok',
			'libraries.resetFilters' => 'Filtreleri sıfırla',
			'libraries.all' => 'Tümü',
			'libraries.clearAll' => 'Tümünü Temizle',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '"${title}" kitaplığını taramak istediğinizden emin misiniz?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '"${title}" kitaplığını analiz etmek istediğinizden emin misiniz?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '"${title}" kitaplığı için meta verileri yenilemek istediğinizden emin misiniz?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '"${title}" için çöpü boşaltmak istediğinizden emin misiniz?',
			'libraries.manageLibraries' => 'Kitaplıkları Yönet',
			'libraries.sort' => 'Sırala',
			'libraries.sortBy' => 'Sıralama Ölçütü',
			'libraries.filters' => 'Filtreler',
			'libraries.confirmActionMessage' => 'Bu eylemi gerçekleştirmek istediğinizden emin misiniz?',
			'libraries.showLibrary' => 'Kitaplığı göster',
			'libraries.hideLibrary' => 'Kitaplığı gizle',
			'libraries.libraryOptions' => 'Kitaplık seçenekleri',
			'libraries.content' => 'kitaplık içeriği',
			'libraries.selectLibrary' => 'Kitaplık seç',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtreler (${count})',
			'libraries.noRecommendations' => 'Öneri bulunmuyor',
			'libraries.noCollections' => 'Bu kitaplıkta koleksiyon yok',
			'libraries.noFoldersFound' => 'Klasör bulunamadı',
			'libraries.folders' => 'klasörler',
			'libraries.tabs.recommended' => 'Önerilenler',
			'libraries.tabs.browse' => 'Göz At',
			'libraries.tabs.collections' => 'Koleksiyonlar',
			'libraries.tabs.playlists' => 'Oynatma Listeleri',
			'libraries.groupings.title' => 'Gruplama',
			'libraries.groupings.all' => 'Tümü',
			'libraries.groupings.movies' => 'Filmler',
			'libraries.groupings.shows' => 'TV Dizileri',
			'libraries.groupings.seasons' => 'Sezonlar',
			'libraries.groupings.episodes' => 'Bölümler',
			'libraries.groupings.artists' => 'Sanatçılar',
			'libraries.groupings.albums' => 'Albümler',
			'libraries.groupings.tracks' => 'Parçalar',
			'libraries.groupings.folders' => 'Klasörler',
			'libraries.filterCategories.genre' => 'Tür',
			'libraries.filterCategories.year' => 'Yıl',
			'libraries.filterCategories.contentRating' => 'İçerik Derecelendirmesi',
			'libraries.filterCategories.tag' => 'Etiket',
			'libraries.filterCategories.unwatched' => 'İzlenmemiş',
			'libraries.filterCategories.unplayed' => 'Oynatılmamış',
			'libraries.filterCategories.favorites' => 'Favoriler',
			'libraries.sortLabels.title' => 'Başlık',
			'libraries.sortLabels.dateAdded' => 'Ekleme Tarihi',
			'libraries.sortLabels.releaseDate' => 'Yayınlanma Tarihi',
			'libraries.sortLabels.rating' => 'Puan',
			'libraries.sortLabels.communityRating' => 'Topluluk Puanı',
			'libraries.sortLabels.criticRating' => 'Eleştirmen Puanı',
			'libraries.sortLabels.userRating' => 'Kullanıcı Puanı',
			'libraries.sortLabels.datePlayed' => 'Oynatılma Tarihi',
			'libraries.sortLabels.playCount' => 'Oynatma Sayısı',
			'libraries.sortLabels.productionYear' => 'Yapım Yılı',
			'libraries.sortLabels.runtime' => 'Çalışma Süresi',
			'libraries.sortLabels.officialRating' => 'Resmi Puan',
			'libraries.sortLabels.premiereDate' => 'Prömiyer Tarihi',
			'libraries.sortLabels.startDate' => 'Başlangıç Tarihi',
			'libraries.sortLabels.airTime' => 'Yayın Zamanı',
			'libraries.sortLabels.studio' => 'Stüdyo',
			'libraries.sortLabels.random' => 'Rastgele',
			'libraries.sortLabels.dateShared' => 'Paylaşılma Tarihi',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Son Bölüm Yayın Tarihi',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Eklenen Son Bölüm Tarihi',
			'about.title' => 'Hakkında',
			'about.openSourceLicenses' => 'Açık Kaynak Lisansları',
			'about.versionLabel' => ({required Object version}) => 'Sürüm ${version}',
			'about.appDescription' => 'Flutter için şık bir Plex ve Jellyfin istemcisi',
			'about.viewLicensesDescription' => 'Üçüncü taraf kütüphanelerin lisanslarını görüntüleyin',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email}) için sunucu bulunamadı',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Sunucular yüklenemedi: ${error}',
			'hubDetail.title' => 'Başlık',
			'hubDetail.releaseYear' => 'Yayın Yılı',
			'hubDetail.dateAdded' => 'Ekleme Tarihi',
			'hubDetail.rating' => 'Puan',
			'hubDetail.noItemsFound' => 'Öge bulunamadı',
			'logs.clearLogs' => 'Günlükleri Temizle',
			'logs.copyLogs' => 'Günlükleri Kopyala',
			'logs.uploadLogs' => 'Günlükleri Yükle',
			'licenses.relatedPackages' => 'İlgili Paketler',
			'licenses.license' => 'Lisans',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisans ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} lisans',
			'navigation.libraries' => 'Kitaplıklar',
			'navigation.downloads' => 'İndirmeler',
			'navigation.liveTv' => 'Canlı TV',
			'navigation.explore' => 'Keşfet',
			'explore.title' => 'Keşfet',
			'explore.selectSource' => 'Kaynak seçin',
			'explore.rows.watchlist' => 'İzleme Listesi',
			'explore.rows.recommendedMovies' => 'Önerilen Filmler',
			'explore.rows.recommendedShows' => 'Önerilen Diziler',
			'explore.rows.trendingMovies' => 'Trend Filmler',
			'explore.rows.trendingShows' => 'Trend Diziler',
			'explore.rows.popularMovies' => 'Popüler Filmler',
			'explore.rows.popularShows' => 'Popüler Diziler',
			'explore.rows.trendingAnime' => 'Trend Animeler',
			'explore.rows.suggestedAnime' => 'Önerilen Animeler',
			'explore.rows.airingAnime' => 'En İyi Yayınlanan Animeler',
			'explore.rows.popularAnime' => 'En Popüler Animeler',
			'explore.rows.trending' => 'Trendler',
			'explore.rows.upcomingMovies' => 'Gelecek Filmler',
			'explore.rows.upcomingShows' => 'Gelecek Diziler',
			'explore.status.airing' => 'Yayınlanıyor',
			'explore.status.ended' => 'Bitti',
			'explore.status.canceled' => 'İptal Edildi',
			'explore.status.upcoming' => 'Gelecek',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n, one: '${n} bölüm', other: '${n} bölüm', ), 
			'explore.cast' => 'Oyuncular',
			'explore.characters' => 'Karakterler',
			'explore.addToWatchlist' => 'İzleme Listesine Ekle',
			'explore.removeFromWatchlist' => 'İzleme Listesinden Kaldır',
			'explore.watchlistUpdateFailed' => 'İzleme listesi güncellenemedi',
			'explore.notInLibrary' => 'Kitaplığınızda yok',
			'explore.inTheseLibraries' => 'Bu kitaplıklarda var',
			'explore.checkingLibrary' => 'Kitaplığınız kontrol ediliyor...',
			'explore.emptyTitle' => 'Henüz burada bir şey yok',
			'explore.emptyMessage' => ({required Object source}) => '${source} kaynağındaki satırlar içerik bulunduğunda burada görünecektir.',
			'explore.searchHint' => ({required Object source}) => '${source} üzerinde ara',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" için sonuç bulunamadı',
			'explore.searchPrompt' => ({required Object source}) => '${source} üzerinde film ve dizileri arayın.',
			'explore.searchFailed' => 'Arama başarısız. Bağlantınızı kontrol edip tekrar deneyin.',
			'liveTv.title' => 'Canlı TV',
			'liveTv.guide' => 'Rehber',
			'liveTv.noChannels' => 'Kullanılabilir kanal yok',
			'liveTv.noDvr' => 'Hiçbir sunucuda DVR yapılandırılmadı',
			'liveTv.serverUnavailable' => 'Canlı TV sunucusu kullanılabilir değil.',
			'liveTv.serverNotConnected' => 'Canlı TV sunucusu bağlı değil.',
			'liveTv.noPrograms' => 'Program verisi bulunmuyor',
			'liveTv.liveStreamFailed' => 'Canlı akış başarısız oldu',
			'liveTv.unknownProgram' => 'Bilinmeyen Program',
			'liveTv.unknownHub' => 'Bilinmiyor',
			'liveTv.unknownError' => 'Bilinmeyen hata',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Bilinmeyen kanal',
			'liveTv.live' => 'CANLI',
			'liveTv.reloadGuide' => 'Rehberi Yeniden Yükle',
			'liveTv.now' => 'Şimdi',
			'liveTv.today' => 'Bugün',
			'liveTv.tomorrow' => 'Yarın',
			'liveTv.midnight' => 'Gece Yarısı',
			'liveTv.overnight' => 'Gece Boyunca',
			'liveTv.morning' => 'Sabah',
			'liveTv.daytime' => 'Gündüz',
			'liveTv.evening' => 'Akşam',
			'liveTv.lateNight' => 'Gece Geç Saatler',
			'liveTv.whatsOn' => 'Şimdi Ne Var?',
			'liveTv.watchChannel' => 'Kanalı İzle',
			'liveTv.favorites' => 'Favoriler',
			'liveTv.reorderFavorites' => 'Favorileri Yeniden Sırala',
			'liveTv.favoritesLoadFailed' => 'Favoriler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.',
			'liveTv.favoritesUpdateFailed' => 'Favoriler güncellenemedi. Bağlantınızı kontrol edip tekrar deneyin.',
			'liveTv.joinSession' => 'Devam Eden Oturuma Katıl',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Baştan izle (${minutes} dk önce)',
			'liveTv.watchLive' => 'Canlı İzle',
			'liveTv.goToLive' => 'Canlıya Git',
			'liveTv.record' => 'Kaydet',
			'liveTv.recordEpisode' => 'Bölümü Kaydet',
			'liveTv.recordSeries' => 'Diziyi Kaydet',
			'liveTv.recordOptions' => 'Kayıt Seçenekleri',
			'liveTv.saveTo' => 'Şuraya kaydet',
			'liveTv.recordings' => 'Kayıtlar',
			'liveTv.scheduledRecordings' => 'Planlananlar',
			'liveTv.recordingRules' => 'Kayıt Kuralları',
			'liveTv.noScheduledRecordings' => 'Kaydedilecek planlanmış bir şey yok',
			'liveTv.manageRecording' => 'Kaydı yönet',
			'liveTv.cancelRecording' => 'Kaydı iptal et',
			'liveTv.cancelRecordingTitle' => 'Bu kayıt iptal edilsin mi?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} artık kaydedilmeyecek.',
			'liveTv.deleteRule' => 'Kuralı sil',
			'liveTv.deleteRuleTitle' => 'Kayıt kuralı silinsin mi?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title} dizisinin gelecek bölümleri kaydedilmeyecek.',
			'liveTv.recordingScheduled' => 'Kayıt planlandı',
			'liveTv.alreadyScheduled' => 'Bu program zaten planlanmış',
			'liveTv.dvrAdminRequired' => 'DVR ayarları bir yönetici hesabı gerektirir',
			'liveTv.recordingFailed' => 'Kayıt planlanamadı',
			'liveTv.recordingTargetMissing' => 'Kayıt kitaplığı belirlenemedi',
			'liveTv.recordNotAvailable' => 'Bu program için kayıt kullanılamıyor',
			'liveTv.recordingCancelled' => 'Kayıt iptal edildi',
			'liveTv.recordingRuleDeleted' => 'Kayıt kuralı silindi',
			'liveTv.processRecordingRules' => 'Kuralları yeniden değerlendir',
			'liveTv.recordingInProgress' => 'Şimdi kaydediliyor',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} planlandı',
			'liveTv.editRule' => 'Kuralı düzenle',
			'liveTv.editRuleAction' => 'Düzenle',
			'liveTv.recordingRuleUpdated' => 'Kayıt kuralı güncellendi',
			'liveTv.guideReloadRequested' => 'Rehber yenilemesi istendi',
			'liveTv.rulesProcessRequested' => 'Kuralın yeniden değerlendirilmesi istendi',
			'liveTv.recordShow' => 'Programı kaydet',
			'collections.title' => 'Koleksiyonlar',
			'collections.collection' => 'Koleksiyon',
			'collections.empty' => 'Koleksiyon boş',
			'collections.deleteCollection' => 'Koleksiyonu Sil',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" silinsin mi? Bu işlem geri alınamaz.',
			'collections.deleted' => 'Koleksiyon silindi',
			'collections.deleteFailed' => 'Koleksiyon silinemedi',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Koleksiyon silinemedi: ${error}',
			'collections.selectCollection' => 'Koleksiyon Seç',
			'collections.collectionName' => 'Koleksiyon Adı',
			'collections.enterCollectionName' => 'Koleksiyon adını girin',
			'collections.addedToCollection' => 'Koleksiyona eklendi',
			'collections.errorAddingToCollection' => 'Koleksiyona eklenemedi',
			'collections.created' => 'Koleksiyon oluşturuldu',
			'collections.removeFromCollection' => 'Koleksiyondan kaldır',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" bu koleksiyondan kaldırılsın mı?',
			'collections.removedFromCollection' => 'Koleksiyondan kaldırıldı',
			'collections.removeFromCollectionFailed' => 'Koleksiyondan kaldırılamadı',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Koleksiyondan kaldırılırken hata: ${error}',
			'collections.searchCollections' => 'Koleksiyonlarda ara...',
			'playlists.title' => 'Oynatma Listeleri',
			'playlists.playlist' => 'Oynatma Listesi',
			'playlists.noPlaylists' => 'Oynatma listesi bulunamadı',
			'playlists.create' => 'Oynatma Listesi Oluştur',
			'playlists.playlistName' => 'Oynatma Listesi Adı',
			'playlists.enterPlaylistName' => 'Oynatma listesi adını girin',
			'playlists.delete' => 'Oynatma Listesini Sil',
			'playlists.removeItem' => 'Oynatma Listesinden Kaldır',
			'playlists.smartPlaylist' => 'Akıllı Oynatma Listesi',
			'playlists.itemCount' => ({required Object count}) => '${count} öge',
			'playlists.oneItem' => '1 öge',
			'playlists.emptyPlaylist' => 'Bu oynatma listesi boş',
			'playlists.deleteConfirm' => 'Oynatma Listesi Silinsin mi?',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}" listesini silmek istediğinizden emin misiniz?',
			'playlists.created' => 'Oynatma listesi oluşturuldu',
			'playlists.deleted' => 'Oynatma listesi silindi',
			'playlists.itemAdded' => 'Oynatma listesine eklendi',
			'playlists.itemRemoved' => 'Oynatma listesinden kaldırıldı',
			'playlists.selectPlaylist' => 'Oynatma Listesi Seç',
			'playlists.searchPlaylists' => 'Oynatma listelerinde ara...',
			'playlists.errorCreating' => 'Oynatma listesi oluşturulamadı',
			'playlists.errorDeleting' => 'Oynatma listesi silinemedi',
			'playlists.errorLoading' => 'Oynatma listeleri yüklenemedi',
			'playlists.errorAdding' => 'Oynatma listesine eklenemedi',
			'playlists.errorReordering' => 'Oynatma listesi ögesi yeniden sıralanamadı',
			'playlists.errorRemoving' => 'Oynatma listesinden kaldırılamadı',
			'music.goToAlbum' => 'Albüme git',
			'music.goToArtist' => 'Sanatçıya git',
			'music.instantMix' => 'Anında Karışım',
			'music.playNext' => 'Sonrakini oynat',
			'music.addToQueue' => 'Kuyruğa ekle',
			'music.discNumber' => ({required Object n}) => 'Disk ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n, one: '${n} parça', other: '${n} parça', ), 
			'music.nowPlaying' => 'Şimdi Oynatılıyor',
			'music.playingFrom' => ({required Object title}) => '${title} kaynağından oynatılıyor',
			'music.queue' => 'Kuyruk',
			'music.clearQueue' => 'Kuyruğu temizle',
			'music.lyrics' => 'Şarkı Sözleri',
			'music.noLyrics' => 'Şarkı sözü bulunmuyor',
			'music.sleepTimer' => 'Uyku zamanlayıcısı',
			'music.sleepTimerEndOfTrack' => 'Parçanın sonu',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} dakika',
			'music.stopPlayback' => 'Oynatmayı durdur',
			'music.previousTrack' => 'Önceki parça',
			'music.nextTrack' => 'Sonraki parça',
			'music.repeat' => 'Tekrarla',
			'music.repeatAll' => 'Tümünü tekrarla',
			'music.repeatOne' => 'Tekini tekrarla',
			'watchTogether.title' => 'Birlikte İzle',
			'watchTogether.description' => 'Arkadaşlarınızla ve ailenizle eş zamanlı içerik izleyin',
			'watchTogether.createSession' => 'Oturum Oluştur',
			'watchTogether.creating' => 'Oluşturuluyor...',
			'watchTogether.joinSession' => 'Oturuma Katıl',
			'watchTogether.joining' => 'Katılınıyor...',
			'watchTogether.controlMode' => 'Kontrol Modu',
			'watchTogether.controlModeQuestion' => 'Oynatmayı kimler kontrol edebilir?',
			'watchTogether.hostOnly' => 'Yalnızca Kurucu',
			'watchTogether.anyone' => 'Herkes',
			'watchTogether.hostingSession' => 'Oturum Sunuluyor',
			'watchTogether.inSession' => 'Oturumda',
			'watchTogether.sessionCode' => 'Oturum Kodu',
			'watchTogether.openSessionControls' => 'Birlikte İzle oturum kontrollerini aç',
			'watchTogether.copySessionCode' => 'Oturum kodunu kopyala',
			'watchTogether.hostControlsPlayback' => 'Oynatmayı kurucu kontrol eder',
			'watchTogether.anyoneCanControl' => 'Oynatmayı herkes kontrol edebilir',
			'watchTogether.hostControls' => 'Kurucu kontrol eder',
			'watchTogether.anyoneControls' => 'Herkes kontrol eder',
			'watchTogether.participants' => 'Katılımcılar',
			'watchTogether.host' => 'Kurucu',
			'watchTogether.hostBadge' => 'KURUCU',
			'watchTogether.youAreHost' => 'Kurucu sizsiniz',
			'watchTogether.watchingWithOthers' => 'Başkalarıyla birlikte izleniyor',
			'watchTogether.endSession' => 'Oturumu Bitir',
			'watchTogether.leaveSession' => 'Oturumdan Ayrıl',
			'watchTogether.endSessionQuestion' => 'Oturum Bitirilsin mi?',
			'watchTogether.leaveSessionQuestion' => 'Oturumdan Ayrılınsın mı?',
			'watchTogether.endSessionConfirm' => 'Bu işlem tüm katılımcılar için oturumu bitirecektir.',
			'watchTogether.leaveSessionConfirm' => 'Oturumdan çıkarılacaksınız.',
			'watchTogether.endSessionConfirmOverlay' => 'Bu işlem tüm katılımcılar için izleme oturumunu bitirecektir.',
			'watchTogether.leaveSessionConfirmOverlay' => 'İzleme oturumuyla bağlantınız kesilecek.',
			'watchTogether.end' => 'Bitir',
			'watchTogether.leave' => 'Ayrıl',
			'watchTogether.syncing' => 'Eşitleniyor...',
			'watchTogether.joinWatchSession' => 'İzleme Oturumuna Katıl',
			'watchTogether.enterCodeHint' => '5 karakterlik kodu girin',
			'watchTogether.pasteFromClipboard' => 'Panodan yapıştır',
			'watchTogether.pleaseEnterCode' => 'Lütfen bir oturum kodu girin',
			'watchTogether.codeMustBe5Chars' => 'Oturum kodu 5 karakter olmalıdır',
			_ => null,
		} ?? switch (path) {
			'watchTogether.joinInstructions' => 'Katılmak için kurucunun oturum kodunu girin.',
			'watchTogether.failedToCreate' => 'Oturum oluşturulamadı',
			'watchTogether.failedToJoin' => 'Oturuma katılınamadı',
			'watchTogether.sessionCodeCopied' => 'Oturum kodu panoya kopyalandı',
			'watchTogether.relayUnreachable' => 'Aktarıcı sunucusuna ulaşılamıyor. İSS engellemesi Birlikte İzle\'yi önleyebilir.',
			'watchTogether.reconnectingToHost' => 'Kurucuya yeniden bağlanılıyor...',
			'watchTogether.currentPlayback' => 'Mevcut Oynatma',
			'watchTogether.joinCurrentPlayback' => 'Mevcut Oynatmaya Katıl',
			'watchTogether.joinCurrentPlaybackDescription' => 'Kurucunun şu anda izlediği şeye doğrudan atlayın',
			'watchTogether.failedToOpenCurrentPlayback' => 'Mevcut oynatma açılamadı',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} katıldı',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} ayrıldı',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} duraklattı',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} devam ettirdi',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} oynatma konumunu değiştirdi',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} arabelleğe alıyor',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} eski bir uygulama sürümünde — eşitleme kullanılamıyor',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name} olmadan devam ediliyor',
			'watchTogether.waitingForParticipants' => 'Diğerlerinin yüklemesi bekleniyor...',
			'watchTogether.waitingForName' => ({required Object name}) => '${name} bekleniyor...',
			'watchTogether.recentRooms' => 'Son Odalar',
			'watchTogether.renameRoom' => 'Odayı Yeniden Adlandır',
			'watchTogether.removeRoom' => 'Kaldır',
			'watchTogether.guestSwitchUnavailable' => 'Geçiş yapılamadı — eşitleme için sunucu mevcut değil',
			'watchTogether.guestSwitchFailed' => 'Geçiş yapılamadı — içerik bu sunucuda bulunamadı',
			'downloads.title' => 'İndirmeler',
			'downloads.manage' => 'Yönet',
			'downloads.tvShows' => 'TV Dizileri',
			'downloads.movies' => 'Filmler',
			'downloads.music' => 'Müzik',
			'downloads.tracksQueued' => ({required Object count}) => 'İndirmek için ${count} parça kuyruğa alındı',
			'downloads.noDownloads' => 'Henüz indirme yok',
			'downloads.noDownloadsDescription' => 'İndirilen içerik çevrimdışı izlemek için burada görünecektir',
			'downloads.downloadNow' => 'İndir',
			'downloads.deleteDownload' => 'İndirmeyi sil',
			'downloads.retryDownload' => 'İndirmeyi tekrar dene',
			'downloads.downloadQueued' => 'İndirme kuyruğa alındı',
			'downloads.downloadResumed' => 'İndirme devam ettirildi',
			'downloads.serverErrorBitrate' => 'Sunucu hatası: dosya uzak bit hızı sınırını aşıyor olabilir',
			'downloads.storageFull' => 'Cihaz depolama alanı dolu olduğu için indirmeler durduruldu. Biraz alan boşaltıp tekrar deneyin.',
			'downloads.episodesQueued' => ({required Object count}) => 'İndirmek için ${count} bölüm kuyruğa alındı',
			'downloads.downloadDeleted' => 'İndirme silindi',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" bu cihazdan silinsin mi?',
			'downloads.cancelledDownloadTitle' => 'İptal Edilen İndirme',
			'downloads.cancelledDownloadMessage' => 'Bu indirme iptal edildi. Ne yapmak istersiniz?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Tüm bölümler zaten indirildi',
			'downloads.resumeDownload' => 'İndirmeyi devam ettir',
			'downloads.cancelledDownload' => 'İptal edilen indirme',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} eşitleniyor)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'İndirildi ${file} - Tamamlamak için tıklayın',
			'downloads.partialDownloadClickToComplete' => 'Kısmen indirildi - Tamamlamak için tıklayın',
			'downloads.deleting' => 'Siliniyor...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} siliniyor... (${current} / ${total})',
			'downloads.queuedTooltip' => 'Kuyrukta',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Kuyruğa alınan dosyalar: ${files}',
			'downloads.downloadingTooltip' => 'İndiriliyor...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'İndirilen dosyalar: ${files}',
			'downloads.noDownloadsTree' => 'İndirme yok',
			'downloads.pauseAll' => 'Tümünü duraklat',
			'downloads.resumeAll' => 'Tümünü devam ettir',
			'downloads.deleteAll' => 'Tümünü sil',
			'downloads.selectVersion' => 'Sürüm Seç',
			'downloads.allEpisodes' => 'Tüm bölümler',
			'downloads.unwatchedOnly' => 'Yalnızca izlenmeyenler',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Sonraki ${count} izlenmeyen',
			'downloads.customAmount' => 'Özel miktar...',
			'downloads.includeSpecials' => 'Özel Bölümleri Dahil Et',
			'downloads.howManyEpisodes' => 'Kaç bölüm?',
			'downloads.invalidEpisodeCount' => 'Geçerli bir bölüm sayısı girin.',
			'downloads.keepSynced' => 'Eşitlenmiş tut',
			'downloads.downloadOnce' => 'Bir kez indir',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} izlenmeyen bölümü tut',
			'downloads.editSyncRule' => 'Eşitleme kuralını düzenle',
			'downloads.removeSyncRule' => 'Eşitleme kuralını kaldır',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" eşitlemesi durdurulsun mu? İndirilen bölümler saklanacaktır.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '"${title}" eşitlemesi durdurulsun mu?',
			'downloads.deleteSyncRuleDownloads' => 'İlişkili indirmeleri de sil',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Başka bir eşitleme kuralı veya profil tarafından kullanılan indirmeler saklanır.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Eşitleme kuralı oluşturuldu — ${count} izlenmeyen bölüm saklanıyor',
			'downloads.syncRuleUpdated' => 'Eşitleme kuralı güncellendi',
			'downloads.syncRuleRemoved' => 'Eşitleme kuralı kaldırıldı',
			'downloads.syncRuleAndDownloadsRemoved' => 'Eşitleme kuralı ve ilişkili indirmeler kaldırıldı',
			'downloads.syncRuleCleanupBusy' => 'Eşitleme kuralları şu anda güncelleniyor. Birazdan tekrar deneyin.',
			'downloads.syncRuleCleanupUnavailable' => 'İlişkili indirmeler güvenli biçimde belirlenemedi. Sunucuya yeniden bağlanıp tekrar deneyin veya kuralı indirmeleri silmeden kaldırın.',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title} için ${count} yeni bölüm eşitlendi',
			'downloads.activeSyncRules' => 'Eşitleme kuralları',
			'downloads.noSyncRules' => 'Eşitleme kuralı yok',
			'downloads.manageSyncRule' => 'Eşitlemeyi yönet',
			'downloads.editEpisodeCount' => 'Bölüm sayısı',
			'downloads.editSyncFilter' => 'Eşitleme filtresi',
			'downloads.syncAllItems' => 'Tüm ögeler eşitleniyor',
			'downloads.syncUnwatchedItems' => 'İzlenmeyen ögeler eşitleniyor',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Sunucu: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Kullanılabilir',
			'downloads.syncRuleOffline' => 'Çevrimdışı',
			'downloads.syncRuleSignInRequired' => 'Giriş gerekli',
			'downloads.syncRuleNotAvailableForProfile' => 'Mevcut profil için kullanılamaz',
			'downloads.syncRuleUnknownServer' => 'Bilinmeyen sunucu',
			'downloads.syncRuleListCreated' => 'Eşitleme kuralı oluşturuldu',
			'downloads.backgroundWarning.bannerBlocked' => 'Uygulamadan çıktığınızda indirmeler duracak',
			'downloads.backgroundWarning.bannerDegraded' => 'Arka plan indirmeleri sınırlı olabilir',
			'downloads.backgroundWarning.bannerAction' => 'Detaylar',
			'downloads.backgroundWarning.sheetTitle' => 'Arka plan indirmeleri engellendi',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Arka plan indirmeleri sınırlı olabilir',
			'downloads.backgroundWarning.sheetIntro' => 'Android, Plezy\'nin arka planda güvenilir şekilde indirme yapmasını engelliyor.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Cihazınız, Plezy\'nin arka planda ne zaman indirme yapabileceğini sınırlıyor.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy\'nin arka plan kullanımı kısıtlanmış. Pil veya arka plan kullanımını "Kısıtlanmamış" olarak ayarlayın.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android, Plezy\'yi kısıtlı bekleme durumuna aldı. Pil kullanımını "Kısıtlanmamış" olarak ayarlayın.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'İndirme bildirimleri kapalı; bu nedenle ilerleme ve kontroller kullanılamayabilir.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Bildirimler kapalı. Android 13 ve sonraki sürümlerde uzun arka plan indirmeleri için gereklidir.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Veri Tasarrufu açık; bu, mobil veride arka plan indirmelerini engeller. Wi-Fi üzerinde indirmeler yine de çalışır.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy arka plandayken indirmeler tekrar tekrar durdu. Plezy\'nin pil veya arka plan kullanım ayarlarını kontrol edin.',
			'downloads.backgroundWarning.openSettings' => 'Ayarları aç',
			'downloads.backgroundWarning.stillNotWorking' => 'Cihaza özel yardım',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Cihazınıza yönelik adımlara bakın veya sorun sürerse Ayarlar › Günlükleri Görüntüle bölümünden bir günlük gönderin.',
			'downloads.backgroundWarning.dialogTitle' => 'İndirmeler tamamlanmayabilir',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Yine de indir',
			'downloads.backgroundWarning.dialogFixFirst' => 'Önce bunu düzelt',
			'downloads.backgroundWarning.statusTile' => 'Arka plan indirmeleri',
			'downloads.backgroundWarning.statusOk' => 'Arka planda çalışmasına izin veriliyor',
			'downloads.backgroundWarning.statusBlocked' => 'Sistem ayarları tarafından engellendi',
			'downloads.backgroundWarning.statusDegraded' => 'Sistem ayarları tarafından sınırlandırıldı',
			'downloads.backgroundWarning.statusUnknown' => 'Henüz kontrol edilmedi',
			'downloads.backgroundWarning.settingsUnavailable' => 'Bu cihazda sistem ayarları açılamadı',
			'downloads.backgroundWarning.linkUnavailable' => 'Bu cihazda dontkillmyapp.com açılamadı',
			'shaders.title' => 'Gölgelendiriciler',
			'shaders.noShaderDescription' => 'Video iyileştirmesi yok',
			'shaders.nvscalerDescription' => 'Daha keskin video için NVIDIA görsel ölçekleme',
			'shaders.artcnnVariantNeutral' => 'Nötr',
			'shaders.artcnnVariantDenoise' => 'Parazit Giderme',
			'shaders.artcnnVariantDenoiseSharpen' => 'Parazit Giderme + Keskinleştirme',
			'shaders.qualityFast' => 'Hızlı',
			'shaders.qualityHQ' => 'Yüksek Kalite',
			'shaders.mode' => 'Mod',
			'shaders.importShader' => 'Gölgelendirici İçe Aktar',
			'shaders.customShaderDescription' => 'Özel GLSL gölgelendirici',
			'shaders.shaderImported' => 'Gölgelendirici içe aktarıldı',
			'shaders.shaderImportFailed' => 'Gölgelendirici içe aktarılamadı',
			'shaders.deleteShader' => 'Gölgelendiriciyi Sil',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" silinsin mi?',
			'companionRemote.title' => 'Yardımcı Kumanda',
			'companionRemote.connectedTo' => ({required Object name}) => '${name} cihazına bağlandı',
			'companionRemote.unknownDevice' => 'Bilinmeyen Cihaz',
			'companionRemote.session.startingServer' => 'Uzaktan kumanda sunucusu başlatılıyor...',
			'companionRemote.session.hostAddress' => 'Ana Bilgisayar Adresi',
			'companionRemote.session.connected' => 'Bağlandı',
			'companionRemote.session.serverRunning' => 'Uzaktan kumanda sunucusu aktif',
			'companionRemote.session.serverStopped' => 'Uzaktan kumanda sunucusu durduruldu',
			'companionRemote.session.serverRunningDescription' => 'Ağınızdaki mobil cihazlar bu uygulamaya bağlanabilir',
			'companionRemote.session.serverStoppedDescription' => 'Mobil cihazların bağlanmasına izin vermek için sunucuyu başlatın',
			'companionRemote.session.usePhoneToControl' => 'Bu uygulamayı kontrol etmek için mobil cihazınızı kullanın',
			'companionRemote.session.startServer' => 'Sunucuyu Başlat',
			'companionRemote.session.stopServer' => 'Sunucuyu Durdur',
			'companionRemote.session.minimize' => 'Küçült',
			'companionRemote.pairing.discoveryDescription' => 'Aynı Plex hesabına sahip Plezy cihazları burada görünür',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Bağlanılıyor...',
			'companionRemote.pairing.searchingForDevices' => 'Cihazlar aranıyor...',
			'companionRemote.pairing.noDevicesFound' => 'Ağınızda cihaz bulunamadı',
			'companionRemote.pairing.noDevicesHint' => 'Masaüstünde Plezy\'yi açın ve aynı Wi-Fi ağını kullanın',
			'companionRemote.pairing.availableDevices' => 'Kullanılabilir Cihazlar',
			'companionRemote.pairing.manualConnection' => 'Manuel Bağlantı',
			'companionRemote.pairing.cryptoInitFailed' => 'Güvenli bağlantı başlatılamadı. Önce Plex\'e giriş yapın.',
			'companionRemote.pairing.validationHostRequired' => 'Lütfen ana bilgisayar adresini girin',
			'companionRemote.pairing.validationHostFormat' => 'Biçim IP:port şeklinde olmalıdır (ör. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Bağlantı zaman aşımına uğradı. Her iki cihazda da aynı ağı kullanın.',
			'companionRemote.pairing.sessionNotFound' => 'Cihaz bulunamadı. Plezy\'nin ana bilgisayarda çalıştığından emin olun.',
			'companionRemote.pairing.authFailed' => 'Kimlik doğrulama başarısız oldu. Her iki cihazın da aynı Plex hesabına ihtiyacı var.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Bağlantı başarısız: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Uzaktan kumanda oturumundan ayrılmak istiyor musunuz?',
			'companionRemote.remote.reconnecting' => 'Yeniden bağlanılıyor...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Deneme ${current} / 5',
			'companionRemote.remote.retryNow' => 'Şimdi Tekrar Dene',
			'companionRemote.remote.tabRemote' => 'Kumanda',
			'companionRemote.remote.tabPlay' => 'Oynat',
			'companionRemote.remote.tabMore' => 'Daha Fazla',
			'companionRemote.remote.menu' => 'Menü',
			'companionRemote.remote.tabNavigation' => 'Sekme Gezinmesi',
			'companionRemote.remote.tabDiscover' => 'Keşfet',
			'companionRemote.remote.tabLibraries' => 'Kitaplıklar',
			'companionRemote.remote.tabSearch' => 'Ara',
			'companionRemote.remote.tabDownloads' => 'İndirmeler',
			'companionRemote.remote.tabSettings' => 'Ayarlar',
			'companionRemote.remote.previous' => 'Önceki',
			'companionRemote.remote.playPause' => 'Oynat/Duraklat',
			'companionRemote.remote.next' => 'Sonraki',
			'companionRemote.remote.seekBack' => 'Geri Sar',
			'companionRemote.remote.stop' => 'Durdur',
			'companionRemote.remote.seekForward' => 'İleri Sar',
			'companionRemote.remote.volume' => 'Ses',
			'companionRemote.remote.volumeDown' => 'Kıs',
			'companionRemote.remote.volumeUp' => 'Aç',
			'companionRemote.remote.fullscreen' => 'Tam Ekran',
			'companionRemote.remote.subtitles' => 'Altyazılar',
			'companionRemote.remote.audio' => 'Ses',
			'companionRemote.remote.searchHint' => 'Masaüstünde ara...',
			'companionRemote.errors.noNetworkInterface' => 'Ağ arabirimi bulunamadı',
			'companionRemote.errors.authenticationFailed' => 'Kimlik doğrulama başarısız oldu',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Uzaktan kumanda sunucusu başlatılamadı: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Uzaktan komut gönderilemedi: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Oturuma katılma zaman aşımına uğradı',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Hiçbir adrese bağlanılamadı',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} denemeden sonra bağlantı kesildi',
			'companionRemote.errors.connectionLost' => 'Bağlantı kesildi',
			'videoSettings.playbackSpeed' => 'Oynatma Hızı',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktif (${duration})',
			'videoSettings.zoom' => 'Yakınlaştırma',
			'videoSettings.sleepTimer' => 'Uyku Zamanlayıcısı',
			'videoSettings.audioSync' => 'Ses Senkronizasyonu',
			'videoSettings.subtitleSync' => 'Altyazı Senkronizasyonu',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Ses Çıkışı',
			'videoSettings.performanceOverlay' => 'Performans Katmanı',
			'videoSettings.audioPassthrough' => 'Ses Doğrudan Geçişi',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Çevreleyen Ses',
			'videoSettings.audioOutputSpatial' => 'Uzamsal Ses',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioNormalization' => 'Ses Yüksekliğini Normalleştir',
			'videoSettings.audioDownmix' => 'Stereo\'ya Dönüştür',
			'performanceOverlay.color' => 'Renk',
			'performanceOverlay.performance' => 'Performans',
			'performanceOverlay.buffer' => 'Arabellek',
			'performanceOverlay.app' => 'Uygulama',
			'performanceOverlay.decoder' => 'Çözücü',
			'performanceOverlay.rawDecoder' => 'Ham Çözücü',
			'performanceOverlay.tunneling' => 'Tünelleme',
			'performanceOverlay.aspect' => 'Oran',
			'performanceOverlay.rotation' => 'Döndürme',
			'performanceOverlay.dvSource' => 'DV Kaynağı',
			'performanceOverlay.dvPath' => 'DV Yolu',
			'performanceOverlay.p7Conversion' => 'P7 Dönüştürme',
			'performanceOverlay.sampleRate' => 'Örnekleme Hızı',
			'performanceOverlay.pixelFormat' => 'Piksel Biçimi',
			'performanceOverlay.hwFormat' => 'HW Biçimi',
			'performanceOverlay.matrix' => 'Matris',
			'performanceOverlay.primaries' => 'Ana Renkler',
			'performanceOverlay.transfer' => 'Aktarım',
			'performanceOverlay.renderFps' => 'İşleme FPS',
			'performanceOverlay.displayFps' => 'Ekran FPS',
			'performanceOverlay.avSync' => 'A/V Eşitleme',
			'performanceOverlay.dropped' => 'Kare Kaybı',
			'performanceOverlay.dvRpus' => 'DV RPU\'ları',
			'performanceOverlay.dvRpuAverage' => 'DV RPU Ort.',
			'performanceOverlay.dvSampleAverage' => 'DV Örnek Ort.',
			'performanceOverlay.maxLuma' => 'Maks Luma',
			'performanceOverlay.minLuma' => 'Min Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Kullanılan Önbellek',
			'performanceOverlay.cacheLimit' => 'Önbellek Sınırı',
			'performanceOverlay.speed' => 'Hız',
			'performanceOverlay.player' => 'Oynatıcı',
			'performanceOverlay.memory' => 'Bellek',
			'performanceOverlay.uiFps' => 'Arayüz (UI) FPS',
			'externalPlayer.title' => 'Harici Oynatıcı',
			'externalPlayer.useExternalPlayer' => 'Harici Oynatıcı Kullan',
			'externalPlayer.useExternalPlayerDescription' => 'Videoları başka bir uygulamada açın',
			'externalPlayer.selectPlayer' => 'Oynatıcı Seç',
			'externalPlayer.customPlayers' => 'Özel Oynatıcılar',
			'externalPlayer.systemDefault' => 'Sistem Varsayılanı',
			'externalPlayer.addCustomPlayer' => 'Özel Oynatıcı Ekle',
			'externalPlayer.playerName' => 'Oynatıcı Adı',
			'externalPlayer.playerNameHint' => 'Oynatıcım',
			'externalPlayer.playerCommand' => 'Komut',
			'externalPlayer.playerPackage' => 'Paket Adı',
			'externalPlayer.playerUrlScheme' => 'URL Şeması',
			'externalPlayer.off' => 'Kapalı',
			'externalPlayer.launchFailed' => 'Harici oynatıcı açılamadı',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} yüklü değil',
			'externalPlayer.playInExternalPlayer' => 'Harici Oynatıcıda Oynat',
			'metadataEdit.editMetadata' => 'Düzenle...',
			'metadataEdit.screenTitle' => 'Meta Verileri Düzenle',
			'metadataEdit.basicInfo' => 'Temel Bilgiler',
			'metadataEdit.artwork' => 'Görseller',
			'metadataEdit.advancedSettings' => 'Gelişmiş Ayarlar',
			'metadataEdit.title' => 'Başlık',
			'metadataEdit.sortTitle' => 'Sıralama Başlığı',
			'metadataEdit.originalTitle' => 'Orijinal Başlık',
			'metadataEdit.releaseDate' => 'Yayınlanma Tarihi',
			'metadataEdit.contentRating' => 'İçerik Derecelendirmesi',
			'metadataEdit.studio' => 'Stüdyo',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Özet',
			'metadataEdit.poster' => 'Afiş',
			'metadataEdit.background' => 'Arka Plan',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Kare Görsel',
			'metadataEdit.selectPoster' => 'Afiş Seç',
			'metadataEdit.selectBackground' => 'Arka Plan Seç',
			'metadataEdit.selectLogo' => 'Logo Seç',
			'metadataEdit.selectSquareArt' => 'Kare Görsel Seç',
			'metadataEdit.fromUrl' => 'URL\'den',
			'metadataEdit.uploadFile' => 'Dosya Yükle',
			'metadataEdit.enterImageUrl' => 'Görsel URL\'si girin',
			'metadataEdit.imageUrl' => 'Görsel URL\'si',
			'metadataEdit.metadataUpdated' => 'Meta veriler güncellendi',
			'metadataEdit.metadataUpdateFailed' => 'Meta veriler güncellenemedi',
			'metadataEdit.artworkUpdated' => 'Görseller güncellendi',
			'metadataEdit.artworkUpdateFailed' => 'Görseller güncellenemedi',
			'metadataEdit.noArtworkAvailable' => 'Görsel bulunmuyor',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Görsel seçeneği ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Görsel seçeneği ${index}, seçildi',
			'metadataEdit.notSet' => 'Ayarlanmadı',
			'metadataEdit.libraryDefault' => 'Kitaplık varsayılanı',
			'metadataEdit.accountDefault' => 'Hesap varsayılanı',
			'metadataEdit.seriesDefault' => 'Dizi varsayılanı',
			'metadataEdit.episodeSorting' => 'Bölüm Sıralaması',
			'metadataEdit.oldestFirst' => 'Önce en eski',
			'metadataEdit.newestFirst' => 'Önce en yeni',
			'metadataEdit.keep' => 'Sakla',
			'metadataEdit.allEpisodes' => 'Tüm bölümler',
			'metadataEdit.latestEpisodes' => ({required Object count}) => 'En son ${count} bölüm',
			'metadataEdit.latestEpisode' => 'En son bölüm',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Son ${count} günde eklenen bölümler',
			'metadataEdit.deleteAfterPlaying' => 'Oynatıldıktan Sonra Bölümleri Sil',
			'metadataEdit.never' => 'Asla',
			'metadataEdit.afterADay' => 'Bir gün sonra',
			'metadataEdit.afterAWeek' => 'Bir hafta sonra',
			'metadataEdit.afterAMonth' => 'Bir ay sonra',
			'metadataEdit.onNextRefresh' => 'Sonraki yenilemede',
			'metadataEdit.seasons' => 'Sezonlar',
			'metadataEdit.show' => 'Göster',
			'metadataEdit.hide' => 'Gizle',
			'metadataEdit.episodeOrdering' => 'Bölüm Düzeni',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Yayınlanma)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Yayınlanma)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Mutlak)',
			'metadataEdit.metadataLanguage' => 'Meta Veri Dili',
			'metadataEdit.useOriginalTitle' => 'Orijinal Başlığı Kullan',
			'metadataEdit.preferredAudioLanguage' => 'Tercih Edilen Ses Dili',
			'metadataEdit.preferredSubtitleLanguage' => 'Tercih Edilen Altyazı Dili',
			'metadataEdit.subtitleMode' => 'Otomatik Altyazı Seçim Modu',
			'metadataEdit.manuallySelected' => 'Manuel seçilen',
			'metadataEdit.shownWithForeignAudio' => 'Yabancı sesle gösterilen',
			'metadataEdit.alwaysEnabled' => 'Her zaman etkin',
			'metadataEdit.tags' => 'Etiketler',
			'metadataEdit.addTag' => 'Etiket ekle',
			'metadataEdit.genre' => 'Tür',
			'metadataEdit.director' => 'Yönetmen',
			'metadataEdit.writer' => 'Yazar',
			'metadataEdit.producer' => 'Yapımcı',
			'metadataEdit.country' => 'Ülke',
			'metadataEdit.collection' => 'Koleksiyon',
			'metadataEdit.label' => 'Etiket',
			'metadataEdit.style' => 'Tarz',
			'metadataEdit.mood' => 'Ruh Hali',
			'matchScreen.match' => 'Eşleştir...',
			'matchScreen.fixMatch' => 'Eşleşmeyi Düzelt...',
			'matchScreen.unmatch' => 'Eşleşmeyi Kaldır',
			'matchScreen.unmatchConfirm' => 'Bu eşleşme temizlensin mi? Plex, tekrar eşleştirilene kadar bunu eşleşmemiş sayacaktır.',
			'matchScreen.unmatchSuccess' => 'Öge eşleşmesi kaldırıldı',
			'matchScreen.unmatchFailed' => 'Eşleşme kaldırılamadı',
			'matchScreen.matchApplied' => 'Eşleşme uygulandı',
			'matchScreen.matchFailed' => 'Eşleşme uygulanamadı',
			'matchScreen.titleHint' => 'Başlık',
			'matchScreen.yearHint' => 'Yıl',
			'matchScreen.search' => 'Ara',
			'matchScreen.noMatchesFound' => 'Eşleşme bulunamadı',
			'serverTasks.title' => 'Sunucu Görevleri',
			'serverTasks.failedToLoad' => 'Görevler yüklenemedi',
			'serverTasks.noTasks' => 'Çalışan görev yok',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Bağlandı',
			'trakt.connectedAs' => ({required Object username}) => '@${username} olarak bağlandı',
			'trakt.disconnectConfirm' => 'Trakt hesabının bağlantısı kesilsin mi?',
			'trakt.disconnectConfirmBody' => 'Plezy, Trakt\'a olay göndermeyi durduracak. İstediğiniz zaman yeniden bağlanabilirsiniz.',
			'trakt.scrobble' => 'Gerçek zamanlı scrobble',
			'trakt.scrobbleDescription' => 'Oynatma sırasında Trakt\'a oynatma, duraklatma ve durdurma olayları gönderin.',
			'trakt.watchedSync' => 'İzleme durumunu eşitle',
			'trakt.watchedSyncDescription' => 'Plezy\'de ögeleri izlendi olarak işaretlediğinizde, Trakt üzerinde de izlendi olarak işaretlenir.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr Bağla',
			'seerr.serverUrl' => 'Sunucu URL\'si',
			'seerr.serverUrlHelper' => 'Seerr örneğinizin adresi',
			'seerr.checkServer' => 'Devam Et',
			'seerr.signInWithJellyfin' => 'Jellyfin ile Giriş Yap',
			'seerr.signInWithEmby' => 'Emby ile Giriş Yap',
			'seerr.signInWithLocal' => 'Yerel hesap kullan',
			'seerr.email' => 'E-posta',
			'seerr.noSignInMethods' => 'Bu Seerr örneği Plezy\'nin desteklediği bir giriş yöntemi sunmuyor.',
			'seerr.instance' => 'Örnek (Instance)',
			'seerr.disconnectConfirm' => 'Seerr bağlantısı kesilsin mi?',
			'seerr.disconnectConfirmBody' => 'Plezy bu Seerr örneğini unutacak. İstediğiniz zaman yeniden bağlanabilirsiniz.',
			'seerr.request' => 'İstek Gönder',
			'seerr.request4k' => '4K İstek Gönder',
			'seerr.seasons' => 'Sezonlar',
			'seerr.allSeasons' => 'Tüm sezonlar',
			'seerr.advancedOptions' => 'Gelişmiş',
			'seerr.destinationServer' => 'Hedef sunucu',
			'seerr.qualityProfile' => 'Kalite profili',
			'seerr.rootFolder' => 'Kök klasör',
			'seerr.languageProfile' => 'Dil profili',
			'seerr.requestSubmitted' => 'İstek gönderildi',
			'seerr.requestFailed' => ({required Object error}) => 'İstek başarısız oldu: ${error}',
			'seerr.requestsLoadFailed' => 'İstek seçenekleri yüklenemedi',
			'seerr.nothingToRequest' => 'Her şey zaten mevcut veya istendi.',
			'seerr.statusAvailable' => 'Mevcut',
			'seerr.statusPartiallyAvailable' => 'Kısmen mevcut',
			'seerr.statusRequested' => 'İstendi',
			'seerr.statusProcessing' => 'İşleniyor',
			'services.title' => 'Servisler',
			'services.hubSubtitle' => 'İzleme ilerlemesini eşitleyin ve yeni başlıklar isteyin.',
			'services.notConnected' => 'Bağlı değil',
			'services.connectedAs' => ({required Object username}) => '@${username} olarak bağlandı',
			'services.scrobble' => 'İlerlemeyi otomatik takip et',
			'services.scrobbleDescription' => 'Bir bölümü veya filmi bitirdiğinizde listenizi güncelleyin.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} bağlantısı kesilsin mi?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy, ${service} güncellemeyi durduracak. İstediğiniz zaman yeniden bağlanabilirsiniz.',
			'services.connectFailed' => ({required Object service}) => '${service} ile bağlantı kurulamadı. Tekrar deneyin.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy\'yi ${service} üzerinde etkinleştirin',
			'services.deviceCode.body' => ({required Object url}) => '${url} adresini ziyaret edin ve bu kodu girin:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Etkinleştirmek için ${service} servisini açın',
			'services.deviceCode.copyCode' => 'Etkinleştirme kodunu kopyala',
			'services.deviceCode.waitingForAuthorization' => 'Yetkilendirme bekleniyor…',
			'services.deviceCode.codeCopied' => 'Kod kopyalandı',
			'services.oauthProxy.title' => ({required Object service}) => '${service} servisine giriş yapın',
			'services.oauthProxy.body' => 'Bu QR kodunu tarayın veya URL\'yi herhangi bir cihazda açın.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Giriş yapmak için ${service} servisini açın',
			'services.oauthProxy.copyUrl' => 'Giriş URL\'sini kopyala',
			'services.oauthProxy.urlCopied' => 'URL kopyalandı',
			'services.libraryFilter.title' => 'Kitaplık filtresi',
			'services.libraryFilter.subtitleAllSyncing' => 'Tüm kitaplıklar eşitleniyor',
			'services.libraryFilter.subtitleNoneSyncing' => 'Hiçbir şey eşitlenmiyor',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} engellendi',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} izin verildi',
			'services.libraryFilter.mode' => 'Filtre modu',
			'services.libraryFilter.modeBlacklist' => 'Kara Liste',
			'services.libraryFilter.modeWhitelist' => 'Beyaz Liste',
			'services.libraryFilter.modeHintBlacklist' => 'Aşağıda işaretlenenler dışındaki tüm kitaplıkları eşitle.',
			'services.libraryFilter.modeHintWhitelist' => 'Yalnızca aşağıda işaretlenen kitaplıkları eşitle.',
			'services.libraryFilter.libraries' => 'Kitaplıklar',
			'services.libraryFilter.noLibraries' => 'Kitaplık bulunmuyor',
			'addServer.serverUrls' => 'Sunucu URL\'leri',
			'addServer.serverUrlsHelper' => 'Virgülle ayrılmış birden fazla URL\'ye izin verilir.',
			'addServer.findServer' => 'Sunucu bul',
			'addServer.username' => 'Kullanıcı adı',
			'addServer.password' => 'Şifre',
			'addServer.signIn' => 'Giriş Yap',
			'addServer.change' => 'Değiştir',
			'addServer.required' => 'Gerekli',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Sunucuya ulaşılamadı: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Giriş başarısız: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Hızlı Bağlantı başarısız: ${error}',
			'addServer.addPlexTitle' => 'Plex ile Giriş Yap',
			'addServer.pinExpired' => 'Giriş yapmadan önce PIN süresi doldu. Lütfen tekrar deneyin.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Hesap kaydı başarısız oldu: ${error}',
			'addServer.addConnectionTitle' => 'Bağlantı ekle',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} profiline ekle',
			'addServer.signInWithPlexCard' => 'Plex ile Giriş Yap',
			'addServer.signInWithPlexCardSubtitle' => 'Bu cihazı yetkilendirin. Paylaşılan sunucular eklenir.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Bir Plex hesabını yetkilendirin. Ev kullanıcıları profile dönüşür.',
			'addServer.borrowFromAnotherProfile' => 'Başka bir profilden ödünç al',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Başka bir profilin bağlantısını yeniden kullanın. PIN korumalı profiller bir PIN gerektirir.',
			_ => null,
		};
	}
}
