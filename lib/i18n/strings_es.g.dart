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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$es app = _Translations$app$es._(_root);
	@override late final _Translations$auth$es auth = _Translations$auth$es._(_root);
	@override late final _Translations$common$es common = _Translations$common$es._(_root);
	@override late final _Translations$screens$es screens = _Translations$screens$es._(_root);
	@override late final _Translations$update$es update = _Translations$update$es._(_root);
	@override late final _Translations$settings$es settings = _Translations$settings$es._(_root);
	@override late final _Translations$search$es search = _Translations$search$es._(_root);
	@override late final _Translations$hotkeys$es hotkeys = _Translations$hotkeys$es._(_root);
	@override late final _Translations$fileInfo$es fileInfo = _Translations$fileInfo$es._(_root);
	@override late final _Translations$mediaMenu$es mediaMenu = _Translations$mediaMenu$es._(_root);
	@override late final _Translations$rateSheet$es rateSheet = _Translations$rateSheet$es._(_root);
	@override late final _Translations$accessibility$es accessibility = _Translations$accessibility$es._(_root);
	@override late final _Translations$tooltips$es tooltips = _Translations$tooltips$es._(_root);
	@override late final _Translations$audioTracks$es audioTracks = _Translations$audioTracks$es._(_root);
	@override late final _Translations$videoControls$es videoControls = _Translations$videoControls$es._(_root);
	@override late final _Translations$messages$es messages = _Translations$messages$es._(_root);
	@override late final _Translations$subtitlingStyling$es subtitlingStyling = _Translations$subtitlingStyling$es._(_root);
	@override late final _Translations$mpvConfig$es mpvConfig = _Translations$mpvConfig$es._(_root);
	@override late final _Translations$dialog$es dialog = _Translations$dialog$es._(_root);
	@override late final _Translations$profiles$es profiles = _Translations$profiles$es._(_root);
	@override late final _Translations$connections$es connections = _Translations$connections$es._(_root);
	@override late final _Translations$discover$es discover = _Translations$discover$es._(_root);
	@override late final _Translations$errors$es errors = _Translations$errors$es._(_root);
	@override late final _Translations$libraries$es libraries = _Translations$libraries$es._(_root);
	@override late final _Translations$about$es about = _Translations$about$es._(_root);
	@override late final _Translations$serverSelection$es serverSelection = _Translations$serverSelection$es._(_root);
	@override late final _Translations$hubDetail$es hubDetail = _Translations$hubDetail$es._(_root);
	@override late final _Translations$logs$es logs = _Translations$logs$es._(_root);
	@override late final _Translations$licenses$es licenses = _Translations$licenses$es._(_root);
	@override late final _Translations$navigation$es navigation = _Translations$navigation$es._(_root);
	@override late final _Translations$explore$es explore = _Translations$explore$es._(_root);
	@override late final _Translations$liveTv$es liveTv = _Translations$liveTv$es._(_root);
	@override late final _Translations$collections$es collections = _Translations$collections$es._(_root);
	@override late final _Translations$playlists$es playlists = _Translations$playlists$es._(_root);
	@override late final _Translations$music$es music = _Translations$music$es._(_root);
	@override late final _Translations$watchTogether$es watchTogether = _Translations$watchTogether$es._(_root);
	@override late final _Translations$downloads$es downloads = _Translations$downloads$es._(_root);
	@override late final _Translations$shaders$es shaders = _Translations$shaders$es._(_root);
	@override late final _Translations$companionRemote$es companionRemote = _Translations$companionRemote$es._(_root);
	@override late final _Translations$videoSettings$es videoSettings = _Translations$videoSettings$es._(_root);
	@override late final _Translations$performanceOverlay$es performanceOverlay = _Translations$performanceOverlay$es._(_root);
	@override late final _Translations$externalPlayer$es externalPlayer = _Translations$externalPlayer$es._(_root);
	@override late final _Translations$metadataEdit$es metadataEdit = _Translations$metadataEdit$es._(_root);
	@override late final _Translations$matchScreen$es matchScreen = _Translations$matchScreen$es._(_root);
	@override late final _Translations$serverTasks$es serverTasks = _Translations$serverTasks$es._(_root);
	@override late final _Translations$trakt$es trakt = _Translations$trakt$es._(_root);
	@override late final _Translations$seerr$es seerr = _Translations$seerr$es._(_root);
	@override late final _Translations$services$es services = _Translations$services$es._(_root);
	@override late final _Translations$addServer$es addServer = _Translations$addServer$es._(_root);
}

