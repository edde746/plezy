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
class TranslationsEs with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppEs app = _TranslationsAppEs._(_root);
	@override late final _TranslationsAuthEs auth = _TranslationsAuthEs._(_root);
	@override late final _TranslationsCommonEs common = _TranslationsCommonEs._(_root);
	@override late final _TranslationsScreensEs screens = _TranslationsScreensEs._(_root);
	@override late final _TranslationsUpdateEs update = _TranslationsUpdateEs._(_root);
	@override late final _TranslationsSettingsEs settings = _TranslationsSettingsEs._(_root);
	@override late final _TranslationsSearchEs search = _TranslationsSearchEs._(_root);
	@override late final _TranslationsHotkeysEs hotkeys = _TranslationsHotkeysEs._(_root);
	@override late final _TranslationsFileInfoEs fileInfo = _TranslationsFileInfoEs._(_root);
	@override late final _TranslationsMediaMenuEs mediaMenu = _TranslationsMediaMenuEs._(_root);
	@override late final _TranslationsAccessibilityEs accessibility = _TranslationsAccessibilityEs._(_root);
	@override late final _TranslationsTooltipsEs tooltips = _TranslationsTooltipsEs._(_root);
	@override late final _TranslationsVideoControlsEs videoControls = _TranslationsVideoControlsEs._(_root);
	@override late final _TranslationsUserStatusEs userStatus = _TranslationsUserStatusEs._(_root);
	@override late final _TranslationsMessagesEs messages = _TranslationsMessagesEs._(_root);
	@override late final _TranslationsSubtitlingStylingEs subtitlingStyling = _TranslationsSubtitlingStylingEs._(_root);
	@override late final _TranslationsMpvConfigEs mpvConfig = _TranslationsMpvConfigEs._(_root);
	@override late final _TranslationsDialogEs dialog = _TranslationsDialogEs._(_root);
	@override late final _TranslationsDiscoverEs discover = _TranslationsDiscoverEs._(_root);
	@override late final _TranslationsErrorsEs errors = _TranslationsErrorsEs._(_root);
	@override late final _TranslationsLibrariesEs libraries = _TranslationsLibrariesEs._(_root);
	@override late final _TranslationsAboutEs about = _TranslationsAboutEs._(_root);
	@override late final _TranslationsServerSelectionEs serverSelection = _TranslationsServerSelectionEs._(_root);
	@override late final _TranslationsHubDetailEs hubDetail = _TranslationsHubDetailEs._(_root);
	@override late final _TranslationsLogsEs logs = _TranslationsLogsEs._(_root);
	@override late final _TranslationsLicensesEs licenses = _TranslationsLicensesEs._(_root);
	@override late final _TranslationsNavigationEs navigation = _TranslationsNavigationEs._(_root);
	@override late final _TranslationsLiveTvEs liveTv = _TranslationsLiveTvEs._(_root);
	@override late final _TranslationsCollectionsEs collections = _TranslationsCollectionsEs._(_root);
	@override late final _TranslationsPlaylistsEs playlists = _TranslationsPlaylistsEs._(_root);
	@override late final _TranslationsWatchTogetherEs watchTogether = _TranslationsWatchTogetherEs._(_root);
	@override late final _TranslationsDownloadsEs downloads = _TranslationsDownloadsEs._(_root);
	@override late final _TranslationsShadersEs shaders = _TranslationsShadersEs._(_root);
	@override late final _TranslationsCompanionRemoteEs companionRemote = _TranslationsCompanionRemoteEs._(_root);
	@override late final _TranslationsVideoSettingsEs videoSettings = _TranslationsVideoSettingsEs._(_root);
	@override late final _TranslationsExternalPlayerEs externalPlayer = _TranslationsExternalPlayerEs._(_root);
	@override late final _TranslationsMetadataEditEs metadataEdit = _TranslationsMetadataEditEs._(_root);
	@override late final _TranslationsMatchScreenEs matchScreen = _TranslationsMatchScreenEs._(_root);
	@override late final _TranslationsServerTasksEs serverTasks = _TranslationsServerTasksEs._(_root);
	@override late final _TranslationsTraktEs trakt = _TranslationsTraktEs._(_root);
	@override late final _TranslationsTrackersEs trackers = _TranslationsTrackersEs._(_root);
}

