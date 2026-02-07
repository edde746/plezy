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
	@override late final _TranslationsPinEntryEs pinEntry = _TranslationsPinEntryEs._(_root);
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
	@override late final _TranslationsCollectionsEs collections = _TranslationsCollectionsEs._(_root);
	@override late final _TranslationsPlaylistsEs playlists = _TranslationsPlaylistsEs._(_root);
	@override late final _TranslationsWatchTogetherEs watchTogether = _TranslationsWatchTogetherEs._(_root);
	@override late final _TranslationsDownloadsEs downloads = _TranslationsDownloadsEs._(_root);
	@override late final _TranslationsShadersEs shaders = _TranslationsShadersEs._(_root);
}

// Path: app
class _TranslationsAppEs implements TranslationsAppEn {
	_TranslationsAppEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Cargando...';
}

// Path: auth
class _TranslationsAuthEs implements TranslationsAuthEn {
	_TranslationsAuthEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inicia sesión con Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get cancel => 'Cancelar';
	@override String get authenticate => 'Autenticar';
	@override String get retry => 'Reintentar';
	@override String get debugEnterToken => 'Debug: Ingresar Token de Plex';
	@override String get plexTokenLabel => 'Token de Autenticación de Plex';
	@override String get plexTokenHint => 'Ingresa tu token de Plex.tv';
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
}