// Path: app
class _Translations$app$es extends Translations$app$en {
	_Translations$app$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$es extends Translations$auth$en {
	_Translations$auth$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inicia sesión con Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'Se agotó el tiempo de autenticación. Inténtalo de nuevo.';
	@override String get scanQRToSignIn => 'Escanea este código QR para iniciar sesión';
	@override String get waitingForAuth => 'Esperando autenticación...\nInicia sesión desde tu navegador.';
	@override String get useBrowser => 'Usar navegador';
	@override String get or => 'o';
	@override String get connectToJellyfin => 'Conectar a Jellyfin';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectInstructions => 'Abre Quick Connect en Jellyfin e introduce este código.';
	@override String get quickConnectWaiting => 'Esperando aprobación…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'Quick Connect caducó. Inténtalo de nuevo.';
	@override String get localDataRecoveryRequired => 'Plezy no pudo recuperar de forma segura los datos locales de inicio de sesión ni la reproducción pendiente. Vuelve a iniciar sesión.';
}

// Path: common
class _Translations$common$es extends Translations$common$en {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Cerrar';
	@override String get clear => 'Borrar';
	@override String get reset => 'Restablecer';
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
	@override String get edit => 'Editar';
	@override String get shuffle => 'Reproducción aleatoria';
	@override String get addTo => 'Añadir a...';
	@override String get createNew => 'Crear';
	@override String get connect => 'Conectar';
	@override String get disconnect => 'Desconectar';
	@override String get play => 'Reproducir';
	@override String get pause => 'Pausar';
	@override String get resume => 'Reanudar';
	@override String get error => 'Error';
	@override String get search => 'Buscar';
	@override String get home => 'Inicio';
	@override String get back => 'Atrás';
	@override String get settings => 'Ajustes';
	@override String get mute => 'Silenciar';
	@override String get ok => 'OK';
	@override String get off => 'Desactivado';
	@override String seasonNumber({required Object number}) => 'Temporada ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episodio ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Capítulo ${number}';
	@override String get reconnect => 'Reconectar';
	@override String get viewAll => 'Ver todo';
	@override String get checkingNetwork => 'Comprobando red...';
	@override String get loadingServers => 'Cargando servidores...';
	@override String get connectingToServers => 'Conectando a servidores...';
	@override String get startingOfflineMode => 'Iniciando modo sin conexión...';
	@override String get loading => 'Cargando...';
	@override String get fullscreen => 'Pantalla completa';
	@override String get exitFullscreen => 'Salir de pantalla completa';
	@override String get pressBackAgainToExit => 'Pulsa Atrás de nuevo para salir';
}

// Path: screens
class _Translations$screens$es extends Translations$screens$en {
	_Translations$screens$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencias';
	@override String get switchProfile => 'Cambiar perfil';
	@override String get subtitleStyling => 'Estilo de subtítulos';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Registros';
}

// Path: update
class _Translations$update$es extends Translations$update$en {
	_Translations$update$es._(TranslationsEs root) : this._root = root, super.internal(root);

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
class _Translations$settings$es extends Translations$settings$en {
	_Translations$settings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración';
	@override String get supportDeveloper => 'Apoya Plezy';
	@override String get supportDeveloperDescription => 'Dona vía Liberapay para financiar el desarrollo';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Apariencia';
	@override String get videoPlayback => 'Reproducción de video';
	@override String get videoPlaybackDescription => 'Configurar el comportamiento de reproducción';
	@override String get advanced => 'Avanzado';
	@override String get episodePosterMode => 'Estilo del póster de episodio';
	@override String get seriesPoster => 'Póster de la serie';
	@override String get seasonPoster => 'Póster de la temporada';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Mostrar carrusel de contenido destacado en la pantalla de inicio';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Introduce la duración (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Oscuro';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Densidad de la biblioteca';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Cómodo';
	@override String get tvCornerSpotlightBackdrop => 'Imagen destacada en la esquina';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostrar la imagen destacada en la esquina superior derecha en lugar de ocupar toda la pantalla';
	@override String get viewMode => 'Modo de vista';
	@override String get gridView => 'Cuadrícula';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar sección destacada';
	@override String get continueWatchingAction => 'Acción de «Seguir viendo»';
	@override String get continueWatchingPlay => 'Reproducir';
	@override String get continueWatchingDetails => 'Abrir detalles';
	@override String get episodeAction => 'Acción de episodio';
	@override String get episodePlay => 'Reproducir';
	@override String get episodeDetails => 'Abrir detalles';
	@override String get useGlobalHubs => 'Usar secciones de inicio';
	@override String get useGlobalHubsDescription => 'Mostrar secciones de inicio unificadas. De lo contrario, usar las recomendaciones de cada biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar el nombre del servidor en las secciones';
	@override String get showServerNameOnHubsDescription => 'Mostrar siempre el nombre del servidor en los títulos de las secciones.';
	@override String get groupLibrariesByServer => 'Agrupar bibliotecas por servidor';
	@override String get groupLibrariesByServerDescription => 'Agrupar bibliotecas de la barra lateral por servidor multimedia.';
	@override String get alwaysKeepSidebarOpen => 'Mantener siempre la barra lateral abierta';
	@override String get alwaysKeepSidebarOpenDescription => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse';
	@override String get showUnwatchedCount => 'Mostrar el número de elementos no vistos';
	@override String get showUnwatchedCountDescription => 'Mostrar el número de episodios no vistos en series y temporadas';
	@override String get showEpisodeNumberOnCards => 'Mostrar número de episodio en las tarjetas';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostrar temporada y episodio en tarjetas de episodio';
	@override String get showSeasonPostersOnTabs => 'Mostrar pósters de temporada en las pestañas';
	@override String get showSeasonPostersOnTabsDescription => 'Mostrar el póster de cada temporada sobre su pestaña';
	@override String get tvFullCardLayout => 'Tarjetas TV completas';
	@override String get tvFullCardLayoutDescription => 'Usar tarjetas TV solo con imagen y nombres de actores superpuestos';
	@override String get focusGlow => 'Resplandor de selección';
	@override String get focusGlowDescription => 'Mostrar un resplandor suave alrededor de la tarjeta seleccionada';
	@override String get visualEffects => 'Efectos visuales';
	@override String get visualEffectsAuto => 'Automático';
	@override String get visualEffectsAutoDescription => 'Reduce automáticamente los efectos en dispositivos de bajo consumo';
	@override String get visualEffectsFull => 'Completos';
	@override String get visualEffectsReduced => 'Reducidos';
	@override String get visualEffectsReducedDescription => 'Menos animaciones e ilustraciones de menor resolución';
	@override String get hideSpoilers => 'Ocultar spoilers de episodios no vistos';
	@override String get hideSpoilersDescription => 'Desenfocar miniaturas y descripciones de episodios no vistos';
	@override String get playerBackend => 'Motor de reproducción';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Decodificación por hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleración por hardware cuando esté disponible';
	@override String get bufferSize => 'Tamaño del búfer';
	@override String bufferSizeMB({required Object size}) => '${size} MB';
	@override String get bufferSizeAuto => 'Automático (recomendado)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap} MB de memoria disponible. Un búfer de ${size} MB puede afectar a la reproducción.';
	@override String get defaultQualityTitle => 'Calidad predeterminada';
	@override String get musicQualityTitle => 'Calidad de música';
	@override String get subtitleStyling => 'Estilo de subtítulos';
	@override String get subtitleStylingDescription => 'Personalizar la apariencia de los subtítulos';
	@override String get smallSkipDuration => 'Salto pequeño';
	@override String get largeSkipDuration => 'Salto grande';
	@override String get rewindOnResume => 'Rebobinar al reanudar';
	@override String secondsUnit({required Object seconds}) => '${seconds} segundos';
	@override String get defaultSleepTimer => 'Temporizador de apagado';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutos';
	@override String get rememberTrackSelections => 'Recordar selección de pistas por serie/película';
	@override String get rememberTrackSelectionsDescription => 'Recordar opciones de audio y subtítulos por título';
	@override String get showChapterMarkersOnTimeline => 'Mostrar marcadores de capítulos en la barra de progreso';
	@override String get showChapterMarkersOnTimelineDescription => 'Dividir la barra de progreso en los límites de capítulos';
	@override String get clickVideoTogglesPlayback => 'Clic en el video para reproducir/pausar';
	@override String get clickVideoTogglesPlaybackDescription => 'Haz clic en el video para reproducir/pausar en vez de mostrar controles.';
	@override String get videoPlayerControls => 'Controles del reproductor de video';
	@override String get keyboardShortcuts => 'Atajos de teclado';
	@override String get keyboardShortcutsDescription => 'Personalizar los atajos de teclado';
	@override String get videoPlayerNavigation => 'Navegación del reproductor de video';
	@override String get videoPlayerNavigationDescription => 'Usar las teclas de flecha para navegar por los controles del reproductor';
	@override String get watchTogetherRelay => 'Servidor de retransmisión de Ver juntos';
	@override String get watchTogetherRelayDescription => 'Configura un servidor de retransmisión personalizado. Todos deben usar el mismo servidor.';
	@override String get watchTogetherRelayHint => 'https://mi-relay.ejemplo.com';
	@override String get watchTogetherRelayInvalid => 'Introduce una URL base HTTP o HTTPS válida para el servidor de retransmisión.';
	@override String get crashReporting => 'Informes de errores';
	@override String get crashReportingDescription => 'Enviar informes de errores para mejorar la aplicación';
	@override String get debugLogging => 'Registro de depuración';
	@override String get debugLoggingDescription => 'Habilitar registros detallados para solucionar problemas';
	@override String get viewLogs => 'Ver registros';
	@override String get viewLogsDescription => 'Ver los registros de la aplicación';
	@override String get resetSettings => 'Restablecer configuración';
	@override String get resetSettingsDescription => 'Restaurar ajustes predeterminados. No se puede deshacer.';
	@override String get resetSettingsSuccess => 'Configuración restablecida con éxito';
	@override String get backup => 'Copia de seguridad';
	@override String get exportSettings => 'Exportar configuración';
	@override String get exportSettingsDescription => 'Guardar tus preferencias en un archivo';
	@override String get exportSettingsSuccess => 'Configuración exportada';
	@override String get importSettings => 'Importar configuración';
	@override String get importSettingsDescription => 'Restaurar preferencias desde un archivo';
	@override String get importSettingsConfirm => 'Esto reemplazará tu configuración actual. ¿Continuar?';
	@override String get importSettingsSuccess => 'Configuración importada';
	@override String get importSettingsInvalidFile => 'Este archivo no es una exportación válida de Plezy';
	@override String get importSettingsNoUser => 'Inicia sesión antes de importar la configuración';
	@override String get shortcutsReset => 'Atajos restablecidos a los valores predeterminados';
	@override String get about => 'Acerca de';
	@override String get aboutDescription => 'Información de la aplicación y licencias';
	@override String get updates => 'Actualizaciones';
	@override String get updateAvailable => 'Actualización disponible';
	@override String get checkForUpdates => 'Buscar actualizaciones';
	@override String get autoCheckUpdatesOnStartup => 'Buscar actualizaciones automáticamente al iniciar';
	@override String get autoCheckUpdatesOnStartupDescription => 'Avisar al iniciar si hay una actualización disponible';
	@override String get validationErrorEnterNumber => 'Introduce un número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La duración debe estar entre ${min} y ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'El atajo ya está asignado a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atajo actualizado para ${action}';
	@override String get saveFailed => 'No se pudieron guardar los cambios. Inténtalo de nuevo.';
	@override String get autoSkip => 'Salto automático';
	@override String get autoSkipIntro => 'Saltar introducción automáticamente';
	@override String get autoSkipIntroDescription => 'Saltar automáticamente los marcadores de introducción después de unos segundos';
	@override String get autoSkipCredits => 'Saltar créditos automáticamente';
	@override String get autoSkipCreditsDescription => 'Saltar automáticamente los créditos y reproducir el episodio siguiente';
	@override String get forceSkipMarkerFallback => 'Forzar marcadores alternativos';
	@override String get forceSkipMarkerFallbackDescription => 'Usar patrones de títulos de capítulos aunque Plex tenga marcadores';
	@override String get autoSkipDelay => 'Retraso del salto automático';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Esperar ${seconds} segundos antes de saltar automáticamente';
	@override String get introPattern => 'Patrón de marcador de introducción';
	@override String get introPatternDescription => 'Expresión regular para reconocer marcadores de introducción en los títulos de los capítulos';
	@override String get creditsPattern => 'Patrón de marcador de créditos';
	@override String get creditsPatternDescription => 'Expresión regular para reconocer marcadores de créditos en los títulos de los capítulos';
	@override String get invalidRegex => 'Expresión regular no válida';
	@override String get regex => 'Expresión regular';
	@override String get downloads => 'Descargas';
	@override String get downloadLocationDescription => 'Elegir dónde almacenar el contenido descargado';
	@override String get downloadLocationDefault => 'Predeterminado (almacenamiento de la aplicación)';
	@override String get downloadLocationCustom => 'Ubicación personalizada';
	@override String get selectFolder => 'Seleccionar carpeta';
	@override String get resetToDefault => 'Restablecer al predeterminado';
	@override String currentPath({required Object path}) => 'Actual: ${path}';
	@override String get downloadLocationChanged => 'Ubicación de descarga cambiada';
	@override String get downloadLocationReset => 'Ubicación de descarga restablecida al predeterminado';
	@override String get downloadLocationInvalid => 'La carpeta seleccionada no tiene permisos de escritura';
	@override String get downloadLocationPickerUnavailable => 'La selección de carpetas no está disponible en este dispositivo';
	@override String get downloadOnWifiOnly => 'Descargar solo con WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Evitar descargas cuando se usan datos móviles';
	@override String get autoRemoveWatchedDownloads => 'Eliminar descargas vistas automáticamente';
	@override String get autoRemoveWatchedDownloadsDescription => 'Eliminar automáticamente descargas vistas';
	@override String get cellularDownloadBlocked => 'Las descargas están bloqueadas en red móvil. Usa WiFi o cambia el ajuste.';
	@override String get maxVolume => 'Volumen máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Presencia de Discord';
	@override String get discordRichPresenceDescription => 'Mostrar lo que estás viendo en Discord';
	@override String get services => 'Servicios';
	@override String get servicesDescription => 'Conecta Trakt, MyAnimeList, Seerr y más';
	@override String get manageLibrariesDescription => 'Reordena y oculta bibliotecas';
	@override String get companionRemoteServer => 'Servidor de control remoto';
	@override String get companionRemoteServerDescription => 'Permitir que dispositivos móviles en tu red controlen esta aplicación';
	@override String get autoPip => 'Imagen en imagen automática';
	@override String get autoPipDescription => 'Activar automáticamente el modo de imagen en imagen al salir de la aplicación durante la reproducción';
	@override String get matchContentFrameRate => 'Ajustar frecuencia de actualización';
	@override String get matchContentFrameRateDescription => 'Ajustar la frecuencia de pantalla al contenido de video';
	@override String get matchRefreshRate => 'Ajustar frecuencia de refresco';
	@override String get matchRefreshRateDescription => 'Ajustar la frecuencia de pantalla en pantalla completa';
	@override String get matchDynamicRange => 'Ajustar rango dinámico';
	@override String get matchDynamicRangeDescription => 'Activar HDR para contenido HDR y luego volver a SDR';
	@override String get displaySwitchDelay => 'Retraso de cambio de pantalla';
	@override String get tunneledPlayback => 'Reproducción tunelizada';
	@override String get tunneledPlaybackDescription => 'Usar tunelización de video. Desactívala si HDR muestra video negro.';
	@override String get audioPassthrough => 'Transferencia directa de audio';
	@override String get audioPassthroughDescription => 'Envía el audio Dolby/DTS a tu receptor o TV sin recodificar, conservando el sonido envolvente. Desactívala si no tienes sonido.';
	@override String get audioPassthroughDescriptionAppleTv => 'Usa el decodificador Dolby nativo de Apple para Dolby Digital Plus, incluido Atmos. DTS y TrueHD se siguen reproduciendo como PCM multicanal. Desactívalo si no tienes sonido.';
	@override String get audioDownmix => 'Mezclar a estéreo';
	@override String get audioDownmixDescription => 'Mezcla el sonido envolvente a dos canales para altavoces estéreo o auriculares';
	@override String get downmixCenterBoost => 'Realce del canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Realce (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizar volumen al mezclar';
	@override String get audioDownmixNormalizeDescription => 'Reduce la mezcla para evitar saturación. Desactívalo para mantener el volumen original (puede distorsionar escenas fuertes).';
	@override String get atmosDiagnostics => 'Prueba de salida Atmos';
	@override String get atmosDiagnosticsDescription => 'Diagnostica la salida Dolby Atmos reproduciendo señales de prueba con el reproductor del sistema';
	@override String get atmosTestHlsAtmos => 'Flujo Atmos de Apple';
	@override String get atmosTestHlsAtmosDescription => 'Flujo Dolby Atmos de referencia. El receptor debería mostrar Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Flujo envolvente de Apple';
	@override String get atmosTestHlsControlDescription => 'Flujo de control sin Atmos. El receptor debería indicar sonido envolvente sin Atmos.';
	@override String get atmosTestRawStream => 'Flujo EAC3 sin procesar';
	@override String get atmosTestRawStreamDescription => 'Transmite el archivo de prueba igual que durante la reproducción de Atmos. Requiere la URL del archivo de prueba.';
	@override String get atmosTestRawFile => 'Archivo EAC3 sin procesar';
	@override String get atmosTestRawFileDescription => 'Reproduce el archivo de prueba con longitud conocida. Necesita la URL del archivo de prueba.';
	@override String get atmosTestAsbarNative => 'Renderizador de búfer de muestras (nativo)';
	@override String get atmosTestAsbarNativeDescription => 'Envía el audio comprimido intacto del archivo directamente al renderizador del sistema. Necesita la URL del archivo de prueba.';
	@override String get atmosTestAsbarGenerated => 'Renderizador de búfer de muestras (reconstruido)';
	@override String get atmosTestAsbarGeneratedDescription => 'Igual, pero con la descripción de audio construida como en la reproducción. Necesita la URL del archivo de prueba.';
	@override String get atmosTestSessionMode => 'Usar modo de reproducción de películas';
	@override String get atmosTestSessionModeDescription => 'Desactivado usa el modo que documenta Dolby. Activado usa el modo anterior.';
	@override String get atmosTestShowRoutePicker => 'Elegir salida AirPlay';
	@override String get atmosTestHideRoutePicker => 'Ocultar selector de salida AirPlay';
	@override String get atmosTestRoutePickerDescription => 'Envía la prueba a un receptor AirPlay. Solo AirPlay informa del modo de audio resuelto.';
	@override String get atmosTestStop => 'Detener prueba';
	@override String get atmosTestUrl => 'URL del archivo de prueba';
	@override String get atmosTestUrlDescription => 'URL HTTP de un archivo .ec3 Dolby Atmos sin procesar (p. ej., extraído con ffmpeg)';
	@override String get atmosTestUrlMissing => 'Configura primero la URL del archivo de prueba';
	@override String get atmosTestStatus => 'Estado';
	@override String get dvConversionMode => 'Conversión de Dolby Vision';
	@override String get dvConversionModeDescription => 'Elige cómo gestiona ExoPlayer los archivos Dolby Vision de perfil 7.';
	@override String get dvConversionAuto => 'Automático';
	@override String get dvConversionNative => 'Nativo / desactivado';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Usar la detección de capacidades del dispositivo y el comportamiento alternativo normal';
	@override String get dvConversionNativeDescription => 'Forzar DV7 nativo y suprimir el reintento de conversión DV';
	@override String get dvConversionDv81Description => 'Forzar la conversión de RPU en línea al perfil 8.1 de Dolby Vision';
	@override String get dvConversionHevcStripDescription => 'Eliminar las capas RPU/EL de Dolby Vision y presentar HEVC convencional';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil al abrir la aplicación';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar selección de perfil cada vez que se abre la aplicación';
	@override String get forceTvMode => 'Forzar modo TV';
	@override String get forceTvModeDescription => 'Forzar diseño TV. Para dispositivos que no lo detectan. Requiere reinicio.';
	@override String get startInFullscreen => 'Iniciar en pantalla completa';
	@override String get startInFullscreenDescription => 'Abrir Plezy en modo pantalla completa al iniciar';
	@override String get exitFullscreenOnPlayerClose => 'Salir de pantalla completa al cerrar el reproductor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Salir automáticamente del modo de pantalla completa al cerrar el reproductor de video';
	@override String get autoHidePerformanceOverlay => 'Ocultar superposición de rendimiento automáticamente';
	@override String get autoHidePerformanceOverlayDescription => 'Desvanecer la superposición de rendimiento con los controles de reproducción';
	@override String get showNavBarLabels => 'Mostrar etiquetas de la barra de navegación';
	@override String get showNavBarLabelsDescription => 'Mostrar etiquetas de texto bajo los iconos de la barra de navegación';
	@override String get startupSection => 'Sección de inicio';
	@override String get liveTvDefaultFavorites => 'Canales favoritos por defecto';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar solo canales favoritos al abrir TV en vivo';
	@override String get display => 'Pantalla';
	@override String get homeScreen => 'Pantalla de inicio';
	@override String get navigation => 'Navegación';
	@override String get window => 'Ventana';
	@override String get content => 'Contenido';
	@override String get player => 'Reproductor';
	@override String get subtitlesAndConfig => 'Subtítulos y configuración';
	@override String get seekAndTiming => 'Desplazamiento y tiempos';
	@override String get behavior => 'Comportamiento';
}

// Path: search
class _Translations$search$es extends Translations$search$en {
	_Translations$search$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar películas, series, música...';
	@override String get tryDifferentTerm => 'Prueba con un término de búsqueda diferente';
	@override String get searchYourMedia => 'Busca en tu contenido';
	@override String get enterTitleActorOrKeyword => 'Introduce un título, actor o palabra clave';
}

// Path: hotkeys
class _Translations$hotkeys$es extends Translations$hotkeys$en {
	_Translations$hotkeys$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Establecer atajo para ${actionName}';
	@override String get clearShortcut => 'Borrar atajo';
	@override String get noShortcutSet => 'Sin atajo asignado';
	@override String get currentShortcut => 'Atajo actual:';
	@override String get pressToRecord => 'Seleccionar para grabar un atajo';
	@override String get recordingShortcut => 'Pulsa el atajo ahora';
	@override late final _Translations$hotkeys$actions$es actions = _Translations$hotkeys$actions$es._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$es extends Translations$fileInfo$en {
	_Translations$fileInfo$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Información del archivo';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Subtítulos';
	@override String get file => 'Archivo';
	@override String get codec => 'Códec';
	@override String get resolution => 'Resolución';
	@override String get bitrate => 'Tasa de bits';
	@override String get frameRate => 'Frecuencia de fotogramas';
	@override String get aspectRatio => 'Relación de aspecto';
	@override String get profile => 'Perfil';
	@override String get bitDepth => 'Profundidad de bits';
	@override String get colorSpace => 'Espacio de color';
	@override String get colorRange => 'Rango de color';
	@override String get colorPrimaries => 'Primarias de color';
	@override String get chromaSubsampling => 'Submuestreo de croma';
	@override String get channels => 'Canales';
	@override String get overallBitrate => 'Tasa de bits total';
	@override String get path => 'Ruta';
	@override String get size => 'Tamaño';
	@override String get container => 'Contenedor';
	@override String get duration => 'Duración';
	@override String get optimizedForStreaming => 'Optimizado para transmisión';
	@override String get has64bitOffsets => 'Desplazamientos de 64 bits';
}

// Path: mediaMenu
class _Translations$mediaMenu$es extends Translations$mediaMenu$en {
	_Translations$mediaMenu$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como no visto';
	@override String get removeFromContinueWatching => 'Eliminar de Seguir viendo';
	@override String get viewDetails => 'Ver detalles';
	@override String get goToSeries => 'Ir a la serie';
	@override String get shufflePlay => 'Reproducción aleatoria';
	@override String get shuffleNotAvailableOffline => 'La reproducción aleatoria no está disponible sin conexión';
	@override String get fileInfo => 'Información del archivo';
	@override String get deleteFromServer => 'Eliminar del servidor';
	@override String get confirmDelete => '¿Eliminar este medio y sus archivos de tu servidor?';
	@override String get deleteMultipleWarning => 'Esto incluye todos los episodios y sus archivos.';
	@override String get mediaDeletedSuccessfully => 'Elemento multimedia eliminado con éxito';
	@override String get mediaFailedToDelete => 'Error al eliminar el elemento multimedia';
	@override String get rate => 'Calificar';
	@override String get playFromBeginning => 'Reproducir desde el inicio';
	@override String get playVersion => 'Reproducir versión...';
}

// Path: rateSheet
class _Translations$rateSheet$es extends Translations$rateSheet$en {
	_Translations$rateSheet$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Calificar';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
	@override String get favorited => 'Marcado como favorito';
	@override String get saved => 'Guardado';
	@override String get notAvailable => 'No se encontró coincidencia';
	@override String get noConnectedServices => 'Conecta un servicio en Configuración para valorar el contenido en él.';
}

// Path: accessibility
class _Translations$accessibility$es extends Translations$accessibility$en {
	_Translations$accessibility$es._(TranslationsEs root) : this._root = root, super.internal(root);

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
	@override String get decrease => 'Disminuir';
	@override String get increase => 'Aumentar';
	@override String decreaseValue({required Object label}) => 'Disminuir ${label}';
	@override String increaseValue({required Object label}) => 'Aumentar ${label}';
	@override String get hue => 'Tono';
	@override String get saturation => 'Saturación';
	@override String get brightness => 'Brillo';
	@override String get hexColor => 'Color hexadecimal';
	@override String get expandText => 'Expandir texto';
	@override String get collapseText => 'Contraer texto';
	@override String get alphabetNavigation => 'Navegación alfabética';
	@override String get alphabetScrollHint => 'Desliza hacia arriba o abajo para avanzar por letra';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Fila ${row} de ${rowCount}, columna ${column} de ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Fila ${row} de ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$es extends Translations$tooltips$en {
	_Translations$tooltips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reproducción aleatoria';
	@override String get playTrailer => 'Reproducir tráiler';
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como no visto';
}

// Path: audioTracks
class _Translations$audioTracks$es extends Translations$audioTracks$en {
	_Translations$audioTracks$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Pista de audio ${n}';
}

// Path: videoControls
class _Translations$videoControls$es extends Translations$videoControls$en {
	_Translations$videoControls$es._(TranslationsEs root) : this._root = root, super.internal(root);

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
	@override String get letterbox => 'Con bandas negras';
	@override String get fillScreen => 'Llenar pantalla';
	@override String get stretch => 'Estirar';
	@override String get lockRotation => 'Bloquear rotación';
	@override String get unlockRotation => 'Desbloquear rotación';
	@override String get timerActive => 'Temporizador activo';
	@override String playbackWillPauseIn({required Object duration}) => 'La reproducción se pausará en ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fin del video actual';
	@override String get sleepTimerStopAtHeader => 'Detener en';
	@override String get sleepTimerDurationHeader => 'Temporizador';
	@override String get playbackWillPauseAtEnd => 'La reproducción se pausará al final de este video';
	@override String get stillWatching => '¿Sigues viendo?';
	@override String pausingIn({required Object seconds}) => 'Se pausará en ${seconds}s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Reproducir siguiente automáticamente';
	@override String get playNext => 'Reproducir siguiente';
	@override String get playButton => 'Reproducir';
	@override String get pauseButton => 'Pausar';
	@override String get showPlaybackControls => 'Mostrar controles de reproducción';
	@override String get hidePlaybackControls => 'Ocultar controles de reproducción';
	@override String seekBackwardButton({required Object seconds}) => 'Retroceder ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avanzar ${seconds} segundos';
	@override String get previousButton => 'Episodio anterior';
	@override String get nextButton => 'Episodio siguiente';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Capítulo siguiente';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Activar sonido';
	@override String get settingsButton => 'Ajustes de reproducción';
	@override String get tracksButton => 'Audio y subtítulos';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionQualityButton => 'Versión y calidad';
	@override String get versionColumnHeader => 'Versión';
	@override String get qualityColumnHeader => 'Calidad';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodificación no disponible — reproduciendo calidad original';
	@override String get subtitleUnavailableFallback => 'No se pudieron cargar los subtítulos seleccionados — continuando sin subtítulos';
	@override String get pipButton => 'Modo de imagen en imagen';
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
	@override String get pipActive => 'Reproduciendo en modo de imagen en imagen';
	@override String get pipFailed => 'No se pudo iniciar el modo de imagen en imagen';
	@override String get screenshotSaved => 'Captura de pantalla guardada';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override late final _Translations$videoControls$pipErrors$es pipErrors = _Translations$videoControls$pipErrors$es._(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'No hay capítulos disponibles';
	@override String get queue => 'Cola';
	@override String get noQueueItems => 'No hay elementos en la cola';
	@override String get searchSubtitles => 'Buscar subtítulos';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'No se encontraron subtítulos';
	@override String get subtitleDownloaded => 'Subtítulo descargado';
	@override String get subtitleDownloadedNotApplied => 'El subtítulo se descargó, pero no se pudo seleccionar';
	@override String get subtitleDownloadFailed => 'Error al descargar subtítulo';
	@override String get searchLanguages => 'Buscar idiomas...';
}

// Path: messages
class _Translations$messages$es extends Translations$messages$en {
	_Translations$messages$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como visto';
	@override String get markedAsUnwatched => 'Marcado como no visto';
	@override String get markedAsWatchedOffline => 'Marcado como visto (se sincronizará al estar en línea)';
	@override String get markedAsUnwatchedOffline => 'Marcado como no visto (se sincronizará al estar en línea)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Eliminado automáticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Se eliminó automáticamente ${n} descarga vista',
		other: 'Se eliminaron automáticamente ${n} descargas vistas',
	);
	@override String get removedFromContinueWatching => 'Eliminado de Seguir Viendo';
	@override String errorLoading({required Object error}) => 'Error: ${error}';
	@override String get streamInterrupted => 'La reproducción se interrumpió. Pulsa reproducir o avanza para volver a intentarlo.';
	@override String get liveStreamInterrupted => 'La transmisión en vivo se interrumpió. Pulsa reproducir para volver a intentarlo.';
	@override String get fileInfoNotAvailable => 'Información de archivo no disponible';
	@override String get playbackAuthenticationRequired => 'Vuelve a iniciar sesión en el servidor multimedia para reproducir este elemento.';
	@override String get playbackServerUnavailable => 'El servidor multimedia no está disponible. Inténtalo de nuevo más tarde.';
	@override String get playbackDataInvalid => 'El servidor devolvió información de reproducción no válida.';
	@override String get playbackCancelled => 'Se canceló la reproducción.';
	@override String get playbackFailed => 'No se pudo iniciar la reproducción.';
	@override String errorLoadingFileInfo({required Object error}) => 'Error al cargar la información del archivo: ${error}';
	@override String get errorLoadingSeries => 'Error al cargar la serie';
	@override String get musicNotSupported => 'La reproducción de música aún no es compatible';
	@override String get noDescriptionAvailable => 'No hay descripción disponible';
	@override String get noProfilesAvailable => 'No hay perfiles disponibles';
	@override String get contactAdminForProfiles => 'Contacta a tu administrador del servidor para añadir perfiles';
	@override String get unableToDetermineLibrarySection => 'No se puede determinar la sección de biblioteca para este elemento';
	@override String get logsCleared => 'Registros borrados';
	@override String get logsCopied => 'Registros copiados al portapapeles';
	@override String get noLogsAvailable => 'No hay registros disponibles';
	@override String libraryScanning({required Object title}) => 'Escaneando "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Escaneo de biblioteca iniciado para "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Error al escanear biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Actualizando metadatos de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Actualización de metadatos iniciada para "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Error al actualizar metadatos: ${error}';
	@override String get logoutConfirm => '¿Estás seguro de que quieres cerrar sesión?';
	@override String get noSeasonsFound => 'No se encontraron temporadas';
	@override String get seasonsLoadFailed => 'No se pudieron cargar las temporadas';
	@override String get noEpisodesFound => 'No se encontraron episodios en la primera temporada';
	@override String get noEpisodesFoundGeneral => 'No se encontraron episodios';
	@override String get episodesLoadFailed => 'No se pudieron cargar los episodios';
	@override String get noResultsFound => 'No se encontraron resultados';
	@override String sleepTimerSet({required Object label}) => 'Temporizador establecido en ${label}';
	@override String get noItemsAvailable => 'No hay elementos disponibles';
	@override String get failedToCreatePlayQueueNoItems => 'No se pudo crear la cola de reproducción: no hay elementos';
	@override String failedPlayback({required Object action, required Object error}) => 'Error al ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Cambiando a reproductor compatible...';
	@override String get serverLimitTitle => 'Error de reproducción';
	@override String get serverLimitBody => 'Error del servidor (HTTP 500). Un límite de ancho de banda/transcodificación probablemente rechazó esta sesión. Pide al propietario que lo ajuste.';
	@override String get logsUploaded => 'Registros subidos';
	@override String get logsUploadFailed => 'Error al subir registros';
	@override String get logId => 'ID de registro';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$es extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
	@override String get border => 'Borde';
	@override String get background => 'Fondo';
	@override String get fontSize => 'Tamaño de fuente';
	@override String get textColor => 'Color del texto';
	@override String get borderSize => 'Tamaño del borde';
	@override String get borderColor => 'Color del borde';
	@override String get backgroundOpacity => 'Opacidad del fondo';
	@override String get backgroundColor => 'Color del fondo';
	@override String get position => 'Posición';
	@override String get assOverride => 'Sobreescritura ASS';
	@override String get overrideScale => 'Escala';
	@override String get overrideForce => 'Forzar';
	@override String get overrideStrip => 'Quitar estilos';
	@override String get positionTop => 'Arriba';
	@override String get positionBottom => 'Abajo';
	@override String get bold => 'Negrita';
	@override String get italic => 'Cursiva';
	@override String get renderResolution => 'Resolución de renderizado';
	@override String get renderResolutionScreen => 'Resolución de pantalla';
	@override String get renderResolutionVideo => 'Resolución del video';
}

// Path: mpvConfig
class _Translations$mpvConfig$es extends Translations$mpvConfig$en {
	_Translations$mpvConfig$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración de mpv';
	@override String get description => 'Ajustes avanzados del reproductor de video';
	@override String get presets => 'Preajustes';
	@override String get noPresets => 'No hay preajustes guardados';
	@override String get saveAsPreset => 'Guardar como preajuste...';
	@override String get presetName => 'Nombre del preajuste';
	@override String get presetNameHint => 'Introduce un nombre para este preajuste';
	@override String get loadPreset => 'Cargar';
	@override String get deletePreset => 'Eliminar';
	@override String get presetSaved => 'Preajuste guardado';
	@override String get presetLoaded => 'Preajuste cargado';
	@override String get presetDeleted => 'Preajuste eliminado';
	@override String get confirmDeletePreset => '¿Estás seguro de que quieres eliminar este preajuste?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _Translations$dialog$es extends Translations$dialog$en {
	_Translations$dialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar acción';
}

// Path: profiles
class _Translations$profiles$es extends Translations$profiles$en {
	_Translations$profiles$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Añadir perfil de Plezy';
	@override String get switchingProfile => 'Cambiando de perfil…';
	@override String get deleteThisProfileTitle => '¿Eliminar este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Eliminar ${displayName}. Las conexiones no se verán afectadas.';
	@override String get active => 'Activo';
	@override String get manage => 'Administrar';
	@override String get delete => 'Eliminar';
	@override String get signOut => 'Cerrar sesión';
	@override String get signOutPlexTitle => '¿Cerrar sesión de Plex?';
	@override String signOutPlexMessage({required Object displayName}) => '¿Eliminar ${displayName} y todos los usuarios de Plex Home? Puedes iniciar sesión de nuevo cuando quieras.';
	@override String get signedOutPlex => 'Sesión de Plex cerrada.';
	@override String get signOutFailed => 'Error al cerrar sesión.';
	@override String get sectionTitle => 'Perfiles';
	@override String get summarySingle => 'Añade perfiles para mezclar usuarios gestionados e identidades locales';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} perfiles · activo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} perfiles';
	@override String get removeConnectionTitle => '¿Eliminar conexión?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Eliminar el acceso de ${displayName} a ${connectionLabel}. Los demás perfiles lo conservan.';
	@override String get deleteProfileTitle => '¿Eliminar perfil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Eliminar ${displayName} y sus conexiones. Los servidores seguirán disponibles.';
	@override String get profileNameLabel => 'Nombre del perfil';
	@override String get pinProtectionLabel => 'Protección con PIN';
	@override String get pinManagedByPlex => 'PIN gestionado por Plex. Edita en plex.tv.';
	@override String get noPinSetEditOnPlex => 'Sin PIN establecido. Para requerir uno, edita el usuario Home en plex.tv.';
	@override String get setPin => 'Establecer PIN';
	@override String get setPinTitle => 'Establecer PIN';
	@override String get confirmPinTitle => 'Confirmar PIN';
	@override String get pinSet => 'PIN establecido';
	@override String get changePin => 'Cambiar';
	@override String get removePin => 'Eliminar';
	@override String get connectionsLabel => 'Conexiones';
	@override String get add => 'Añadir';
	@override String get deleteProfileButton => 'Eliminar perfil';
	@override String get noConnectionsHint => 'Sin conexiones — añade una para usar este perfil.';
	@override String get noConnections => 'Sin conexiones';
	@override String get plexHomeAccount => 'Cuenta Plex Home';
	@override String get connectionDefault => 'Predeterminada';
	@override String connectionAs({required Object displayName}) => 'como ${displayName}';
	@override String get makeDefault => 'Establecer como predeterminada';
	@override String get removeConnection => 'Eliminar';
	@override String get profileRenamed => 'Se cambió el nombre del perfil.';
	@override String borrowAddTo({required Object displayName}) => 'Añadir a ${displayName}';
	@override String get borrowExplain => 'Toma prestada la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.';
	@override String get borrowEmpty => 'Todavía no hay ninguna conexión que tomar prestada.';
	@override String get borrowEmptySubtitle => 'Conecta primero Plex o Jellyfin a otro perfil.';
	@override String get borrowLoadFailed => 'No se pudieron cargar las conexiones disponibles. Inténtalo de nuevo.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Conexión tomada prestada.';
	@override String get borrowFailed => 'No se pudo tomar prestada la conexión.';
	@override String get incorrectPin => 'PIN incorrecto.';
	@override String get incorrectPinTryAgain => 'PIN incorrecto. Inténtalo de nuevo.';
	@override String get sourceProfileMissingParentAccount => 'Al perfil de origen le falta su cuenta principal.';
	@override String get failedToLoadHomeUsers => 'No se pudieron cargar tus usuarios de Plex Home. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get failedToVerifyPin => 'No se pudo verificar el PIN.';
	@override String get newProfile => 'Nuevo perfil';
	@override String get profileNameHint => 'p. ej., Invitados, Niños, Sala familiar';
	@override String get pinProtectionOptional => 'Protección con PIN (opcional)';
	@override String get pinExplain => 'Se requiere PIN de 4 dígitos para cambiar de perfil.';
	@override String get continueButton => 'Continuar';
	@override String get pinsDontMatch => 'Los PIN no coinciden';
}

// Path: connections
class _Translations$connections$es extends Translations$connections$en {
	_Translations$connections$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Conexiones';
	@override String get addConnection => 'Añadir conexión';
	@override String get addConnectionSubtitleNoProfile => 'Inicia sesión con Plex o conecta un servidor de Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Añadir a ${displayName}: Plex, Jellyfin u otra conexión de perfil';
	@override String sessionExpiredOne({required Object name}) => 'Sesión caducada para ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sesión caducada para ${count} servidores';
	@override String get signInAgain => 'Iniciar sesión de nuevo';
	@override String get editJellyfinTitle => 'Editar conexión de Jellyfin';
	@override String editJellyfinIntro({required Object serverName}) => 'Añade o elimina direcciones URL para ${serverName}. Plezy usará la dirección accesible con menor latencia.';
}

// Path: discover
class _Translations$discover$es extends Translations$discover$en {
	_Translations$discover$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descubrir';
	@override String get noContentAvailable => 'No hay contenido disponible';
	@override String get addMediaToLibraries => 'Añade contenido a tus bibliotecas';
	@override String get continueWatching => 'Seguir viendo';
	@override String continueWatchingIn({required Object library}) => 'Seguir viendo en ${library}';
	@override String get nextUp => 'A continuación';
	@override String nextUpIn({required Object library}) => 'A continuación en ${library}';
	@override String get recentlyAdded => 'Añadido recientemente';
	@override String recentlyAddedIn({required Object library}) => 'Añadido recientemente en ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Últimos álbumes en ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Reproducido recientemente en ${library}';
	@override String mostPlayedIn({required Object library}) => 'Más reproducido en ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'T${season}E${episode}';
	@override String get overview => 'Resumen';
	@override String get cast => 'Reparto';
	@override String get extras => 'Tráilers y extras';
	@override String get studio => 'Estudio';
	@override String get rating => 'Valoración';
	@override String get director => 'Director';
	@override String get directors => 'Directores';
	@override String get movie => 'Película';
	@override String get tvShow => 'Serie de TV';
	@override String minutesLeft({required Object minutes}) => 'quedan ${minutes} min';
	@override String get moreLikeThis => 'Más contenido similar';
}

// Path: errors
class _Translations$errors$es extends Translations$errors$en {
	_Translations$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Error en la búsqueda: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tiempo de conexión agotado al cargar ${context}';
	@override String get connectionFailed => 'No se puede conectar al servidor multimedia';
	@override String unableToLoad({required Object context}) => 'No se pudo cargar ${context}. Inténtalo de nuevo.';
	@override String get noClientAvailable => 'No hay cliente disponible';
	@override String get pleaseEnterToken => 'Introduce un token';
	@override String get invalidToken => 'Token no válido';
	@override String failedToVerifyToken({required Object error}) => 'Error al verificar el token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Error al cambiar al perfil ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Error al eliminar ${displayName}';
	@override String get failedToRate => 'No se pudo actualizar la valoración';
}

// Path: libraries
class _Translations$libraries$es extends Translations$libraries$en {
	_Translations$libraries$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
	@override String get fallbackTitle => 'Biblioteca';
	@override String get scanLibraryFiles => 'Escanear archivos de la biblioteca';
	@override String get scanLibrary => 'Escanear biblioteca';
	@override String get analyze => 'Analizar';
	@override String get analyzeLibrary => 'Analizar biblioteca';
	@override String get refreshMetadata => 'Actualizar metadatos';
	@override String get emptyTrash => 'Vaciar papelera';
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
	@override String get noItemsMatchFilters => 'Ningún elemento coincide con los filtros activos';
	@override String get resetFilters => 'Restablecer filtros';
	@override String get all => 'Todos';
	@override String get clearAll => 'Borrar todo';
	@override String scanLibraryConfirm({required Object title}) => '¿Estás seguro de que quieres escanear "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => '¿Estás seguro de que quieres analizar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => '¿Estás seguro de que quieres actualizar los metadatos de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => '¿Estás seguro de que quieres vaciar la papelera de "${title}"?';
	@override String get manageLibraries => 'Gestionar bibliotecas';
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
	@override late final _Translations$libraries$tabs$es tabs = _Translations$libraries$tabs$es._(_root);
	@override late final _Translations$libraries$groupings$es groupings = _Translations$libraries$groupings$es._(_root);
	@override late final _Translations$libraries$filterCategories$es filterCategories = _Translations$libraries$filterCategories$es._(_root);
	@override late final _Translations$libraries$sortLabels$es sortLabels = _Translations$libraries$sortLabels$es._(_root);
}

// Path: about
class _Translations$about$es extends Translations$about$en {
	_Translations$about$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Acerca de';
	@override String get openSourceLicenses => 'Licencias de código abierto';
	@override String versionLabel({required Object version}) => 'Versión ${version}';
	@override String get appDescription => 'Un cliente de Plex y Jellyfin para Flutter';
	@override String get viewLicensesDescription => 'Ver las licencias de bibliotecas de terceros';
}

// Path: serverSelection
class _Translations$serverSelection$es extends Translations$serverSelection$en {
	_Translations$serverSelection$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'No se encontraron servidores para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Error al cargar servidores: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$es extends Translations$hubDetail$en {
	_Translations$hubDetail$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Año de lanzamiento';
	@override String get dateAdded => 'Añadido el';
	@override String get rating => 'Valoración';
	@override String get noItemsFound => 'No se encontraron elementos';
}

// Path: logs
class _Translations$logs$es extends Translations$logs$en {
	_Translations$logs$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Borrar registros';
	@override String get copyLogs => 'Copiar registros';
	@override String get uploadLogs => 'Subir registros';
}

// Path: licenses
class _Translations$licenses$es extends Translations$licenses$en {
	_Translations$licenses$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Paquetes relacionados';
	@override String get license => 'Licencia';
	@override String licenseNumber({required Object number}) => 'Licencia ${number}';
	@override String licensesCount({required Object count}) => '${count} licencias';
}

// Path: navigation
class _Translations$navigation$es extends Translations$navigation$en {
	_Translations$navigation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Descargas';
	@override String get liveTv => 'TV en vivo';
	@override String get explore => 'Explorar';
}

// Path: explore
class _Translations$explore$es extends Translations$explore$en {
	_Translations$explore$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explorar';
	@override String get selectSource => 'Seleccionar fuente';
	@override late final _Translations$explore$rows$es rows = _Translations$explore$rows$es._(_root);
	@override late final _Translations$explore$status$es status = _Translations$explore$status$es._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} episodio',
		other: '${n} episodios',
	);
	@override String get cast => 'Reparto';
	@override String get characters => 'Personajes';
	@override String get addToWatchlist => 'Añadir a la lista de seguimiento';
	@override String get removeFromWatchlist => 'Quitar de la lista de seguimiento';
	@override String get watchlistUpdateFailed => 'No se pudo actualizar la lista de seguimiento';
	@override String get notInLibrary => 'No está en tu biblioteca';
	@override String get inTheseLibraries => 'En estas bibliotecas';
	@override String get checkingLibrary => 'Comprobando tu biblioteca...';
	@override String get emptyTitle => 'Aquí no hay nada todavía';
	@override String emptyMessage({required Object source}) => 'Las filas de ${source} aparecerán aquí cuando tengan contenido.';
	@override String searchHint({required Object source}) => 'Buscar en ${source}';
	@override String searchEmpty({required Object query}) => 'Sin resultados para "${query}"';
	@override String searchPrompt({required Object source}) => 'Busca películas y series en ${source}.';
	@override String get searchFailed => 'La búsqueda falló. Comprueba tu conexión e inténtalo de nuevo.';
}