// Path: app
class _TranslationsAppEs implements TranslationsAppEn {
	_TranslationsAppEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthEs implements TranslationsAuthEn {
	_TranslationsAuthEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inicia sesión con Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'Tiempo de autenticación agotado. Por favor, intenta de nuevo.';
	@override String get scanQRToSignIn => 'Escanea este código QR para iniciar sesión';
	@override String get waitingForAuth => 'Esperando autenticación...\nPor favor completa el inicio de sesión en tu navegador.';
	@override String get useBrowser => 'Usar navegador';
}

// Path: common
class _TranslationsCommonEs implements TranslationsCommonEn {
	_TranslationsCommonEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Cerrar';
	@override String get clear => 'Borrar';
	@override String get reset => 'Reiniciar';
	@override String get later => 'Más tarde';
	@override String get submit => 'Enviar';
	@override String get confirm => 'Confirmar';
	@override String get retry => 'Reintentar';
	@override String get logout => 'Cerrar sesión';
	@override String get unknown => 'Desconocido';
	@override String get refresh => 'Actualizar';
	@override String get yes => 'Sí';
	@override String get no => 'No';
	@override String get delete => 'Eliminar';
	@override String get shuffle => 'Aleatorio';
	@override String get addTo => 'Añadir a...';
	@override String get createNew => 'Crear';
	@override String get connect => 'Conectar';
	@override String get disconnect => 'Desconectar';
	@override String get play => 'Reproducir';
	@override String get pause => 'Pausa';
	@override String get resume => 'Reanudar';
	@override String get error => 'Error';
	@override String get search => 'Buscar';
	@override String get home => 'Inicio';
	@override String get back => 'Atrás';
	@override String get settings => 'Ajustes';
	@override String get mute => 'Silencio';
	@override String get ok => 'OK';
	@override String get reconnect => 'Reconectar';
	@override String get exitConfirmTitle => '¿Salir de la app?';
	@override String get exitConfirmMessage => '¿Estás seguro de que quieres salir?';
	@override String get dontAskAgain => 'No volver a preguntar';
	@override String get exit => 'Salir';
	@override String get viewAll => 'Ver todo';
	@override String get checkingNetwork => 'Comprobando red...';
	@override String get refreshingServers => 'Actualizando servidores...';
	@override String get loadingServers => 'Cargando servidores...';
	@override String get connectingToServers => 'Conectando a servidores...';
	@override String get startingOfflineMode => 'Iniciando modo sin conexión...';
	@override String get loading => 'Cargando...';
	@override String get fullscreen => 'Pantalla completa';
	@override String get exitFullscreen => 'Salir de pantalla completa';
	@override String get pressBackAgainToExit => 'Presiona atrás otra vez para salir';
}

// Path: screens
class _TranslationsScreensEs implements TranslationsScreensEn {
	_TranslationsScreensEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencias';
	@override String get switchProfile => 'Cambiar Perfil';
	@override String get subtitleStyling => 'Estilo de Subtítulos';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class _TranslationsUpdateEs implements TranslationsUpdateEn {
	_TranslationsUpdateEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get available => 'Actualización disponible';
	@override String versionAvailable({required Object version}) => 'Versión ${version} disponible';
	@override String currentVersion({required Object version}) => 'Actual: ${version}';
	@override String get skipVersion => 'Saltar esta versión';
	@override String get viewRelease => 'Ver versión';
	@override String get latestVersion => 'Ya estás en la última versión';
	@override String get checkFailed => 'Error al buscar actualizaciones';
}

// Path: settings
class _TranslationsSettingsEs implements TranslationsSettingsEn {
	_TranslationsSettingsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración';
	@override String get supportDeveloper => 'Apoya Plezy';
	@override String get supportDeveloperDescription => 'Dona vía Liberapay para financiar el desarrollo';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Apariencia';
	@override String get videoPlayback => 'Reproducción de Video';
	@override String get videoPlaybackDescription => 'Configurar el comportamiento de reproducción';
	@override String get advanced => 'Avanzado';
	@override String get episodePosterMode => 'Estilo de Póster de Episodio';
	@override String get seriesPoster => 'Póster de Serie';
	@override String get seasonPoster => 'Póster de Temporada';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Mostrar carrusel de contenido destacado en la pantalla de inicio';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Ingresa la duración (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Oscuro';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Densidad de Biblioteca';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Cómodo';
	@override String get viewMode => 'Modo de Vista';
	@override String get gridView => 'Cuadrícula';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar Sección Destacada';
	@override String get useGlobalHubs => 'Usar Diseño de Inicio de Plex';
	@override String get useGlobalHubsDescription => 'Mostrar los hubs de la página de inicio como el cliente oficial de Plex. Cuando está desactivado, muestra recomendaciones por biblioteca en su lugar.';
	@override String get showServerNameOnHubs => 'Mostrar Nombre del Servidor en los Hubs';
	@override String get showServerNameOnHubsDescription => 'Mostrar siempre el nombre del servidor en los títulos de los hubs. Cuando está desactivado, solo se muestra para nombres de hubs duplicados.';
	@override String get groupLibrariesByServer => 'Agrupar bibliotecas por servidor';
	@override String get groupLibrariesByServerDescription => 'Muestra un encabezado para cada servidor Plex en la barra lateral cuando estás conectado a varios servidores.';
	@override String get alwaysKeepSidebarOpen => 'Mantener siempre la barra lateral abierta';
	@override String get alwaysKeepSidebarOpenDescription => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse';
	@override String get showUnwatchedCount => 'Mostrar conteo de no vistos';
	@override String get showUnwatchedCountDescription => 'Mostrar el conteo de episodios no vistos en series y temporadas';
	@override String get showEpisodeNumberOnCards => 'Mostrar número de episodio en las tarjetas';
	@override String get showEpisodeNumberOnCardsDescription => 'Muestra el número de episodio junto a la temporada (p. ej. S2 E3) en las tarjetas de episodios';
	@override String get showSeasonPostersOnTabs => 'Mostrar pósters de temporada en las pestañas';
	@override String get showSeasonPostersOnTabsDescription => 'Muestra el póster de la temporada sobre cada pestaña de temporada en la página de detalles de una serie';
	@override String get hideSpoilers => 'Ocultar spoilers de episodios no vistos';
	@override String get hideSpoilersDescription => 'Difuminar miniaturas y ocultar descripciones de episodios que aún no has visto';
	@override String get playerBackend => 'Reproductor';
	@override String get exoPlayer => 'ExoPlayer (Recomendado)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Decodificación por Hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleración por hardware cuando esté disponible';
	@override String get bufferSize => 'Tamaño del Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Recomendado)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Tu dispositivo tiene ${heap}MB de memoria. Un búfer de ${size}MB puede causar problemas de reproducción.';
	@override String get defaultQualityTitle => 'Calidad predeterminada';
	@override String get defaultQualityDescription => 'Se utiliza al iniciar la reproducción. Los valores más bajos reducen el ancho de banda.';
	@override String get subtitleStyling => 'Estilo de Subtítulos';
	@override String get subtitleStylingDescription => 'Personalizar la apariencia de los subtítulos';
	@override String get smallSkipDuration => 'Salto pequeño';
	@override String get largeSkipDuration => 'Salto grande';
	@override String get rewindOnResume => 'Rebobinar al reanudar';
	@override String secondsUnit({required Object seconds}) => '${seconds} segundos';
	@override String get defaultSleepTimer => 'Temporizador de apagado';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutos';
	@override String get rememberTrackSelections => 'Recordar selección de pistas por serie/película';
	@override String get rememberTrackSelectionsDescription => 'Guardar automáticamente las preferencias de idioma de audio y subtítulos al cambiarlas durante la reproducción';
	@override String get clickVideoTogglesPlayback => 'Clic en el video para reproducir/pausar';
	@override String get clickVideoTogglesPlaybackDescription => 'Si está habilitado, hacer clic en el reproductor de video reproducirá/pausará el video. De lo contrario, mostrará/ocultará los controles.';
	@override String get videoPlayerControls => 'Controles del Reproductor de Video';
	@override String get keyboardShortcuts => 'Atajos de Teclado';
	@override String get keyboardShortcutsDescription => 'Personalizar los atajos de teclado';
	@override String get videoPlayerNavigation => 'Navegación del Reproductor de Video';
	@override String get videoPlayerNavigationDescription => 'Usar las teclas de flecha para navegar por los controles del reproductor';
	@override String get watchTogetherRelay => 'Relay de Ver Juntos';
	@override String get watchTogetherRelayDescription => 'Configurar un servidor relay personalizado para Ver Juntos. Todos los participantes deben usar el mismo servidor.';
	@override String get watchTogetherRelayHint => 'https://mi-relay.ejemplo.com';
	@override String get crashReporting => 'Informes de Errores';
	@override String get crashReportingDescription => 'Enviar informes de errores para mejorar la aplicación';
	@override String get debugLogging => 'Registro de Depuración';
	@override String get debugLoggingDescription => 'Habilitar registros detallados para resolución de problemas';
	@override String get viewLogs => 'Ver Logs';
	@override String get viewLogsDescription => 'Ver los registros de la aplicación';
	@override String get clearCache => 'Borrar Caché';
	@override String get clearCacheDescription => 'Esto borrará todas las imágenes y datos en caché. La aplicación puede tardar más en cargar contenido después de borrar la caché.';
	@override String get clearCacheSuccess => 'Caché borrada con éxito';
	@override String get resetSettings => 'Restablecer Configuración';
	@override String get resetSettingsDescription => 'Esto restablecerá todos los ajustes a sus valores predeterminados. Esta acción no se puede deshacer.';
	@override String get resetSettingsSuccess => 'Configuración restablecida con éxito';
	@override String get backup => 'Copia de seguridad';
	@override String get exportSettings => 'Exportar Configuración';
	@override String get exportSettingsDescription => 'Guardar tus preferencias en un archivo';
	@override String get exportSettingsSuccess => 'Configuración exportada';
	@override String get exportSettingsFailed => 'No se pudo exportar la configuración';
	@override String get importSettings => 'Importar Configuración';
	@override String get importSettingsDescription => 'Restaurar preferencias desde un archivo';
	@override String get importSettingsConfirm => 'Esto reemplazará tu configuración actual. ¿Continuar?';
	@override String get importSettingsSuccess => 'Configuración importada';
	@override String get importSettingsFailed => 'No se pudo importar la configuración';
	@override String get importSettingsInvalidFile => 'Este archivo no es una exportación válida de Plezy';
	@override String get importSettingsNoUser => 'Inicia sesión antes de importar la configuración';
	@override String get shortcutsReset => 'Atajos restablecidos a los valores predeterminados';
	@override String get about => 'Acerca de';
	@override String get aboutDescription => 'Información de la aplicación y licencias';
	@override String get updates => 'Actualizaciones';
	@override String get updateAvailable => 'Actualización disponible';
	@override String get checkForUpdates => 'Buscar actualizaciones';
	@override String get autoCheckUpdatesOnStartup => 'Buscar actualizaciones automáticamente al iniciar';
	@override String get autoCheckUpdatesOnStartupDescription => 'Mostrar una notificación cuando haya una nueva versión disponible al iniciar';
	@override String get validationErrorEnterNumber => 'Por favor, introduce un número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La duración debe estar entre ${min} y ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'El atajo ya está asignado a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atajo actualizado para ${action}';
	@override String get autoSkip => 'Salto automático';
	@override String get autoSkipIntro => 'Saltar Intro automáticamente';
	@override String get autoSkipIntroDescription => 'Saltar automáticamente los marcadores de intro después de unos segundos';
	@override String get autoSkipCredits => 'Saltar Créditos automáticamente';
	@override String get autoSkipCreditsDescription => 'Saltar automáticamente los créditos y reproducir el siguiente episodio';
	@override String get autoSkipDelay => 'Retraso de Salto automático';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Esperar ${seconds} segundos antes de saltar automáticamente';
	@override String get introPattern => 'Patrón de marcador de intro';
	@override String get introPatternDescription => 'Expresión regular para reconocer marcadores de intro en los títulos de capítulos';
	@override String get creditsPattern => 'Patrón de marcador de créditos';
	@override String get creditsPatternDescription => 'Expresión regular para reconocer marcadores de créditos en los títulos de capítulos';
	@override String get invalidRegex => 'Expresión regular no válida';
	@override String get downloads => 'Descargas';
	@override String get downloadLocationDescription => 'Elegir dónde almacenar el contenido descargado';
	@override String get downloadLocationDefault => 'Predeterminado (Almacenamiento de la App)';
	@override String get downloadLocationCustom => 'Ubicación personalizada';
	@override String get selectFolder => 'Seleccionar carpeta';
	@override String get resetToDefault => 'Restablecer al predeterminado';
	@override String currentPath({required Object path}) => 'Actual: ${path}';
	@override String get downloadLocationChanged => 'Ubicación de descarga cambiada';
	@override String get downloadLocationReset => 'Ubicación de descarga restablecida al predeterminado';
	@override String get downloadLocationInvalid => 'La carpeta seleccionada no tiene permisos de escritura';
	@override String get downloadLocationSelectError => 'Error al seleccionar la carpeta';
	@override String get downloadOnWifiOnly => 'Descargar solo con WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Evitar descargas cuando se usan datos móviles';
	@override String get autoRemoveWatchedDownloads => 'Eliminar descargas vistas automáticamente';
	@override String get autoRemoveWatchedDownloadsDescription => 'Eliminar automáticamente episodios y películas descargados cuando se marquen como vistos';
	@override String get cellularDownloadBlocked => 'Las descargas están desactivadas en datos móviles. Conéctate a una red WiFi o cambia la configuración.';
	@override String get maxVolume => 'Volumen Máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Presencia de Discord';
	@override String get discordRichPresenceDescription => 'Mostrar lo que estás viendo en Discord';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Sincronizar historial de visualización con Trakt';
	@override String get trackers => 'Rastreadores';
	@override String get trackersDescription => 'Sincronizar progreso con Trakt, MyAnimeList, AniList y Simkl';
	@override String get companionRemoteServer => 'Servidor de control remoto';
	@override String get companionRemoteServerDescription => 'Permitir que dispositivos móviles en tu red controlen esta aplicación';
	@override String get autoPip => 'Imagen en imagen automática';
	@override String get autoPipDescription => 'Activar automáticamente imagen en imagen al salir de la app durante la reproducción';
	@override String get matchContentFrameRate => 'Ajustar frecuencia de actualización';
	@override String get matchContentFrameRateDescription => 'Ajustar la frecuencia de actualización de la pantalla para que coincida con el video, reduciendo tirones y ahorrando batería';
	@override String get matchRefreshRate => 'Ajustar frecuencia de refresco';
	@override String get matchRefreshRateDescription => 'Cambiar la frecuencia de refresco de la pantalla para coincidir con el contenido de video en pantalla completa';
	@override String get matchDynamicRange => 'Ajustar rango dinámico';
	@override String get matchDynamicRangeDescription => 'Activar HDR automáticamente para contenido HDR y volver a SDR al salir del reproductor';
	@override String get displaySwitchDelay => 'Retraso de cambio de pantalla';
	@override String get tunneledPlayback => 'Reproducción tunelizada';
	@override String get tunneledPlaybackDescription => 'Usar tunelización de video acelerada por hardware. Desactivar si ves una pantalla negra con audio en contenido HDR';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil al abrir la app';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar selección de perfil cada vez que se abre la aplicación';
	@override String get confirmExitOnBack => 'Confirmar antes de salir';
	@override String get confirmExitOnBackDescription => 'Mostrar un diálogo de confirmación al presionar atrás para salir de la app';
	@override String get forceTvMode => 'Forzar modo TV';
	@override String get forceTvModeDescription => 'Usar el diseño de TV independientemente de la detección automática. Útil en dispositivos Android TV que no informan la característica leanback. Reinicia la app al cambiar.';
	@override String get startInFullscreen => 'Iniciar en pantalla completa';
	@override String get startInFullscreenDescription => 'Abrir Plezy en modo pantalla completa al iniciar';
	@override String get autoHidePerformanceOverlay => 'Ocultar superposición de rendimiento automáticamente';
	@override String get autoHidePerformanceOverlayDescription => 'Desvanecer la superposición de rendimiento con los controles de reproducción';
	@override String get showNavBarLabels => 'Mostrar etiquetas de la barra de navegación';
	@override String get showNavBarLabelsDescription => 'Mostrar etiquetas de texto bajo los iconos de la barra de navegación';
	@override String get liveTvDefaultFavorites => 'Canales favoritos por defecto';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar solo canales favoritos al abrir TV en vivo';
	@override String get display => 'Display';
	@override String get homeScreen => 'Home Screen';
	@override String get navigation => 'Navigation';
	@override String get window => 'Window';
	@override String get content => 'Content';
	@override String get player => 'Player';
	@override String get subtitlesAndConfig => 'Subtitles & Configuration';
	@override String get seekAndTiming => 'Seek & Timing';
	@override String get behavior => 'Behavior';
}

// Path: search
class _TranslationsSearchEs implements TranslationsSearchEn {
	_TranslationsSearchEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar películas, series, música...';
	@override String get tryDifferentTerm => 'Prueba con un término de búsqueda diferente';
	@override String get searchYourMedia => 'Busca en tu contenido';
	@override String get enterTitleActorOrKeyword => 'Introduce un título, actor o palabra clave';
}

// Path: hotkeys
class _TranslationsHotkeysEs implements TranslationsHotkeysEn {
	_TranslationsHotkeysEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Establecer atajo para ${actionName}';
	@override String get clearShortcut => 'Borrar atajo';
	@override late final _TranslationsHotkeysActionsEs actions = _TranslationsHotkeysActionsEs._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoEs implements TranslationsFileInfoEn {
	_TranslationsFileInfoEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Información del Archivo';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Archivo';
	@override String get advanced => 'Avanzado';
	@override String get codec => 'Códec';
	@override String get resolution => 'Resolución';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frecuencia de fotogramas';
	@override String get aspectRatio => 'Relación de aspecto';
	@override String get profile => 'Perfil';
	@override String get bitDepth => 'Profundidad de bits';
	@override String get colorSpace => 'Espacio de color';
	@override String get colorRange => 'Rango de color';
	@override String get colorPrimaries => 'Primarias de color';
	@override String get chromaSubsampling => 'Submuestreo de croma';
	@override String get channels => 'Canales';
	@override String get subtitles => 'Subtítulos';
	@override String get overallBitrate => 'Bitrate total';
	@override String get path => 'Ruta';
	@override String get size => 'Tamaño';
	@override String get container => 'Contenedor';
	@override String get duration => 'Duración';
	@override String get optimizedForStreaming => 'Optimizado para streaming';
	@override String get has64bitOffsets => 'Offsets de 64 bits';
}

// Path: mediaMenu
class _TranslationsMediaMenuEs implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como Visto';
	@override String get markAsUnwatched => 'Marcar como No Visto';
	@override String get removeFromContinueWatching => 'Eliminar de Seguir Viendo';
	@override String get goToSeries => 'Ir a la serie';
	@override String get goToSeason => 'Ir a la temporada';
	@override String get shufflePlay => 'Reproducción Aleatoria';
	@override String get fileInfo => 'Información del Archivo';
	@override String get deleteFromServer => 'Eliminar del servidor';
	@override String get confirmDelete => 'Esto eliminará permanentemente este contenido y sus archivos de tu servidor. Esta acción no se puede deshacer.';
	@override String get deleteMultipleWarning => 'Esto incluye todos los episodios y sus archivos.';
	@override String get mediaDeletedSuccessfully => 'Elemento multimedia eliminado con éxito';
	@override String get mediaFailedToDelete => 'Error al eliminar el elemento multimedia';
	@override String get rate => 'Calificar';
	@override String get playFromBeginning => 'Reproducir desde el inicio';
	@override String get playVersion => 'Reproducir versión...';
}

// Path: accessibility
class _TranslationsAccessibilityEs implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, película';
	@override String mediaCardShow({required Object title}) => '${title}, serie de TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} por ciento visto';
	@override String get mediaCardUnwatched => 'no visto';
	@override String get tapToPlay => 'Toca para reproducir';
}

// Path: tooltips
class _TranslationsTooltipsEs implements TranslationsTooltipsEn {
	_TranslationsTooltipsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reproducción aleatoria';
	@override String get playTrailer => 'Reproducir tráiler';
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como no visto';
}

// Path: videoControls
class _TranslationsVideoControlsEs implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Subtítulos';
	@override String get resetToZero => 'Restablecer a 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} se reproduce más tarde';
	@override String playsEarlier({required Object label}) => '${label} se reproduce antes';
	@override String get noOffset => 'Sin desfase';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Llenar pantalla';
	@override String get stretch => 'Estirar';
	@override String get lockRotation => 'Bloquear rotación';
	@override String get unlockRotation => 'Desbloquear rotación';
	@override String get timerActive => 'Temporizador Activo';
	@override String playbackWillPauseIn({required Object duration}) => 'La reproducción se pausará en ${duration}';
	@override String get stillWatching => '¿Sigues viendo?';
	@override String pausingIn({required Object seconds}) => 'Pausa en ${seconds}s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Reproducir siguiente automáticamente';
	@override String get playNext => 'Reproducir siguiente';
	@override String get playButton => 'Reproducir';
	@override String get pauseButton => 'Pausa';
	@override String seekBackwardButton({required Object seconds}) => 'Retroceder ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avanzar ${seconds} segundos';
	@override String get previousButton => 'Episodio anterior';
	@override String get nextButton => 'Episodio siguiente';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Capítulo siguiente';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Activar sonido';
	@override String get settingsButton => 'Ajustes de video';
	@override String get tracksButton => 'Audio y subtítulos';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionsButton => 'Versiones de video';
	@override String get versionQualityButton => 'Versión y calidad';
	@override String get versionColumnHeader => 'Versión';
	@override String get qualityColumnHeader => 'Calidad';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodificación no disponible — reproduciendo calidad original';
	@override String get pipButton => 'Modo PiP (Imagen en Imagen)';
	@override String get aspectRatioButton => 'Relación de aspecto';
	@override String get ambientLighting => 'Iluminación ambiental';
	@override String get fullscreenButton => 'Entrar en pantalla completa';
	@override String get exitFullscreenButton => 'Salir de pantalla completa';
	@override String get alwaysOnTopButton => 'Siempre visible';
	@override String get rotationLockButton => 'Bloqueo de rotación';
	@override String get lockScreen => 'Bloquear pantalla';
	@override String get screenLockButton => 'Bloqueo de pantalla';
	@override String get longPressToUnlock => 'Mantén pulsado para desbloquear';
	@override String get timelineSlider => 'Línea de tiempo del video';
	@override String get volumeSlider => 'Nivel de volumen';
	@override String endsAt({required Object time}) => 'Termina a las ${time}';
	@override String get pipActive => 'Reproduciendo en Imagen en Imagen';
	@override String get pipFailed => 'Error al iniciar Imagen en Imagen';
	@override late final _TranslationsVideoControlsPipErrorsEs pipErrors = _TranslationsVideoControlsPipErrorsEs._(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'No hay capítulos disponibles';
	@override String get queue => 'Cola';
	@override String get noQueueItems => 'No hay elementos en la cola';
	@override String get searchSubtitles => 'Buscar subtítulos';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'No se encontraron subtítulos';
	@override String get subtitleDownloaded => 'Subtítulo descargado';
	@override String get subtitleDownloadFailed => 'Error al descargar subtítulo';
	@override String get searchLanguages => 'Buscar idiomas...';
}

// Path: userStatus
class _TranslationsUserStatusEs implements TranslationsUserStatusEn {
	_TranslationsUserStatusEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Administrador';
	@override String get restricted => 'Restringido';
	@override String get protected => 'Protegido';
	@override String get current => 'ACTUAL';
}

// Path: messages
class _TranslationsMessagesEs implements TranslationsMessagesEn {
	_TranslationsMessagesEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como visto';
	@override String get markedAsUnwatched => 'Marcado como no visto';
	@override String get markedAsWatchedOffline => 'Marcado como visto (se sincronizará al estar en línea)';
	@override String get markedAsUnwatchedOffline => 'Marcado como no visto (se sincronizará al estar en línea)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Eliminado automáticamente: ${title}';
	@override String get removedFromContinueWatching => 'Eliminado de Seguir Viendo';
	@override String errorLoading({required Object error}) => 'Error: ${error}';
	@override String get fileInfoNotAvailable => 'Información de archivo no disponible';
	@override String errorLoadingFileInfo({required Object error}) => 'Error al cargar info de archivo: ${error}';
	@override String get errorLoadingSeries => 'Error al cargar la serie';
	@override String get errorLoadingSeason => 'Error al cargar la temporada';
	@override String get musicNotSupported => 'La reproducción de música aún no está soportada';
	@override String get noDescriptionAvailable => 'No hay descripción disponible';
	@override String get noProfilesAvailable => 'No hay perfiles disponibles';
	@override String get contactAdminForProfiles => 'Contacta con tu administrador de Plex para añadir perfiles';
	@override String get unableToDetermineLibrarySection => 'No se puede determinar la sección de biblioteca para este elemento';
	@override String get logsCleared => 'Logs borrados';
	@override String get logsCopied => 'Logs copiados al portapapeles';
	@override String get noLogsAvailable => 'No hay logs disponibles';
	@override String libraryScanning({required Object title}) => 'Escaneando "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Escaneo de biblioteca iniciado para "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Error al escanear biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Actualizando metadatos de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Actualización de metadatos iniciada para "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Error al actualizar metadatos: ${error}';
	@override String get logoutConfirm => '¿Estás seguro de que quieres cerrar sesión?';
	@override String get noSeasonsFound => 'No se encontraron temporadas';
	@override String get noEpisodesFound => 'No se encontraron episodios en la primera temporada';
	@override String get noEpisodesFoundGeneral => 'No se encontraron episodios';
	@override String get noResultsFound => 'No se encontraron resultados';
	@override String sleepTimerSet({required Object label}) => 'Temporizador establecido en ${label}';
	@override String get noItemsAvailable => 'No hay elementos disponibles';
	@override String get failedToCreatePlayQueueNoItems => 'Error al crear la cola de reproducción - no hay elementos';
	@override String failedPlayback({required Object action, required Object error}) => 'Error al ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Cambiando a reproductor compatible...';
	@override String get serverLimitTitle => 'Error de reproducción';
	@override String get serverLimitBody => 'El servidor devolvió un error (HTTP 500). Normalmente esto significa que el propietario del servidor ha establecido un límite de ancho de banda o transcodificación que está rechazando tu sesión. No hay nada que puedas hacer desde el cliente — el propietario del servidor debe ajustar su configuración.';
	@override String get logsUploaded => 'Registros subidos';
	@override String get logsUploadFailed => 'Error al subir registros';
	@override String get logId => 'ID de registro';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingEs implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
	@override String get border => 'Borde';
	@override String get background => 'Fondo';
	@override String get fontSize => 'Tamaño de Fuente';
	@override String get textColor => 'Color de Texto';
	@override String get borderSize => 'Tamaño de Borde';
	@override String get borderColor => 'Color de Borde';
	@override String get backgroundOpacity => 'Opacidad de Fondo';
	@override String get backgroundColor => 'Color de Fondo';
	@override String get position => 'Posición';
	@override String get assOverride => 'Sobreescritura ASS';
	@override String get bold => 'Negrita';
	@override String get italic => 'Cursiva';
}

// Path: mpvConfig
class _TranslationsMpvConfigEs implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración de mpv';
	@override String get description => 'Ajustes avanzados del reproductor de video';
	@override String get presets => 'Ajustes preestablecidos';
	@override String get noPresets => 'No hay ajustes guardados';
	@override String get saveAsPreset => 'Guardar como Ajuste...';
	@override String get presetName => 'Nombre del Ajuste';
	@override String get presetNameHint => 'Introduce un nombre para este ajuste';
	@override String get loadPreset => 'Cargar';
	@override String get deletePreset => 'Eliminar';
	@override String get presetSaved => 'Ajuste guardado';
	@override String get presetLoaded => 'Ajuste cargado';
	@override String get presetDeleted => 'Ajuste eliminado';
	@override String get confirmDeletePreset => '¿Estás seguro de que quieres eliminar este ajuste?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogEs implements TranslationsDialogEn {
	_TranslationsDialogEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar Acción';
}