// Path: screens
class _TranslationsScreensEs implements TranslationsScreensEn {
	_TranslationsScreensEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencias';
	@override String get switchProfile => 'Cambiar Perfil';
	@override String get subtitleStyling => 'Estilo de Subtítulos';
	@override String get mpvConfig => 'Configuración de MPV';
	@override String get search => 'Buscar';
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
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Apariencia';
	@override String get videoPlayback => 'Reproducción de Video';
	@override String get advanced => 'Avanzado';
	@override String get episodePosterMode => 'Estilo de Póster de Episodio';
	@override String get seriesPoster => 'Póster de Serie';
	@override String get seriesPosterDescription => 'Mostrar el póster de la serie para todos los episodios';
	@override String get seasonPoster => 'Póster de Temporada';
	@override String get seasonPosterDescription => 'Mostrar el póster de la temporada para los episodios';
	@override String get episodeThumbnail => 'Miniatura de Episodio';
	@override String get episodeThumbnailDescription => 'Mostrar miniaturas de capturas de pantalla de episodios en 16:9';
	@override String get showHeroSectionDescription => 'Mostrar carrusel de contenido destacado en la pantalla de inicio';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Ingresa la duración (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get systemThemeDescription => 'Sigue la configuración del sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Oscuro';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Negro puro para pantallas OLED';
	@override String get libraryDensity => 'Densidad de Biblioteca';
	@override String get compact => 'Compacto';
	@override String get compactDescription => 'Tarjetas más pequeñas, más elementos visibles';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Tamaño predeterminado';
	@override String get comfortable => 'Cómodo';
	@override String get comfortableDescription => 'Tarjetas más grandes, menos elementos visibles';
	@override String get viewMode => 'Modo de Vista';
	@override String get gridView => 'Cuadrícula';
	@override String get gridViewDescription => 'Mostrar elementos en un diseño de cuadrícula';
	@override String get listView => 'Lista';
	@override String get listViewDescription => 'Mostrar elementos en un diseño de lista';
	@override String get showHeroSection => 'Mostrar Sección Destacada';
	@override String get useGlobalHubs => 'Usar Diseño de Inicio de Plex';
	@override String get useGlobalHubsDescription => 'Mostrar los hubs de la página de inicio como el cliente oficial de Plex. Cuando está desactivado, muestra recomendaciones por biblioteca en su lugar.';
	@override String get showServerNameOnHubs => 'Mostrar Nombre del Servidor en los Hubs';
	@override String get showServerNameOnHubsDescription => 'Mostrar siempre el nombre del servidor en los títulos de los hubs. Cuando está desactivado, solo se muestra para nombres de hubs duplicados.';
	@override String get alwaysKeepSidebarOpen => 'Mantener siempre la barra lateral abierta';
	@override String get alwaysKeepSidebarOpenDescription => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse';
	@override String get showUnwatchedCount => 'Mostrar conteo de no vistos';
	@override String get showUnwatchedCountDescription => 'Mostrar el conteo de episodios no vistos en series y temporadas';
	@override String get playerBackend => 'Reproductor';
	@override String get exoPlayer => 'ExoPlayer (Recomendado)';
	@override String get exoPlayerDescription => 'Reproductor nativo de Android con mejor soporte de hardware';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => 'Reproductor avanzado con más funciones y soporte de subtítulos ASS';
	@override String get hardwareDecoding => 'Decodificación por Hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleración por hardware cuando esté disponible';
	@override String get bufferSize => 'Tamaño del Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Estilo de Subtítulos';
	@override String get subtitleStylingDescription => 'Personalizar la apariencia de los subtítulos';
	@override String get smallSkipDuration => 'Salto pequeño';
	@override String get largeSkipDuration => 'Salto grande';
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
	@override String get shortcutsReset => 'Atajos restablecidos a los valores predeterminados';
	@override String get about => 'Acerca de';
	@override String get aboutDescription => 'Información de la aplicación y licencias';
	@override String get updates => 'Actualizaciones';
	@override String get updateAvailable => 'Actualización disponible';
	@override String get checkForUpdates => 'Buscar actualizaciones';
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
	@override String get cellularDownloadBlocked => 'Las descargas están desactivadas en datos móviles. Conéctate a una red WiFi o cambia la configuración.';
	@override String get maxVolume => 'Volumen Máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Presencia de Discord';
	@override String get discordRichPresenceDescription => 'Mostrar lo que estás viendo en Discord';
	@override String get matchContentFrameRate => 'Ajustar frecuencia de actualización';
	@override String get matchContentFrameRateDescription => 'Ajustar la frecuencia de actualización de la pantalla para que coincida con el video, reduciendo tirones y ahorrando batería';
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

// Path: pinEntry
class _TranslationsPinEntryEs implements TranslationsPinEntryEn {
	_TranslationsPinEntryEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Introduce el PIN';
	@override String get showPin => 'Mostrar PIN';
	@override String get hidePin => 'Ocultar PIN';
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
	@override String get confirmDelete => '¿Estás seguro de que quieres eliminar este elemento de tu sistema de archivos?';
	@override String get deleteMultipleWarning => 'Es posible que se eliminen varios elementos.';
	@override String get mediaDeletedSuccessfully => 'Elemento multimedia eliminado con éxito';
	@override String get mediaFailedToDelete => 'Error al eliminar el elemento multimedia';
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
	@override String get sleepTimerCompleted => 'Temporizador completado - reproducción pausada';
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
	@override String get audioTrackButton => 'Pistas de audio';
	@override String get subtitlesButton => 'Subtítulos';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionsButton => 'Versiones de video';
	@override String get pipButton => 'Modo PiP (Imagen en Imagen)';
	@override String get aspectRatioButton => 'Relación de aspecto';
	@override String get fullscreenButton => 'Entrar en pantalla completa';
	@override String get exitFullscreenButton => 'Salir de pantalla completa';
	@override String get alwaysOnTopButton => 'Siempre visible';
	@override String get rotationLockButton => 'Bloqueo de rotación';
	@override String get timelineSlider => 'Línea de tiempo del video';
	@override String get volumeSlider => 'Nivel de volumen';
	@override String endsAt({required Object time}) => 'Termina a las ${time}';
	@override String get backButton => 'Atrás';
	@override String get pipFailed => 'Error al iniciar Imagen en Imagen';
	@override late final _TranslationsVideoControlsPipErrorsEs pipErrors = _TranslationsVideoControlsPipErrorsEs._(_root);
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
	@override String get removedFromContinueWatching => 'Eliminado de Seguir Viendo';
	@override String errorLoading({required Object error}) => 'Error: ${error}';
	@override String get fileInfoNotAvailable => 'Información de archivo no disponible';
	@override String errorLoadingFileInfo({required Object error}) => 'Error al cargar info de archivo: ${error}';
	@override String get errorLoadingSeries => 'Error al cargar la serie';
	@override String get errorLoadingSeason => 'Error al cargar la temporada';
	@override String get musicNotSupported => 'La reproducción de música aún no está soportada';
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
	@override String get logsUploaded => 'Logs uploaded';
	@override String get logsUploadFailed => 'Failed to upload logs';
	@override String get logId => 'Log ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingEs implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opciones de Estilo';
	@override String get fontSize => 'Tamaño de Fuente';
	@override String get textColor => 'Color de Texto';
	@override String get borderSize => 'Tamaño de Borde';
	@override String get borderColor => 'Color de Borde';
	@override String get backgroundOpacity => 'Opacidad de Fondo';
	@override String get backgroundColor => 'Color de Fondo';
}

// Path: mpvConfig
class _TranslationsMpvConfigEs implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración de MPV';
	@override String get description => 'Ajustes avanzados del reproductor de video';
	@override String get properties => 'Propiedades';
	@override String get presets => 'Ajustes preestablecidos';
	@override String get noProperties => 'No hay propiedades configuradas';
	@override String get noPresets => 'No hay ajustes guardados';
	@override String get addProperty => 'Añadir Propiedad';
	@override String get editProperty => 'Editar Propiedad';
	@override String get deleteProperty => 'Eliminar Propiedad';
	@override String get propertyKey => 'Clave de la Propiedad';
	@override String get propertyKeyHint => 'ej., hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Valor de la Propiedad';
	@override String get propertyValueHint => 'ej., auto, 256000000';
	@override String get saveAsPreset => 'Guardar como Ajuste...';
	@override String get presetName => 'Nombre del Ajuste';
	@override String get presetNameHint => 'Introduce un nombre para este ajuste';
	@override String get loadPreset => 'Cargar';
	@override String get deletePreset => 'Eliminar';
	@override String get presetSaved => 'Ajuste guardado';
	@override String get presetLoaded => 'Ajuste cargado';
	@override String get presetDeleted => 'Ajuste eliminado';
	@override String get confirmDeletePreset => '¿Estás seguro de que quieres eliminar este ajuste?';
	@override String get confirmDeleteProperty => '¿Estás seguro de que quieres eliminar esta propiedad?';
	@override String entriesCount({required Object count}) => '${count} entradas';
}

// Path: dialog
class _TranslationsDialogEs implements TranslationsDialogEn {
	_TranslationsDialogEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar Acción';
	@override String get cancel => 'Cancelar';
}

// Path: discover
class _TranslationsDiscoverEs implements TranslationsDiscoverEn {
	_TranslationsDiscoverEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descubrir';
	@override String get switchProfile => 'Cambiar Perfil';
	@override String get logout => 'Cerrar sesión';
	@override String get noContentAvailable => 'No hay contenido disponible';
	@override String get addMediaToLibraries => 'Añade contenido a tus bibliotecas';
	@override String get continueWatching => 'Seguir Viendo';
	@override String get play => 'Reproducir';
	@override String playEpisode({required Object season, required Object episode}) => 'T${season}E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Resumen';
	@override String get cast => 'Reparto';
	@override String get seasons => 'Temporadas';
	@override String get studio => 'Estudio';
	@override String get rating => 'Calificación';
	@override String episodeCount({required Object count}) => '${count} episodios';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} vistos';
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
	@override String get uploadLogs => 'Upload Logs';
	@override String get error => 'Error:';
	@override String get stackTrace => 'Traza de la pila (Stack Trace):';
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
	@override String get home => 'Inicio';
	@override String get search => 'Buscar';
	@override String get libraries => 'Bibliotecas';
	@override String get settings => 'Configuración';
	@override String get downloads => 'Descargas';
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
	@override String get createNewCollection => 'Crear Nueva Colección';
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
	@override String get createNewPlaylist => 'Crear Nueva Lista';
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
	@override String get enterCodeHint => 'Introduce el código de 8 caracteres';
	@override String get pasteFromClipboard => 'Pegar desde el portapapeles';
	@override String get pleaseEnterCode => 'Por favor, introduce un código de sesión';
	@override String get codeMustBe8Chars => 'El código de sesión debe tener 8 caracteres';
	@override String get joinInstructions => 'Introduce el código de sesión compartido por el anfitrión para unirte a su sesión.';
	@override String get failedToCreate => 'Error al crear la sesión';
	@override String get failedToJoin => 'Error al unirse a la sesión';
	@override String get sessionCodeCopied => 'Código de sesión copiado al portapapeles';
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
	@override String episodesQueued({required Object count}) => '${count} episodios en cola para descargar';
	@override String get downloadDeleted => 'Descarga eliminada';
	@override String deleteConfirm({required Object title}) => '¿Estás seguro de que quieres eliminar "${title}"? Esto borrará el archivo descargado de tu dispositivo.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})';
}