// Path: liveTv
class _Translations$liveTv$es extends Translations$liveTv$en {
	_Translations$liveTv$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV en vivo';
	@override String get guide => 'Guía';
	@override String get noChannels => 'No hay canales disponibles';
	@override String get noDvr => 'No hay DVR configurado en ningún servidor';
	@override String get serverUnavailable => 'El servidor de TV en vivo no está disponible.';
	@override String get serverNotConnected => 'El servidor de TV en vivo no está conectado.';
	@override String get noPrograms => 'No hay datos de programación disponibles';
	@override String get liveStreamFailed => 'Falló la transmisión en vivo';
	@override String get unknownProgram => 'Programa desconocido';
	@override String get unknownHub => 'Desconocido';
	@override String get unknownError => 'Error desconocido';
	@override String channelNumber({required Object number}) => 'Canal ${number}';
	@override String get unknownChannel => 'Canal desconocido';
	@override String get live => 'EN VIVO';
	@override String get reloadGuide => 'Recargar guía';
	@override String get now => 'Ahora';
	@override String get today => 'Hoy';
	@override String get tomorrow => 'Mañana';
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
	@override String get favoritesLoadFailed => 'No se pudieron cargar los favoritos. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get favoritesUpdateFailed => 'No se pudieron actualizar los favoritos. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get joinSession => 'Unirse a sesión en curso';
	@override String watchFromStart({required Object minutes}) => 'Ver desde el inicio (hace ${minutes} min)';
	@override String get watchLive => 'Ver en vivo';
	@override String get goToLive => 'Ir a la emisión en vivo';
	@override String get record => 'Grabar';
	@override String get recordEpisode => 'Grabar episodio';
	@override String get recordSeries => 'Grabar serie';
	@override String get recordOptions => 'Opciones de grabación';
	@override String get saveTo => 'Guardar en';
	@override String get recordings => 'Grabaciones';
	@override String get scheduledRecordings => 'Programadas';
	@override String get recordingRules => 'Reglas de grabación';
	@override String get noScheduledRecordings => 'No hay grabaciones programadas';
	@override String get manageRecording => 'Gestionar grabación';
	@override String get cancelRecording => 'Cancelar grabación';
	@override String get cancelRecordingTitle => '¿Cancelar esta grabación?';
	@override String cancelRecordingMessage({required Object title}) => '${title} ya no se grabará.';
	@override String get deleteRule => 'Eliminar regla';
	@override String get deleteRuleTitle => '¿Eliminar regla de grabación?';
	@override String deleteRuleMessage({required Object title}) => 'Los próximos episodios de ${title} no se grabarán.';
	@override String get recordingScheduled => 'Grabación programada';
	@override String get alreadyScheduled => 'Este programa ya está programado';
	@override String get dvrAdminRequired => 'La configuración DVR requiere una cuenta de administrador';
	@override String get recordingFailed => 'No se pudo programar la grabación';
	@override String get recordingTargetMissing => 'No se pudo determinar la biblioteca de grabación';
	@override String get recordNotAvailable => 'Grabación no disponible para este programa';
	@override String get recordingCancelled => 'Grabación cancelada';
	@override String get recordingRuleDeleted => 'Regla de grabación eliminada';
	@override String get processRecordingRules => 'Reevaluar reglas';
	@override String get recordingInProgress => 'Grabando ahora';
	@override String recordingsCount({required Object count}) => '${count} programadas';
	@override String get editRule => 'Editar regla';
	@override String get editRuleAction => 'Editar';
	@override String get recordingRuleUpdated => 'Regla de grabación actualizada';
	@override String get guideReloadRequested => 'Solicitada actualización de la guía';
	@override String get rulesProcessRequested => 'Solicitada reevaluación de reglas';
	@override String get recordShow => 'Grabar programa';
}

// Path: collections
class _Translations$collections$es extends Translations$collections$en {
	_Translations$collections$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colecciones';
	@override String get collection => 'Colección';
	@override String get empty => 'La colección está vacía';
	@override String get deleteCollection => 'Eliminar colección';
	@override String deleteConfirm({required Object title}) => '¿Eliminar "${title}"? No se puede deshacer.';
	@override String get deleted => 'Colección eliminada';
	@override String get deleteFailed => 'Error al eliminar la colección';
	@override String deleteFailedWithError({required Object error}) => 'Error al eliminar la colección: ${error}';
	@override String get selectCollection => 'Seleccionar colección';
	@override String get collectionName => 'Nombre de la colección';
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
class _Translations$playlists$es extends Translations$playlists$en {
	_Translations$playlists$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Listas de reproducción';
	@override String get playlist => 'Lista de reproducción';
	@override String get noPlaylists => 'No se encontraron listas de reproducción';
	@override String get create => 'Crear lista de reproducción';
	@override String get playlistName => 'Nombre de la lista de reproducción';
	@override String get enterPlaylistName => 'Introduce el nombre de la lista de reproducción';
	@override String get delete => 'Eliminar lista de reproducción';
	@override String get removeItem => 'Eliminar de la lista de reproducción';
	@override String get smartPlaylist => 'Lista de reproducción inteligente';
	@override String itemCount({required Object count}) => '${count} elementos';
	@override String get oneItem => '1 elemento';
	@override String get emptyPlaylist => 'Esta lista de reproducción está vacía';
	@override String get deleteConfirm => '¿Eliminar lista de reproducción?';
	@override String deleteMessage({required Object name}) => '¿Estás seguro de que quieres eliminar "${name}"?';
	@override String get created => 'Lista de reproducción creada';
	@override String get deleted => 'Lista de reproducción eliminada';
	@override String get itemAdded => 'Añadido a la lista de reproducción';
	@override String get itemRemoved => 'Eliminado de la lista de reproducción';
	@override String get selectPlaylist => 'Seleccionar lista de reproducción';
	@override String get searchPlaylists => 'Buscar listas de reproducción...';
	@override String get errorCreating => 'Error al crear la lista de reproducción';
	@override String get errorDeleting => 'Error al eliminar la lista de reproducción';
	@override String get errorLoading => 'Error al cargar las listas de reproducción';
	@override String get errorAdding => 'Error al añadir a la lista de reproducción';
	@override String get errorReordering => 'Error al reordenar el elemento de la lista de reproducción';
	@override String get errorRemoving => 'Error al eliminar de la lista de reproducción';
}

// Path: music
class _Translations$music$es extends Translations$music$en {
	_Translations$music$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ir al álbum';
	@override String get goToArtist => 'Ir al artista';
	@override String get instantMix => 'Mezcla instantánea';
	@override String get playNext => 'Reproducir a continuación';
	@override String get addToQueue => 'Añadir a la cola';
	@override String discNumber({required Object n}) => 'Disco ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} canción',
		other: '${n} canciones',
	);
	@override String get nowPlaying => 'Reproduciendo ahora';
	@override String playingFrom({required Object title}) => 'Reproduciendo desde ${title}';
	@override String get queue => 'Cola';
	@override String get clearQueue => 'Vaciar la cola';
	@override String get lyrics => 'Letra';
	@override String get noLyrics => 'No hay letra disponible';
	@override String get sleepTimer => 'Temporizador de apagado';
	@override String get sleepTimerEndOfTrack => 'Fin de la canción';
	@override String sleepTimerMinutes({required Object n}) => '${n} minutos';
	@override String get stopPlayback => 'Detener reproducción';
	@override String get previousTrack => 'Canción anterior';
	@override String get nextTrack => 'Canción siguiente';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir todo';
	@override String get repeatOne => 'Repetir una';
}

// Path: watchTogether
class _Translations$watchTogether$es extends Translations$watchTogether$en {
	_Translations$watchTogether$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ver juntos';
	@override String get description => 'Mira contenido sincronizado con amigos y familiares';
	@override String get createSession => 'Crear sesión';
	@override String get creating => 'Creando...';
	@override String get joinSession => 'Unirse a una sesión';
	@override String get joining => 'Conectando...';
	@override String get controlMode => 'Modo de control';
	@override String get controlModeQuestion => '¿Quién puede controlar la reproducción?';
	@override String get hostOnly => 'Solo el anfitrión';
	@override String get anyone => 'Cualquiera';
	@override String get hostingSession => 'Sesión alojada';
	@override String get inSession => 'En una sesión';
	@override String get sessionCode => 'Código de sesión';
	@override String get openSessionControls => 'Abrir los controles de la sesión de Ver juntos';
	@override String get copySessionCode => 'Copiar código de sesión';
	@override String get hostControlsPlayback => 'El anfitrión controla la reproducción';
	@override String get anyoneCanControl => 'Cualquiera puede controlar la reproducción';
	@override String get hostControls => 'Control del anfitrión';
	@override String get anyoneControls => 'Control de cualquiera';
	@override String get participants => 'Participantes';
	@override String get host => 'Anfitrión';
	@override String get hostBadge => 'ANFITRIÓN';
	@override String get youAreHost => 'Eres el anfitrión';
	@override String get watchingWithOthers => 'Viendo contenido con otras personas';
	@override String get endSession => 'Finalizar sesión';
	@override String get leaveSession => 'Salir de la sesión';
	@override String get endSessionQuestion => '¿Finalizar la sesión?';
	@override String get leaveSessionQuestion => '¿Salir de la sesión?';
	@override String get endSessionConfirm => 'Esto finalizará la sesión para todos los participantes.';
	@override String get leaveSessionConfirm => 'Saldrás de la sesión.';
	@override String get endSessionConfirmOverlay => 'Esto finalizará la sesión de reproducción para todos los participantes.';
	@override String get leaveSessionConfirmOverlay => 'Te desconectarás de la sesión de reproducción.';
	@override String get end => 'Finalizar';
	@override String get leave => 'Salir';
	@override String get syncing => 'Sincronizando...';
	@override String get joinWatchSession => 'Unirse a una sesión de reproducción';
	@override String get enterCodeHint => 'Introduce el código de 5 caracteres';
	@override String get pasteFromClipboard => 'Pegar desde el portapapeles';
	@override String get pleaseEnterCode => 'Introduce un código de sesión';
	@override String get codeMustBe5Chars => 'El código de sesión debe tener 5 caracteres';
	@override String get joinInstructions => 'Introduce el código de sesión del anfitrión para unirte.';
	@override String get failedToCreate => 'Error al crear la sesión';
	@override String get failedToJoin => 'Error al unirse a la sesión';
	@override String get sessionCodeCopied => 'Código de sesión copiado al portapapeles';
	@override String get relayUnreachable => 'No se puede acceder al servidor de retransmisión. Es posible que tu proveedor de internet esté bloqueando Ver juntos.';
	@override String get reconnectingToHost => 'Reconectando con el anfitrión...';
	@override String get currentPlayback => 'Reproducción actual';
	@override String get joinCurrentPlayback => 'Unirse a la reproducción actual';
	@override String get joinCurrentPlaybackDescription => 'Vuelve a lo que el anfitrión está viendo ahora mismo';
	@override String get failedToOpenCurrentPlayback => 'No se pudo abrir la reproducción actual';
	@override String participantJoined({required Object name}) => '${name} se unió';
	@override String participantLeft({required Object name}) => '${name} se fue';
	@override String participantPaused({required Object name}) => '${name} pausó';
	@override String participantResumed({required Object name}) => '${name} reanudó';
	@override String participantSeeked({required Object name}) => '${name} cambió la posición de reproducción';
	@override String participantBuffering({required Object name}) => '${name} está almacenando en búfer';
	@override String participantNeedsUpdate({required Object name}) => '${name} usa una versión anterior de la aplicación — sincronización no disponible';
	@override String resumingWithout({required Object name}) => 'Reanudando sin ${name}';
	@override String get waitingForParticipants => 'Esperando a que los demás carguen el contenido...';
	@override String waitingForName({required Object name}) => 'Esperando a ${name}...';
	@override String get recentRooms => 'Salas recientes';
	@override String get renameRoom => 'Renombrar sala';
	@override String get removeRoom => 'Eliminar';
	@override String get guestSwitchUnavailable => 'No se pudo cambiar — servidor no disponible para sincronización';
	@override String get guestSwitchFailed => 'No se pudo cambiar — contenido no encontrado en este servidor';
}