// Path: discover
class _TranslationsDiscoverEs implements TranslationsDiscoverEn {
	_TranslationsDiscoverEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descubrir';
	@override String get switchProfile => 'Cambiar Perfil';
	@override String get noContentAvailable => 'No hay contenido disponible';
	@override String get addMediaToLibraries => 'Añade contenido a tus bibliotecas';
	@override String get continueWatching => 'Seguir Viendo';
	@override String playEpisode({required Object season, required Object episode}) => 'T${season}E${episode}';
	@override String get overview => 'Resumen';
	@override String get cast => 'Reparto';
	@override String get extras => 'Tráilers y Extras';
	@override String get studio => 'Estudio';
	@override String get rating => 'Calificación';
	@override String get movie => 'Película';
	@override String get tvShow => 'Serie de TV';
	@override String minutesLeft({required Object minutes}) => 'quedan ${minutes} min';
}

// Path: errors
class _TranslationsErrorsEs implements TranslationsErrorsEn {
	_TranslationsErrorsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Error en la búsqueda: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tiempo de conexión agotado al cargar ${context}';
	@override String get connectionFailed => 'No se pudo conectar con el servidor Plex';
	@override String failedToLoad({required Object context, required Object error}) => 'Error al cargar ${context}: ${error}';
	@override String get noClientAvailable => 'No hay cliente disponible';
	@override String authenticationFailed({required Object error}) => 'Error de autenticación: ${error}';
	@override String get couldNotLaunchUrl => 'No se pudo abrir la URL de autenticación';
	@override String get pleaseEnterToken => 'Por favor, introduce un token';
	@override String get invalidToken => 'Token no válido';
	@override String failedToVerifyToken({required Object error}) => 'Error al verificar el token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Error al cambiar al perfil ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesEs implements TranslationsLibrariesEn {
	_TranslationsLibrariesEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
	@override String get scanLibraryFiles => 'Escanear Archivos de la Biblioteca';
	@override String get scanLibrary => 'Escanear Biblioteca';
	@override String get analyze => 'Analizar';
	@override String get analyzeLibrary => 'Analizar Biblioteca';
	@override String get refreshMetadata => 'Actualizar Metadatos';
	@override String get emptyTrash => 'Vaciar Papelera';
	@override String emptyingTrash({required Object title}) => 'Vaciando papelera de "${title}"...';
	@override String trashEmptied({required Object title}) => 'Papelera vaciada para "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Error al vaciar papelera: ${error}';
	@override String analyzing({required Object title}) => 'Analizando "${title}"...';
	@override String analysisStarted({required Object title}) => 'Análisis iniciado para "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Error al analizar la biblioteca: ${error}';
	@override String get noLibrariesFound => 'No se encontraron bibliotecas';
	@override String get allLibrariesHidden => 'Todas las bibliotecas están ocultas';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliotecas ocultas (${count})';
	@override String get thisLibraryIsEmpty => 'Esta biblioteca está vacía';
	@override String get all => 'Todos';
	@override String get clearAll => 'Borrar Todo';
	@override String scanLibraryConfirm({required Object title}) => '¿Estás seguro de que quieres escanear "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => '¿Estás seguro de que quieres analizar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => '¿Estás seguro de que quieres actualizar los metadatos de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => '¿Estás seguro de que quieres vaciar la papelera de "${title}"?';
	@override String get manageLibraries => 'Gestionar Bibliotecas';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar por';
	@override String get filters => 'Filtros';
	@override String get confirmActionMessage => '¿Estás seguro de que quieres realizar esta acción?';
	@override String get showLibrary => 'Mostrar biblioteca';
	@override String get hideLibrary => 'Ocultar biblioteca';
	@override String get libraryOptions => 'Opciones de biblioteca';
	@override String get content => 'contenido de la biblioteca';
	@override String get selectLibrary => 'Seleccionar biblioteca';
	@override String filtersWithCount({required Object count}) => 'Filtros (${count})';
	@override String get noRecommendations => 'No hay recomendaciones disponibles';
	@override String get noCollections => 'No hay colecciones en esta biblioteca';
	@override String get noFoldersFound => 'No se encontraron carpetas';
	@override String get folders => 'carpetas';
	@override late final _TranslationsLibrariesTabsEs tabs = _TranslationsLibrariesTabsEs._(_root);
	@override late final _TranslationsLibrariesGroupingsEs groupings = _TranslationsLibrariesGroupingsEs._(_root);
}

// Path: about
class _TranslationsAboutEs implements TranslationsAboutEn {
	_TranslationsAboutEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Acerca de';
	@override String get openSourceLicenses => 'Licencias de Código Abierto';
	@override String versionLabel({required Object version}) => 'Versión ${version}';
	@override String get appDescription => 'Un cliente de Plex para Flutter';
	@override String get viewLicensesDescription => 'Ver licencias de librerías de terceros';
}

// Path: serverSelection
class _TranslationsServerSelectionEs implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'No se pudo conectar con ningún servidor. Por favor, comprueba tu conexión e inténtalo de nuevo.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'No se encontraron servidores para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Error al cargar servidores: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailEs implements TranslationsHubDetailEn {
	_TranslationsHubDetailEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Año de lanzamiento';
	@override String get dateAdded => 'Añadido el';
	@override String get rating => 'Calificación';
	@override String get noItemsFound => 'No se encontraron elementos';
}

// Path: logs
class _TranslationsLogsEs implements TranslationsLogsEn {
	_TranslationsLogsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Borrar Logs';
	@override String get copyLogs => 'Copiar Logs';
	@override String get uploadLogs => 'Subir registros';
}

// Path: licenses
class _TranslationsLicensesEs implements TranslationsLicensesEn {
	_TranslationsLicensesEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Paquetes relacionados';
	@override String get license => 'Licencia';
	@override String licenseNumber({required Object number}) => 'Licencia ${number}';
	@override String licensesCount({required Object count}) => '${count} licencias';
}

// Path: navigation
class _TranslationsNavigationEs implements TranslationsNavigationEn {
	_TranslationsNavigationEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Medios';
	@override String get downloads => 'Descargas';
	@override String get liveTv => 'TV en vivo';
}

// Path: liveTv
class _TranslationsLiveTvEs implements TranslationsLiveTvEn {
	_TranslationsLiveTvEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV en vivo';
	@override String get guide => 'Guía';
	@override String get noChannels => 'No hay canales disponibles';
	@override String get noDvr => 'No hay DVR configurado en ningún servidor';
	@override String get noPrograms => 'No hay datos de programación disponibles';
	@override String get live => 'EN VIVO';
	@override String get reloadGuide => 'Recargar guía';
	@override String get now => 'Ahora';
	@override String get today => 'Hoy';
	@override String get midnight => 'Medianoche';
	@override String get overnight => 'Madrugada';
	@override String get morning => 'Mañana';
	@override String get daytime => 'Día';
	@override String get evening => 'Noche';
	@override String get lateNight => 'Trasnoche';
	@override String get whatsOn => 'En emisión';
	@override String get watchChannel => 'Ver canal';
	@override String get favorites => 'Favoritos';
	@override String get reorderFavorites => 'Reordenar favoritos';
	@override String get joinSession => 'Unirse a sesión en curso';
	@override String watchFromStart({required Object minutes}) => 'Ver desde el inicio (hace ${minutes} min)';
	@override String get watchLive => 'Ver en vivo';
	@override String get goToLive => 'Ir a en vivo';
}

// Path: collections
class _TranslationsCollectionsEs implements TranslationsCollectionsEn {
	_TranslationsCollectionsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colecciones';
	@override String get collection => 'Colección';
	@override String get empty => 'La colección está vacía';
	@override String get unknownLibrarySection => 'No se puede eliminar: Sección de biblioteca desconocida';
	@override String get deleteCollection => 'Eliminar Colección';
	@override String deleteConfirm({required Object title}) => '¿Estás seguro de que quieres eliminar "${title}"? Esta acción no se puede deshacer.';
	@override String get deleted => 'Colección eliminada';
	@override String get deleteFailed => 'Error al eliminar la colección';
	@override String deleteFailedWithError({required Object error}) => 'Error al eliminar la colección: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Error al cargar los elementos de la colección: ${error}';
	@override String get selectCollection => 'Seleccionar Colección';
	@override String get collectionName => 'Nombre de la Colección';
	@override String get enterCollectionName => 'Introduce el nombre de la colección';
	@override String get addedToCollection => 'Añadido a la colección';
	@override String get errorAddingToCollection => 'Error al añadir a la colección';
	@override String get created => 'Colección creada';
	@override String get removeFromCollection => 'Eliminar de la colección';
	@override String removeFromCollectionConfirm({required Object title}) => '¿Eliminar "${title}" de esta colección?';
	@override String get removedFromCollection => 'Eliminado de la colección';
	@override String get removeFromCollectionFailed => 'Error al eliminar de la colección';
	@override String removeFromCollectionError({required Object error}) => 'Error al eliminar de la colección: ${error}';
	@override String get searchCollections => 'Buscar colecciones...';
}

// Path: playlists
class _TranslationsPlaylistsEs implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Listas de reproducción';
	@override String get playlist => 'Lista de reproducción';
	@override String get noPlaylists => 'No se encontraron listas de reproducción';
	@override String get create => 'Crear Lista de Reproducción';
	@override String get playlistName => 'Nombre de la Lista';
	@override String get enterPlaylistName => 'Introduce el nombre de la lista';
	@override String get delete => 'Eliminar Lista';
	@override String get removeItem => 'Eliminar de la Lista';
	@override String get smartPlaylist => 'Lista Inteligente';
	@override String itemCount({required Object count}) => '${count} elementos';
	@override String get oneItem => '1 elemento';
	@override String get emptyPlaylist => 'Esta lista está vacía';
	@override String get deleteConfirm => '¿Eliminar Lista de Reproducción?';
	@override String deleteMessage({required Object name}) => '¿Estás seguro de que quieres eliminar "${name}"?';
	@override String get created => 'Lista de reproducción creada';
	@override String get deleted => 'Lista de reproducción eliminada';
	@override String get itemAdded => 'Añadido a la lista';
	@override String get itemRemoved => 'Eliminado de la lista';
	@override String get selectPlaylist => 'Seleccionar Lista';
	@override String get errorCreating => 'Error al crear la lista';
	@override String get errorDeleting => 'Error al eliminar la lista';
	@override String get errorLoading => 'Error al cargar las listas';
	@override String get errorAdding => 'Error al añadir a la lista';
	@override String get errorReordering => 'Error al reordenar los elementos de la lista';
	@override String get errorRemoving => 'Error al eliminar de la lista';
}

// Path: watchTogether
class _TranslationsWatchTogetherEs implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ver Juntos';
	@override String get description => 'Mira contenido en sincronía con amigos y familiares';
	@override String get createSession => 'Crear Sesión';
	@override String get creating => 'Creando...';
	@override String get joinSession => 'Unirse a Sesión';
	@override String get joining => 'Uniendo...';
	@override String get controlMode => 'Modo de Control';
	@override String get controlModeQuestion => '¿Quién puede controlar la reproducción?';
	@override String get hostOnly => 'Solo el Anfitrión';
	@override String get anyone => 'Cualquiera';
	@override String get hostingSession => 'Anfitrión de la Sesión';
	@override String get inSession => 'En Sesión';
	@override String get sessionCode => 'Código de Sesión';
	@override String get hostControlsPlayback => 'El anfitrión controla la reproducción';
	@override String get anyoneCanControl => 'Cualquiera puede controlar la reproducción';
	@override String get hostControls => 'Control del anfitrión';
	@override String get anyoneControls => 'Control de cualquiera';
	@override String get participants => 'Participantes';
	@override String get host => 'Anfitrión';
	@override String get hostBadge => 'ANFITRIÓN';
	@override String get youAreHost => 'Eres el anfitrión';
	@override String get watchingWithOthers => 'Viendo con otros';
	@override String get endSession => 'Finalizar Sesión';
	@override String get leaveSession => 'Salir de la Sesión';
	@override String get endSessionQuestion => '¿Finalizar Sesión?';
	@override String get leaveSessionQuestion => '¿Salir de la Sesión?';
	@override String get endSessionConfirm => 'Esto finalizará la sesión para todos los participantes.';
	@override String get leaveSessionConfirm => 'Serás eliminado de la sesión.';
	@override String get endSessionConfirmOverlay => 'Esto finalizará la sesión de visualización para todos los participantes.';
	@override String get leaveSessionConfirmOverlay => 'Serás desconectado de la sesión de visualización.';
	@override String get end => 'Finalizar';
	@override String get leave => 'Salir';
	@override String get syncing => 'Sincronizando...';
	@override String get joinWatchSession => 'Unirse a Sesión de Visualización';
	@override String get enterCodeHint => 'Introduce el código de 5 caracteres';
	@override String get pasteFromClipboard => 'Pegar desde el portapapeles';
	@override String get pleaseEnterCode => 'Por favor, introduce un código de sesión';
	@override String get codeMustBe5Chars => 'El código de sesión debe tener 5 caracteres';
	@override String get joinInstructions => 'Introduce el código de sesión compartido por el anfitrión para unirte a su sesión.';
	@override String get failedToCreate => 'Error al crear la sesión';
	@override String get failedToJoin => 'Error al unirse a la sesión';
	@override String get sessionCodeCopied => 'Código de sesión copiado al portapapeles';
	@override String get relayUnreachable => 'El servidor de retransmisión no está disponible. Esto puede deberse a que tu proveedor de internet bloquea la conexión. Puedes intentarlo de todos modos, pero Watch Together podría no funcionar.';
	@override String get reconnectingToHost => 'Reconectando con el anfitrión...';
	@override String get currentPlayback => 'Reproducción actual';
	@override String get joinCurrentPlayback => 'Unirse a la reproducción actual';
	@override String get joinCurrentPlaybackDescription => 'Vuelve a lo que el anfitrión está viendo ahora mismo';
	@override String get failedToOpenCurrentPlayback => 'No se pudo abrir la reproducción actual';
	@override String participantJoined({required Object name}) => '${name} se unió';
	@override String participantLeft({required Object name}) => '${name} se fue';
	@override String participantPaused({required Object name}) => '${name} pausó';
	@override String participantResumed({required Object name}) => '${name} reanudó';
	@override String participantSeeked({required Object name}) => '${name} avanzó';
	@override String participantBuffering({required Object name}) => '${name} está cargando';
	@override String get waitingForParticipants => 'Esperando a que otros carguen...';
	@override String get recentRooms => 'Salas recientes';
	@override String get renameRoom => 'Renombrar sala';
	@override String get removeRoom => 'Eliminar';
}