// Path: shaders
class _TranslationsShadersEs implements TranslationsShadersEn {
	_TranslationsShadersEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sin mejora de video';
	@override String get nvscalerDescription => 'Escalado de imagen NVIDIA para un video más nítido';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta Calidad';
	@override String get mode => 'Modo';
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
	@override String get speedIncrease => 'Aumentar Velocidad';
	@override String get speedDecrease => 'Disminuir Velocidad';
	@override String get speedReset => 'Restablecer Velocidad';
	@override String get subSeekNext => 'Ir al Siguiente Subtítulo';
	@override String get subSeekPrev => 'Ir al Anterior Subtítulo';
	@override String get shaderToggle => 'Alternar Shaders';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsEs implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requiere Android 8.0 o más reciente';
	@override String get permissionDisabled => 'El permiso de Imagen en Imagen está desactivado. Actívalo en Ajustes > Aplicaciones > Plezy > Imagen en Imagen';
	@override String get notSupported => 'El dispositivo no soporta el modo Imagen en Imagen';
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
	@override String get all => 'Todo';
	@override String get movies => 'Películas';
	@override String get shows => 'Series';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episodios';
	@override String get folders => 'Carpetas';
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
			'app.loading' => 'Cargando...',
			'auth.signInWithPlex' => 'Inicia sesión con Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.cancel' => 'Cancelar',
			'auth.authenticate' => 'Autenticar',
			'auth.retry' => 'Reintentar',
			'auth.debugEnterToken' => 'Debug: Ingresar Token de Plex',
			'auth.plexTokenLabel' => 'Token de Autenticación de Plex',
			'auth.plexTokenHint' => 'Ingresa tu token de Plex.tv',
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
			'screens.licenses' => 'Licencias',
			'screens.switchProfile' => 'Cambiar Perfil',
			'screens.subtitleStyling' => 'Estilo de Subtítulos',
			'screens.mpvConfig' => 'Configuración de MPV',
			'screens.search' => 'Buscar',
			'screens.logs' => 'Logs',
			'update.available' => 'Actualización disponible',
			'update.versionAvailable' => ({required Object version}) => 'Versión ${version} disponible',
			'update.currentVersion' => ({required Object version}) => 'Actual: ${version}',
			'update.skipVersion' => 'Saltar esta versión',
			'update.viewRelease' => 'Ver versión',
			'update.latestVersion' => 'Ya estás en la última versión',
			'update.checkFailed' => 'Error al buscar actualizaciones',
			'settings.title' => 'Configuración',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Apariencia',
			'settings.videoPlayback' => 'Reproducción de Video',
			'settings.advanced' => 'Avanzado',
			'settings.episodePosterMode' => 'Estilo de Póster de Episodio',
			'settings.seriesPoster' => 'Póster de Serie',
			'settings.seriesPosterDescription' => 'Mostrar el póster de la serie para todos los episodios',
			'settings.seasonPoster' => 'Póster de Temporada',
			'settings.seasonPosterDescription' => 'Mostrar el póster de la temporada para los episodios',
			'settings.episodeThumbnail' => 'Miniatura de Episodio',
			'settings.episodeThumbnailDescription' => 'Mostrar miniaturas de capturas de pantalla de episodios en 16:9',
			'settings.showHeroSectionDescription' => 'Mostrar carrusel de contenido destacado en la pantalla de inicio',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Ingresa la duración (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.systemThemeDescription' => 'Sigue la configuración del sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Oscuro',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Negro puro para pantallas OLED',
			'settings.libraryDensity' => 'Densidad de Biblioteca',
			'settings.compact' => 'Compacto',
			'settings.compactDescription' => 'Tarjetas más pequeñas, más elementos visibles',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Tamaño predeterminado',
			'settings.comfortable' => 'Cómodo',
			'settings.comfortableDescription' => 'Tarjetas más grandes, menos elementos visibles',
			'settings.viewMode' => 'Modo de Vista',
			'settings.gridView' => 'Cuadrícula',
			'settings.gridViewDescription' => 'Mostrar elementos en un diseño de cuadrícula',
			'settings.listView' => 'Lista',
			'settings.listViewDescription' => 'Mostrar elementos en un diseño de lista',
			'settings.showHeroSection' => 'Mostrar Sección Destacada',
			'settings.useGlobalHubs' => 'Usar Diseño de Inicio de Plex',
			'settings.useGlobalHubsDescription' => 'Mostrar los hubs de la página de inicio como el cliente oficial de Plex. Cuando está desactivado, muestra recomendaciones por biblioteca en su lugar.',
			'settings.showServerNameOnHubs' => 'Mostrar Nombre del Servidor en los Hubs',
			'settings.showServerNameOnHubsDescription' => 'Mostrar siempre el nombre del servidor en los títulos de los hubs. Cuando está desactivado, solo se muestra para nombres de hubs duplicados.',
			'settings.alwaysKeepSidebarOpen' => 'Mantener siempre la barra lateral abierta',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse',
			'settings.showUnwatchedCount' => 'Mostrar conteo de no vistos',
			'settings.showUnwatchedCountDescription' => 'Mostrar el conteo de episodios no vistos en series y temporadas',
			'settings.playerBackend' => 'Reproductor',
			'settings.exoPlayer' => 'ExoPlayer (Recomendado)',
			'settings.exoPlayerDescription' => 'Reproductor nativo de Android con mejor soporte de hardware',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Reproductor avanzado con más funciones y soporte de subtítulos ASS',
			'settings.hardwareDecoding' => 'Decodificación por Hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleración por hardware cuando esté disponible',
			'settings.bufferSize' => 'Tamaño del Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => 'Estilo de Subtítulos',
			'settings.subtitleStylingDescription' => 'Personalizar la apariencia de los subtítulos',
			'settings.smallSkipDuration' => 'Salto pequeño',
			'settings.largeSkipDuration' => 'Salto grande',
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
			'settings.shortcutsReset' => 'Atajos restablecidos a los valores predeterminados',
			'settings.about' => 'Acerca de',
			'settings.aboutDescription' => 'Información de la aplicación y licencias',
			'settings.updates' => 'Actualizaciones',
			'settings.updateAvailable' => 'Actualización disponible',
			'settings.checkForUpdates' => 'Buscar actualizaciones',
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
			'settings.cellularDownloadBlocked' => 'Las descargas están desactivadas en datos móviles. Conéctate a una red WiFi o cambia la configuración.',
			'settings.maxVolume' => 'Volumen Máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Presencia de Discord',
			'settings.discordRichPresenceDescription' => 'Mostrar lo que estás viendo en Discord',
			'settings.matchContentFrameRate' => 'Ajustar frecuencia de actualización',
			'settings.matchContentFrameRateDescription' => 'Ajustar la frecuencia de actualización de la pantalla para que coincida con el video, reduciendo tirones y ahorrando batería',
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
			'hotkeys.actions.speedIncrease' => 'Aumentar Velocidad',
			'hotkeys.actions.speedDecrease' => 'Disminuir Velocidad',
			'hotkeys.actions.speedReset' => 'Restablecer Velocidad',
			'hotkeys.actions.subSeekNext' => 'Ir al Siguiente Subtítulo',
			'hotkeys.actions.subSeekPrev' => 'Ir al Anterior Subtítulo',
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'pinEntry.enterPin' => 'Introduce el PIN',
			'pinEntry.showPin' => 'Mostrar PIN',
			'pinEntry.hidePin' => 'Ocultar PIN',
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
			'mediaMenu.confirmDelete' => '¿Estás seguro de que quieres eliminar este elemento de tu sistema de archivos?',
			'mediaMenu.deleteMultipleWarning' => 'Es posible que se eliminen varios elementos.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Elemento multimedia eliminado con éxito',
			'mediaMenu.mediaFailedToDelete' => 'Error al eliminar el elemento multimedia',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, película',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serie de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por ciento visto',
			'accessibility.mediaCardUnwatched' => 'no visto',
			'accessibility.tapToPlay' => 'Toca para reproducir',
			'tooltips.shufflePlay' => 'Reproducción aleatoria',
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
			'videoControls.sleepTimerCompleted' => 'Temporizador completado - reproducción pausada',
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
			'videoControls.audioTrackButton' => 'Pistas de audio',
			'videoControls.subtitlesButton' => 'Subtítulos',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionsButton' => 'Versiones de video',
			'videoControls.pipButton' => 'Modo PiP (Imagen en Imagen)',
			'videoControls.aspectRatioButton' => 'Relación de aspecto',
			'videoControls.fullscreenButton' => 'Entrar en pantalla completa',
			'videoControls.exitFullscreenButton' => 'Salir de pantalla completa',
			'videoControls.alwaysOnTopButton' => 'Siempre visible',
			'videoControls.rotationLockButton' => 'Bloqueo de rotación',
			'videoControls.timelineSlider' => 'Línea de tiempo del video',
			'videoControls.volumeSlider' => 'Nivel de volumen',
			'videoControls.endsAt' => ({required Object time}) => 'Termina a las ${time}',
			'videoControls.backButton' => 'Atrás',
			'videoControls.pipFailed' => 'Error al iniciar Imagen en Imagen',
			'videoControls.pipErrors.androidVersion' => 'Requiere Android 8.0 o más reciente',
			'videoControls.pipErrors.permissionDisabled' => 'El permiso de Imagen en Imagen está desactivado. Actívalo en Ajustes > Aplicaciones > Plezy > Imagen en Imagen',
			'videoControls.pipErrors.notSupported' => 'El dispositivo no soporta el modo Imagen en Imagen',
			'videoControls.pipErrors.failed' => 'Error al iniciar Imagen en Imagen',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocurrió un error: ${error}',
			'userStatus.admin' => 'Administrador',
			'userStatus.restricted' => 'Restringido',
			'userStatus.protected' => 'Protegido',
			'userStatus.current' => 'ACTUAL',
			'messages.markedAsWatched' => 'Marcado como visto',
			'messages.markedAsUnwatched' => 'Marcado como no visto',
			'messages.markedAsWatchedOffline' => 'Marcado como visto (se sincronizará al estar en línea)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como no visto (se sincronizará al estar en línea)',
			'messages.removedFromContinueWatching' => 'Eliminado de Seguir Viendo',
			'messages.errorLoading' => ({required Object error}) => 'Error: ${error}',
			'messages.fileInfoNotAvailable' => 'Información de archivo no disponible',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Error al cargar info de archivo: ${error}',
			'messages.errorLoadingSeries' => 'Error al cargar la serie',
			'messages.errorLoadingSeason' => 'Error al cargar la temporada',
			'messages.musicNotSupported' => 'La reproducción de música aún no está soportada',
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
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => 'Opciones de Estilo',
			'subtitlingStyling.fontSize' => 'Tamaño de Fuente',
			'subtitlingStyling.textColor' => 'Color de Texto',
			'subtitlingStyling.borderSize' => 'Tamaño de Borde',
			'subtitlingStyling.borderColor' => 'Color de Borde',
			'subtitlingStyling.backgroundOpacity' => 'Opacidad de Fondo',
			'subtitlingStyling.backgroundColor' => 'Color de Fondo',
			'mpvConfig.title' => 'Configuración de MPV',
			'mpvConfig.description' => 'Ajustes avanzados del reproductor de video',
			'mpvConfig.properties' => 'Propiedades',
			'mpvConfig.presets' => 'Ajustes preestablecidos',
			'mpvConfig.noProperties' => 'No hay propiedades configuradas',
			'mpvConfig.noPresets' => 'No hay ajustes guardados',
			'mpvConfig.addProperty' => 'Añadir Propiedad',
			'mpvConfig.editProperty' => 'Editar Propiedad',
			'mpvConfig.deleteProperty' => 'Eliminar Propiedad',
			'mpvConfig.propertyKey' => 'Clave de la Propiedad',
			'mpvConfig.propertyKeyHint' => 'ej., hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Valor de la Propiedad',
			'mpvConfig.propertyValueHint' => 'ej., auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Guardar como Ajuste...',
			'mpvConfig.presetName' => 'Nombre del Ajuste',
			'mpvConfig.presetNameHint' => 'Introduce un nombre para este ajuste',
			'mpvConfig.loadPreset' => 'Cargar',
			'mpvConfig.deletePreset' => 'Eliminar',
			'mpvConfig.presetSaved' => 'Ajuste guardado',
			'mpvConfig.presetLoaded' => 'Ajuste cargado',
			'mpvConfig.presetDeleted' => 'Ajuste eliminado',
			'mpvConfig.confirmDeletePreset' => '¿Estás seguro de que quieres eliminar este ajuste?',
			'mpvConfig.confirmDeleteProperty' => '¿Estás seguro de que quieres eliminar esta propiedad?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} entradas',
			'dialog.confirmAction' => 'Confirmar Acción',
			'dialog.cancel' => 'Cancelar',
			'discover.title' => 'Descubrir',
			'discover.switchProfile' => 'Cambiar Perfil',
			'discover.logout' => 'Cerrar sesión',
			'discover.noContentAvailable' => 'No hay contenido disponible',
			'discover.addMediaToLibraries' => 'Añade contenido a tus bibliotecas',
			'discover.continueWatching' => 'Seguir Viendo',
			'discover.play' => 'Reproducir',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'T${season}E${episode}',
			'discover.pause' => 'Pausa',
			'discover.overview' => 'Resumen',
			'discover.cast' => 'Reparto',
			'discover.seasons' => 'Temporadas',
			'discover.studio' => 'Estudio',
			'discover.rating' => 'Calificación',
			'discover.episodeCount' => ({required Object count}) => '${count} episodios',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} vistos',
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
			'libraries.failedToAnalyze' => ({required Object error}) => 'Error al analizar la biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'No se encontraron bibliotecas',
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
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => 'Error:',
			'logs.stackTrace' => 'Traza de la pila (Stack Trace):',
			'licenses.relatedPackages' => 'Paquetes relacionados',
			'licenses.license' => 'Licencia',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencia ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licencias',
			'navigation.home' => 'Inicio',
			'navigation.search' => 'Buscar',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.settings' => 'Configuración',
			'navigation.downloads' => 'Descargas',
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
			'collections.createNewCollection' => 'Crear Nueva Colección',
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
			'playlists.createNewPlaylist' => 'Crear Nueva Lista',
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
			_ => null,
		} ?? switch (path) {
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
			'watchTogether.enterCodeHint' => 'Introduce el código de 8 caracteres',
			'watchTogether.pasteFromClipboard' => 'Pegar desde el portapapeles',
			'watchTogether.pleaseEnterCode' => 'Por favor, introduce un código de sesión',
			'watchTogether.codeMustBe8Chars' => 'El código de sesión debe tener 8 caracteres',
			'watchTogether.joinInstructions' => 'Introduce el código de sesión compartido por el anfitrión para unirte a su sesión.',
			'watchTogether.failedToCreate' => 'Error al crear la sesión',
			'watchTogether.failedToJoin' => 'Error al unirse a la sesión',
			'watchTogether.sessionCodeCopied' => 'Código de sesión copiado al portapapeles',
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodios en cola para descargar',
			'downloads.downloadDeleted' => 'Descarga eliminada',
			'downloads.deleteConfirm' => ({required Object title}) => '¿Estás seguro de que quieres eliminar "${title}"? Esto borrará el archivo descargado de tu dispositivo.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sin mejora de video',
			'shaders.nvscalerDescription' => 'Escalado de imagen NVIDIA para un video más nítido',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta Calidad',
			'shaders.mode' => 'Modo',
			_ => null,
		};
	}
}