// Path: downloads
class _Translations$downloads$es extends Translations$downloads$en {
	_Translations$downloads$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descargas';
	@override String get manage => 'Gestionar';
	@override String get tvShows => 'Series de TV';
	@override String get movies => 'Películas';
	@override String get music => 'Música';
	@override String tracksQueued({required Object count}) => '${count} canciones en cola para descargar';
	@override String get noDownloads => 'No hay descargas aún';
	@override String get noDownloadsDescription => 'El contenido descargado aparecerá aquí para verlo sin conexión';
	@override String get downloadNow => 'Descargar';
	@override String get deleteDownload => 'Eliminar descarga';
	@override String get retryDownload => 'Reintentar descarga';
	@override String get downloadQueued => 'Descarga en cola';
	@override String get downloadResumed => 'Descarga reanudada';
	@override String get serverErrorBitrate => 'Error del servidor: el archivo puede superar el límite remoto de tasa de bits';
	@override String get storageFull => 'Las descargas se detuvieron porque el almacenamiento del dispositivo está lleno. Libera espacio e inténtalo de nuevo.';
	@override String episodesQueued({required Object count}) => '${count} episodios en cola para descargar';
	@override String get downloadDeleted => 'Descarga eliminada';
	@override String deleteConfirm({required Object title}) => '¿Eliminar "${title}" de este dispositivo?';
	@override String get cancelledDownloadTitle => 'Descarga cancelada';
	@override String get cancelledDownloadMessage => 'Esta descarga se canceló. ¿Qué quieres hacer?';
	@override String get allEpisodesAlreadyDownloaded => 'Todos los episodios ya están descargados';
	@override String get resumeDownload => 'Reanudar descarga';
	@override String get cancelledDownload => 'Descarga cancelada';
	@override String syncingFile({required Object file, required Object status}) => '${file} (sincronizando ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} descargado — haz clic para completar';
	@override String get partialDownloadClickToComplete => 'Descarga parcial — haz clic para completar';
	@override String get deleting => 'Eliminando...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})';
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
	@override String get includeSpecials => 'Incluir especiales';
	@override String get howManyEpisodes => '¿Cuántos episodios?';
	@override String get invalidEpisodeCount => 'Introduce un número de episodios válido.';
	@override String get keepSynced => 'Mantener sincronizado';
	@override String get downloadOnce => 'Descargar una vez';
	@override String keepNUnwatched({required Object count}) => 'Mantener ${count} no vistos';
	@override String get editSyncRule => 'Editar regla de sincronización';
	@override String get removeSyncRule => 'Eliminar regla de sincronización';
	@override String removeSyncRuleConfirm({required Object title}) => '¿Dejar de sincronizar "${title}"? Los episodios descargados se conservarán.';
	@override String syncRuleCreated({required Object count}) => 'Regla de sincronización creada — se conservarán ${count} episodios no vistos';
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
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Servidor: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponible';
	@override String get syncRuleOffline => 'Sin conexión';
	@override String get syncRuleSignInRequired => 'Se requiere iniciar sesión';
	@override String get syncRuleNotAvailableForProfile => 'No disponible para el perfil actual';
	@override String get syncRuleUnknownServer => 'Servidor desconocido';
	@override String get syncRuleListCreated => 'Regla de sincronización creada';
	@override late final _Translations$downloads$backgroundWarning$es backgroundWarning = _Translations$downloads$backgroundWarning$es._(_root);
}

// Path: shaders
class _Translations$shaders$es extends Translations$shaders$en {
	_Translations$shaders$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sin mejora de video';
	@override String get nvscalerDescription => 'Escalado de imagen NVIDIA para un video más nítido';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Reducción de ruido';
	@override String get artcnnVariantDenoiseSharpen => 'Reducción de ruido + enfoque';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta calidad';
	@override String get mode => 'Modo';
	@override String get importShader => 'Importar shader';
	@override String get customShaderDescription => 'Shader GLSL personalizado';
	@override String get shaderImported => 'Shader importado';
	@override String get shaderImportFailed => 'Error al importar shader';
	@override String get deleteShader => 'Eliminar shader';
	@override String deleteShaderConfirm({required Object name}) => '¿Eliminar "${name}"?';
}