// Path: downloads
class _TranslationsDownloadsEs implements TranslationsDownloadsEn {
	_TranslationsDownloadsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descargas';
	@override String get manage => 'Gestionar';
	@override String get tvShows => 'Series de TV';
	@override String get movies => 'Películas';
	@override String get noDownloads => 'No hay descargas aún';
	@override String get noDownloadsDescription => 'El contenido descargado aparecerá aquí para verlo sin conexión';
	@override String get downloadNow => 'Descargar';
	@override String get deleteDownload => 'Eliminar descarga';
	@override String get retryDownload => 'Reintentar descarga';
	@override String get downloadQueued => 'Descarga en cola';
	@override String get serverErrorBitrate => 'Error del servidor — el archivo puede exceder el límite de bitrate de transmisión remota';
	@override String episodesQueued({required Object count}) => '${count} episodios en cola para descargar';
	@override String get downloadDeleted => 'Descarga eliminada';
	@override String deleteConfirm({required Object title}) => '¿Estás seguro de que quieres eliminar "${title}"? Esto borrará el archivo descargado de tu dispositivo.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})';
	@override String get deleting => 'Eliminando...';
	@override String get queuedTooltip => 'En cola';
	@override String queuedFilesTooltip({required Object files}) => 'En cola: ${files}';
	@override String get downloadingTooltip => 'Descargando...';
	@override String downloadingFilesTooltip({required Object files}) => 'Descargando ${files}';
	@override String get noDownloadsTree => 'Sin descargas';
	@override String get pauseAll => 'Pausar todo';
	@override String get resumeAll => 'Reanudar todo';
	@override String get deleteAll => 'Eliminar todo';
	@override String get selectVersion => 'Seleccionar versión';
	@override String get allEpisodes => 'Todos los episodios';
	@override String get unwatchedOnly => 'Solo no vistos';
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} no vistos';
	@override String get customAmount => 'Cantidad personalizada...';
	@override String get howManyEpisodes => '¿Cuántos episodios?';
	@override String itemsQueued({required Object count}) => '${count} elementos en cola de descarga';
	@override String get keepSynced => 'Mantener sincronizado';
	@override String get downloadOnce => 'Descargar una vez';
	@override String keepNUnwatched({required Object count}) => 'Mantener ${count} sin ver';
	@override String get editSyncRule => 'Editar regla de sincronización';
	@override String get removeSyncRule => 'Eliminar regla de sincronización';
	@override String removeSyncRuleConfirm({required Object title}) => '¿Dejar de sincronizar "${title}"? Los episodios descargados se conservarán.';
	@override String syncRuleCreated({required Object count}) => 'Regla de sincronización creada — conservando ${count} episodios sin ver';
	@override String get syncRuleUpdated => 'Regla de sincronización actualizada';
	@override String get syncRuleRemoved => 'Regla de sincronización eliminada';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} nuevos episodios sincronizados para ${title}';
	@override String get activeSyncRules => 'Reglas de sincronización';
	@override String get noSyncRules => 'Sin reglas de sincronización';
	@override String get manageSyncRule => 'Gestionar sincronización';
	@override String get editEpisodeCount => 'Número de episodios';
	@override String get editSyncFilter => 'Filtro de sincronización';
	@override String get syncAllItems => 'Sincronizando todos los elementos';
	@override String get syncUnwatchedItems => 'Sincronizando elementos no vistos';
	@override String get syncRuleListCreated => 'Regla de sincronización creada';
}

// Path: shaders
class _TranslationsShadersEs implements TranslationsShadersEn {
	_TranslationsShadersEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sin mejora de video';
	@override String get nvscalerDescription => 'Escalado de imagen NVIDIA para un video más nítido';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Reducción de ruido';
	@override String get artcnnVariantDenoiseSharpen => 'Reducción de ruido + enfoque';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta Calidad';
	@override String get mode => 'Modo';
	@override String get importShader => 'Importar shader';
	@override String get customShaderDescription => 'Shader GLSL personalizado';
	@override String get shaderImported => 'Shader importado';
	@override String get shaderImportFailed => 'Error al importar shader';
	@override String get deleteShader => 'Eliminar shader';
	@override String deleteShaderConfirm({required Object name}) => '¿Eliminar "${name}"?';
}

// Path: companionRemote
class _TranslationsCompanionRemoteEs implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Control remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override late final _TranslationsCompanionRemoteSessionEs session = _TranslationsCompanionRemoteSessionEs._(_root);
	@override late final _TranslationsCompanionRemotePairingEs pairing = _TranslationsCompanionRemotePairingEs._(_root);
	@override late final _TranslationsCompanionRemoteRemoteEs remote = _TranslationsCompanionRemoteRemoteEs._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsEs implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Ajustes de reproducción';
	@override String get playbackSpeed => 'Velocidad de reproducción';
	@override String get sleepTimer => 'Temporizador de apagado';
	@override String get audioSync => 'Sincronización de audio';
	@override String get subtitleSync => 'Sincronización de subtítulos';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Salida de audio';
	@override String get performanceOverlay => 'Indicador de rendimiento';
	@override String get audioPassthrough => 'Audio Passthrough';
	@override String get audioNormalization => 'Normalizar volumen';
}

// Path: externalPlayer
class _TranslationsExternalPlayerEs implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reproductor externo';
	@override String get useExternalPlayer => 'Usar reproductor externo';
	@override String get useExternalPlayerDescription => 'Abrir vídeos en una app externa en lugar del reproductor integrado';
	@override String get selectPlayer => 'Seleccionar reproductor';
	@override String get customPlayers => 'Reproductores personalizados';
	@override String get systemDefault => 'Predeterminado del sistema';
	@override String get addCustomPlayer => 'Añadir reproductor personalizado';
	@override String get playerName => 'Nombre del reproductor';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nombre del paquete';
	@override String get playerUrlScheme => 'Esquema URL';
	@override String get off => 'Desactivado';
	@override String get launchFailed => 'No se pudo abrir el reproductor externo';
	@override String appNotInstalled({required Object name}) => '${name} no está instalado';
	@override String get playInExternalPlayer => 'Reproducir en reproductor externo';
}

// Path: metadataEdit
class _TranslationsMetadataEditEs implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar...';
	@override String get screenTitle => 'Editar metadatos';
	@override String get basicInfo => 'Información básica';
	@override String get artwork => 'Artwork';
	@override String get advancedSettings => 'Ajustes avanzados';
	@override String get title => 'Título';
	@override String get sortTitle => 'Título de ordenación';
	@override String get originalTitle => 'Título original';
	@override String get releaseDate => 'Fecha de estreno';
	@override String get contentRating => 'Clasificación de contenido';
	@override String get studio => 'Estudio';
	@override String get tagline => 'Eslogan';
	@override String get summary => 'Resumen';
	@override String get poster => 'Póster';
	@override String get background => 'Fondo';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Imagen cuadrada';
	@override String get selectPoster => 'Seleccionar póster';
	@override String get selectBackground => 'Seleccionar fondo';
	@override String get selectLogo => 'Seleccionar logo';
	@override String get selectSquareArt => 'Seleccionar imagen cuadrada';
	@override String get fromUrl => 'Desde URL';
	@override String get uploadFile => 'Subir archivo';
	@override String get enterImageUrl => 'Introducir URL de imagen';
	@override String get imageUrl => 'URL de imagen';
	@override String get metadataUpdated => 'Metadatos actualizados';
	@override String get metadataUpdateFailed => 'Error al actualizar los metadatos';
	@override String get artworkUpdated => 'Artwork actualizado';
	@override String get artworkUpdateFailed => 'Error al actualizar el artwork';
	@override String get noArtworkAvailable => 'No hay artwork disponible';
	@override String get notSet => 'No establecido';
	@override String get libraryDefault => 'Predeterminado de biblioteca';
	@override String get accountDefault => 'Predeterminado de cuenta';
	@override String get seriesDefault => 'Predeterminado de serie';
	@override String get episodeSorting => 'Orden de episodios';
	@override String get oldestFirst => 'Más antiguos primero';
	@override String get newestFirst => 'Más recientes primero';
	@override String get keep => 'Conservar';
	@override String get allEpisodes => 'Todos los episodios';
	@override String latestEpisodes({required Object count}) => '${count} episodios más recientes';
	@override String get latestEpisode => 'Episodio más reciente';
	@override String episodesAddedPastDays({required Object count}) => 'Episodios añadidos en los últimos ${count} días';
	@override String get deleteAfterPlaying => 'Eliminar episodios después de reproducir';
	@override String get never => 'Nunca';
	@override String get afterADay => 'Después de un día';
	@override String get afterAWeek => 'Después de una semana';
	@override String get afterAMonth => 'Después de un mes';
	@override String get onNextRefresh => 'En la próxima actualización';
	@override String get seasons => 'Temporadas';
	@override String get show => 'Mostrar';
	@override String get hide => 'Ocultar';
	@override String get episodeOrdering => 'Orden de episodios';
	@override String get tmdbAiring => 'The Movie Database (Emisión)';
	@override String get tvdbAiring => 'TheTVDB (Emisión)';
	@override String get tvdbAbsolute => 'TheTVDB (Absoluto)';
	@override String get metadataLanguage => 'Idioma de metadatos';
	@override String get useOriginalTitle => 'Usar título original';
	@override String get preferredAudioLanguage => 'Idioma de audio preferido';
	@override String get preferredSubtitleLanguage => 'Idioma de subtítulos preferido';
	@override String get subtitleMode => 'Selección automática de subtítulos';
	@override String get manuallySelected => 'Seleccionado manualmente';
	@override String get shownWithForeignAudio => 'Mostrar con audio extranjero';
	@override String get alwaysEnabled => 'Siempre activado';
	@override String get tags => 'Etiquetas';
	@override String get addTag => 'Añadir etiqueta';
	@override String get genre => 'Género';
	@override String get director => 'Director';
	@override String get writer => 'Guionista';
	@override String get producer => 'Productor';
	@override String get country => 'País';
	@override String get collection => 'Colección';
	@override String get label => 'Etiqueta';
	@override String get style => 'Estilo';
	@override String get mood => 'Estado de ánimo';
}

// Path: matchScreen
class _TranslationsMatchScreenEs implements TranslationsMatchScreenEn {
	_TranslationsMatchScreenEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get match => 'Emparejar...';
	@override String get fixMatch => 'Corregir coincidencia...';
	@override String get unmatch => 'Desvincular';
	@override String get unmatchConfirm => '¿Quitar la coincidencia actual de este elemento? Plex lo tratará como sin coincidencia hasta que vuelvas a emparejarlo.';
	@override String get unmatchSuccess => 'Elemento desvinculado';
	@override String get unmatchFailed => 'No se pudo desvincular el elemento';
	@override String get matchApplied => 'Coincidencia aplicada';
	@override String get matchFailed => 'No se pudo aplicar la coincidencia';
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Año';
	@override String get search => 'Buscar';
	@override String get noMatchesFound => 'No se encontraron coincidencias';
}

// Path: serverTasks
class _TranslationsServerTasksEs implements TranslationsServerTasksEn {
	_TranslationsServerTasksEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tareas del servidor';
	@override String get failedToLoad => 'Error al cargar tareas';
	@override String get noTasks => 'No hay tareas en ejecución';
}

// Path: trakt
class _TranslationsTraktEs implements TranslationsTraktEn {
	_TranslationsTraktEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => '¿Desconectar cuenta de Trakt?';
	@override String get disconnectConfirmBody => 'Plezy dejará de enviar eventos de reproducción a Trakt. Puedes volver a conectar cuando quieras.';
	@override String get scrobble => 'Scrobbling en tiempo real';
	@override String get scrobbleDescription => 'Enviar eventos de reproducción, pausa y parada a Trakt durante la reproducción.';
	@override String get watchedSync => 'Sincronizar estado de visto';
	@override String get watchedSyncDescription => 'Cuando marques elementos como vistos en Plezy, también se marcarán en Trakt.';
}

// Path: trackers
class _TranslationsTrackersEs implements TranslationsTrackersEn {
	_TranslationsTrackersEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rastreadores';
	@override String get hubSubtitle => 'Mantén sincronizado tu progreso con Trakt y otros servicios.';
	@override String get notConnected => 'No conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Registrar progreso automáticamente';
	@override String get scrobbleDescription => 'Actualiza tu lista cuando termines un episodio o película.';
	@override String disconnectConfirm({required Object service}) => '¿Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy dejará de actualizar tu lista de ${service}. Puedes reconectarte en cualquier momento.';
	@override String connectFailed({required Object service}) => 'No se pudo conectar a ${service}. Inténtalo de nuevo.';
	@override late final _TranslationsTrackersServicesEs services = _TranslationsTrackersServicesEs._(_root);
	@override late final _TranslationsTrackersDeviceCodeEs deviceCode = _TranslationsTrackersDeviceCodeEs._(_root);
	@override late final _TranslationsTrackersOauthProxyEs oauthProxy = _TranslationsTrackersOauthProxyEs._(_root);
	@override late final _TranslationsTrackersLibraryFilterEs libraryFilter = _TranslationsTrackersLibraryFilterEs._(_root);
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsEs implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Reproducir/Pausar';
	@override String get volumeUp => 'Subir Volumen';
	@override String get volumeDown => 'Bajar Volumen';
	@override String seekForward({required Object seconds}) => 'Avanzar (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Retroceder (${seconds}s)';
	@override String get fullscreenToggle => 'Alternar Pantalla Completa';
	@override String get muteToggle => 'Alternar Silencio';
	@override String get subtitleToggle => 'Alternar Subtítulos';
	@override String get audioTrackNext => 'Siguiente Pista de Audio';
	@override String get subtitleTrackNext => 'Siguiente Pista de Subtítulos';
	@override String get chapterNext => 'Siguiente Capítulo';
	@override String get chapterPrevious => 'Anterior Capítulo';
	@override String get episodeNext => 'Siguiente Episodio';
	@override String get episodePrevious => 'Anterior Episodio';
	@override String get speedIncrease => 'Aumentar Velocidad';
	@override String get speedDecrease => 'Disminuir Velocidad';
	@override String get speedReset => 'Restablecer Velocidad';
	@override String get subSeekNext => 'Ir al Siguiente Subtítulo';
	@override String get subSeekPrev => 'Ir al Anterior Subtítulo';
	@override String get shaderToggle => 'Alternar Shaders';
	@override String get skipMarker => 'Saltar Intro/Créditos';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsEs implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requiere Android 8.0 o más reciente';
	@override String get iosVersion => 'Requiere iOS 15.0 o más reciente';
	@override String get permissionDisabled => 'El permiso de Imagen en Imagen está desactivado. Actívalo en Ajustes > Aplicaciones > Plezy > Imagen en Imagen';
	@override String get notSupported => 'El dispositivo no soporta el modo Imagen en Imagen';
	@override String get voSwitchFailed => 'Error al cambiar la salida de video para Imagen en Imagen';
	@override String get failed => 'Error al iniciar Imagen en Imagen';
	@override String unknown({required Object error}) => 'Ocurrió un error: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsEs implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendado';
	@override String get browse => 'Explorar';
	@override String get collections => 'Colecciones';
	@override String get playlists => 'Listas';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsEs implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Agrupación';
	@override String get all => 'Todo';
	@override String get movies => 'Películas';
	@override String get shows => 'Series';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episodios';
	@override String get folders => 'Carpetas';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionEs implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Iniciando servidor remoto...';
	@override String get failedToCreate => 'Error al iniciar el servidor remoto:';
	@override String get hostAddress => 'Dirección del host';
	@override String get connected => 'Conectado';
	@override String get serverRunning => 'Servidor remoto activo';
	@override String get serverStopped => 'Servidor remoto detenido';
	@override String get serverRunningDescription => 'Los dispositivos móviles en tu red pueden descubrir y conectarse a esta aplicación';
	@override String get serverStoppedDescription => 'Inicia el servidor para permitir que los dispositivos móviles se conecten';
	@override String get usePhoneToControl => 'Usa tu dispositivo móvil para controlar esta aplicación';
	@override String get startServer => 'Iniciar servidor';
	@override String get stopServer => 'Detener servidor';
	@override String get minimize => 'Minimizar';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingEs implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Los dispositivos en tu red que ejecutan Plezy con la misma cuenta de Plex aparecerán automáticamente';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Conectando...';
	@override String get searchingForDevices => 'Buscando dispositivos...';
	@override String get noDevicesFound => 'No se encontraron dispositivos en tu red';
	@override String get noDevicesHint => 'Asegúrate de que Plezy esté abierto en tu escritorio y que ambos dispositivos estén en la misma red WiFi';
	@override String get availableDevices => 'Dispositivos disponibles';
	@override String get manualConnection => 'Conexión manual';
	@override String get cryptoInitFailed => 'No se pudo inicializar la conexión segura. Asegúrate de haber iniciado sesión en una cuenta de Plex.';
	@override String get validationHostRequired => 'Ingresa la dirección del host';
	@override String get validationHostFormat => 'El formato debe ser IP:puerto (ej. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tiempo de conexión agotado. Asegúrate de que ambos dispositivos estén en la misma red.';
	@override String get sessionNotFound => 'No se encontró el dispositivo. Asegúrate de que Plezy esté ejecutándose en el host.';
	@override String get authFailed => 'Autenticación fallida. Asegúrate de que ambos dispositivos usen la misma cuenta de Plex.';
	@override String failedToConnect({required Object error}) => 'Error al conectar: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteEs implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '¿Quieres desconectarte de la sesión remota?';
	@override String get reconnecting => 'Reconectando...';
	@override String attemptOf({required Object current}) => 'Intento ${current} de 5';
	@override String get retryNow => 'Reintentar ahora';
	@override String get tabRemote => 'Remoto';
	@override String get tabPlay => 'Reproducir';
	@override String get tabMore => 'Más';
	@override String get menu => 'Menú';
	@override String get tabNavigation => 'Navegación por pestañas';
	@override String get tabDiscover => 'Descubrir';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Buscar';
	@override String get tabDownloads => 'Descargas';
	@override String get tabSettings => 'Configuración';
	@override String get previous => 'Anterior';
	@override String get playPause => 'Reproducir/Pausar';
	@override String get next => 'Siguiente';
	@override String get seekBack => 'Retroceder';
	@override String get stop => 'Detener';
	@override String get seekForward => 'Avanzar';
	@override String get volume => 'Volumen';
	@override String get volumeDown => 'Bajar';
	@override String get volumeUp => 'Subir';
	@override String get fullscreen => 'Pantalla completa';
	@override String get subtitles => 'Subtítulos';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Buscar en escritorio...';
}

// Path: trackers.services
class _TranslationsTrackersServicesEs implements TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodeEs implements TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodeEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Activar Plezy en ${service}';
	@override String body({required Object url}) => 'Visita ${url} e introduce este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para activar';
	@override String get waitingForAuthorization => 'Esperando autorización…';
	@override String get codeCopied => 'Código copiado';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxyEs implements TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxyEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Inicia sesión en ${service}';
	@override String get body => 'Escanea este código QR con tu teléfono, o abre la URL de abajo en cualquier dispositivo con navegador.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para iniciar sesión';
	@override String get urlCopied => 'URL copiada';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterEs implements TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'Sincronizando todas las bibliotecas';
	@override String get subtitleNoneSyncing => 'Nada se sincroniza';
	@override String subtitleBlocked({required Object count}) => '${count} bloqueadas';
	@override String subtitleAllowed({required Object count}) => '${count} permitidas';
	@override String get mode => 'Modo de filtro';
	@override String get modeBlacklist => 'Lista negra';
	@override String get modeWhitelist => 'Lista blanca';
	@override String get modeHintBlacklist => 'Sincronizar todas las bibliotecas excepto las marcadas abajo.';
	@override String get modeHintWhitelist => 'Sincronizar solo las bibliotecas marcadas abajo.';
	@override String get libraries => 'Bibliotecas';
	@override String get noLibraries => 'No hay bibliotecas disponibles';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Inicia sesión con Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'Tiempo de autenticación agotado. Por favor, intenta de nuevo.',
			'auth.scanQRToSignIn' => 'Escanea este código QR para iniciar sesión',
			'auth.waitingForAuth' => 'Esperando autenticación...\nPor favor completa el inicio de sesión en tu navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.close' => 'Cerrar',
			'common.clear' => 'Borrar',
			'common.reset' => 'Reiniciar',
			'common.later' => 'Más tarde',
			'common.submit' => 'Enviar',
			'common.confirm' => 'Confirmar',
			'common.retry' => 'Reintentar',
			'common.logout' => 'Cerrar sesión',
			'common.unknown' => 'Desconocido',
			'common.refresh' => 'Actualizar',
			'common.yes' => 'Sí',
			'common.no' => 'No',
			'common.delete' => 'Eliminar',
			'common.shuffle' => 'Aleatorio',
			'common.addTo' => 'Añadir a...',
			'common.createNew' => 'Crear',
			'common.connect' => 'Conectar',
			'common.disconnect' => 'Desconectar',
			'common.play' => 'Reproducir',
			'common.pause' => 'Pausa',
			'common.resume' => 'Reanudar',
			'common.error' => 'Error',
			'common.search' => 'Buscar',
			'common.home' => 'Inicio',
			'common.back' => 'Atrás',
			'common.settings' => 'Ajustes',
			'common.mute' => 'Silencio',
			'common.ok' => 'OK',
			'common.reconnect' => 'Reconectar',
			'common.exitConfirmTitle' => '¿Salir de la app?',
			'common.exitConfirmMessage' => '¿Estás seguro de que quieres salir?',
			'common.dontAskAgain' => 'No volver a preguntar',
			'common.exit' => 'Salir',
			'common.viewAll' => 'Ver todo',
			'common.checkingNetwork' => 'Comprobando red...',
			'common.refreshingServers' => 'Actualizando servidores...',
			'common.loadingServers' => 'Cargando servidores...',
			'common.connectingToServers' => 'Conectando a servidores...',
			'common.startingOfflineMode' => 'Iniciando modo sin conexión...',
			'common.loading' => 'Cargando...',
			'common.fullscreen' => 'Pantalla completa',
			'common.exitFullscreen' => 'Salir de pantalla completa',
			'common.pressBackAgainToExit' => 'Presiona atrás otra vez para salir',
			'screens.licenses' => 'Licencias',
			'screens.switchProfile' => 'Cambiar Perfil',
			'screens.subtitleStyling' => 'Estilo de Subtítulos',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs',
			'update.available' => 'Actualización disponible',
			'update.versionAvailable' => ({required Object version}) => 'Versión ${version} disponible',
			'update.currentVersion' => ({required Object version}) => 'Actual: ${version}',
			'update.skipVersion' => 'Saltar esta versión',
			'update.viewRelease' => 'Ver versión',
			'update.latestVersion' => 'Ya estás en la última versión',
			'update.checkFailed' => 'Error al buscar actualizaciones',
			'settings.title' => 'Configuración',
			'settings.supportDeveloper' => 'Apoya Plezy',
			'settings.supportDeveloperDescription' => 'Dona vía Liberapay para financiar el desarrollo',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Apariencia',
			'settings.videoPlayback' => 'Reproducción de Video',
			'settings.videoPlaybackDescription' => 'Configurar el comportamiento de reproducción',
			'settings.advanced' => 'Avanzado',
			'settings.episodePosterMode' => 'Estilo de Póster de Episodio',
			'settings.seriesPoster' => 'Póster de Serie',
			'settings.seasonPoster' => 'Póster de Temporada',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Mostrar carrusel de contenido destacado en la pantalla de inicio',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Ingresa la duración (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Oscuro',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Densidad de Biblioteca',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Cómodo',
			'settings.viewMode' => 'Modo de Vista',
			'settings.gridView' => 'Cuadrícula',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar Sección Destacada',
			'settings.useGlobalHubs' => 'Usar Diseño de Inicio de Plex',
			'settings.useGlobalHubsDescription' => 'Mostrar los hubs de la página de inicio como el cliente oficial de Plex. Cuando está desactivado, muestra recomendaciones por biblioteca en su lugar.',
			'settings.showServerNameOnHubs' => 'Mostrar Nombre del Servidor en los Hubs',
			'settings.showServerNameOnHubsDescription' => 'Mostrar siempre el nombre del servidor en los títulos de los hubs. Cuando está desactivado, solo se muestra para nombres de hubs duplicados.',
			'settings.groupLibrariesByServer' => 'Agrupar bibliotecas por servidor',
			'settings.groupLibrariesByServerDescription' => 'Muestra un encabezado para cada servidor Plex en la barra lateral cuando estás conectado a varios servidores.',
			'settings.alwaysKeepSidebarOpen' => 'Mantener siempre la barra lateral abierta',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse',
			'settings.showUnwatchedCount' => 'Mostrar conteo de no vistos',
			'settings.showUnwatchedCountDescription' => 'Mostrar el conteo de episodios no vistos en series y temporadas',
			'settings.showEpisodeNumberOnCards' => 'Mostrar número de episodio en las tarjetas',
			'settings.showEpisodeNumberOnCardsDescription' => 'Muestra el número de episodio junto a la temporada (p. ej. S2 E3) en las tarjetas de episodios',
			'settings.showSeasonPostersOnTabs' => 'Mostrar pósters de temporada en las pestañas',
			'settings.showSeasonPostersOnTabsDescription' => 'Muestra el póster de la temporada sobre cada pestaña de temporada en la página de detalles de una serie',
			'settings.hideSpoilers' => 'Ocultar spoilers de episodios no vistos',
			'settings.hideSpoilersDescription' => 'Difuminar miniaturas y ocultar descripciones de episodios que aún no has visto',
			'settings.playerBackend' => 'Reproductor',
			'settings.exoPlayer' => 'ExoPlayer (Recomendado)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Decodificación por Hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleración por hardware cuando esté disponible',
			'settings.bufferSize' => 'Tamaño del Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Recomendado)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Tu dispositivo tiene ${heap}MB de memoria. Un búfer de ${size}MB puede causar problemas de reproducción.',
			'settings.defaultQualityTitle' => 'Calidad predeterminada',
			'settings.defaultQualityDescription' => 'Se utiliza al iniciar la reproducción. Los valores más bajos reducen el ancho de banda.',
			'settings.subtitleStyling' => 'Estilo de Subtítulos',
			'settings.subtitleStylingDescription' => 'Personalizar la apariencia de los subtítulos',
			'settings.smallSkipDuration' => 'Salto pequeño',
			'settings.largeSkipDuration' => 'Salto grande',
			'settings.rewindOnResume' => 'Rebobinar al reanudar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} segundos',
			'settings.defaultSleepTimer' => 'Temporizador de apagado',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutos',
			'settings.rememberTrackSelections' => 'Recordar selección de pistas por serie/película',
			'settings.rememberTrackSelectionsDescription' => 'Guardar automáticamente las preferencias de idioma de audio y subtítulos al cambiarlas durante la reproducción',
			'settings.clickVideoTogglesPlayback' => 'Clic en el video para reproducir/pausar',
			'settings.clickVideoTogglesPlaybackDescription' => 'Si está habilitado, hacer clic en el reproductor de video reproducirá/pausará el video. De lo contrario, mostrará/ocultará los controles.',
			'settings.videoPlayerControls' => 'Controles del Reproductor de Video',
			'settings.keyboardShortcuts' => 'Atajos de Teclado',
			'settings.keyboardShortcutsDescription' => 'Personalizar los atajos de teclado',
			'settings.videoPlayerNavigation' => 'Navegación del Reproductor de Video',
			'settings.videoPlayerNavigationDescription' => 'Usar las teclas de flecha para navegar por los controles del reproductor',
			'settings.watchTogetherRelay' => 'Relay de Ver Juntos',
			'settings.watchTogetherRelayDescription' => 'Configurar un servidor relay personalizado para Ver Juntos. Todos los participantes deben usar el mismo servidor.',
			'settings.watchTogetherRelayHint' => 'https://mi-relay.ejemplo.com',
			'settings.crashReporting' => 'Informes de Errores',
			'settings.crashReportingDescription' => 'Enviar informes de errores para mejorar la aplicación',
			'settings.debugLogging' => 'Registro de Depuración',
			'settings.debugLoggingDescription' => 'Habilitar registros detallados para resolución de problemas',
			'settings.viewLogs' => 'Ver Logs',
			'settings.viewLogsDescription' => 'Ver los registros de la aplicación',
			'settings.clearCache' => 'Borrar Caché',
			'settings.clearCacheDescription' => 'Esto borrará todas las imágenes y datos en caché. La aplicación puede tardar más en cargar contenido después de borrar la caché.',
			'settings.clearCacheSuccess' => 'Caché borrada con éxito',
			'settings.resetSettings' => 'Restablecer Configuración',
			'settings.resetSettingsDescription' => 'Esto restablecerá todos los ajustes a sus valores predeterminados. Esta acción no se puede deshacer.',
			'settings.resetSettingsSuccess' => 'Configuración restablecida con éxito',
			'settings.backup' => 'Copia de seguridad',
			'settings.exportSettings' => 'Exportar Configuración',
			'settings.exportSettingsDescription' => 'Guardar tus preferencias en un archivo',
			'settings.exportSettingsSuccess' => 'Configuración exportada',
			'settings.exportSettingsFailed' => 'No se pudo exportar la configuración',
			'settings.importSettings' => 'Importar Configuración',
			'settings.importSettingsDescription' => 'Restaurar preferencias desde un archivo',
			'settings.importSettingsConfirm' => 'Esto reemplazará tu configuración actual. ¿Continuar?',
			'settings.importSettingsSuccess' => 'Configuración importada',
			'settings.importSettingsFailed' => 'No se pudo importar la configuración',
			'settings.importSettingsInvalidFile' => 'Este archivo no es una exportación válida de Plezy',
			'settings.importSettingsNoUser' => 'Inicia sesión antes de importar la configuración',
			'settings.shortcutsReset' => 'Atajos restablecidos a los valores predeterminados',
			'settings.about' => 'Acerca de',
			'settings.aboutDescription' => 'Información de la aplicación y licencias',
			'settings.updates' => 'Actualizaciones',
			'settings.updateAvailable' => 'Actualización disponible',
			'settings.checkForUpdates' => 'Buscar actualizaciones',
			'settings.autoCheckUpdatesOnStartup' => 'Buscar actualizaciones automáticamente al iniciar',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Mostrar una notificación cuando haya una nueva versión disponible al iniciar',
			'settings.validationErrorEnterNumber' => 'Por favor, introduce un número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La duración debe estar entre ${min} y ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'El atajo ya está asignado a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atajo actualizado para ${action}',
			'settings.autoSkip' => 'Salto automático',
			'settings.autoSkipIntro' => 'Saltar Intro automáticamente',
			'settings.autoSkipIntroDescription' => 'Saltar automáticamente los marcadores de intro después de unos segundos',
			'settings.autoSkipCredits' => 'Saltar Créditos automáticamente',
			'settings.autoSkipCreditsDescription' => 'Saltar automáticamente los créditos y reproducir el siguiente episodio',
			'settings.autoSkipDelay' => 'Retraso de Salto automático',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Esperar ${seconds} segundos antes de saltar automáticamente',
			'settings.introPattern' => 'Patrón de marcador de intro',
			'settings.introPatternDescription' => 'Expresión regular para reconocer marcadores de intro en los títulos de capítulos',
			'settings.creditsPattern' => 'Patrón de marcador de créditos',
			'settings.creditsPatternDescription' => 'Expresión regular para reconocer marcadores de créditos en los títulos de capítulos',
			'settings.invalidRegex' => 'Expresión regular no válida',
			'settings.downloads' => 'Descargas',
			'settings.downloadLocationDescription' => 'Elegir dónde almacenar el contenido descargado',
			'settings.downloadLocationDefault' => 'Predeterminado (Almacenamiento de la App)',
			'settings.downloadLocationCustom' => 'Ubicación personalizada',
			'settings.selectFolder' => 'Seleccionar carpeta',
			'settings.resetToDefault' => 'Restablecer al predeterminado',
			'settings.currentPath' => ({required Object path}) => 'Actual: ${path}',
			'settings.downloadLocationChanged' => 'Ubicación de descarga cambiada',
			'settings.downloadLocationReset' => 'Ubicación de descarga restablecida al predeterminado',
			'settings.downloadLocationInvalid' => 'La carpeta seleccionada no tiene permisos de escritura',
			'settings.downloadLocationSelectError' => 'Error al seleccionar la carpeta',
			'settings.downloadOnWifiOnly' => 'Descargar solo con WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Evitar descargas cuando se usan datos móviles',
			'settings.autoRemoveWatchedDownloads' => 'Eliminar descargas vistas automáticamente',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Eliminar automáticamente episodios y películas descargados cuando se marquen como vistos',
			'settings.cellularDownloadBlocked' => 'Las descargas están desactivadas en datos móviles. Conéctate a una red WiFi o cambia la configuración.',
			'settings.maxVolume' => 'Volumen Máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Presencia de Discord',
			'settings.discordRichPresenceDescription' => 'Mostrar lo que estás viendo en Discord',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Sincronizar historial de visualización con Trakt',
			'settings.trackers' => 'Rastreadores',
			'settings.trackersDescription' => 'Sincronizar progreso con Trakt, MyAnimeList, AniList y Simkl',
			'settings.companionRemoteServer' => 'Servidor de control remoto',
			'settings.companionRemoteServerDescription' => 'Permitir que dispositivos móviles en tu red controlen esta aplicación',
			'settings.autoPip' => 'Imagen en imagen automática',
			'settings.autoPipDescription' => 'Activar automáticamente imagen en imagen al salir de la app durante la reproducción',
			'settings.matchContentFrameRate' => 'Ajustar frecuencia de actualización',
			'settings.matchContentFrameRateDescription' => 'Ajustar la frecuencia de actualización de la pantalla para que coincida con el video, reduciendo tirones y ahorrando batería',
			'settings.matchRefreshRate' => 'Ajustar frecuencia de refresco',
			'settings.matchRefreshRateDescription' => 'Cambiar la frecuencia de refresco de la pantalla para coincidir con el contenido de video en pantalla completa',
			'settings.matchDynamicRange' => 'Ajustar rango dinámico',
			'settings.matchDynamicRangeDescription' => 'Activar HDR automáticamente para contenido HDR y volver a SDR al salir del reproductor',
			'settings.displaySwitchDelay' => 'Retraso de cambio de pantalla',
			'settings.tunneledPlayback' => 'Reproducción tunelizada',
			'settings.tunneledPlaybackDescription' => 'Usar tunelización de video acelerada por hardware. Desactivar si ves una pantalla negra con audio en contenido HDR',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil al abrir la app',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar selección de perfil cada vez que se abre la aplicación',
			'settings.confirmExitOnBack' => 'Confirmar antes de salir',
			'settings.confirmExitOnBackDescription' => 'Mostrar un diálogo de confirmación al presionar atrás para salir de la app',
			'settings.forceTvMode' => 'Forzar modo TV',
			'settings.forceTvModeDescription' => 'Usar el diseño de TV independientemente de la detección automática. Útil en dispositivos Android TV que no informan la característica leanback. Reinicia la app al cambiar.',
			'settings.startInFullscreen' => 'Iniciar en pantalla completa',
			'settings.startInFullscreenDescription' => 'Abrir Plezy en modo pantalla completa al iniciar',
			'settings.autoHidePerformanceOverlay' => 'Ocultar superposición de rendimiento automáticamente',
			'settings.autoHidePerformanceOverlayDescription' => 'Desvanecer la superposición de rendimiento con los controles de reproducción',
			'settings.showNavBarLabels' => 'Mostrar etiquetas de la barra de navegación',
			'settings.showNavBarLabelsDescription' => 'Mostrar etiquetas de texto bajo los iconos de la barra de navegación',
			'settings.liveTvDefaultFavorites' => 'Canales favoritos por defecto',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar solo canales favoritos al abrir TV en vivo',
			'settings.display' => 'Display',
			'settings.homeScreen' => 'Home Screen',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Window',
			'settings.content' => 'Content',
			'settings.player' => 'Player',
			'settings.subtitlesAndConfig' => 'Subtitles & Configuration',
			'settings.seekAndTiming' => 'Seek & Timing',
			'settings.behavior' => 'Behavior',
			'search.hint' => 'Buscar películas, series, música...',
			'search.tryDifferentTerm' => 'Prueba con un término de búsqueda diferente',
			'search.searchYourMedia' => 'Busca en tu contenido',
			'search.enterTitleActorOrKeyword' => 'Introduce un título, actor o palabra clave',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Establecer atajo para ${actionName}',
			'hotkeys.clearShortcut' => 'Borrar atajo',
			'hotkeys.actions.playPause' => 'Reproducir/Pausar',
			'hotkeys.actions.volumeUp' => 'Subir Volumen',
			'hotkeys.actions.volumeDown' => 'Bajar Volumen',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avanzar (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Retroceder (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Alternar Pantalla Completa',
			'hotkeys.actions.muteToggle' => 'Alternar Silencio',
			'hotkeys.actions.subtitleToggle' => 'Alternar Subtítulos',
			'hotkeys.actions.audioTrackNext' => 'Siguiente Pista de Audio',
			'hotkeys.actions.subtitleTrackNext' => 'Siguiente Pista de Subtítulos',
			'hotkeys.actions.chapterNext' => 'Siguiente Capítulo',
			'hotkeys.actions.chapterPrevious' => 'Anterior Capítulo',
			'hotkeys.actions.episodeNext' => 'Siguiente Episodio',
			'hotkeys.actions.episodePrevious' => 'Anterior Episodio',
			'hotkeys.actions.speedIncrease' => 'Aumentar Velocidad',
			'hotkeys.actions.speedDecrease' => 'Disminuir Velocidad',
			'hotkeys.actions.speedReset' => 'Restablecer Velocidad',
			'hotkeys.actions.subSeekNext' => 'Ir al Siguiente Subtítulo',
			'hotkeys.actions.subSeekPrev' => 'Ir al Anterior Subtítulo',
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'hotkeys.actions.skipMarker' => 'Saltar Intro/Créditos',
			'fileInfo.title' => 'Información del Archivo',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'Archivo',
			'fileInfo.advanced' => 'Avanzado',
			'fileInfo.codec' => 'Códec',
			'fileInfo.resolution' => 'Resolución',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frecuencia de fotogramas',
			'fileInfo.aspectRatio' => 'Relación de aspecto',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.bitDepth' => 'Profundidad de bits',
			'fileInfo.colorSpace' => 'Espacio de color',
			'fileInfo.colorRange' => 'Rango de color',
			'fileInfo.colorPrimaries' => 'Primarias de color',
			'fileInfo.chromaSubsampling' => 'Submuestreo de croma',
			'fileInfo.channels' => 'Canales',
			'fileInfo.subtitles' => 'Subtítulos',
			'fileInfo.overallBitrate' => 'Bitrate total',
			'fileInfo.path' => 'Ruta',
			'fileInfo.size' => 'Tamaño',
			'fileInfo.container' => 'Contenedor',
			'fileInfo.duration' => 'Duración',
			'fileInfo.optimizedForStreaming' => 'Optimizado para streaming',
			'fileInfo.has64bitOffsets' => 'Offsets de 64 bits',
			'mediaMenu.markAsWatched' => 'Marcar como Visto',
			'mediaMenu.markAsUnwatched' => 'Marcar como No Visto',
			'mediaMenu.removeFromContinueWatching' => 'Eliminar de Seguir Viendo',
			'mediaMenu.goToSeries' => 'Ir a la serie',
			'mediaMenu.goToSeason' => 'Ir a la temporada',
			'mediaMenu.shufflePlay' => 'Reproducción Aleatoria',
			'mediaMenu.fileInfo' => 'Información del Archivo',
			'mediaMenu.deleteFromServer' => 'Eliminar del servidor',
			'mediaMenu.confirmDelete' => 'Esto eliminará permanentemente este contenido y sus archivos de tu servidor. Esta acción no se puede deshacer.',
			'mediaMenu.deleteMultipleWarning' => 'Esto incluye todos los episodios y sus archivos.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Elemento multimedia eliminado con éxito',
			'mediaMenu.mediaFailedToDelete' => 'Error al eliminar el elemento multimedia',
			'mediaMenu.rate' => 'Calificar',
			'mediaMenu.playFromBeginning' => 'Reproducir desde el inicio',
			'mediaMenu.playVersion' => 'Reproducir versión...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, película',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serie de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por ciento visto',
			'accessibility.mediaCardUnwatched' => 'no visto',
			'accessibility.tapToPlay' => 'Toca para reproducir',
			'tooltips.shufflePlay' => 'Reproducción aleatoria',
			'tooltips.playTrailer' => 'Reproducir tráiler',
			'tooltips.markAsWatched' => 'Marcar como visto',
			'tooltips.markAsUnwatched' => 'Marcar como no visto',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Subtítulos',
			'videoControls.resetToZero' => 'Restablecer a 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} se reproduce más tarde',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} se reproduce antes',
			'videoControls.noOffset' => 'Sin desfase',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Llenar pantalla',
			'videoControls.stretch' => 'Estirar',
			'videoControls.lockRotation' => 'Bloquear rotación',
			'videoControls.unlockRotation' => 'Desbloquear rotación',
			'videoControls.timerActive' => 'Temporizador Activo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La reproducción se pausará en ${duration}',
			'videoControls.stillWatching' => '¿Sigues viendo?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausa en ${seconds}s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Reproducir siguiente automáticamente',
			'videoControls.playNext' => 'Reproducir siguiente',
			'videoControls.playButton' => 'Reproducir',
			'videoControls.pauseButton' => 'Pausa',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Retroceder ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avanzar ${seconds} segundos',
			'videoControls.previousButton' => 'Episodio anterior',
			'videoControls.nextButton' => 'Episodio siguiente',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Capítulo siguiente',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Activar sonido',
			'videoControls.settingsButton' => 'Ajustes de video',
			'videoControls.tracksButton' => 'Audio y subtítulos',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionsButton' => 'Versiones de video',
			'videoControls.versionQualityButton' => 'Versión y calidad',
			'videoControls.versionColumnHeader' => 'Versión',
			'videoControls.qualityColumnHeader' => 'Calidad',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodificación no disponible — reproduciendo calidad original',
			'videoControls.pipButton' => 'Modo PiP (Imagen en Imagen)',
			'videoControls.aspectRatioButton' => 'Relación de aspecto',
			'videoControls.ambientLighting' => 'Iluminación ambiental',
			'videoControls.fullscreenButton' => 'Entrar en pantalla completa',
			'videoControls.exitFullscreenButton' => 'Salir de pantalla completa',
			'videoControls.alwaysOnTopButton' => 'Siempre visible',
			'videoControls.rotationLockButton' => 'Bloqueo de rotación',
			'videoControls.lockScreen' => 'Bloquear pantalla',
			'videoControls.screenLockButton' => 'Bloqueo de pantalla',
			'videoControls.longPressToUnlock' => 'Mantén pulsado para desbloquear',
			'videoControls.timelineSlider' => 'Línea de tiempo del video',
			'videoControls.volumeSlider' => 'Nivel de volumen',
			'videoControls.endsAt' => ({required Object time}) => 'Termina a las ${time}',
			'videoControls.pipActive' => 'Reproduciendo en Imagen en Imagen',
			'videoControls.pipFailed' => 'Error al iniciar Imagen en Imagen',
			'videoControls.pipErrors.androidVersion' => 'Requiere Android 8.0 o más reciente',
			'videoControls.pipErrors.iosVersion' => 'Requiere iOS 15.0 o más reciente',
			'videoControls.pipErrors.permissionDisabled' => 'El permiso de Imagen en Imagen está desactivado. Actívalo en Ajustes > Aplicaciones > Plezy > Imagen en Imagen',
			'videoControls.pipErrors.notSupported' => 'El dispositivo no soporta el modo Imagen en Imagen',
			'videoControls.pipErrors.voSwitchFailed' => 'Error al cambiar la salida de video para Imagen en Imagen',
			'videoControls.pipErrors.failed' => 'Error al iniciar Imagen en Imagen',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocurrió un error: ${error}',
			'videoControls.chapters' => 'Capítulos',
			'videoControls.noChaptersAvailable' => 'No hay capítulos disponibles',
			'videoControls.queue' => 'Cola',
			'videoControls.noQueueItems' => 'No hay elementos en la cola',
			'videoControls.searchSubtitles' => 'Buscar subtítulos',
			'videoControls.language' => 'Idioma',
			'videoControls.noSubtitlesFound' => 'No se encontraron subtítulos',
			'videoControls.subtitleDownloaded' => 'Subtítulo descargado',
			'videoControls.subtitleDownloadFailed' => 'Error al descargar subtítulo',
			'videoControls.searchLanguages' => 'Buscar idiomas...',
			'userStatus.admin' => 'Administrador',
			'userStatus.restricted' => 'Restringido',
			'userStatus.protected' => 'Protegido',
			'userStatus.current' => 'ACTUAL',
			'messages.markedAsWatched' => 'Marcado como visto',
			'messages.markedAsUnwatched' => 'Marcado como no visto',
			'messages.markedAsWatchedOffline' => 'Marcado como visto (se sincronizará al estar en línea)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como no visto (se sincronizará al estar en línea)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Eliminado automáticamente: ${title}',
			'messages.removedFromContinueWatching' => 'Eliminado de Seguir Viendo',
			'messages.errorLoading' => ({required Object error}) => 'Error: ${error}',
			'messages.fileInfoNotAvailable' => 'Información de archivo no disponible',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Error al cargar info de archivo: ${error}',
			'messages.errorLoadingSeries' => 'Error al cargar la serie',
			'messages.errorLoadingSeason' => 'Error al cargar la temporada',
			'messages.musicNotSupported' => 'La reproducción de música aún no está soportada',
			'messages.noDescriptionAvailable' => 'No hay descripción disponible',
			'messages.noProfilesAvailable' => 'No hay perfiles disponibles',
			'messages.contactAdminForProfiles' => 'Contacta con tu administrador de Plex para añadir perfiles',
			'messages.unableToDetermineLibrarySection' => 'No se puede determinar la sección de biblioteca para este elemento',
			'messages.logsCleared' => 'Logs borrados',
			'messages.logsCopied' => 'Logs copiados al portapapeles',
			'messages.noLogsAvailable' => 'No hay logs disponibles',
			'messages.libraryScanning' => ({required Object title}) => 'Escaneando "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Escaneo de biblioteca iniciado para "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Error al escanear biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Actualizando metadatos de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Actualización de metadatos iniciada para "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Error al actualizar metadatos: ${error}',
			'messages.logoutConfirm' => '¿Estás seguro de que quieres cerrar sesión?',
			'messages.noSeasonsFound' => 'No se encontraron temporadas',
			'messages.noEpisodesFound' => 'No se encontraron episodios en la primera temporada',
			'messages.noEpisodesFoundGeneral' => 'No se encontraron episodios',
			'messages.noResultsFound' => 'No se encontraron resultados',
			'messages.sleepTimerSet' => ({required Object label}) => 'Temporizador establecido en ${label}',
			'messages.noItemsAvailable' => 'No hay elementos disponibles',
			'messages.failedToCreatePlayQueueNoItems' => 'Error al crear la cola de reproducción - no hay elementos',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Error al ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Cambiando a reproductor compatible...',
			'messages.serverLimitTitle' => 'Error de reproducción',
			'messages.serverLimitBody' => 'El servidor devolvió un error (HTTP 500). Normalmente esto significa que el propietario del servidor ha establecido un límite de ancho de banda o transcodificación que está rechazando tu sesión. No hay nada que puedas hacer desde el cliente — el propietario del servidor debe ajustar su configuración.',
			'messages.logsUploaded' => 'Registros subidos',
			'messages.logsUploadFailed' => 'Error al subir registros',
			'messages.logId' => 'ID de registro',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.border' => 'Borde',
			'subtitlingStyling.background' => 'Fondo',
			'subtitlingStyling.fontSize' => 'Tamaño de Fuente',
			'subtitlingStyling.textColor' => 'Color de Texto',
			'subtitlingStyling.borderSize' => 'Tamaño de Borde',
			'subtitlingStyling.borderColor' => 'Color de Borde',
			'subtitlingStyling.backgroundOpacity' => 'Opacidad de Fondo',
			'subtitlingStyling.backgroundColor' => 'Color de Fondo',
			'subtitlingStyling.position' => 'Posición',
			'subtitlingStyling.assOverride' => 'Sobreescritura ASS',
			'subtitlingStyling.bold' => 'Negrita',
			'subtitlingStyling.italic' => 'Cursiva',
			'mpvConfig.title' => 'Configuración de mpv',
			'mpvConfig.description' => 'Ajustes avanzados del reproductor de video',
			'mpvConfig.presets' => 'Ajustes preestablecidos',
			'mpvConfig.noPresets' => 'No hay ajustes guardados',
			'mpvConfig.saveAsPreset' => 'Guardar como Ajuste...',
			'mpvConfig.presetName' => 'Nombre del Ajuste',
			'mpvConfig.presetNameHint' => 'Introduce un nombre para este ajuste',
			'mpvConfig.loadPreset' => 'Cargar',
			'mpvConfig.deletePreset' => 'Eliminar',
			'mpvConfig.presetSaved' => 'Ajuste guardado',
			'mpvConfig.presetLoaded' => 'Ajuste cargado',
			'mpvConfig.presetDeleted' => 'Ajuste eliminado',
			'mpvConfig.confirmDeletePreset' => '¿Estás seguro de que quieres eliminar este ajuste?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Confirmar Acción',
			'discover.title' => 'Descubrir',
			'discover.switchProfile' => 'Cambiar Perfil',
			'discover.noContentAvailable' => 'No hay contenido disponible',
			'discover.addMediaToLibraries' => 'Añade contenido a tus bibliotecas',
			'discover.continueWatching' => 'Seguir Viendo',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'T${season}E${episode}',
			'discover.overview' => 'Resumen',
			'discover.cast' => 'Reparto',
			'discover.extras' => 'Tráilers y Extras',
			'discover.studio' => 'Estudio',
			'discover.rating' => 'Calificación',
			'discover.movie' => 'Película',
			'discover.tvShow' => 'Serie de TV',
			'discover.minutesLeft' => ({required Object minutes}) => 'quedan ${minutes} min',
			'errors.searchFailed' => ({required Object error}) => 'Error en la búsqueda: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tiempo de conexión agotado al cargar ${context}',
			'errors.connectionFailed' => 'No se pudo conectar con el servidor Plex',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Error al cargar ${context}: ${error}',
			'errors.noClientAvailable' => 'No hay cliente disponible',
			'errors.authenticationFailed' => ({required Object error}) => 'Error de autenticación: ${error}',
			'errors.couldNotLaunchUrl' => 'No se pudo abrir la URL de autenticación',
			'errors.pleaseEnterToken' => 'Por favor, introduce un token',
			'errors.invalidToken' => 'Token no válido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Error al verificar el token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Error al cambiar al perfil ${displayName}',
			'libraries.title' => 'Bibliotecas',
			'libraries.scanLibraryFiles' => 'Escanear Archivos de la Biblioteca',
			'libraries.scanLibrary' => 'Escanear Biblioteca',
			'libraries.analyze' => 'Analizar',
			'libraries.analyzeLibrary' => 'Analizar Biblioteca',
			'libraries.refreshMetadata' => 'Actualizar Metadatos',
			'libraries.emptyTrash' => 'Vaciar Papelera',
			'libraries.emptyingTrash' => ({required Object title}) => 'Vaciando papelera de "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papelera vaciada para "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Error al vaciar papelera: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analizando "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Análisis iniciado para "${title}"',
			_ => null,
		} ?? switch (path) {
			'libraries.failedToAnalyze' => ({required Object error}) => 'Error al analizar la biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'No se encontraron bibliotecas',
			'libraries.allLibrariesHidden' => 'Todas las bibliotecas están ocultas',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliotecas ocultas (${count})',
			'libraries.thisLibraryIsEmpty' => 'Esta biblioteca está vacía',
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Borrar Todo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '¿Estás seguro de que quieres escanear "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '¿Estás seguro de que quieres analizar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '¿Estás seguro de que quieres actualizar los metadatos de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '¿Estás seguro de que quieres vaciar la papelera de "${title}"?',
			'libraries.manageLibraries' => 'Gestionar Bibliotecas',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar por',
			'libraries.filters' => 'Filtros',
			'libraries.confirmActionMessage' => '¿Estás seguro de que quieres realizar esta acción?',
			'libraries.showLibrary' => 'Mostrar biblioteca',
			'libraries.hideLibrary' => 'Ocultar biblioteca',
			'libraries.libraryOptions' => 'Opciones de biblioteca',
			'libraries.content' => 'contenido de la biblioteca',
			'libraries.selectLibrary' => 'Seleccionar biblioteca',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtros (${count})',
			'libraries.noRecommendations' => 'No hay recomendaciones disponibles',
			'libraries.noCollections' => 'No hay colecciones en esta biblioteca',
			'libraries.noFoldersFound' => 'No se encontraron carpetas',
			'libraries.folders' => 'carpetas',
			'libraries.tabs.recommended' => 'Recomendado',
			'libraries.tabs.browse' => 'Explorar',
			'libraries.tabs.collections' => 'Colecciones',
			'libraries.tabs.playlists' => 'Listas',
			'libraries.groupings.title' => 'Agrupación',
			'libraries.groupings.all' => 'Todo',
			'libraries.groupings.movies' => 'Películas',
			'libraries.groupings.shows' => 'Series',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episodios',
			'libraries.groupings.folders' => 'Carpetas',
			'about.title' => 'Acerca de',
			'about.openSourceLicenses' => 'Licencias de Código Abierto',
			'about.versionLabel' => ({required Object version}) => 'Versión ${version}',
			'about.appDescription' => 'Un cliente de Plex para Flutter',
			'about.viewLicensesDescription' => 'Ver licencias de librerías de terceros',
			'serverSelection.allServerConnectionsFailed' => 'No se pudo conectar con ningún servidor. Por favor, comprueba tu conexión e inténtalo de nuevo.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'No se encontraron servidores para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Error al cargar servidores: ${error}',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Año de lanzamiento',
			'hubDetail.dateAdded' => 'Añadido el',
			'hubDetail.rating' => 'Calificación',
			'hubDetail.noItemsFound' => 'No se encontraron elementos',
			'logs.clearLogs' => 'Borrar Logs',
			'logs.copyLogs' => 'Copiar Logs',
			'logs.uploadLogs' => 'Subir registros',
			'licenses.relatedPackages' => 'Paquetes relacionados',
			'licenses.license' => 'Licencia',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencia ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licencias',
			'navigation.libraries' => 'Medios',
			'navigation.downloads' => 'Descargas',
			'navigation.liveTv' => 'TV en vivo',
			'liveTv.title' => 'TV en vivo',
			'liveTv.guide' => 'Guía',
			'liveTv.noChannels' => 'No hay canales disponibles',
			'liveTv.noDvr' => 'No hay DVR configurado en ningún servidor',
			'liveTv.noPrograms' => 'No hay datos de programación disponibles',
			'liveTv.live' => 'EN VIVO',
			'liveTv.reloadGuide' => 'Recargar guía',
			'liveTv.now' => 'Ahora',
			'liveTv.today' => 'Hoy',
			'liveTv.midnight' => 'Medianoche',
			'liveTv.overnight' => 'Madrugada',
			'liveTv.morning' => 'Mañana',
			'liveTv.daytime' => 'Día',
			'liveTv.evening' => 'Noche',
			'liveTv.lateNight' => 'Trasnoche',
			'liveTv.whatsOn' => 'En emisión',
			'liveTv.watchChannel' => 'Ver canal',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.reorderFavorites' => 'Reordenar favoritos',
			'liveTv.joinSession' => 'Unirse a sesión en curso',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Ver desde el inicio (hace ${minutes} min)',
			'liveTv.watchLive' => 'Ver en vivo',
			'liveTv.goToLive' => 'Ir a en vivo',
			'collections.title' => 'Colecciones',
			'collections.collection' => 'Colección',
			'collections.empty' => 'La colección está vacía',
			'collections.unknownLibrarySection' => 'No se puede eliminar: Sección de biblioteca desconocida',
			'collections.deleteCollection' => 'Eliminar Colección',
			'collections.deleteConfirm' => ({required Object title}) => '¿Estás seguro de que quieres eliminar "${title}"? Esta acción no se puede deshacer.',
			'collections.deleted' => 'Colección eliminada',
			'collections.deleteFailed' => 'Error al eliminar la colección',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Error al eliminar la colección: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Error al cargar los elementos de la colección: ${error}',
			'collections.selectCollection' => 'Seleccionar Colección',
			'collections.collectionName' => 'Nombre de la Colección',
			'collections.enterCollectionName' => 'Introduce el nombre de la colección',
			'collections.addedToCollection' => 'Añadido a la colección',
			'collections.errorAddingToCollection' => 'Error al añadir a la colección',
			'collections.created' => 'Colección creada',
			'collections.removeFromCollection' => 'Eliminar de la colección',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '¿Eliminar "${title}" de esta colección?',
			'collections.removedFromCollection' => 'Eliminado de la colección',
			'collections.removeFromCollectionFailed' => 'Error al eliminar de la colección',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Error al eliminar de la colección: ${error}',
			'collections.searchCollections' => 'Buscar colecciones...',
			'playlists.title' => 'Listas de reproducción',
			'playlists.playlist' => 'Lista de reproducción',
			'playlists.noPlaylists' => 'No se encontraron listas de reproducción',
			'playlists.create' => 'Crear Lista de Reproducción',
			'playlists.playlistName' => 'Nombre de la Lista',
			'playlists.enterPlaylistName' => 'Introduce el nombre de la lista',
			'playlists.delete' => 'Eliminar Lista',
			'playlists.removeItem' => 'Eliminar de la Lista',
			'playlists.smartPlaylist' => 'Lista Inteligente',
			'playlists.itemCount' => ({required Object count}) => '${count} elementos',
			'playlists.oneItem' => '1 elemento',
			'playlists.emptyPlaylist' => 'Esta lista está vacía',
			'playlists.deleteConfirm' => '¿Eliminar Lista de Reproducción?',
			'playlists.deleteMessage' => ({required Object name}) => '¿Estás seguro de que quieres eliminar "${name}"?',
			'playlists.created' => 'Lista de reproducción creada',
			'playlists.deleted' => 'Lista de reproducción eliminada',
			'playlists.itemAdded' => 'Añadido a la lista',
			'playlists.itemRemoved' => 'Eliminado de la lista',
			'playlists.selectPlaylist' => 'Seleccionar Lista',
			'playlists.errorCreating' => 'Error al crear la lista',
			'playlists.errorDeleting' => 'Error al eliminar la lista',
			'playlists.errorLoading' => 'Error al cargar las listas',
			'playlists.errorAdding' => 'Error al añadir a la lista',
			'playlists.errorReordering' => 'Error al reordenar los elementos de la lista',
			'playlists.errorRemoving' => 'Error al eliminar de la lista',
			'watchTogether.title' => 'Ver Juntos',
			'watchTogether.description' => 'Mira contenido en sincronía con amigos y familiares',
			'watchTogether.createSession' => 'Crear Sesión',
			'watchTogether.creating' => 'Creando...',
			'watchTogether.joinSession' => 'Unirse a Sesión',
			'watchTogether.joining' => 'Uniendo...',
			'watchTogether.controlMode' => 'Modo de Control',
			'watchTogether.controlModeQuestion' => '¿Quién puede controlar la reproducción?',
			'watchTogether.hostOnly' => 'Solo el Anfitrión',
			'watchTogether.anyone' => 'Cualquiera',
			'watchTogether.hostingSession' => 'Anfitrión de la Sesión',
			'watchTogether.inSession' => 'En Sesión',
			'watchTogether.sessionCode' => 'Código de Sesión',
			'watchTogether.hostControlsPlayback' => 'El anfitrión controla la reproducción',
			'watchTogether.anyoneCanControl' => 'Cualquiera puede controlar la reproducción',
			'watchTogether.hostControls' => 'Control del anfitrión',
			'watchTogether.anyoneControls' => 'Control de cualquiera',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.host' => 'Anfitrión',
			'watchTogether.hostBadge' => 'ANFITRIÓN',
			'watchTogether.youAreHost' => 'Eres el anfitrión',
			'watchTogether.watchingWithOthers' => 'Viendo con otros',
			'watchTogether.endSession' => 'Finalizar Sesión',
			'watchTogether.leaveSession' => 'Salir de la Sesión',
			'watchTogether.endSessionQuestion' => '¿Finalizar Sesión?',
			'watchTogether.leaveSessionQuestion' => '¿Salir de la Sesión?',
			'watchTogether.endSessionConfirm' => 'Esto finalizará la sesión para todos los participantes.',
			'watchTogether.leaveSessionConfirm' => 'Serás eliminado de la sesión.',
			'watchTogether.endSessionConfirmOverlay' => 'Esto finalizará la sesión de visualización para todos los participantes.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Serás desconectado de la sesión de visualización.',
			'watchTogether.end' => 'Finalizar',
			'watchTogether.leave' => 'Salir',
			'watchTogether.syncing' => 'Sincronizando...',
			'watchTogether.joinWatchSession' => 'Unirse a Sesión de Visualización',
			'watchTogether.enterCodeHint' => 'Introduce el código de 5 caracteres',
			'watchTogether.pasteFromClipboard' => 'Pegar desde el portapapeles',
			'watchTogether.pleaseEnterCode' => 'Por favor, introduce un código de sesión',
			'watchTogether.codeMustBe5Chars' => 'El código de sesión debe tener 5 caracteres',
			'watchTogether.joinInstructions' => 'Introduce el código de sesión compartido por el anfitrión para unirte a su sesión.',
			'watchTogether.failedToCreate' => 'Error al crear la sesión',
			'watchTogether.failedToJoin' => 'Error al unirse a la sesión',
			'watchTogether.sessionCodeCopied' => 'Código de sesión copiado al portapapeles',
			'watchTogether.relayUnreachable' => 'El servidor de retransmisión no está disponible. Esto puede deberse a que tu proveedor de internet bloquea la conexión. Puedes intentarlo de todos modos, pero Watch Together podría no funcionar.',
			'watchTogether.reconnectingToHost' => 'Reconectando con el anfitrión...',
			'watchTogether.currentPlayback' => 'Reproducción actual',
			'watchTogether.joinCurrentPlayback' => 'Unirse a la reproducción actual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Vuelve a lo que el anfitrión está viendo ahora mismo',
			'watchTogether.failedToOpenCurrentPlayback' => 'No se pudo abrir la reproducción actual',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} se unió',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} se fue',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pausó',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} reanudó',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} avanzó',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} está cargando',
			'watchTogether.waitingForParticipants' => 'Esperando a que otros carguen...',
			'watchTogether.recentRooms' => 'Salas recientes',
			'watchTogether.renameRoom' => 'Renombrar sala',
			'watchTogether.removeRoom' => 'Eliminar',
			'downloads.title' => 'Descargas',
			'downloads.manage' => 'Gestionar',
			'downloads.tvShows' => 'Series de TV',
			'downloads.movies' => 'Películas',
			'downloads.noDownloads' => 'No hay descargas aún',
			'downloads.noDownloadsDescription' => 'El contenido descargado aparecerá aquí para verlo sin conexión',
			'downloads.downloadNow' => 'Descargar',
			'downloads.deleteDownload' => 'Eliminar descarga',
			'downloads.retryDownload' => 'Reintentar descarga',
			'downloads.downloadQueued' => 'Descarga en cola',
			'downloads.serverErrorBitrate' => 'Error del servidor — el archivo puede exceder el límite de bitrate de transmisión remota',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodios en cola para descargar',
			'downloads.downloadDeleted' => 'Descarga eliminada',
			'downloads.deleteConfirm' => ({required Object title}) => '¿Estás seguro de que quieres eliminar "${title}"? Esto borrará el archivo descargado de tu dispositivo.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})',
			'downloads.deleting' => 'Eliminando...',
			'downloads.queuedTooltip' => 'En cola',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'En cola: ${files}',
			'downloads.downloadingTooltip' => 'Descargando...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Descargando ${files}',
			'downloads.noDownloadsTree' => 'Sin descargas',
			'downloads.pauseAll' => 'Pausar todo',
			'downloads.resumeAll' => 'Reanudar todo',
			'downloads.deleteAll' => 'Eliminar todo',
			'downloads.selectVersion' => 'Seleccionar versión',
			'downloads.allEpisodes' => 'Todos los episodios',
			'downloads.unwatchedOnly' => 'Solo no vistos',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} no vistos',
			'downloads.customAmount' => 'Cantidad personalizada...',
			'downloads.howManyEpisodes' => '¿Cuántos episodios?',
			'downloads.itemsQueued' => ({required Object count}) => '${count} elementos en cola de descarga',
			'downloads.keepSynced' => 'Mantener sincronizado',
			'downloads.downloadOnce' => 'Descargar una vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Mantener ${count} sin ver',
			'downloads.editSyncRule' => 'Editar regla de sincronización',
			'downloads.removeSyncRule' => 'Eliminar regla de sincronización',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '¿Dejar de sincronizar "${title}"? Los episodios descargados se conservarán.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regla de sincronización creada — conservando ${count} episodios sin ver',
			'downloads.syncRuleUpdated' => 'Regla de sincronización actualizada',
			'downloads.syncRuleRemoved' => 'Regla de sincronización eliminada',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} nuevos episodios sincronizados para ${title}',
			'downloads.activeSyncRules' => 'Reglas de sincronización',
			'downloads.noSyncRules' => 'Sin reglas de sincronización',
			'downloads.manageSyncRule' => 'Gestionar sincronización',
			'downloads.editEpisodeCount' => 'Número de episodios',
			'downloads.editSyncFilter' => 'Filtro de sincronización',
			'downloads.syncAllItems' => 'Sincronizando todos los elementos',
			'downloads.syncUnwatchedItems' => 'Sincronizando elementos no vistos',
			'downloads.syncRuleListCreated' => 'Regla de sincronización creada',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sin mejora de video',
			'shaders.nvscalerDescription' => 'Escalado de imagen NVIDIA para un video más nítido',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Reducción de ruido',
			'shaders.artcnnVariantDenoiseSharpen' => 'Reducción de ruido + enfoque',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta Calidad',
			'shaders.mode' => 'Modo',
			'shaders.importShader' => 'Importar shader',
			'shaders.customShaderDescription' => 'Shader GLSL personalizado',
			'shaders.shaderImported' => 'Shader importado',
			'shaders.shaderImportFailed' => 'Error al importar shader',
			'shaders.deleteShader' => 'Eliminar shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '¿Eliminar "${name}"?',
			'companionRemote.title' => 'Control remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.session.startingServer' => 'Iniciando servidor remoto...',
			'companionRemote.session.failedToCreate' => 'Error al iniciar el servidor remoto:',
			'companionRemote.session.hostAddress' => 'Dirección del host',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.serverRunning' => 'Servidor remoto activo',
			'companionRemote.session.serverStopped' => 'Servidor remoto detenido',
			'companionRemote.session.serverRunningDescription' => 'Los dispositivos móviles en tu red pueden descubrir y conectarse a esta aplicación',
			'companionRemote.session.serverStoppedDescription' => 'Inicia el servidor para permitir que los dispositivos móviles se conecten',
			'companionRemote.session.usePhoneToControl' => 'Usa tu dispositivo móvil para controlar esta aplicación',
			'companionRemote.session.startServer' => 'Iniciar servidor',
			'companionRemote.session.stopServer' => 'Detener servidor',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.pairing.discoveryDescription' => 'Los dispositivos en tu red que ejecutan Plezy con la misma cuenta de Plex aparecerán automáticamente',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.searchingForDevices' => 'Buscando dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'No se encontraron dispositivos en tu red',
			'companionRemote.pairing.noDevicesHint' => 'Asegúrate de que Plezy esté abierto en tu escritorio y que ambos dispositivos estén en la misma red WiFi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponibles',
			'companionRemote.pairing.manualConnection' => 'Conexión manual',
			'companionRemote.pairing.cryptoInitFailed' => 'No se pudo inicializar la conexión segura. Asegúrate de haber iniciado sesión en una cuenta de Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Ingresa la dirección del host',
			'companionRemote.pairing.validationHostFormat' => 'El formato debe ser IP:puerto (ej. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tiempo de conexión agotado. Asegúrate de que ambos dispositivos estén en la misma red.',
			'companionRemote.pairing.sessionNotFound' => 'No se encontró el dispositivo. Asegúrate de que Plezy esté ejecutándose en el host.',
			'companionRemote.pairing.authFailed' => 'Autenticación fallida. Asegúrate de que ambos dispositivos usen la misma cuenta de Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Error al conectar: ${error}',
			'companionRemote.remote.disconnectConfirm' => '¿Quieres desconectarte de la sesión remota?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Intento ${current} de 5',
			'companionRemote.remote.retryNow' => 'Reintentar ahora',
			'companionRemote.remote.tabRemote' => 'Remoto',
			'companionRemote.remote.tabPlay' => 'Reproducir',
			'companionRemote.remote.tabMore' => 'Más',
			'companionRemote.remote.menu' => 'Menú',
			'companionRemote.remote.tabNavigation' => 'Navegación por pestañas',
			'companionRemote.remote.tabDiscover' => 'Descubrir',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Buscar',
			'companionRemote.remote.tabDownloads' => 'Descargas',
			'companionRemote.remote.tabSettings' => 'Configuración',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.playPause' => 'Reproducir/Pausar',
			'companionRemote.remote.next' => 'Siguiente',
			'companionRemote.remote.seekBack' => 'Retroceder',
			'companionRemote.remote.stop' => 'Detener',
			'companionRemote.remote.seekForward' => 'Avanzar',
			'companionRemote.remote.volume' => 'Volumen',
			'companionRemote.remote.volumeDown' => 'Bajar',
			'companionRemote.remote.volumeUp' => 'Subir',
			'companionRemote.remote.fullscreen' => 'Pantalla completa',
			'companionRemote.remote.subtitles' => 'Subtítulos',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Buscar en escritorio...',
			'videoSettings.playbackSettings' => 'Ajustes de reproducción',
			'videoSettings.playbackSpeed' => 'Velocidad de reproducción',
			'videoSettings.sleepTimer' => 'Temporizador de apagado',
			'videoSettings.audioSync' => 'Sincronización de audio',
			'videoSettings.subtitleSync' => 'Sincronización de subtítulos',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Salida de audio',
			'videoSettings.performanceOverlay' => 'Indicador de rendimiento',
			'videoSettings.audioPassthrough' => 'Audio Passthrough',
			'videoSettings.audioNormalization' => 'Normalizar volumen',
			'externalPlayer.title' => 'Reproductor externo',
			'externalPlayer.useExternalPlayer' => 'Usar reproductor externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir vídeos en una app externa en lugar del reproductor integrado',
			'externalPlayer.selectPlayer' => 'Seleccionar reproductor',
			'externalPlayer.customPlayers' => 'Reproductores personalizados',
			'externalPlayer.systemDefault' => 'Predeterminado del sistema',
			'externalPlayer.addCustomPlayer' => 'Añadir reproductor personalizado',
			'externalPlayer.playerName' => 'Nombre del reproductor',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nombre del paquete',
			'externalPlayer.playerUrlScheme' => 'Esquema URL',
			'externalPlayer.off' => 'Desactivado',
			'externalPlayer.launchFailed' => 'No se pudo abrir el reproductor externo',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} no está instalado',
			'externalPlayer.playInExternalPlayer' => 'Reproducir en reproductor externo',
			'metadataEdit.editMetadata' => 'Editar...',
			'metadataEdit.screenTitle' => 'Editar metadatos',
			'metadataEdit.basicInfo' => 'Información básica',
			'metadataEdit.artwork' => 'Artwork',
			'metadataEdit.advancedSettings' => 'Ajustes avanzados',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Título de ordenación',
			'metadataEdit.originalTitle' => 'Título original',
			'metadataEdit.releaseDate' => 'Fecha de estreno',
			'metadataEdit.contentRating' => 'Clasificación de contenido',
			'metadataEdit.studio' => 'Estudio',
			'metadataEdit.tagline' => 'Eslogan',
			'metadataEdit.summary' => 'Resumen',
			'metadataEdit.poster' => 'Póster',
			'metadataEdit.background' => 'Fondo',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Imagen cuadrada',
			'metadataEdit.selectPoster' => 'Seleccionar póster',
			'metadataEdit.selectBackground' => 'Seleccionar fondo',
			'metadataEdit.selectLogo' => 'Seleccionar logo',
			'metadataEdit.selectSquareArt' => 'Seleccionar imagen cuadrada',
			'metadataEdit.fromUrl' => 'Desde URL',
			'metadataEdit.uploadFile' => 'Subir archivo',
			'metadataEdit.enterImageUrl' => 'Introducir URL de imagen',
			'metadataEdit.imageUrl' => 'URL de imagen',
			'metadataEdit.metadataUpdated' => 'Metadatos actualizados',
			'metadataEdit.metadataUpdateFailed' => 'Error al actualizar los metadatos',
			'metadataEdit.artworkUpdated' => 'Artwork actualizado',
			'metadataEdit.artworkUpdateFailed' => 'Error al actualizar el artwork',
			'metadataEdit.noArtworkAvailable' => 'No hay artwork disponible',
			'metadataEdit.notSet' => 'No establecido',
			'metadataEdit.libraryDefault' => 'Predeterminado de biblioteca',
			'metadataEdit.accountDefault' => 'Predeterminado de cuenta',
			'metadataEdit.seriesDefault' => 'Predeterminado de serie',
			'metadataEdit.episodeSorting' => 'Orden de episodios',
			'metadataEdit.oldestFirst' => 'Más antiguos primero',
			'metadataEdit.newestFirst' => 'Más recientes primero',
			'metadataEdit.keep' => 'Conservar',
			'metadataEdit.allEpisodes' => 'Todos los episodios',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episodios más recientes',
			'metadataEdit.latestEpisode' => 'Episodio más reciente',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episodios añadidos en los últimos ${count} días',
			'metadataEdit.deleteAfterPlaying' => 'Eliminar episodios después de reproducir',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.afterADay' => 'Después de un día',
			'metadataEdit.afterAWeek' => 'Después de una semana',
			'metadataEdit.afterAMonth' => 'Después de un mes',
			'metadataEdit.onNextRefresh' => 'En la próxima actualización',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.show' => 'Mostrar',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.episodeOrdering' => 'Orden de episodios',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Emisión)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Emisión)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absoluto)',
			'metadataEdit.metadataLanguage' => 'Idioma de metadatos',
			'metadataEdit.useOriginalTitle' => 'Usar título original',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de audio preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de subtítulos preferido',
			'metadataEdit.subtitleMode' => 'Selección automática de subtítulos',
			'metadataEdit.manuallySelected' => 'Seleccionado manualmente',
			'metadataEdit.shownWithForeignAudio' => 'Mostrar con audio extranjero',
			'metadataEdit.alwaysEnabled' => 'Siempre activado',
			'metadataEdit.tags' => 'Etiquetas',
			'metadataEdit.addTag' => 'Añadir etiqueta',
			'metadataEdit.genre' => 'Género',
			'metadataEdit.director' => 'Director',
			'metadataEdit.writer' => 'Guionista',
			'metadataEdit.producer' => 'Productor',
			'metadataEdit.country' => 'País',
			'metadataEdit.collection' => 'Colección',
			'metadataEdit.label' => 'Etiqueta',
			'metadataEdit.style' => 'Estilo',
			'metadataEdit.mood' => 'Estado de ánimo',
			'matchScreen.match' => 'Emparejar...',
			'matchScreen.fixMatch' => 'Corregir coincidencia...',
			'matchScreen.unmatch' => 'Desvincular',
			'matchScreen.unmatchConfirm' => '¿Quitar la coincidencia actual de este elemento? Plex lo tratará como sin coincidencia hasta que vuelvas a emparejarlo.',
			'matchScreen.unmatchSuccess' => 'Elemento desvinculado',
			'matchScreen.unmatchFailed' => 'No se pudo desvincular el elemento',
			'matchScreen.matchApplied' => 'Coincidencia aplicada',
			'matchScreen.matchFailed' => 'No se pudo aplicar la coincidencia',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Año',
			'matchScreen.search' => 'Buscar',
			'matchScreen.noMatchesFound' => 'No se encontraron coincidencias',
			'serverTasks.title' => 'Tareas del servidor',
			'serverTasks.failedToLoad' => 'Error al cargar tareas',
			'serverTasks.noTasks' => 'No hay tareas en ejecución',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Conectado',
			'trakt.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'trakt.disconnectConfirm' => '¿Desconectar cuenta de Trakt?',
			'trakt.disconnectConfirmBody' => 'Plezy dejará de enviar eventos de reproducción a Trakt. Puedes volver a conectar cuando quieras.',
			'trakt.scrobble' => 'Scrobbling en tiempo real',
			'trakt.scrobbleDescription' => 'Enviar eventos de reproducción, pausa y parada a Trakt durante la reproducción.',
			'trakt.watchedSync' => 'Sincronizar estado de visto',
			'trakt.watchedSyncDescription' => 'Cuando marques elementos como vistos en Plezy, también se marcarán en Trakt.',
			'trackers.title' => 'Rastreadores',
			'trackers.hubSubtitle' => 'Mantén sincronizado tu progreso con Trakt y otros servicios.',
			'trackers.notConnected' => 'No conectado',
			'trackers.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'trackers.scrobble' => 'Registrar progreso automáticamente',
			'trackers.scrobbleDescription' => 'Actualiza tu lista cuando termines un episodio o película.',
			'trackers.disconnectConfirm' => ({required Object service}) => '¿Desconectar ${service}?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy dejará de actualizar tu lista de ${service}. Puedes reconectarte en cualquier momento.',
			'trackers.connectFailed' => ({required Object service}) => 'No se pudo conectar a ${service}. Inténtalo de nuevo.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => 'Activar Plezy en ${service}',
			'trackers.deviceCode.body' => ({required Object url}) => 'Visita ${url} e introduce este código:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para activar',
			'trackers.deviceCode.waitingForAuthorization' => 'Esperando autorización…',
			'trackers.deviceCode.codeCopied' => 'Código copiado',
			'trackers.oauthProxy.title' => ({required Object service}) => 'Inicia sesión en ${service}',
			'trackers.oauthProxy.body' => 'Escanea este código QR con tu teléfono, o abre la URL de abajo en cualquier dispositivo con navegador.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para iniciar sesión',
			'trackers.oauthProxy.urlCopied' => 'URL copiada',
			'trackers.libraryFilter.title' => 'Filtro de bibliotecas',
			'trackers.libraryFilter.subtitleAllSyncing' => 'Sincronizando todas las bibliotecas',
			'trackers.libraryFilter.subtitleNoneSyncing' => 'Nada se sincroniza',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloqueadas',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} permitidas',
			'trackers.libraryFilter.mode' => 'Modo de filtro',
			'trackers.libraryFilter.modeBlacklist' => 'Lista negra',
			'trackers.libraryFilter.modeWhitelist' => 'Lista blanca',
			'trackers.libraryFilter.modeHintBlacklist' => 'Sincronizar todas las bibliotecas excepto las marcadas abajo.',
			'trackers.libraryFilter.modeHintWhitelist' => 'Sincronizar solo las bibliotecas marcadas abajo.',
			'trackers.libraryFilter.libraries' => 'Bibliotecas',
			'trackers.libraryFilter.noLibraries' => 'No hay bibliotecas disponibles',
			_ => null,
		};
	}
}