// Path: companionRemote
class _Translations$companionRemote$es extends Translations$companionRemote$en {
	_Translations$companionRemote$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Control remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override String get unknownDevice => 'Dispositivo desconocido';
	@override late final _Translations$companionRemote$session$es session = _Translations$companionRemote$session$es._(_root);
	@override late final _Translations$companionRemote$pairing$es pairing = _Translations$companionRemote$pairing$es._(_root);
	@override late final _Translations$companionRemote$remote$es remote = _Translations$companionRemote$remote$es._(_root);
	@override late final _Translations$companionRemote$errors$es errors = _Translations$companionRemote$errors$es._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$es extends Translations$videoSettings$en {
	_Translations$videoSettings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidad de reproducción';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Activo (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Temporizador de apagado';
	@override String get audioSync => 'Sincronización de audio';
	@override String get subtitleSync => 'Sincronización de subtítulos';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Salida de audio';
	@override String get performanceOverlay => 'Indicador de rendimiento';
	@override String get audioPassthrough => 'Transferencia directa de audio';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Envolvente';
	@override String get audioOutputSpatial => 'Audio espacial';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioNormalization => 'Normalizar volumen';
	@override String get audioDownmix => 'Mezclar a estéreo';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$es extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get color => 'Color';
	@override String get performance => 'Rendimiento';
	@override String get buffer => 'Búfer';
	@override String get app => 'App';
	@override String get decoder => 'Decodificador';
	@override String get rawDecoder => 'Decodificador sin procesar';
	@override String get tunneling => 'Túnel';
	@override String get aspect => 'Aspecto';
	@override String get rotation => 'Rotación';
	@override String get dvSource => 'Origen DV';
	@override String get dvPath => 'Ruta DV';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Frecuencia de muestreo';
	@override String get pixelFormat => 'Formato de píxel';
	@override String get hwFormat => 'Formato HW';
	@override String get matrix => 'Matriz';
	@override String get primaries => 'Primarios';
	@override String get transfer => 'Transferencia';
	@override String get renderFps => 'FPS render';
	@override String get displayFps => 'FPS pantalla';
	@override String get avSync => 'Sincronía A/V';
	@override String get dropped => 'Descartados';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'Prom. DV RPU';
	@override String get dvSampleAverage => 'Prom. muestra DV';
	@override String get maxLuma => 'Luma máx.';
	@override String get minLuma => 'Luma mín.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Caché usada';
	@override String get cacheLimit => 'Límite de caché';
	@override String get speed => 'Velocidad';
	@override String get player => 'Reproductor';
	@override String get memory => 'Memoria';
	@override String get uiFps => 'FPS UI';
}

// Path: externalPlayer
class _Translations$externalPlayer$es extends Translations$externalPlayer$en {
	_Translations$externalPlayer$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reproductor externo';
	@override String get useExternalPlayer => 'Usar reproductor externo';
	@override String get useExternalPlayerDescription => 'Abrir videos en otra aplicación';
	@override String get selectPlayer => 'Seleccionar reproductor';
	@override String get customPlayers => 'Reproductores personalizados';
	@override String get systemDefault => 'Predeterminado del sistema';
	@override String get addCustomPlayer => 'Añadir reproductor personalizado';
	@override String get playerName => 'Nombre del reproductor';
	@override String get playerNameHint => 'Mi reproductor';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nombre del paquete';
	@override String get playerUrlScheme => 'Esquema URL';
	@override String get off => 'Desactivado';
	@override String get launchFailed => 'No se pudo abrir el reproductor externo';
	@override String appNotInstalled({required Object name}) => '${name} no está instalado';
	@override String get playInExternalPlayer => 'Reproducir en reproductor externo';
}

// Path: metadataEdit
class _Translations$metadataEdit$es extends Translations$metadataEdit$en {
	_Translations$metadataEdit$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar...';
	@override String get screenTitle => 'Editar metadatos';
	@override String get basicInfo => 'Información básica';
	@override String get artwork => 'Imágenes';
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
	@override String get artworkUpdated => 'Imágenes actualizadas';
	@override String get artworkUpdateFailed => 'Error al actualizar las imágenes';
	@override String get noArtworkAvailable => 'No hay imágenes disponibles';
	@override String artworkOption({required Object index}) => 'Opción de imagen ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opción de imagen ${index}, seleccionada';
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
class _Translations$matchScreen$es extends Translations$matchScreen$en {
	_Translations$matchScreen$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get match => 'Asociar...';
	@override String get fixMatch => 'Corregir asociación...';
	@override String get unmatch => 'Desasociar';
	@override String get unmatchConfirm => '¿Borrar esta asociación? Plex tratará el elemento como no asociado hasta que vuelvas a asociarlo.';
	@override String get unmatchSuccess => 'Elemento desasociado';
	@override String get unmatchFailed => 'No se pudo desasociar el elemento';
	@override String get matchApplied => 'Asociación aplicada';
	@override String get matchFailed => 'No se pudo aplicar la asociación';
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Año';
	@override String get search => 'Buscar';
	@override String get noMatchesFound => 'No se encontraron coincidencias';
}

// Path: serverTasks
class _Translations$serverTasks$es extends Translations$serverTasks$en {
	_Translations$serverTasks$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tareas del servidor';
	@override String get failedToLoad => 'Error al cargar tareas';
	@override String get noTasks => 'No hay tareas en ejecución';
}

// Path: trakt
class _Translations$trakt$es extends Translations$trakt$en {
	_Translations$trakt$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => '¿Desconectar cuenta de Trakt?';
	@override String get disconnectConfirmBody => 'Plezy dejará de enviar eventos a Trakt. Puedes reconectar cuando quieras.';
	@override String get scrobble => 'Scrobbling en tiempo real';
	@override String get scrobbleDescription => 'Enviar eventos de reproducción, pausa y parada a Trakt durante la reproducción.';
	@override String get watchedSync => 'Sincronizar el estado de visualización';
	@override String get watchedSyncDescription => 'Cuando marques contenido como visto en Plezy, también se marcará como visto en Trakt.';
}

// Path: seerr
class _Translations$seerr$es extends Translations$seerr$en {
	_Translations$seerr$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Conectar Seerr';
	@override String get serverUrl => 'URL del servidor';
	@override String get serverUrlHelper => 'La dirección de tu instancia de Seerr';
	@override String get checkServer => 'Continuar';
	@override String get signInWithJellyfin => 'Iniciar sesión con Jellyfin';
	@override String get signInWithEmby => 'Iniciar sesión con Emby';
	@override String get signInWithLocal => 'Usar una cuenta local';
	@override String get email => 'Correo electrónico';
	@override String get noSignInMethods => 'Esta instancia de Seerr no ofrece ningún método de inicio de sesión compatible con Plezy.';
	@override String get instance => 'Instancia';
	@override String get disconnectConfirm => '¿Desconectar Seerr?';
	@override String get disconnectConfirmBody => 'Plezy olvidará esta instancia de Seerr. Reconecta cuando quieras.';
	@override String get request => 'Solicitar';
	@override String get request4k => 'Solicitar en 4K';
	@override String get seasons => 'Temporadas';
	@override String get allSeasons => 'Todas las temporadas';
	@override String get advancedOptions => 'Avanzado';
	@override String get destinationServer => 'Servidor de destino';
	@override String get qualityProfile => 'Perfil de calidad';
	@override String get rootFolder => 'Carpeta raíz';
	@override String get languageProfile => 'Perfil de idioma';
	@override String get requestSubmitted => 'Solicitud enviada';
	@override String requestFailed({required Object error}) => 'La solicitud falló: ${error}';
	@override String get requestsLoadFailed => 'No se pudieron cargar las opciones de solicitud';
	@override String get nothingToRequest => 'Todo ya está disponible o solicitado.';
	@override String get statusAvailable => 'Disponible';
	@override String get statusPartiallyAvailable => 'Parcialmente disponible';
	@override String get statusRequested => 'Solicitado';
	@override String get statusProcessing => 'Procesando';
}

// Path: services
class _Translations$services$es extends Translations$services$en {
	_Translations$services$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Servicios';
	@override String get hubSubtitle => 'Sincroniza tu progreso de visualización y solicita nuevos títulos.';
	@override String get notConnected => 'No conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Registrar progreso automáticamente';
	@override String get scrobbleDescription => 'Actualiza tu lista cuando termines un episodio o película.';
	@override String disconnectConfirm({required Object service}) => '¿Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy dejará de actualizar ${service}. Reconecta cuando quieras.';
	@override String connectFailed({required Object service}) => 'No se pudo conectar a ${service}. Inténtalo de nuevo.';
	@override late final _Translations$services$names$es names = _Translations$services$names$es._(_root);
	@override late final _Translations$services$deviceCode$es deviceCode = _Translations$services$deviceCode$es._(_root);
	@override late final _Translations$services$oauthProxy$es oauthProxy = _Translations$services$oauthProxy$es._(_root);
	@override late final _Translations$services$libraryFilter$es libraryFilter = _Translations$services$libraryFilter$es._(_root);
}

// Path: addServer
class _Translations$addServer$es extends Translations$addServer$en {
	_Translations$addServer$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Añadir servidor Jellyfin';
	@override String get serverUrls => 'Direcciones URL del servidor';
	@override String get serverUrlsHelper => 'Se permiten varias URL, separadas por comas.';
	@override String get findServer => 'Buscar servidor';
	@override String get searchingLocalServers => 'Buscando servidores Jellyfin locales...';
	@override String get localServers => 'Servidores Jellyfin locales';
	@override String get username => 'Usuario';
	@override String get password => 'Contraseña';
	@override String get signIn => 'Iniciar sesión';
	@override String get change => 'Cambiar';
	@override String get required => 'Obligatorio';
	@override String couldNotReachServer({required Object error}) => 'No se pudo conectar con el servidor: ${error}';
	@override String signInFailed({required Object error}) => 'Error al iniciar sesión: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect ha fallado: ${error}';
	@override String get addPlexTitle => 'Iniciar sesión con Plex';
	@override String get pinExpired => 'El PIN caducó antes de iniciar sesión. Inténtalo de nuevo.';
	@override String failedToRegisterAccount({required Object error}) => 'No se pudo registrar la cuenta: ${error}';
	@override String get enterJellyfinUrlError => 'Introduce la URL de tu servidor Jellyfin';
	@override String get addConnectionTitle => 'Añadir conexión';
	@override String addConnectionTitleScoped({required Object name}) => 'Añadir a ${name}';
	@override String get signInWithPlexCard => 'Iniciar sesión con Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoriza este dispositivo. Se añaden servidores compartidos.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoriza una cuenta Plex. Los usuarios de Home se convierten en perfiles.';
	@override String get connectToJellyfinCard => 'Conectar a Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Introduce la URL del servidor, usuario y contraseña.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Inicia sesión en un servidor Jellyfin. Se vincula a ${name}.';
	@override String get borrowFromAnotherProfile => 'Tomar prestado de otro perfil';
	@override String get borrowFromAnotherProfileSubtitle => 'Reutiliza la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$es extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Reproducir/pausar';
	@override String get volumeUp => 'Subir volumen';
	@override String get volumeDown => 'Bajar volumen';
	@override String seekForward({required Object seconds}) => 'Avanzar (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Retroceder (${seconds}s)';
	@override String get fullscreenToggle => 'Alternar pantalla completa';
	@override String get muteToggle => 'Activar/desactivar silencio';
	@override String get subtitleToggle => 'Activar/desactivar subtítulos';
	@override String get audioTrackNext => 'Pista de audio siguiente';
	@override String get subtitleTrackNext => 'Pista de subtítulos siguiente';
	@override String get chapterNext => 'Capítulo siguiente';
	@override String get chapterPrevious => 'Capítulo anterior';
	@override String get episodeNext => 'Episodio siguiente';
	@override String get episodePrevious => 'Episodio anterior';
	@override String get speedIncrease => 'Aumentar velocidad';
	@override String get speedDecrease => 'Disminuir velocidad';
	@override String get speedReset => 'Restablecer velocidad';
	@override String get zoomIn => 'Acercar';
	@override String get zoomOut => 'Alejar';
	@override String get zoomReset => 'Restablecer zoom';
	@override String get subSeekNext => 'Ir al subtítulo siguiente';
	@override String get subSeekPrev => 'Ir al subtítulo anterior';
	@override String get shaderToggle => 'Activar/desactivar shaders';
	@override String get skipMarker => 'Saltar introducción/créditos';
	@override String get screenshot => 'Tomar captura de pantalla';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$es extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requiere Android 8.0 o más reciente';
	@override String get iosVersion => 'Requiere iOS 15.0 o más reciente';
	@override String get permissionDisabled => 'El modo de imagen en imagen está desactivado. Actívalo en los ajustes del sistema.';
	@override String get notSupported => 'El dispositivo no admite el modo de imagen en imagen';
	@override String get voSwitchFailed => 'No se pudo cambiar la salida de video para el modo de imagen en imagen';
	@override String get failed => 'No se pudo iniciar el modo de imagen en imagen';
	@override String unknown({required Object error}) => 'Ocurrió un error: ${error}';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$es extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendado';
	@override String get browse => 'Explorar';
	@override String get collections => 'Colecciones';
	@override String get playlists => 'Listas de reproducción';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$es extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Agrupación';
	@override String get all => 'Todo';
	@override String get movies => 'Películas';
	@override String get shows => 'Series';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episodios';
	@override String get artists => 'Artistas';
	@override String get albums => 'Álbumes';
	@override String get tracks => 'Canciones';
	@override String get folders => 'Carpetas';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$es extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Género';
	@override String get year => 'Año';
	@override String get contentRating => 'Clasificación por edad';
	@override String get tag => 'Etiqueta';
	@override String get unwatched => 'No vistos';
	@override String get unplayed => 'No reproducidos';
	@override String get favorites => 'Favoritos';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$es extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Fecha de adición';
	@override String get releaseDate => 'Fecha de estreno';
	@override String get rating => 'Valoración';
	@override String get communityRating => 'Valoración de la comunidad';
	@override String get criticRating => 'Valoración de la crítica';
	@override String get userRating => 'Valoración del usuario';
	@override String get datePlayed => 'Fecha de reproducción';
	@override String get playCount => 'Reproducciones';
	@override String get productionYear => 'Año de producción';
	@override String get runtime => 'Duración';
	@override String get officialRating => 'Clasificación oficial';
	@override String get premiereDate => 'Fecha de estreno';
	@override String get startDate => 'Fecha de inicio';
	@override String get airTime => 'Hora de emisión';
	@override String get studio => 'Estudio';
	@override String get random => 'Aleatorio';
	@override String get dateShared => 'Fecha en que se compartió';
	@override String get latestEpisodeAirDate => 'Fecha de emisión del episodio más reciente';
	@override String get lastEpisodeDateAdded => 'Fecha en que se añadió el último episodio';
}

// Path: explore.rows
class _Translations$explore$rows$es extends Translations$explore$rows$en {
	_Translations$explore$rows$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista de seguimiento';
	@override String get recommendedMovies => 'Películas recomendadas';
	@override String get recommendedShows => 'Series recomendadas';
	@override String get trendingMovies => 'Películas en tendencia';
	@override String get trendingShows => 'Series en tendencia';
	@override String get popularMovies => 'Películas populares';
	@override String get popularShows => 'Series populares';
	@override String get trendingAnime => 'Anime en tendencia';
	@override String get suggestedAnime => 'Anime sugerido';
	@override String get airingAnime => 'Mejor anime en emisión';
	@override String get popularAnime => 'Anime más popular';
	@override String get trending => 'Tendencias';
	@override String get upcomingMovies => 'Próximas películas';
	@override String get upcomingShows => 'Próximas series';
}

// Path: explore.status
class _Translations$explore$status$es extends Translations$explore$status$en {
	_Translations$explore$status$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get airing => 'En emisión';
	@override String get ended => 'Finalizada';
	@override String get canceled => 'Cancelada';
	@override String get upcoming => 'Próximamente';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$es extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Las descargas se detendrán al salir de la app';
	@override String get bannerDegraded => 'Las descargas en segundo plano pueden estar limitadas';
	@override String get bannerAction => 'Detalles';
	@override String get sheetTitle => 'Las descargas en segundo plano están bloqueadas';
	@override String get sheetTitleDegraded => 'Las descargas en segundo plano pueden estar limitadas';
	@override String get sheetIntro => 'Android impide que Plezy descargue de forma fiable en segundo plano.';
	@override String get sheetIntroDegraded => 'Tu dispositivo limita cuándo puede descargar Plezy en segundo plano.';
	@override String get reasonBackgroundRestricted => 'El uso en segundo plano de Plezy está restringido. Configura el uso de batería o en segundo plano como "Sin restricciones".';
	@override String get reasonStandbyRestricted => 'Android ha puesto a Plezy en un estado de espera restringido. Configura el uso de batería como "Sin restricciones".';
	@override String get reasonDownloadChannelBlocked => 'Las notificaciones de descargas están desactivadas, por lo que el progreso y los controles podrían no estar disponibles.';
	@override String get reasonNotificationsDisabled => 'Las notificaciones están desactivadas. En Android 13 o versiones posteriores, son necesarias para las descargas largas en segundo plano.';
	@override String get reasonDataSaver => 'El Ahorro de datos está activado y bloquea las descargas en segundo plano con datos móviles. Las descargas deberían seguir funcionando con Wi-Fi.';
	@override String get reasonOemUnknown => 'Las descargas se detuvieron repetidamente mientras Plezy estaba en segundo plano. Revisa la configuración de batería o de uso en segundo plano de Plezy.';
	@override String get openSettings => 'Abrir configuración';
	@override String get stillNotWorking => 'Ayuda específica para tu dispositivo';
	@override String get stillNotWorkingDescription => 'Consulta los pasos para tu dispositivo o envía un registro desde Configuración › Ver registros si el problema continúa.';
	@override String get dialogTitle => 'Es posible que las descargas no finalicen';
	@override String get dialogDownloadAnyway => 'Descargar de todos modos';
	@override String get dialogFixFirst => 'Solucionarlo primero';
	@override String get statusTile => 'Descargas en segundo plano';
	@override String get statusOk => 'Permitidas en segundo plano';
	@override String get statusBlocked => 'Bloqueadas por la configuración del sistema';
	@override String get statusDegraded => 'Limitadas por la configuración del sistema';
	@override String get statusUnknown => 'Aún no se ha comprobado';
	@override String get settingsUnavailable => 'No se pudo abrir la configuración del sistema en este dispositivo';
	@override String get linkUnavailable => 'No se pudo abrir dontkillmyapp.com en este dispositivo';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$es extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Iniciando servidor remoto...';
	@override String get hostAddress => 'Dirección del host';
	@override String get connected => 'Conectado';
	@override String get serverRunning => 'Servidor remoto activo';
	@override String get serverStopped => 'Servidor remoto detenido';
	@override String get serverRunningDescription => 'Los dispositivos móviles de tu red pueden conectarse a esta aplicación';
	@override String get serverStoppedDescription => 'Inicia el servidor para permitir que los dispositivos móviles se conecten';
	@override String get usePhoneToControl => 'Usa tu dispositivo móvil para controlar esta aplicación';
	@override String get startServer => 'Iniciar servidor';
	@override String get stopServer => 'Detener servidor';
	@override String get minimize => 'Minimizar';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$es extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Los dispositivos Plezy con la misma cuenta Plex aparecen aquí';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Conectando...';
	@override String get searchingForDevices => 'Buscando dispositivos...';
	@override String get noDevicesFound => 'No se encontraron dispositivos en tu red';
	@override String get noDevicesHint => 'Abre Plezy en tu equipo y usa la misma red WiFi';
	@override String get availableDevices => 'Dispositivos disponibles';
	@override String get manualConnection => 'Conexión manual';
	@override String get cryptoInitFailed => 'No se pudo iniciar la conexión segura. Inicia sesión en Plex primero.';
	@override String get validationHostRequired => 'Introduce la dirección del host';
	@override String get validationHostFormat => 'El formato debe ser IP:puerto (p. ej., 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tiempo de conexión agotado. Usa la misma red en ambos dispositivos.';
	@override String get sessionNotFound => 'Dispositivo no encontrado. Asegúrate de que Plezy esté en ejecución en el host.';
	@override String get authFailed => 'Autenticación fallida. Ambos dispositivos necesitan la misma cuenta Plex.';
	@override String failedToConnect({required Object error}) => 'Error al conectar: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$es extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$es._(TranslationsEs root) : this._root = root, super.internal(root);

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

// Path: companionRemote.errors
class _Translations$companionRemote$errors$es extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'No se encontró ninguna interfaz de red';
	@override String get authenticationFailed => 'Autenticación fallida';
	@override String serverStartFailed({required Object error}) => 'No se pudo iniciar el servidor remoto: ${error}';
	@override String commandFailed({required Object error}) => 'No se pudo enviar el comando remoto: ${error}';
	@override String get joinTimedOut => 'Se agotó el tiempo al unirse a la sesión';
	@override String get failedToConnectAnyAddress => 'No se pudo conectar a ninguna dirección';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Conexión perdida tras ${attempts} intentos';
	@override String get connectionLost => 'Conexión perdida';
}

// Path: services.names
class _Translations$services$names$es extends Translations$services$names$en {
	_Translations$services$names$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$es extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Activar Plezy en ${service}';
	@override String body({required Object url}) => 'Visita ${url} e introduce este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para activar';
	@override String get copyCode => 'Copiar código de activación';
	@override String get waitingForAuthorization => 'Esperando autorización…';
	@override String get codeCopied => 'Código copiado';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$es extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Inicia sesión en ${service}';
	@override String get body => 'Escanea este código QR o abre la URL en cualquier dispositivo.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para iniciar sesión';
	@override String get copyUrl => 'Copiar URL de inicio de sesión';
	@override String get urlCopied => 'URL copiada';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$es extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'Sincronizando todas las bibliotecas';
	@override String get subtitleNoneSyncing => 'No se sincroniza ninguna biblioteca';
	@override String subtitleBlocked({required Object count}) => '${count} bloqueadas';
	@override String subtitleAllowed({required Object count}) => '${count} permitidas';
	@override String get mode => 'Modo de filtro';
	@override String get modeBlacklist => 'Lista de exclusión';
	@override String get modeWhitelist => 'Lista de inclusión';
	@override String get modeHintBlacklist => 'Sincronizar todas las bibliotecas excepto las seleccionadas abajo.';
	@override String get modeHintWhitelist => 'Sincronizar solo las bibliotecas seleccionadas abajo.';
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
			'auth.authenticationTimeout' => 'Se agotó el tiempo de autenticación. Inténtalo de nuevo.',
			'auth.scanQRToSignIn' => 'Escanea este código QR para iniciar sesión',
			'auth.waitingForAuth' => 'Esperando autenticación...\nInicia sesión desde tu navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'o',
			'auth.connectToJellyfin' => 'Conectar a Jellyfin',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectInstructions' => 'Abre Quick Connect en Jellyfin e introduce este código.',
			'auth.quickConnectWaiting' => 'Esperando aprobación…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'Quick Connect caducó. Inténtalo de nuevo.',
			'auth.localDataRecoveryRequired' => 'Plezy no pudo recuperar de forma segura los datos locales de inicio de sesión ni la reproducción pendiente. Vuelve a iniciar sesión.',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.close' => 'Cerrar',
			'common.clear' => 'Borrar',
			'common.reset' => 'Restablecer',
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
			'common.edit' => 'Editar',
			'common.shuffle' => 'Reproducción aleatoria',
			'common.addTo' => 'Añadir a...',
			'common.createNew' => 'Crear',
			'common.connect' => 'Conectar',
			'common.disconnect' => 'Desconectar',
			'common.play' => 'Reproducir',
			'common.pause' => 'Pausar',
			'common.resume' => 'Reanudar',
			'common.error' => 'Error',
			'common.search' => 'Buscar',
			'common.home' => 'Inicio',
			'common.back' => 'Atrás',
			'common.settings' => 'Ajustes',
			'common.mute' => 'Silenciar',
			'common.ok' => 'OK',
			'common.off' => 'Desactivado',
			'common.seasonNumber' => ({required Object number}) => 'Temporada ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episodio ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Capítulo ${number}',
			'common.reconnect' => 'Reconectar',
			'common.viewAll' => 'Ver todo',
			'common.checkingNetwork' => 'Comprobando red...',
			'common.loadingServers' => 'Cargando servidores...',
			'common.connectingToServers' => 'Conectando a servidores...',
			'common.startingOfflineMode' => 'Iniciando modo sin conexión...',
			'common.loading' => 'Cargando...',
			'common.fullscreen' => 'Pantalla completa',
			'common.exitFullscreen' => 'Salir de pantalla completa',
			'common.pressBackAgainToExit' => 'Pulsa Atrás de nuevo para salir',
			'screens.licenses' => 'Licencias',
			'screens.switchProfile' => 'Cambiar perfil',
			'screens.subtitleStyling' => 'Estilo de subtítulos',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Registros',
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
			'settings.videoPlayback' => 'Reproducción de video',
			'settings.videoPlaybackDescription' => 'Configurar el comportamiento de reproducción',
			'settings.advanced' => 'Avanzado',
			'settings.episodePosterMode' => 'Estilo del póster de episodio',
			'settings.seriesPoster' => 'Póster de la serie',
			'settings.seasonPoster' => 'Póster de la temporada',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Mostrar carrusel de contenido destacado en la pantalla de inicio',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Introduce la duración (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Oscuro',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Densidad de la biblioteca',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Cómodo',
			'settings.tvCornerSpotlightBackdrop' => 'Imagen destacada en la esquina',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostrar la imagen destacada en la esquina superior derecha en lugar de ocupar toda la pantalla',
			'settings.viewMode' => 'Modo de vista',
			'settings.gridView' => 'Cuadrícula',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar sección destacada',
			'settings.continueWatchingAction' => 'Acción de «Seguir viendo»',
			'settings.continueWatchingPlay' => 'Reproducir',
			'settings.continueWatchingDetails' => 'Abrir detalles',
			'settings.episodeAction' => 'Acción de episodio',
			'settings.episodePlay' => 'Reproducir',
			'settings.episodeDetails' => 'Abrir detalles',
			'settings.useGlobalHubs' => 'Usar secciones de inicio',
			'settings.useGlobalHubsDescription' => 'Mostrar secciones de inicio unificadas. De lo contrario, usar las recomendaciones de cada biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar el nombre del servidor en las secciones',
			'settings.showServerNameOnHubsDescription' => 'Mostrar siempre el nombre del servidor en los títulos de las secciones.',
			'settings.groupLibrariesByServer' => 'Agrupar bibliotecas por servidor',
			'settings.groupLibrariesByServerDescription' => 'Agrupar bibliotecas de la barra lateral por servidor multimedia.',
			'settings.alwaysKeepSidebarOpen' => 'Mantener siempre la barra lateral abierta',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse',
			'settings.showUnwatchedCount' => 'Mostrar el número de elementos no vistos',
			'settings.showUnwatchedCountDescription' => 'Mostrar el número de episodios no vistos en series y temporadas',
			'settings.showEpisodeNumberOnCards' => 'Mostrar número de episodio en las tarjetas',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostrar temporada y episodio en tarjetas de episodio',
			'settings.showSeasonPostersOnTabs' => 'Mostrar pósters de temporada en las pestañas',
			'settings.showSeasonPostersOnTabsDescription' => 'Mostrar el póster de cada temporada sobre su pestaña',
			'settings.tvFullCardLayout' => 'Tarjetas TV completas',
			'settings.tvFullCardLayoutDescription' => 'Usar tarjetas TV solo con imagen y nombres de actores superpuestos',
			'settings.focusGlow' => 'Resplandor de selección',
			'settings.focusGlowDescription' => 'Mostrar un resplandor suave alrededor de la tarjeta seleccionada',
			'settings.visualEffects' => 'Efectos visuales',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.visualEffectsAutoDescription' => 'Reduce automáticamente los efectos en dispositivos de bajo consumo',
			'settings.visualEffectsFull' => 'Completos',
			'settings.visualEffectsReduced' => 'Reducidos',
			'settings.visualEffectsReducedDescription' => 'Menos animaciones e ilustraciones de menor resolución',
			'settings.hideSpoilers' => 'Ocultar spoilers de episodios no vistos',
			'settings.hideSpoilersDescription' => 'Desenfocar miniaturas y descripciones de episodios no vistos',
			'settings.playerBackend' => 'Motor de reproducción',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Decodificación por hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleración por hardware cuando esté disponible',
			'settings.bufferSize' => 'Tamaño del búfer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size} MB',
			'settings.bufferSizeAuto' => 'Automático (recomendado)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap} MB de memoria disponible. Un búfer de ${size} MB puede afectar a la reproducción.',
			'settings.defaultQualityTitle' => 'Calidad predeterminada',
			'settings.musicQualityTitle' => 'Calidad de música',
			'settings.subtitleStyling' => 'Estilo de subtítulos',
			'settings.subtitleStylingDescription' => 'Personalizar la apariencia de los subtítulos',
			'settings.smallSkipDuration' => 'Salto pequeño',
			'settings.largeSkipDuration' => 'Salto grande',
			'settings.rewindOnResume' => 'Rebobinar al reanudar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} segundos',
			'settings.defaultSleepTimer' => 'Temporizador de apagado',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutos',
			'settings.rememberTrackSelections' => 'Recordar selección de pistas por serie/película',
			'settings.rememberTrackSelectionsDescription' => 'Recordar opciones de audio y subtítulos por título',
			'settings.showChapterMarkersOnTimeline' => 'Mostrar marcadores de capítulos en la barra de progreso',
			'settings.showChapterMarkersOnTimelineDescription' => 'Dividir la barra de progreso en los límites de capítulos',
			'settings.clickVideoTogglesPlayback' => 'Clic en el video para reproducir/pausar',
			'settings.clickVideoTogglesPlaybackDescription' => 'Haz clic en el video para reproducir/pausar en vez de mostrar controles.',
			'settings.videoPlayerControls' => 'Controles del reproductor de video',
			'settings.keyboardShortcuts' => 'Atajos de teclado',
			'settings.keyboardShortcutsDescription' => 'Personalizar los atajos de teclado',
			'settings.videoPlayerNavigation' => 'Navegación del reproductor de video',
			'settings.videoPlayerNavigationDescription' => 'Usar las teclas de flecha para navegar por los controles del reproductor',
			'settings.watchTogetherRelay' => 'Servidor de retransmisión de Ver juntos',
			'settings.watchTogetherRelayDescription' => 'Configura un servidor de retransmisión personalizado. Todos deben usar el mismo servidor.',
			'settings.watchTogetherRelayHint' => 'https://mi-relay.ejemplo.com',
			'settings.watchTogetherRelayInvalid' => 'Introduce una URL base HTTP o HTTPS válida para el servidor de retransmisión.',
			'settings.crashReporting' => 'Informes de errores',
			'settings.crashReportingDescription' => 'Enviar informes de errores para mejorar la aplicación',
			'settings.debugLogging' => 'Registro de depuración',
			'settings.debugLoggingDescription' => 'Habilitar registros detallados para solucionar problemas',
			'settings.viewLogs' => 'Ver registros',
			'settings.viewLogsDescription' => 'Ver los registros de la aplicación',
			'settings.resetSettings' => 'Restablecer configuración',
			'settings.resetSettingsDescription' => 'Restaurar ajustes predeterminados. No se puede deshacer.',
			'settings.resetSettingsSuccess' => 'Configuración restablecida con éxito',
			'settings.backup' => 'Copia de seguridad',
			'settings.exportSettings' => 'Exportar configuración',
			'settings.exportSettingsDescription' => 'Guardar tus preferencias en un archivo',
			'settings.exportSettingsSuccess' => 'Configuración exportada',
			'settings.importSettings' => 'Importar configuración',
			'settings.importSettingsDescription' => 'Restaurar preferencias desde un archivo',
			'settings.importSettingsConfirm' => 'Esto reemplazará tu configuración actual. ¿Continuar?',
			'settings.importSettingsSuccess' => 'Configuración importada',
			'settings.importSettingsInvalidFile' => 'Este archivo no es una exportación válida de Plezy',
			'settings.importSettingsNoUser' => 'Inicia sesión antes de importar la configuración',
			'settings.shortcutsReset' => 'Atajos restablecidos a los valores predeterminados',
			'settings.about' => 'Acerca de',
			'settings.aboutDescription' => 'Información de la aplicación y licencias',
			'settings.updates' => 'Actualizaciones',
			'settings.updateAvailable' => 'Actualización disponible',
			'settings.checkForUpdates' => 'Buscar actualizaciones',
			'settings.autoCheckUpdatesOnStartup' => 'Buscar actualizaciones automáticamente al iniciar',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Avisar al iniciar si hay una actualización disponible',
			'settings.validationErrorEnterNumber' => 'Introduce un número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La duración debe estar entre ${min} y ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'El atajo ya está asignado a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atajo actualizado para ${action}',
			'settings.saveFailed' => 'No se pudieron guardar los cambios. Inténtalo de nuevo.',
			'settings.autoSkip' => 'Salto automático',
			'settings.autoSkipIntro' => 'Saltar introducción automáticamente',
			'settings.autoSkipIntroDescription' => 'Saltar automáticamente los marcadores de introducción después de unos segundos',
			'settings.autoSkipCredits' => 'Saltar créditos automáticamente',
			'settings.autoSkipCreditsDescription' => 'Saltar automáticamente los créditos y reproducir el episodio siguiente',
			'settings.forceSkipMarkerFallback' => 'Forzar marcadores alternativos',
			'settings.forceSkipMarkerFallbackDescription' => 'Usar patrones de títulos de capítulos aunque Plex tenga marcadores',
			'settings.autoSkipDelay' => 'Retraso del salto automático',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Esperar ${seconds} segundos antes de saltar automáticamente',
			'settings.introPattern' => 'Patrón de marcador de introducción',
			'settings.introPatternDescription' => 'Expresión regular para reconocer marcadores de introducción en los títulos de los capítulos',
			'settings.creditsPattern' => 'Patrón de marcador de créditos',
			'settings.creditsPatternDescription' => 'Expresión regular para reconocer marcadores de créditos en los títulos de los capítulos',
			'settings.invalidRegex' => 'Expresión regular no válida',
			'settings.regex' => 'Expresión regular',
			'settings.downloads' => 'Descargas',
			'settings.downloadLocationDescription' => 'Elegir dónde almacenar el contenido descargado',
			'settings.downloadLocationDefault' => 'Predeterminado (almacenamiento de la aplicación)',
			'settings.downloadLocationCustom' => 'Ubicación personalizada',
			'settings.selectFolder' => 'Seleccionar carpeta',
			'settings.resetToDefault' => 'Restablecer al predeterminado',
			'settings.currentPath' => ({required Object path}) => 'Actual: ${path}',
			'settings.downloadLocationChanged' => 'Ubicación de descarga cambiada',
			'settings.downloadLocationReset' => 'Ubicación de descarga restablecida al predeterminado',
			'settings.downloadLocationInvalid' => 'La carpeta seleccionada no tiene permisos de escritura',
			'settings.downloadLocationPickerUnavailable' => 'La selección de carpetas no está disponible en este dispositivo',
			'settings.downloadOnWifiOnly' => 'Descargar solo con WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Evitar descargas cuando se usan datos móviles',
			'settings.autoRemoveWatchedDownloads' => 'Eliminar descargas vistas automáticamente',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Eliminar automáticamente descargas vistas',
			'settings.cellularDownloadBlocked' => 'Las descargas están bloqueadas en red móvil. Usa WiFi o cambia el ajuste.',
			'settings.maxVolume' => 'Volumen máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Presencia de Discord',
			'settings.discordRichPresenceDescription' => 'Mostrar lo que estás viendo en Discord',
			'settings.services' => 'Servicios',
			'settings.servicesDescription' => 'Conecta Trakt, MyAnimeList, Seerr y más',
			'settings.manageLibrariesDescription' => 'Reordena y oculta bibliotecas',
			'settings.companionRemoteServer' => 'Servidor de control remoto',
			'settings.companionRemoteServerDescription' => 'Permitir que dispositivos móviles en tu red controlen esta aplicación',
			'settings.autoPip' => 'Imagen en imagen automática',
			'settings.autoPipDescription' => 'Activar automáticamente el modo de imagen en imagen al salir de la aplicación durante la reproducción',
			'settings.matchContentFrameRate' => 'Ajustar frecuencia de actualización',
			'settings.matchContentFrameRateDescription' => 'Ajustar la frecuencia de pantalla al contenido de video',
			'settings.matchRefreshRate' => 'Ajustar frecuencia de refresco',
			'settings.matchRefreshRateDescription' => 'Ajustar la frecuencia de pantalla en pantalla completa',
			'settings.matchDynamicRange' => 'Ajustar rango dinámico',
			'settings.matchDynamicRangeDescription' => 'Activar HDR para contenido HDR y luego volver a SDR',
			'settings.displaySwitchDelay' => 'Retraso de cambio de pantalla',
			'settings.tunneledPlayback' => 'Reproducción tunelizada',
			'settings.tunneledPlaybackDescription' => 'Usar tunelización de video. Desactívala si HDR muestra video negro.',
			'settings.audioPassthrough' => 'Transferencia directa de audio',
			'settings.audioPassthroughDescription' => 'Envía el audio Dolby/DTS a tu receptor o TV sin recodificar, conservando el sonido envolvente. Desactívala si no tienes sonido.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Usa el decodificador Dolby nativo de Apple para Dolby Digital Plus, incluido Atmos. DTS y TrueHD se siguen reproduciendo como PCM multicanal. Desactívalo si no tienes sonido.',
			'settings.audioDownmix' => 'Mezclar a estéreo',
			'settings.audioDownmixDescription' => 'Mezcla el sonido envolvente a dos canales para altavoces estéreo o auriculares',
			'settings.downmixCenterBoost' => 'Realce del canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Realce (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizar volumen al mezclar',
			'settings.audioDownmixNormalizeDescription' => 'Reduce la mezcla para evitar saturación. Desactívalo para mantener el volumen original (puede distorsionar escenas fuertes).',
			'settings.atmosDiagnostics' => 'Prueba de salida Atmos',
			'settings.atmosDiagnosticsDescription' => 'Diagnostica la salida Dolby Atmos reproduciendo señales de prueba con el reproductor del sistema',
			'settings.atmosTestHlsAtmos' => 'Flujo Atmos de Apple',
			'settings.atmosTestHlsAtmosDescription' => 'Flujo Dolby Atmos de referencia. El receptor debería mostrar Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Flujo envolvente de Apple',
			'settings.atmosTestHlsControlDescription' => 'Flujo de control sin Atmos. El receptor debería indicar sonido envolvente sin Atmos.',
			'settings.atmosTestRawStream' => 'Flujo EAC3 sin procesar',
			'settings.atmosTestRawStreamDescription' => 'Transmite el archivo de prueba igual que durante la reproducción de Atmos. Requiere la URL del archivo de prueba.',
			'settings.atmosTestRawFile' => 'Archivo EAC3 sin procesar',
			'settings.atmosTestRawFileDescription' => 'Reproduce el archivo de prueba con longitud conocida. Necesita la URL del archivo de prueba.',
			'settings.atmosTestAsbarNative' => 'Renderizador de búfer de muestras (nativo)',
			'settings.atmosTestAsbarNativeDescription' => 'Envía el audio comprimido intacto del archivo directamente al renderizador del sistema. Necesita la URL del archivo de prueba.',
			'settings.atmosTestAsbarGenerated' => 'Renderizador de búfer de muestras (reconstruido)',
			'settings.atmosTestAsbarGeneratedDescription' => 'Igual, pero con la descripción de audio construida como en la reproducción. Necesita la URL del archivo de prueba.',
			'settings.atmosTestSessionMode' => 'Usar modo de reproducción de películas',
			'settings.atmosTestSessionModeDescription' => 'Desactivado usa el modo que documenta Dolby. Activado usa el modo anterior.',
			'settings.atmosTestShowRoutePicker' => 'Elegir salida AirPlay',
			'settings.atmosTestHideRoutePicker' => 'Ocultar selector de salida AirPlay',
			'settings.atmosTestRoutePickerDescription' => 'Envía la prueba a un receptor AirPlay. Solo AirPlay informa del modo de audio resuelto.',
			'settings.atmosTestStop' => 'Detener prueba',
			'settings.atmosTestUrl' => 'URL del archivo de prueba',
			'settings.atmosTestUrlDescription' => 'URL HTTP de un archivo .ec3 Dolby Atmos sin procesar (p. ej., extraído con ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Configura primero la URL del archivo de prueba',
			'settings.atmosTestStatus' => 'Estado',
			'settings.dvConversionMode' => 'Conversión de Dolby Vision',
			'settings.dvConversionModeDescription' => 'Elige cómo gestiona ExoPlayer los archivos Dolby Vision de perfil 7.',
			'settings.dvConversionAuto' => 'Automático',
			'settings.dvConversionNative' => 'Nativo / desactivado',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Usar la detección de capacidades del dispositivo y el comportamiento alternativo normal',
			'settings.dvConversionNativeDescription' => 'Forzar DV7 nativo y suprimir el reintento de conversión DV',
			'settings.dvConversionDv81Description' => 'Forzar la conversión de RPU en línea al perfil 8.1 de Dolby Vision',
			'settings.dvConversionHevcStripDescription' => 'Eliminar las capas RPU/EL de Dolby Vision y presentar HEVC convencional',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil al abrir la aplicación',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar selección de perfil cada vez que se abre la aplicación',
			'settings.forceTvMode' => 'Forzar modo TV',
			'settings.forceTvModeDescription' => 'Forzar diseño TV. Para dispositivos que no lo detectan. Requiere reinicio.',
			'settings.startInFullscreen' => 'Iniciar en pantalla completa',
			'settings.startInFullscreenDescription' => 'Abrir Plezy en modo pantalla completa al iniciar',
			'settings.exitFullscreenOnPlayerClose' => 'Salir de pantalla completa al cerrar el reproductor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Salir automáticamente del modo de pantalla completa al cerrar el reproductor de video',
			'settings.autoHidePerformanceOverlay' => 'Ocultar superposición de rendimiento automáticamente',
			'settings.autoHidePerformanceOverlayDescription' => 'Desvanecer la superposición de rendimiento con los controles de reproducción',
			'settings.showNavBarLabels' => 'Mostrar etiquetas de la barra de navegación',
			'settings.showNavBarLabelsDescription' => 'Mostrar etiquetas de texto bajo los iconos de la barra de navegación',
			'settings.startupSection' => 'Sección de inicio',
			'settings.liveTvDefaultFavorites' => 'Canales favoritos por defecto',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar solo canales favoritos al abrir TV en vivo',
			'settings.display' => 'Pantalla',
			'settings.homeScreen' => 'Pantalla de inicio',
			'settings.navigation' => 'Navegación',
			'settings.window' => 'Ventana',
			'settings.content' => 'Contenido',
			'settings.player' => 'Reproductor',
			'settings.subtitlesAndConfig' => 'Subtítulos y configuración',
			'settings.seekAndTiming' => 'Desplazamiento y tiempos',
			'settings.behavior' => 'Comportamiento',
			'search.hint' => 'Buscar películas, series, música...',
			'search.tryDifferentTerm' => 'Prueba con un término de búsqueda diferente',
			'search.searchYourMedia' => 'Busca en tu contenido',
			'search.enterTitleActorOrKeyword' => 'Introduce un título, actor o palabra clave',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Establecer atajo para ${actionName}',
			'hotkeys.clearShortcut' => 'Borrar atajo',
			'hotkeys.noShortcutSet' => 'Sin atajo asignado',
			'hotkeys.currentShortcut' => 'Atajo actual:',
			'hotkeys.pressToRecord' => 'Seleccionar para grabar un atajo',
			'hotkeys.recordingShortcut' => 'Pulsa el atajo ahora',
			'hotkeys.actions.playPause' => 'Reproducir/pausar',
			'hotkeys.actions.volumeUp' => 'Subir volumen',
			'hotkeys.actions.volumeDown' => 'Bajar volumen',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avanzar (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Retroceder (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Alternar pantalla completa',
			'hotkeys.actions.muteToggle' => 'Activar/desactivar silencio',
			'hotkeys.actions.subtitleToggle' => 'Activar/desactivar subtítulos',
			'hotkeys.actions.audioTrackNext' => 'Pista de audio siguiente',
			'hotkeys.actions.subtitleTrackNext' => 'Pista de subtítulos siguiente',
			'hotkeys.actions.chapterNext' => 'Capítulo siguiente',
			'hotkeys.actions.chapterPrevious' => 'Capítulo anterior',
			'hotkeys.actions.episodeNext' => 'Episodio siguiente',
			'hotkeys.actions.episodePrevious' => 'Episodio anterior',
			'hotkeys.actions.speedIncrease' => 'Aumentar velocidad',
			'hotkeys.actions.speedDecrease' => 'Disminuir velocidad',
			'hotkeys.actions.speedReset' => 'Restablecer velocidad',
			'hotkeys.actions.zoomIn' => 'Acercar',
			'hotkeys.actions.zoomOut' => 'Alejar',
			'hotkeys.actions.zoomReset' => 'Restablecer zoom',
			'hotkeys.actions.subSeekNext' => 'Ir al subtítulo siguiente',
			'hotkeys.actions.subSeekPrev' => 'Ir al subtítulo anterior',
			'hotkeys.actions.shaderToggle' => 'Activar/desactivar shaders',
			'hotkeys.actions.skipMarker' => 'Saltar introducción/créditos',
			'hotkeys.actions.screenshot' => 'Tomar captura de pantalla',
			'fileInfo.title' => 'Información del archivo',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Subtítulos',
			'fileInfo.file' => 'Archivo',
			'fileInfo.codec' => 'Códec',
			'fileInfo.resolution' => 'Resolución',
			'fileInfo.bitrate' => 'Tasa de bits',
			'fileInfo.frameRate' => 'Frecuencia de fotogramas',
			'fileInfo.aspectRatio' => 'Relación de aspecto',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.bitDepth' => 'Profundidad de bits',
			'fileInfo.colorSpace' => 'Espacio de color',
			'fileInfo.colorRange' => 'Rango de color',
			'fileInfo.colorPrimaries' => 'Primarias de color',
			'fileInfo.chromaSubsampling' => 'Submuestreo de croma',
			'fileInfo.channels' => 'Canales',
			'fileInfo.overallBitrate' => 'Tasa de bits total',
			'fileInfo.path' => 'Ruta',
			'fileInfo.size' => 'Tamaño',
			'fileInfo.container' => 'Contenedor',
			'fileInfo.duration' => 'Duración',
			'fileInfo.optimizedForStreaming' => 'Optimizado para transmisión',
			'fileInfo.has64bitOffsets' => 'Desplazamientos de 64 bits',
			'mediaMenu.markAsWatched' => 'Marcar como visto',
			'mediaMenu.markAsUnwatched' => 'Marcar como no visto',
			'mediaMenu.removeFromContinueWatching' => 'Eliminar de Seguir viendo',
			'mediaMenu.viewDetails' => 'Ver detalles',
			'mediaMenu.goToSeries' => 'Ir a la serie',
			'mediaMenu.shufflePlay' => 'Reproducción aleatoria',
			'mediaMenu.shuffleNotAvailableOffline' => 'La reproducción aleatoria no está disponible sin conexión',
			'mediaMenu.fileInfo' => 'Información del archivo',
			'mediaMenu.deleteFromServer' => 'Eliminar del servidor',
			'mediaMenu.confirmDelete' => '¿Eliminar este medio y sus archivos de tu servidor?',
			'mediaMenu.deleteMultipleWarning' => 'Esto incluye todos los episodios y sus archivos.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Elemento multimedia eliminado con éxito',
			'mediaMenu.mediaFailedToDelete' => 'Error al eliminar el elemento multimedia',
			'mediaMenu.rate' => 'Calificar',
			'mediaMenu.playFromBeginning' => 'Reproducir desde el inicio',
			'mediaMenu.playVersion' => 'Reproducir versión...',
			'rateSheet.title' => 'Calificar',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'rateSheet.favorited' => 'Marcado como favorito',
			'rateSheet.saved' => 'Guardado',
			'rateSheet.notAvailable' => 'No se encontró coincidencia',
			'rateSheet.noConnectedServices' => 'Conecta un servicio en Configuración para valorar el contenido en él.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, película',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serie de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por ciento visto',
			'accessibility.mediaCardUnwatched' => 'no visto',
			'accessibility.tapToPlay' => 'Toca para reproducir',
			'accessibility.decrease' => 'Disminuir',
			'accessibility.increase' => 'Aumentar',
			'accessibility.decreaseValue' => ({required Object label}) => 'Disminuir ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Aumentar ${label}',
			'accessibility.hue' => 'Tono',
			'accessibility.saturation' => 'Saturación',
			'accessibility.brightness' => 'Brillo',
			'accessibility.hexColor' => 'Color hexadecimal',
			'accessibility.expandText' => 'Expandir texto',
			'accessibility.collapseText' => 'Contraer texto',
			'accessibility.alphabetNavigation' => 'Navegación alfabética',
			'accessibility.alphabetScrollHint' => 'Desliza hacia arriba o abajo para avanzar por letra',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Fila ${row} de ${rowCount}, columna ${column} de ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Fila ${row} de ${rowCount}',
			'tooltips.shufflePlay' => 'Reproducción aleatoria',
			'tooltips.playTrailer' => 'Reproducir tráiler',
			'tooltips.markAsWatched' => 'Marcar como visto',
			'tooltips.markAsUnwatched' => 'Marcar como no visto',
			'audioTracks.track' => ({required Object n}) => 'Pista de audio ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Subtítulos',
			'videoControls.resetToZero' => 'Restablecer a 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} se reproduce más tarde',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} se reproduce antes',
			'videoControls.noOffset' => 'Sin desfase',
			'videoControls.letterbox' => 'Con bandas negras',
			'videoControls.fillScreen' => 'Llenar pantalla',
			'videoControls.stretch' => 'Estirar',
			'videoControls.lockRotation' => 'Bloquear rotación',
			'videoControls.unlockRotation' => 'Desbloquear rotación',
			'videoControls.timerActive' => 'Temporizador activo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La reproducción se pausará en ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fin del video actual',
			'videoControls.sleepTimerStopAtHeader' => 'Detener en',
			'videoControls.sleepTimerDurationHeader' => 'Temporizador',
			'videoControls.playbackWillPauseAtEnd' => 'La reproducción se pausará al final de este video',
			'videoControls.stillWatching' => '¿Sigues viendo?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Se pausará en ${seconds}s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Reproducir siguiente automáticamente',
			'videoControls.playNext' => 'Reproducir siguiente',
			'videoControls.playButton' => 'Reproducir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.showPlaybackControls' => 'Mostrar controles de reproducción',
			'videoControls.hidePlaybackControls' => 'Ocultar controles de reproducción',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Retroceder ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avanzar ${seconds} segundos',
			'videoControls.previousButton' => 'Episodio anterior',
			'videoControls.nextButton' => 'Episodio siguiente',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Capítulo siguiente',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Activar sonido',
			'videoControls.settingsButton' => 'Ajustes de reproducción',
			'videoControls.tracksButton' => 'Audio y subtítulos',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionQualityButton' => 'Versión y calidad',
			'videoControls.versionColumnHeader' => 'Versión',
			'videoControls.qualityColumnHeader' => 'Calidad',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodificación no disponible — reproduciendo calidad original',
			'videoControls.subtitleUnavailableFallback' => 'No se pudieron cargar los subtítulos seleccionados — continuando sin subtítulos',
			'videoControls.pipButton' => 'Modo de imagen en imagen',
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
			'videoControls.pipActive' => 'Reproduciendo en modo de imagen en imagen',
			'videoControls.pipFailed' => 'No se pudo iniciar el modo de imagen en imagen',
			'videoControls.screenshotSaved' => 'Captura de pantalla guardada',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Requiere Android 8.0 o más reciente',
			'videoControls.pipErrors.iosVersion' => 'Requiere iOS 15.0 o más reciente',
			'videoControls.pipErrors.permissionDisabled' => 'El modo de imagen en imagen está desactivado. Actívalo en los ajustes del sistema.',
			'videoControls.pipErrors.notSupported' => 'El dispositivo no admite el modo de imagen en imagen',
			'videoControls.pipErrors.voSwitchFailed' => 'No se pudo cambiar la salida de video para el modo de imagen en imagen',
			'videoControls.pipErrors.failed' => 'No se pudo iniciar el modo de imagen en imagen',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocurrió un error: ${error}',
			'videoControls.chapters' => 'Capítulos',
			'videoControls.noChaptersAvailable' => 'No hay capítulos disponibles',
			'videoControls.queue' => 'Cola',
			'videoControls.noQueueItems' => 'No hay elementos en la cola',
			'videoControls.searchSubtitles' => 'Buscar subtítulos',
			'videoControls.language' => 'Idioma',
			'videoControls.noSubtitlesFound' => 'No se encontraron subtítulos',
			'videoControls.subtitleDownloaded' => 'Subtítulo descargado',
			'videoControls.subtitleDownloadedNotApplied' => 'El subtítulo se descargó, pero no se pudo seleccionar',
			_ => null,
		} ?? switch (path) {
			'videoControls.subtitleDownloadFailed' => 'Error al descargar subtítulo',
			'videoControls.searchLanguages' => 'Buscar idiomas...',
			'messages.markedAsWatched' => 'Marcado como visto',
			'messages.markedAsUnwatched' => 'Marcado como no visto',
			'messages.markedAsWatchedOffline' => 'Marcado como visto (se sincronizará al estar en línea)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como no visto (se sincronizará al estar en línea)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Eliminado automáticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Se eliminó automáticamente ${n} descarga vista', other: 'Se eliminaron automáticamente ${n} descargas vistas', ), 
			'messages.removedFromContinueWatching' => 'Eliminado de Seguir Viendo',
			'messages.errorLoading' => ({required Object error}) => 'Error: ${error}',
			'messages.streamInterrupted' => 'La reproducción se interrumpió. Pulsa reproducir o avanza para volver a intentarlo.',
			'messages.liveStreamInterrupted' => 'La transmisión en vivo se interrumpió. Pulsa reproducir para volver a intentarlo.',
			'messages.fileInfoNotAvailable' => 'Información de archivo no disponible',
			'messages.playbackAuthenticationRequired' => 'Vuelve a iniciar sesión en el servidor multimedia para reproducir este elemento.',
			'messages.playbackServerUnavailable' => 'El servidor multimedia no está disponible. Inténtalo de nuevo más tarde.',
			'messages.playbackDataInvalid' => 'El servidor devolvió información de reproducción no válida.',
			'messages.playbackCancelled' => 'Se canceló la reproducción.',
			'messages.playbackFailed' => 'No se pudo iniciar la reproducción.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Error al cargar la información del archivo: ${error}',
			'messages.errorLoadingSeries' => 'Error al cargar la serie',
			'messages.musicNotSupported' => 'La reproducción de música aún no es compatible',
			'messages.noDescriptionAvailable' => 'No hay descripción disponible',
			'messages.noProfilesAvailable' => 'No hay perfiles disponibles',
			'messages.contactAdminForProfiles' => 'Contacta a tu administrador del servidor para añadir perfiles',
			'messages.unableToDetermineLibrarySection' => 'No se puede determinar la sección de biblioteca para este elemento',
			'messages.logsCleared' => 'Registros borrados',
			'messages.logsCopied' => 'Registros copiados al portapapeles',
			'messages.noLogsAvailable' => 'No hay registros disponibles',
			'messages.libraryScanning' => ({required Object title}) => 'Escaneando "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Escaneo de biblioteca iniciado para "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Error al escanear biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Actualizando metadatos de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Actualización de metadatos iniciada para "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Error al actualizar metadatos: ${error}',
			'messages.logoutConfirm' => '¿Estás seguro de que quieres cerrar sesión?',
			'messages.noSeasonsFound' => 'No se encontraron temporadas',
			'messages.seasonsLoadFailed' => 'No se pudieron cargar las temporadas',
			'messages.noEpisodesFound' => 'No se encontraron episodios en la primera temporada',
			'messages.noEpisodesFoundGeneral' => 'No se encontraron episodios',
			'messages.episodesLoadFailed' => 'No se pudieron cargar los episodios',
			'messages.noResultsFound' => 'No se encontraron resultados',
			'messages.sleepTimerSet' => ({required Object label}) => 'Temporizador establecido en ${label}',
			'messages.noItemsAvailable' => 'No hay elementos disponibles',
			'messages.failedToCreatePlayQueueNoItems' => 'No se pudo crear la cola de reproducción: no hay elementos',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Error al ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Cambiando a reproductor compatible...',
			'messages.serverLimitTitle' => 'Error de reproducción',
			'messages.serverLimitBody' => 'Error del servidor (HTTP 500). Un límite de ancho de banda/transcodificación probablemente rechazó esta sesión. Pide al propietario que lo ajuste.',
			'messages.logsUploaded' => 'Registros subidos',
			'messages.logsUploadFailed' => 'Error al subir registros',
			'messages.logId' => 'ID de registro',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.border' => 'Borde',
			'subtitlingStyling.background' => 'Fondo',
			'subtitlingStyling.fontSize' => 'Tamaño de fuente',
			'subtitlingStyling.textColor' => 'Color del texto',
			'subtitlingStyling.borderSize' => 'Tamaño del borde',
			'subtitlingStyling.borderColor' => 'Color del borde',
			'subtitlingStyling.backgroundOpacity' => 'Opacidad del fondo',
			'subtitlingStyling.backgroundColor' => 'Color del fondo',
			'subtitlingStyling.position' => 'Posición',
			'subtitlingStyling.assOverride' => 'Sobreescritura ASS',
			'subtitlingStyling.overrideScale' => 'Escala',
			'subtitlingStyling.overrideForce' => 'Forzar',
			'subtitlingStyling.overrideStrip' => 'Quitar estilos',
			'subtitlingStyling.positionTop' => 'Arriba',
			'subtitlingStyling.positionBottom' => 'Abajo',
			'subtitlingStyling.bold' => 'Negrita',
			'subtitlingStyling.italic' => 'Cursiva',
			'subtitlingStyling.renderResolution' => 'Resolución de renderizado',
			'subtitlingStyling.renderResolutionScreen' => 'Resolución de pantalla',
			'subtitlingStyling.renderResolutionVideo' => 'Resolución del video',
			'mpvConfig.title' => 'Configuración de mpv',
			'mpvConfig.description' => 'Ajustes avanzados del reproductor de video',
			'mpvConfig.presets' => 'Preajustes',
			'mpvConfig.noPresets' => 'No hay preajustes guardados',
			'mpvConfig.saveAsPreset' => 'Guardar como preajuste...',
			'mpvConfig.presetName' => 'Nombre del preajuste',
			'mpvConfig.presetNameHint' => 'Introduce un nombre para este preajuste',
			'mpvConfig.loadPreset' => 'Cargar',
			'mpvConfig.deletePreset' => 'Eliminar',
			'mpvConfig.presetSaved' => 'Preajuste guardado',
			'mpvConfig.presetLoaded' => 'Preajuste cargado',
			'mpvConfig.presetDeleted' => 'Preajuste eliminado',
			'mpvConfig.confirmDeletePreset' => '¿Estás seguro de que quieres eliminar este preajuste?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Confirmar acción',
			'profiles.addPlezyProfile' => 'Añadir perfil de Plezy',
			'profiles.switchingProfile' => 'Cambiando de perfil…',
			'profiles.deleteThisProfileTitle' => '¿Eliminar este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Eliminar ${displayName}. Las conexiones no se verán afectadas.',
			'profiles.active' => 'Activo',
			'profiles.manage' => 'Administrar',
			'profiles.delete' => 'Eliminar',
			'profiles.signOut' => 'Cerrar sesión',
			'profiles.signOutPlexTitle' => '¿Cerrar sesión de Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '¿Eliminar ${displayName} y todos los usuarios de Plex Home? Puedes iniciar sesión de nuevo cuando quieras.',
			'profiles.signedOutPlex' => 'Sesión de Plex cerrada.',
			'profiles.signOutFailed' => 'Error al cerrar sesión.',
			'profiles.sectionTitle' => 'Perfiles',
			'profiles.summarySingle' => 'Añade perfiles para mezclar usuarios gestionados e identidades locales',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} perfiles · activo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} perfiles',
			'profiles.removeConnectionTitle' => '¿Eliminar conexión?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Eliminar el acceso de ${displayName} a ${connectionLabel}. Los demás perfiles lo conservan.',
			'profiles.deleteProfileTitle' => '¿Eliminar perfil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Eliminar ${displayName} y sus conexiones. Los servidores seguirán disponibles.',
			'profiles.profileNameLabel' => 'Nombre del perfil',
			'profiles.pinProtectionLabel' => 'Protección con PIN',
			'profiles.pinManagedByPlex' => 'PIN gestionado por Plex. Edita en plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Sin PIN establecido. Para requerir uno, edita el usuario Home en plex.tv.',
			'profiles.setPin' => 'Establecer PIN',
			'profiles.setPinTitle' => 'Establecer PIN',
			'profiles.confirmPinTitle' => 'Confirmar PIN',
			'profiles.pinSet' => 'PIN establecido',
			'profiles.changePin' => 'Cambiar',
			'profiles.removePin' => 'Eliminar',
			'profiles.connectionsLabel' => 'Conexiones',
			'profiles.add' => 'Añadir',
			'profiles.deleteProfileButton' => 'Eliminar perfil',
			'profiles.noConnectionsHint' => 'Sin conexiones — añade una para usar este perfil.',
			'profiles.noConnections' => 'Sin conexiones',
			'profiles.plexHomeAccount' => 'Cuenta Plex Home',
			'profiles.connectionDefault' => 'Predeterminada',
			'profiles.connectionAs' => ({required Object displayName}) => 'como ${displayName}',
			'profiles.makeDefault' => 'Establecer como predeterminada',
			'profiles.removeConnection' => 'Eliminar',
			'profiles.profileRenamed' => 'Se cambió el nombre del perfil.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Añadir a ${displayName}',
			'profiles.borrowExplain' => 'Toma prestada la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.',
			'profiles.borrowEmpty' => 'Todavía no hay ninguna conexión que tomar prestada.',
			'profiles.borrowEmptySubtitle' => 'Conecta primero Plex o Jellyfin a otro perfil.',
			'profiles.borrowLoadFailed' => 'No se pudieron cargar las conexiones disponibles. Inténtalo de nuevo.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Conexión tomada prestada.',
			'profiles.borrowFailed' => 'No se pudo tomar prestada la conexión.',
			'profiles.incorrectPin' => 'PIN incorrecto.',
			'profiles.incorrectPinTryAgain' => 'PIN incorrecto. Inténtalo de nuevo.',
			'profiles.sourceProfileMissingParentAccount' => 'Al perfil de origen le falta su cuenta principal.',
			'profiles.failedToLoadHomeUsers' => 'No se pudieron cargar tus usuarios de Plex Home. Comprueba tu conexión e inténtalo de nuevo.',
			'profiles.failedToVerifyPin' => 'No se pudo verificar el PIN.',
			'profiles.newProfile' => 'Nuevo perfil',
			'profiles.profileNameHint' => 'p. ej., Invitados, Niños, Sala familiar',
			'profiles.pinProtectionOptional' => 'Protección con PIN (opcional)',
			'profiles.pinExplain' => 'Se requiere PIN de 4 dígitos para cambiar de perfil.',
			'profiles.continueButton' => 'Continuar',
			'profiles.pinsDontMatch' => 'Los PIN no coinciden',
			'connections.sectionTitle' => 'Conexiones',
			'connections.addConnection' => 'Añadir conexión',
			'connections.addConnectionSubtitleNoProfile' => 'Inicia sesión con Plex o conecta un servidor de Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Añadir a ${displayName}: Plex, Jellyfin u otra conexión de perfil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sesión caducada para ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sesión caducada para ${count} servidores',
			'connections.signInAgain' => 'Iniciar sesión de nuevo',
			'connections.editJellyfinTitle' => 'Editar conexión de Jellyfin',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Añade o elimina direcciones URL para ${serverName}. Plezy usará la dirección accesible con menor latencia.',
			'discover.title' => 'Descubrir',
			'discover.noContentAvailable' => 'No hay contenido disponible',
			'discover.addMediaToLibraries' => 'Añade contenido a tus bibliotecas',
			'discover.continueWatching' => 'Seguir viendo',
			'discover.continueWatchingIn' => ({required Object library}) => 'Seguir viendo en ${library}',
			'discover.nextUp' => 'A continuación',
			'discover.nextUpIn' => ({required Object library}) => 'A continuación en ${library}',
			'discover.recentlyAdded' => 'Añadido recientemente',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Añadido recientemente en ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Últimos álbumes en ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Reproducido recientemente en ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Más reproducido en ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'T${season}E${episode}',
			'discover.overview' => 'Resumen',
			'discover.cast' => 'Reparto',
			'discover.extras' => 'Tráilers y extras',
			'discover.studio' => 'Estudio',
			'discover.rating' => 'Valoración',
			'discover.director' => 'Director',
			'discover.directors' => 'Directores',
			'discover.movie' => 'Película',
			'discover.tvShow' => 'Serie de TV',
			'discover.minutesLeft' => ({required Object minutes}) => 'quedan ${minutes} min',
			'discover.moreLikeThis' => 'Más contenido similar',
			'errors.searchFailed' => ({required Object error}) => 'Error en la búsqueda: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tiempo de conexión agotado al cargar ${context}',
			'errors.connectionFailed' => 'No se puede conectar al servidor multimedia',
			'errors.unableToLoad' => ({required Object context}) => 'No se pudo cargar ${context}. Inténtalo de nuevo.',
			'errors.noClientAvailable' => 'No hay cliente disponible',
			'errors.pleaseEnterToken' => 'Introduce un token',
			'errors.invalidToken' => 'Token no válido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Error al verificar el token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Error al cambiar al perfil ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Error al eliminar ${displayName}',
			'errors.failedToRate' => 'No se pudo actualizar la valoración',
			'libraries.title' => 'Bibliotecas',
			'libraries.fallbackTitle' => 'Biblioteca',
			'libraries.scanLibraryFiles' => 'Escanear archivos de la biblioteca',
			'libraries.scanLibrary' => 'Escanear biblioteca',
			'libraries.analyze' => 'Analizar',
			'libraries.analyzeLibrary' => 'Analizar biblioteca',
			'libraries.refreshMetadata' => 'Actualizar metadatos',
			'libraries.emptyTrash' => 'Vaciar papelera',
			'libraries.emptyingTrash' => ({required Object title}) => 'Vaciando papelera de "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papelera vaciada para "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Error al vaciar papelera: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analizando "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Análisis iniciado para "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Error al analizar la biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'No se encontraron bibliotecas',
			'libraries.allLibrariesHidden' => 'Todas las bibliotecas están ocultas',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliotecas ocultas (${count})',
			'libraries.thisLibraryIsEmpty' => 'Esta biblioteca está vacía',
			'libraries.noItemsMatchFilters' => 'Ningún elemento coincide con los filtros activos',
			'libraries.resetFilters' => 'Restablecer filtros',
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Borrar todo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '¿Estás seguro de que quieres escanear "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '¿Estás seguro de que quieres analizar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '¿Estás seguro de que quieres actualizar los metadatos de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '¿Estás seguro de que quieres vaciar la papelera de "${title}"?',
			'libraries.manageLibraries' => 'Gestionar bibliotecas',
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
			'libraries.tabs.playlists' => 'Listas de reproducción',
			'libraries.groupings.title' => 'Agrupación',
			'libraries.groupings.all' => 'Todo',
			'libraries.groupings.movies' => 'Películas',
			'libraries.groupings.shows' => 'Series',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episodios',
			'libraries.groupings.artists' => 'Artistas',
			'libraries.groupings.albums' => 'Álbumes',
			'libraries.groupings.tracks' => 'Canciones',
			'libraries.groupings.folders' => 'Carpetas',
			'libraries.filterCategories.genre' => 'Género',
			'libraries.filterCategories.year' => 'Año',
			'libraries.filterCategories.contentRating' => 'Clasificación por edad',
			'libraries.filterCategories.tag' => 'Etiqueta',
			'libraries.filterCategories.unwatched' => 'No vistos',
			'libraries.filterCategories.unplayed' => 'No reproducidos',
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Fecha de adición',
			'libraries.sortLabels.releaseDate' => 'Fecha de estreno',
			'libraries.sortLabels.rating' => 'Valoración',
			'libraries.sortLabels.communityRating' => 'Valoración de la comunidad',
			'libraries.sortLabels.criticRating' => 'Valoración de la crítica',
			'libraries.sortLabels.userRating' => 'Valoración del usuario',
			'libraries.sortLabels.datePlayed' => 'Fecha de reproducción',
			'libraries.sortLabels.playCount' => 'Reproducciones',
			'libraries.sortLabels.productionYear' => 'Año de producción',
			'libraries.sortLabels.runtime' => 'Duración',
			'libraries.sortLabels.officialRating' => 'Clasificación oficial',
			'libraries.sortLabels.premiereDate' => 'Fecha de estreno',
			'libraries.sortLabels.startDate' => 'Fecha de inicio',
			'libraries.sortLabels.airTime' => 'Hora de emisión',
			'libraries.sortLabels.studio' => 'Estudio',
			'libraries.sortLabels.random' => 'Aleatorio',
			'libraries.sortLabels.dateShared' => 'Fecha en que se compartió',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Fecha de emisión del episodio más reciente',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Fecha en que se añadió el último episodio',
			'about.title' => 'Acerca de',
			'about.openSourceLicenses' => 'Licencias de código abierto',
			'about.versionLabel' => ({required Object version}) => 'Versión ${version}',
			'about.appDescription' => 'Un cliente de Plex y Jellyfin para Flutter',
			'about.viewLicensesDescription' => 'Ver las licencias de bibliotecas de terceros',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'No se encontraron servidores para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Error al cargar servidores: ${error}',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Año de lanzamiento',
			'hubDetail.dateAdded' => 'Añadido el',
			'hubDetail.rating' => 'Valoración',
			'hubDetail.noItemsFound' => 'No se encontraron elementos',
			'logs.clearLogs' => 'Borrar registros',
			'logs.copyLogs' => 'Copiar registros',
			'logs.uploadLogs' => 'Subir registros',
			'licenses.relatedPackages' => 'Paquetes relacionados',
			'licenses.license' => 'Licencia',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencia ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licencias',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Descargas',
			'navigation.liveTv' => 'TV en vivo',
			'navigation.explore' => 'Explorar',
			'explore.title' => 'Explorar',
			'explore.selectSource' => 'Seleccionar fuente',
			'explore.rows.watchlist' => 'Lista de seguimiento',
			'explore.rows.recommendedMovies' => 'Películas recomendadas',
			'explore.rows.recommendedShows' => 'Series recomendadas',
			'explore.rows.trendingMovies' => 'Películas en tendencia',
			'explore.rows.trendingShows' => 'Series en tendencia',
			'explore.rows.popularMovies' => 'Películas populares',
			'explore.rows.popularShows' => 'Series populares',
			'explore.rows.trendingAnime' => 'Anime en tendencia',
			'explore.rows.suggestedAnime' => 'Anime sugerido',
			'explore.rows.airingAnime' => 'Mejor anime en emisión',
			'explore.rows.popularAnime' => 'Anime más popular',
			'explore.rows.trending' => 'Tendencias',
			'explore.rows.upcomingMovies' => 'Próximas películas',
			'explore.rows.upcomingShows' => 'Próximas series',
			'explore.status.airing' => 'En emisión',
			'explore.status.ended' => 'Finalizada',
			'explore.status.canceled' => 'Cancelada',
			'explore.status.upcoming' => 'Próximamente',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} episodio', other: '${n} episodios', ), 
			'explore.cast' => 'Reparto',
			'explore.characters' => 'Personajes',
			'explore.addToWatchlist' => 'Añadir a la lista de seguimiento',
			'explore.removeFromWatchlist' => 'Quitar de la lista de seguimiento',
			'explore.watchlistUpdateFailed' => 'No se pudo actualizar la lista de seguimiento',
			'explore.notInLibrary' => 'No está en tu biblioteca',
			'explore.inTheseLibraries' => 'En estas bibliotecas',
			'explore.checkingLibrary' => 'Comprobando tu biblioteca...',
			'explore.emptyTitle' => 'Aquí no hay nada todavía',
			'explore.emptyMessage' => ({required Object source}) => 'Las filas de ${source} aparecerán aquí cuando tengan contenido.',
			'explore.searchHint' => ({required Object source}) => 'Buscar en ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Sin resultados para "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Busca películas y series en ${source}.',
			'explore.searchFailed' => 'La búsqueda falló. Comprueba tu conexión e inténtalo de nuevo.',
			'liveTv.title' => 'TV en vivo',
			'liveTv.guide' => 'Guía',
			'liveTv.noChannels' => 'No hay canales disponibles',
			'liveTv.noDvr' => 'No hay DVR configurado en ningún servidor',
			'liveTv.serverUnavailable' => 'El servidor de TV en vivo no está disponible.',
			'liveTv.serverNotConnected' => 'El servidor de TV en vivo no está conectado.',
			'liveTv.noPrograms' => 'No hay datos de programación disponibles',
			'liveTv.liveStreamFailed' => 'Falló la transmisión en vivo',
			'liveTv.unknownProgram' => 'Programa desconocido',
			'liveTv.unknownHub' => 'Desconocido',
			'liveTv.unknownError' => 'Error desconocido',
			'liveTv.channelNumber' => ({required Object number}) => 'Canal ${number}',
			'liveTv.unknownChannel' => 'Canal desconocido',
			'liveTv.live' => 'EN VIVO',
			'liveTv.reloadGuide' => 'Recargar guía',
			'liveTv.now' => 'Ahora',
			'liveTv.today' => 'Hoy',
			'liveTv.tomorrow' => 'Mañana',
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
			'liveTv.favoritesLoadFailed' => 'No se pudieron cargar los favoritos. Comprueba tu conexión e inténtalo de nuevo.',
			'liveTv.favoritesUpdateFailed' => 'No se pudieron actualizar los favoritos. Comprueba tu conexión e inténtalo de nuevo.',
			'liveTv.joinSession' => 'Unirse a sesión en curso',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Ver desde el inicio (hace ${minutes} min)',
			'liveTv.watchLive' => 'Ver en vivo',
			'liveTv.goToLive' => 'Ir a la emisión en vivo',
			'liveTv.record' => 'Grabar',
			'liveTv.recordEpisode' => 'Grabar episodio',
			'liveTv.recordSeries' => 'Grabar serie',
			'liveTv.recordOptions' => 'Opciones de grabación',
			'liveTv.saveTo' => 'Guardar en',
			'liveTv.recordings' => 'Grabaciones',
			'liveTv.scheduledRecordings' => 'Programadas',
			'liveTv.recordingRules' => 'Reglas de grabación',
			'liveTv.noScheduledRecordings' => 'No hay grabaciones programadas',
			'liveTv.manageRecording' => 'Gestionar grabación',
			'liveTv.cancelRecording' => 'Cancelar grabación',
			'liveTv.cancelRecordingTitle' => '¿Cancelar esta grabación?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} ya no se grabará.',
			'liveTv.deleteRule' => 'Eliminar regla',
			'liveTv.deleteRuleTitle' => '¿Eliminar regla de grabación?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Los próximos episodios de ${title} no se grabarán.',
			'liveTv.recordingScheduled' => 'Grabación programada',
			'liveTv.alreadyScheduled' => 'Este programa ya está programado',
			'liveTv.dvrAdminRequired' => 'La configuración DVR requiere una cuenta de administrador',
			'liveTv.recordingFailed' => 'No se pudo programar la grabación',
			'liveTv.recordingTargetMissing' => 'No se pudo determinar la biblioteca de grabación',
			'liveTv.recordNotAvailable' => 'Grabación no disponible para este programa',
			'liveTv.recordingCancelled' => 'Grabación cancelada',
			'liveTv.recordingRuleDeleted' => 'Regla de grabación eliminada',
			'liveTv.processRecordingRules' => 'Reevaluar reglas',
			'liveTv.recordingInProgress' => 'Grabando ahora',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} programadas',
			'liveTv.editRule' => 'Editar regla',
			'liveTv.editRuleAction' => 'Editar',
			'liveTv.recordingRuleUpdated' => 'Regla de grabación actualizada',
			'liveTv.guideReloadRequested' => 'Solicitada actualización de la guía',
			'liveTv.rulesProcessRequested' => 'Solicitada reevaluación de reglas',
			'liveTv.recordShow' => 'Grabar programa',
			'collections.title' => 'Colecciones',
			'collections.collection' => 'Colección',
			'collections.empty' => 'La colección está vacía',
			'collections.deleteCollection' => 'Eliminar colección',
			'collections.deleteConfirm' => ({required Object title}) => '¿Eliminar "${title}"? No se puede deshacer.',
			'collections.deleted' => 'Colección eliminada',
			'collections.deleteFailed' => 'Error al eliminar la colección',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Error al eliminar la colección: ${error}',
			'collections.selectCollection' => 'Seleccionar colección',
			'collections.collectionName' => 'Nombre de la colección',
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
			'playlists.create' => 'Crear lista de reproducción',
			'playlists.playlistName' => 'Nombre de la lista de reproducción',
			'playlists.enterPlaylistName' => 'Introduce el nombre de la lista de reproducción',
			'playlists.delete' => 'Eliminar lista de reproducción',
			'playlists.removeItem' => 'Eliminar de la lista de reproducción',
			'playlists.smartPlaylist' => 'Lista de reproducción inteligente',
			'playlists.itemCount' => ({required Object count}) => '${count} elementos',
			'playlists.oneItem' => '1 elemento',
			'playlists.emptyPlaylist' => 'Esta lista de reproducción está vacía',
			'playlists.deleteConfirm' => '¿Eliminar lista de reproducción?',
			'playlists.deleteMessage' => ({required Object name}) => '¿Estás seguro de que quieres eliminar "${name}"?',
			'playlists.created' => 'Lista de reproducción creada',
			'playlists.deleted' => 'Lista de reproducción eliminada',
			'playlists.itemAdded' => 'Añadido a la lista de reproducción',
			'playlists.itemRemoved' => 'Eliminado de la lista de reproducción',
			'playlists.selectPlaylist' => 'Seleccionar lista de reproducción',
			'playlists.searchPlaylists' => 'Buscar listas de reproducción...',
			'playlists.errorCreating' => 'Error al crear la lista de reproducción',
			'playlists.errorDeleting' => 'Error al eliminar la lista de reproducción',
			'playlists.errorLoading' => 'Error al cargar las listas de reproducción',
			'playlists.errorAdding' => 'Error al añadir a la lista de reproducción',
			'playlists.errorReordering' => 'Error al reordenar el elemento de la lista de reproducción',
			'playlists.errorRemoving' => 'Error al eliminar de la lista de reproducción',
			'music.goToAlbum' => 'Ir al álbum',
			'music.goToArtist' => 'Ir al artista',
			'music.instantMix' => 'Mezcla instantánea',
			'music.playNext' => 'Reproducir a continuación',
			'music.addToQueue' => 'Añadir a la cola',
			'music.discNumber' => ({required Object n}) => 'Disco ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} canción', other: '${n} canciones', ), 
			'music.nowPlaying' => 'Reproduciendo ahora',
			'music.playingFrom' => ({required Object title}) => 'Reproduciendo desde ${title}',
			'music.queue' => 'Cola',
			'music.clearQueue' => 'Vaciar la cola',
			'music.lyrics' => 'Letra',
			'music.noLyrics' => 'No hay letra disponible',
			'music.sleepTimer' => 'Temporizador de apagado',
			'music.sleepTimerEndOfTrack' => 'Fin de la canción',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutos',
			'music.stopPlayback' => 'Detener reproducción',
			'music.previousTrack' => 'Canción anterior',
			'music.nextTrack' => 'Canción siguiente',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir todo',
			'music.repeatOne' => 'Repetir una',
			'watchTogether.title' => 'Ver juntos',
			'watchTogether.description' => 'Mira contenido sincronizado con amigos y familiares',
			'watchTogether.createSession' => 'Crear sesión',
			'watchTogether.creating' => 'Creando...',
			'watchTogether.joinSession' => 'Unirse a una sesión',
			'watchTogether.joining' => 'Conectando...',
			'watchTogether.controlMode' => 'Modo de control',
			'watchTogether.controlModeQuestion' => '¿Quién puede controlar la reproducción?',
			'watchTogether.hostOnly' => 'Solo el anfitrión',
			'watchTogether.anyone' => 'Cualquiera',
			'watchTogether.hostingSession' => 'Sesión alojada',
			'watchTogether.inSession' => 'En una sesión',
			'watchTogether.sessionCode' => 'Código de sesión',
			'watchTogether.openSessionControls' => 'Abrir los controles de la sesión de Ver juntos',
			'watchTogether.copySessionCode' => 'Copiar código de sesión',
			'watchTogether.hostControlsPlayback' => 'El anfitrión controla la reproducción',
			'watchTogether.anyoneCanControl' => 'Cualquiera puede controlar la reproducción',
			'watchTogether.hostControls' => 'Control del anfitrión',
			'watchTogether.anyoneControls' => 'Control de cualquiera',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.host' => 'Anfitrión',
			'watchTogether.hostBadge' => 'ANFITRIÓN',
			'watchTogether.youAreHost' => 'Eres el anfitrión',
			'watchTogether.watchingWithOthers' => 'Viendo contenido con otras personas',
			'watchTogether.endSession' => 'Finalizar sesión',
			'watchTogether.leaveSession' => 'Salir de la sesión',
			'watchTogether.endSessionQuestion' => '¿Finalizar la sesión?',
			'watchTogether.leaveSessionQuestion' => '¿Salir de la sesión?',
			'watchTogether.endSessionConfirm' => 'Esto finalizará la sesión para todos los participantes.',
			'watchTogether.leaveSessionConfirm' => 'Saldrás de la sesión.',
			'watchTogether.endSessionConfirmOverlay' => 'Esto finalizará la sesión de reproducción para todos los participantes.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Te desconectarás de la sesión de reproducción.',
			'watchTogether.end' => 'Finalizar',
			'watchTogether.leave' => 'Salir',
			'watchTogether.syncing' => 'Sincronizando...',
			'watchTogether.joinWatchSession' => 'Unirse a una sesión de reproducción',
			'watchTogether.enterCodeHint' => 'Introduce el código de 5 caracteres',
			'watchTogether.pasteFromClipboard' => 'Pegar desde el portapapeles',
			'watchTogether.pleaseEnterCode' => 'Introduce un código de sesión',
			'watchTogether.codeMustBe5Chars' => 'El código de sesión debe tener 5 caracteres',
			'watchTogether.joinInstructions' => 'Introduce el código de sesión del anfitrión para unirte.',
			'watchTogether.failedToCreate' => 'Error al crear la sesión',
			'watchTogether.failedToJoin' => 'Error al unirse a la sesión',
			'watchTogether.sessionCodeCopied' => 'Código de sesión copiado al portapapeles',
			'watchTogether.relayUnreachable' => 'No se puede acceder al servidor de retransmisión. Es posible que tu proveedor de internet esté bloqueando Ver juntos.',
			'watchTogether.reconnectingToHost' => 'Reconectando con el anfitrión...',
			_ => null,
		} ?? switch (path) {
			'watchTogether.currentPlayback' => 'Reproducción actual',
			'watchTogether.joinCurrentPlayback' => 'Unirse a la reproducción actual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Vuelve a lo que el anfitrión está viendo ahora mismo',
			'watchTogether.failedToOpenCurrentPlayback' => 'No se pudo abrir la reproducción actual',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} se unió',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} se fue',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pausó',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} reanudó',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} cambió la posición de reproducción',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} está almacenando en búfer',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} usa una versión anterior de la aplicación — sincronización no disponible',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Reanudando sin ${name}',
			'watchTogether.waitingForParticipants' => 'Esperando a que los demás carguen el contenido...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Esperando a ${name}...',
			'watchTogether.recentRooms' => 'Salas recientes',
			'watchTogether.renameRoom' => 'Renombrar sala',
			'watchTogether.removeRoom' => 'Eliminar',
			'watchTogether.guestSwitchUnavailable' => 'No se pudo cambiar — servidor no disponible para sincronización',
			'watchTogether.guestSwitchFailed' => 'No se pudo cambiar — contenido no encontrado en este servidor',
			'downloads.title' => 'Descargas',
			'downloads.manage' => 'Gestionar',
			'downloads.tvShows' => 'Series de TV',
			'downloads.movies' => 'Películas',
			'downloads.music' => 'Música',
			'downloads.tracksQueued' => ({required Object count}) => '${count} canciones en cola para descargar',
			'downloads.noDownloads' => 'No hay descargas aún',
			'downloads.noDownloadsDescription' => 'El contenido descargado aparecerá aquí para verlo sin conexión',
			'downloads.downloadNow' => 'Descargar',
			'downloads.deleteDownload' => 'Eliminar descarga',
			'downloads.retryDownload' => 'Reintentar descarga',
			'downloads.downloadQueued' => 'Descarga en cola',
			'downloads.downloadResumed' => 'Descarga reanudada',
			'downloads.serverErrorBitrate' => 'Error del servidor: el archivo puede superar el límite remoto de tasa de bits',
			'downloads.storageFull' => 'Las descargas se detuvieron porque el almacenamiento del dispositivo está lleno. Libera espacio e inténtalo de nuevo.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodios en cola para descargar',
			'downloads.downloadDeleted' => 'Descarga eliminada',
			'downloads.deleteConfirm' => ({required Object title}) => '¿Eliminar "${title}" de este dispositivo?',
			'downloads.cancelledDownloadTitle' => 'Descarga cancelada',
			'downloads.cancelledDownloadMessage' => 'Esta descarga se canceló. ¿Qué quieres hacer?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Todos los episodios ya están descargados',
			'downloads.resumeDownload' => 'Reanudar descarga',
			'downloads.cancelledDownload' => 'Descarga cancelada',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (sincronizando ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} descargado — haz clic para completar',
			'downloads.partialDownloadClickToComplete' => 'Descarga parcial — haz clic para completar',
			'downloads.deleting' => 'Eliminando...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})',
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
			'downloads.includeSpecials' => 'Incluir especiales',
			'downloads.howManyEpisodes' => '¿Cuántos episodios?',
			'downloads.invalidEpisodeCount' => 'Introduce un número de episodios válido.',
			'downloads.keepSynced' => 'Mantener sincronizado',
			'downloads.downloadOnce' => 'Descargar una vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Mantener ${count} no vistos',
			'downloads.editSyncRule' => 'Editar regla de sincronización',
			'downloads.removeSyncRule' => 'Eliminar regla de sincronización',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '¿Dejar de sincronizar "${title}"? Los episodios descargados se conservarán.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regla de sincronización creada — se conservarán ${count} episodios no vistos',
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
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Servidor: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponible',
			'downloads.syncRuleOffline' => 'Sin conexión',
			'downloads.syncRuleSignInRequired' => 'Se requiere iniciar sesión',
			'downloads.syncRuleNotAvailableForProfile' => 'No disponible para el perfil actual',
			'downloads.syncRuleUnknownServer' => 'Servidor desconocido',
			'downloads.syncRuleListCreated' => 'Regla de sincronización creada',
			'downloads.backgroundWarning.bannerBlocked' => 'Las descargas se detendrán al salir de la app',
			'downloads.backgroundWarning.bannerDegraded' => 'Las descargas en segundo plano pueden estar limitadas',
			'downloads.backgroundWarning.bannerAction' => 'Detalles',
			'downloads.backgroundWarning.sheetTitle' => 'Las descargas en segundo plano están bloqueadas',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Las descargas en segundo plano pueden estar limitadas',
			'downloads.backgroundWarning.sheetIntro' => 'Android impide que Plezy descargue de forma fiable en segundo plano.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Tu dispositivo limita cuándo puede descargar Plezy en segundo plano.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'El uso en segundo plano de Plezy está restringido. Configura el uso de batería o en segundo plano como "Sin restricciones".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android ha puesto a Plezy en un estado de espera restringido. Configura el uso de batería como "Sin restricciones".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Las notificaciones de descargas están desactivadas, por lo que el progreso y los controles podrían no estar disponibles.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Las notificaciones están desactivadas. En Android 13 o versiones posteriores, son necesarias para las descargas largas en segundo plano.',
			'downloads.backgroundWarning.reasonDataSaver' => 'El Ahorro de datos está activado y bloquea las descargas en segundo plano con datos móviles. Las descargas deberían seguir funcionando con Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Las descargas se detuvieron repetidamente mientras Plezy estaba en segundo plano. Revisa la configuración de batería o de uso en segundo plano de Plezy.',
			'downloads.backgroundWarning.openSettings' => 'Abrir configuración',
			'downloads.backgroundWarning.stillNotWorking' => 'Ayuda específica para tu dispositivo',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Consulta los pasos para tu dispositivo o envía un registro desde Configuración › Ver registros si el problema continúa.',
			'downloads.backgroundWarning.dialogTitle' => 'Es posible que las descargas no finalicen',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Descargar de todos modos',
			'downloads.backgroundWarning.dialogFixFirst' => 'Solucionarlo primero',
			'downloads.backgroundWarning.statusTile' => 'Descargas en segundo plano',
			'downloads.backgroundWarning.statusOk' => 'Permitidas en segundo plano',
			'downloads.backgroundWarning.statusBlocked' => 'Bloqueadas por la configuración del sistema',
			'downloads.backgroundWarning.statusDegraded' => 'Limitadas por la configuración del sistema',
			'downloads.backgroundWarning.statusUnknown' => 'Aún no se ha comprobado',
			'downloads.backgroundWarning.settingsUnavailable' => 'No se pudo abrir la configuración del sistema en este dispositivo',
			'downloads.backgroundWarning.linkUnavailable' => 'No se pudo abrir dontkillmyapp.com en este dispositivo',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sin mejora de video',
			'shaders.nvscalerDescription' => 'Escalado de imagen NVIDIA para un video más nítido',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Reducción de ruido',
			'shaders.artcnnVariantDenoiseSharpen' => 'Reducción de ruido + enfoque',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta calidad',
			'shaders.mode' => 'Modo',
			'shaders.importShader' => 'Importar shader',
			'shaders.customShaderDescription' => 'Shader GLSL personalizado',
			'shaders.shaderImported' => 'Shader importado',
			'shaders.shaderImportFailed' => 'Error al importar shader',
			'shaders.deleteShader' => 'Eliminar shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '¿Eliminar "${name}"?',
			'companionRemote.title' => 'Control remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.unknownDevice' => 'Dispositivo desconocido',
			'companionRemote.session.startingServer' => 'Iniciando servidor remoto...',
			'companionRemote.session.hostAddress' => 'Dirección del host',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.serverRunning' => 'Servidor remoto activo',
			'companionRemote.session.serverStopped' => 'Servidor remoto detenido',
			'companionRemote.session.serverRunningDescription' => 'Los dispositivos móviles de tu red pueden conectarse a esta aplicación',
			'companionRemote.session.serverStoppedDescription' => 'Inicia el servidor para permitir que los dispositivos móviles se conecten',
			'companionRemote.session.usePhoneToControl' => 'Usa tu dispositivo móvil para controlar esta aplicación',
			'companionRemote.session.startServer' => 'Iniciar servidor',
			'companionRemote.session.stopServer' => 'Detener servidor',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.pairing.discoveryDescription' => 'Los dispositivos Plezy con la misma cuenta Plex aparecen aquí',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.searchingForDevices' => 'Buscando dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'No se encontraron dispositivos en tu red',
			'companionRemote.pairing.noDevicesHint' => 'Abre Plezy en tu equipo y usa la misma red WiFi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponibles',
			'companionRemote.pairing.manualConnection' => 'Conexión manual',
			'companionRemote.pairing.cryptoInitFailed' => 'No se pudo iniciar la conexión segura. Inicia sesión en Plex primero.',
			'companionRemote.pairing.validationHostRequired' => 'Introduce la dirección del host',
			'companionRemote.pairing.validationHostFormat' => 'El formato debe ser IP:puerto (p. ej., 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tiempo de conexión agotado. Usa la misma red en ambos dispositivos.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo no encontrado. Asegúrate de que Plezy esté en ejecución en el host.',
			'companionRemote.pairing.authFailed' => 'Autenticación fallida. Ambos dispositivos necesitan la misma cuenta Plex.',
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
			'companionRemote.errors.noNetworkInterface' => 'No se encontró ninguna interfaz de red',
			'companionRemote.errors.authenticationFailed' => 'Autenticación fallida',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'No se pudo iniciar el servidor remoto: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'No se pudo enviar el comando remoto: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Se agotó el tiempo al unirse a la sesión',
			'companionRemote.errors.failedToConnectAnyAddress' => 'No se pudo conectar a ninguna dirección',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Conexión perdida tras ${attempts} intentos',
			'companionRemote.errors.connectionLost' => 'Conexión perdida',
			'videoSettings.playbackSpeed' => 'Velocidad de reproducción',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Activo (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Temporizador de apagado',
			'videoSettings.audioSync' => 'Sincronización de audio',
			'videoSettings.subtitleSync' => 'Sincronización de subtítulos',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Salida de audio',
			'videoSettings.performanceOverlay' => 'Indicador de rendimiento',
			'videoSettings.audioPassthrough' => 'Transferencia directa de audio',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Envolvente',
			'videoSettings.audioOutputSpatial' => 'Audio espacial',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioNormalization' => 'Normalizar volumen',
			'videoSettings.audioDownmix' => 'Mezclar a estéreo',
			'performanceOverlay.color' => 'Color',
			'performanceOverlay.performance' => 'Rendimiento',
			'performanceOverlay.buffer' => 'Búfer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decodificador',
			'performanceOverlay.rawDecoder' => 'Decodificador sin procesar',
			'performanceOverlay.tunneling' => 'Túnel',
			'performanceOverlay.aspect' => 'Aspecto',
			'performanceOverlay.rotation' => 'Rotación',
			'performanceOverlay.dvSource' => 'Origen DV',
			'performanceOverlay.dvPath' => 'Ruta DV',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Frecuencia de muestreo',
			'performanceOverlay.pixelFormat' => 'Formato de píxel',
			'performanceOverlay.hwFormat' => 'Formato HW',
			'performanceOverlay.matrix' => 'Matriz',
			'performanceOverlay.primaries' => 'Primarios',
			'performanceOverlay.transfer' => 'Transferencia',
			'performanceOverlay.renderFps' => 'FPS render',
			'performanceOverlay.displayFps' => 'FPS pantalla',
			'performanceOverlay.avSync' => 'Sincronía A/V',
			'performanceOverlay.dropped' => 'Descartados',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'Prom. DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Prom. muestra DV',
			'performanceOverlay.maxLuma' => 'Luma máx.',
			'performanceOverlay.minLuma' => 'Luma mín.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Caché usada',
			'performanceOverlay.cacheLimit' => 'Límite de caché',
			'performanceOverlay.speed' => 'Velocidad',
			'performanceOverlay.player' => 'Reproductor',
			'performanceOverlay.memory' => 'Memoria',
			'performanceOverlay.uiFps' => 'FPS UI',
			'externalPlayer.title' => 'Reproductor externo',
			'externalPlayer.useExternalPlayer' => 'Usar reproductor externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir videos en otra aplicación',
			'externalPlayer.selectPlayer' => 'Seleccionar reproductor',
			'externalPlayer.customPlayers' => 'Reproductores personalizados',
			'externalPlayer.systemDefault' => 'Predeterminado del sistema',
			'externalPlayer.addCustomPlayer' => 'Añadir reproductor personalizado',
			'externalPlayer.playerName' => 'Nombre del reproductor',
			'externalPlayer.playerNameHint' => 'Mi reproductor',
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
			'metadataEdit.artwork' => 'Imágenes',
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
			'metadataEdit.artworkUpdated' => 'Imágenes actualizadas',
			'metadataEdit.artworkUpdateFailed' => 'Error al actualizar las imágenes',
			'metadataEdit.noArtworkAvailable' => 'No hay imágenes disponibles',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opción de imagen ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opción de imagen ${index}, seleccionada',
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
			'matchScreen.match' => 'Asociar...',
			'matchScreen.fixMatch' => 'Corregir asociación...',
			'matchScreen.unmatch' => 'Desasociar',
			'matchScreen.unmatchConfirm' => '¿Borrar esta asociación? Plex tratará el elemento como no asociado hasta que vuelvas a asociarlo.',
			'matchScreen.unmatchSuccess' => 'Elemento desasociado',
			'matchScreen.unmatchFailed' => 'No se pudo desasociar el elemento',
			'matchScreen.matchApplied' => 'Asociación aplicada',
			'matchScreen.matchFailed' => 'No se pudo aplicar la asociación',
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
			'trakt.disconnectConfirmBody' => 'Plezy dejará de enviar eventos a Trakt. Puedes reconectar cuando quieras.',
			'trakt.scrobble' => 'Scrobbling en tiempo real',
			'trakt.scrobbleDescription' => 'Enviar eventos de reproducción, pausa y parada a Trakt durante la reproducción.',
			'trakt.watchedSync' => 'Sincronizar el estado de visualización',
			'trakt.watchedSyncDescription' => 'Cuando marques contenido como visto en Plezy, también se marcará como visto en Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Conectar Seerr',
			'seerr.serverUrl' => 'URL del servidor',
			'seerr.serverUrlHelper' => 'La dirección de tu instancia de Seerr',
			'seerr.checkServer' => 'Continuar',
			'seerr.signInWithJellyfin' => 'Iniciar sesión con Jellyfin',
			'seerr.signInWithEmby' => 'Iniciar sesión con Emby',
			'seerr.signInWithLocal' => 'Usar una cuenta local',
			'seerr.email' => 'Correo electrónico',
			'seerr.noSignInMethods' => 'Esta instancia de Seerr no ofrece ningún método de inicio de sesión compatible con Plezy.',
			'seerr.instance' => 'Instancia',
			'seerr.disconnectConfirm' => '¿Desconectar Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy olvidará esta instancia de Seerr. Reconecta cuando quieras.',
			'seerr.request' => 'Solicitar',
			'seerr.request4k' => 'Solicitar en 4K',
			'seerr.seasons' => 'Temporadas',
			'seerr.allSeasons' => 'Todas las temporadas',
			'seerr.advancedOptions' => 'Avanzado',
			'seerr.destinationServer' => 'Servidor de destino',
			'seerr.qualityProfile' => 'Perfil de calidad',
			'seerr.rootFolder' => 'Carpeta raíz',
			'seerr.languageProfile' => 'Perfil de idioma',
			'seerr.requestSubmitted' => 'Solicitud enviada',
			'seerr.requestFailed' => ({required Object error}) => 'La solicitud falló: ${error}',
			'seerr.requestsLoadFailed' => 'No se pudieron cargar las opciones de solicitud',
			'seerr.nothingToRequest' => 'Todo ya está disponible o solicitado.',
			'seerr.statusAvailable' => 'Disponible',
			'seerr.statusPartiallyAvailable' => 'Parcialmente disponible',
			'seerr.statusRequested' => 'Solicitado',
			'seerr.statusProcessing' => 'Procesando',
			'services.title' => 'Servicios',
			'services.hubSubtitle' => 'Sincroniza tu progreso de visualización y solicita nuevos títulos.',
			'services.notConnected' => 'No conectado',
			'services.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'services.scrobble' => 'Registrar progreso automáticamente',
			'services.scrobbleDescription' => 'Actualiza tu lista cuando termines un episodio o película.',
			'services.disconnectConfirm' => ({required Object service}) => '¿Desconectar ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy dejará de actualizar ${service}. Reconecta cuando quieras.',
			'services.connectFailed' => ({required Object service}) => 'No se pudo conectar a ${service}. Inténtalo de nuevo.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Activar Plezy en ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Visita ${url} e introduce este código:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para activar',
			'services.deviceCode.copyCode' => 'Copiar código de activación',
			'services.deviceCode.waitingForAuthorization' => 'Esperando autorización…',
			'services.deviceCode.codeCopied' => 'Código copiado',
			'services.oauthProxy.title' => ({required Object service}) => 'Inicia sesión en ${service}',
			'services.oauthProxy.body' => 'Escanea este código QR o abre la URL en cualquier dispositivo.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para iniciar sesión',
			'services.oauthProxy.copyUrl' => 'Copiar URL de inicio de sesión',
			'services.oauthProxy.urlCopied' => 'URL copiada',
			'services.libraryFilter.title' => 'Filtro de bibliotecas',
			'services.libraryFilter.subtitleAllSyncing' => 'Sincronizando todas las bibliotecas',
			'services.libraryFilter.subtitleNoneSyncing' => 'No se sincroniza ninguna biblioteca',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloqueadas',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} permitidas',
			'services.libraryFilter.mode' => 'Modo de filtro',
			'services.libraryFilter.modeBlacklist' => 'Lista de exclusión',
			'services.libraryFilter.modeWhitelist' => 'Lista de inclusión',
			'services.libraryFilter.modeHintBlacklist' => 'Sincronizar todas las bibliotecas excepto las seleccionadas abajo.',
			'services.libraryFilter.modeHintWhitelist' => 'Sincronizar solo las bibliotecas seleccionadas abajo.',
			'services.libraryFilter.libraries' => 'Bibliotecas',
			'services.libraryFilter.noLibraries' => 'No hay bibliotecas disponibles',
			'addServer.addJellyfinTitle' => 'Añadir servidor Jellyfin',
			'addServer.serverUrls' => 'Direcciones URL del servidor',
			'addServer.serverUrlsHelper' => 'Se permiten varias URL, separadas por comas.',
			'addServer.findServer' => 'Buscar servidor',
			'addServer.searchingLocalServers' => 'Buscando servidores Jellyfin locales...',
			'addServer.localServers' => 'Servidores Jellyfin locales',
			'addServer.username' => 'Usuario',
			'addServer.password' => 'Contraseña',
			'addServer.signIn' => 'Iniciar sesión',
			'addServer.change' => 'Cambiar',
			'addServer.required' => 'Obligatorio',
			'addServer.couldNotReachServer' => ({required Object error}) => 'No se pudo conectar con el servidor: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Error al iniciar sesión: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect ha fallado: ${error}',
			'addServer.addPlexTitle' => 'Iniciar sesión con Plex',
			'addServer.pinExpired' => 'El PIN caducó antes de iniciar sesión. Inténtalo de nuevo.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'No se pudo registrar la cuenta: ${error}',
			'addServer.enterJellyfinUrlError' => 'Introduce la URL de tu servidor Jellyfin',
			'addServer.addConnectionTitle' => 'Añadir conexión',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Añadir a ${name}',
			'addServer.signInWithPlexCard' => 'Iniciar sesión con Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoriza este dispositivo. Se añaden servidores compartidos.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoriza una cuenta Plex. Los usuarios de Home se convierten en perfiles.',
			'addServer.connectToJellyfinCard' => 'Conectar a Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Introduce la URL del servidor, usuario y contraseña.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Inicia sesión en un servidor Jellyfin. Se vincula a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Tomar prestado de otro perfil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Reutiliza la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.',
			_ => null,
		};
	}
}
