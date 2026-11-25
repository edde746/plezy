package com.edde746.plezy.presentation.player

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.Anime4kQuality
import com.edde746.plezy.playback.ArtCnnVariant
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.AudioDevice
import com.edde746.plezy.playback.AudioRendering
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlin.math.abs

/** What the options menu and the audio menu's settings show, from the store's plain values. */
internal object PlayerOptions {
    /** Everything [build] lists, as the store holds it. */
    data class Values(
        val fit: VideoFit,
        val zoom: Double,
        val sleepMinutes: Int?,
        val sleepAtEndOfVideo: Boolean,
        val sleepSecondsLeft: Int,
        /** The sleep timer's configured minutes (`sleep_timer_duration`), offered beside the standard ones; null for none. */
        val sleepDefaultMinutes: Int? = null,
        /** Null without a next episode: auto-play next isn't offered then. */
        val autoPlayNext: Boolean?,
        val locale: String,
        /** Watch Together while in a room: its entry opens the session sheet. */
        val watch: PlayerWatchUi? = null,
        /** The shader preset running; null where the player offers no shaders. */
        val shader: ShaderPreset? = null,
        /** The presets this device's renderer runs ([ShaderPreset.available]). */
        val shaders: List<ShaderPreset> = emptyList(),
        /** The Shaders page offers to import one: file dialogs, and a renderer that runs imported shaders. */
        val importsShaders: Boolean = false,
        /** The speed playing; null where the speed isn't offered (live, a guest in a host-only room). */
        val speed: Double? = null,
        /** The speed page's presets, ascending. */
        val speeds: List<Double> = emptyList(),
        /** The version and quality sheet; null where there is nothing to choose. */
        val versions: VersionsMenu? = null,
        /** The file's info can be opened (the server has it, not live). */
        val fileInfo: Boolean = false,
        /** The playback info shows ([PlaybackInfo]). */
        val playbackInfo: Boolean = false,
        /** Ambient lighting is on; null where the player doesn't run it. */
        val ambientLighting: Boolean? = null,
        /** HDR output as the switch shows it; null where the engine has no HDR control. */
        val hdr: Boolean? = null,
        /** The video playing is SDR: the HDR switch shows dimmed, "Not HDR". */
        val sdrVideo: Boolean = false,
        /** A development build's Dolby Vision Profile 7 conversion; null where it isn't offered. */
        val dolbyVisionConversion: DolbyVisionConversion? = null,
        /** A development build's simulated HTTP statuses are offered. */
        val httpStatus: Boolean = false,
    )

    /** The audio settings ([audio]), as the store holds them. */
    data class AudioValues(
        /**
         * The outputs to pick from, an empty list where none was found; null where the engine lists none (the platform
         * routes the audio: [com.edde746.plezy.playback.EngineFeatures.audioDevices]).
         */
        val audioDevices: List<AudioDevice>?,
        val audioDevice: String,
        val audioNormalization: Boolean,
        val audioChannels: AudioChannels,
        val locale: String,
        /** The device offers passthrough: the stereo limit says it turns passthrough off. */
        val passthroughSupported: Boolean = false,
        /** Passthrough is on (the device offers it and its setting is on): the normalization row says it turns it off. */
        val passthroughOn: Boolean = false,
        /** How the system renders the audio, where it knows ([com.edde746.plezy.playback.EngineState.audioRendering]). */
        val audioRendering: AudioRendering? = null,
    )

    /**
     * The options in Plezy's order: playback speed, zoom, version and quality, sleep timer, HDR, auto-play next, shaders,
     * file info, watch together, and a development build's Dolby Vision conversion and simulated HTTP status. Audio and
     * subtitle sync and the audio settings ([audio]) sit in the audio and subtitle menus.
     */
    fun build(values: Values): List<PlayerOption> = listOfNotNull(
        values.speed?.let { speed(it, values.speeds) },
        zoom(values.zoom),
        values.versions?.let(::versions),
        sleepTimer(values),
        values.hdr?.let { hdr ->
            switch(PlayerOptionId.HDR, T.videoSettings.hdr, hdr, adjusted = !hdr, PlayerCommand.SetHdr(!hdr))
                .let { if (values.sdrVideo) it.copy(enabled = false, detail = T.videoSettings.notHdr) else it }
        },
        values.autoPlayNext?.let { switch(PlayerOptionId.AUTO_PLAY_NEXT, T.player.options.autoPlayNext, it, adjusted = !it, PlayerCommand.SetAutoPlayNext(!it)) },
        values.shader?.let { shaders(it, values.shaders, values.importsShaders) },
        values.ambientLighting?.let {
            switch(PlayerOptionId.AMBIENT_LIGHTING, T.videoControls.ambientLighting, it, adjusted = it, PlayerCommand.ToggleAmbientLighting)
        },
        switch(PlayerOptionId.PLAYBACK_INFO, T.player.info.show, values.playbackInfo, adjusted = values.playbackInfo, PlayerCommand.ToggleInfo),
        if (values.fileInfo) page(PlayerOptionId.FILE_INFO, T.fileInfo.title, "", adjusted = false, PlayerMenu.FILE_INFO, emptyList()) else null,
        values.watch?.let(::watchTogether),
        values.dolbyVisionConversion?.let(::dolbyVisionConversion),
        if (values.httpStatus) httpStatus() else null,
    )

    /**
     * The audio menu's settings, after its tracks and the audio delay: the audio output (where the engine lists outputs),
     * how the system renders the audio (where it says), loudness normalization (saying it turns passthrough off where
     * passthrough is on) and the audio channels.
     */
    fun audio(values: AudioValues): List<PlayerOption> = listOfNotNull(
        values.audioDevices?.let { audioOutput(it, values.audioDevice) },
        values.audioRendering?.let(::audioRendering),
        switch(
            PlayerOptionId.AUDIO_NORMALIZATION,
            T.player.options.audioNormalization,
            values.audioNormalization,
            adjusted = values.audioNormalization,
            PlayerCommand.SetAudioNormalization(!values.audioNormalization),
        ).copy(detail = if (values.passthroughOn) T.settings.audioChannelLimitStereoDescription else null),
        audioChannels(values.audioChannels, values.passthroughSupported),
    )

    /** The aspect button ([PlayerUiState.videoFit]): the fit and the fits it cycles through. */
    fun videoFit(fit: VideoFit) = page(
        PlayerOptionId.VIDEO_FIT,
        T.player.options.videoFit,
        fitLabel(fit),
        adjusted = fit != VideoFit.CONTAIN,
        PlayerMenu.VIDEO_FIT,
        VideoFit.entries.map { OptionChoice(fitLabel(it), detail = null, selected = it == fit, PlayerCommand.SetVideoFit(it)) },
    )

    /**
     * The speed page: the presets ("Normal" at 1×), then Custom, which opens the custom speed's control
     * ([PlayerMenu.CUSTOM_SPEED]). The speed playing is ticked within a hundredth; one that is none of the presets is
     * ticked as Custom, which shows it ("Custom · 2.4×").
     */
    private fun speed(current: Double, speeds: List<Double>): PlayerOption {
        val preset = speeds.any { abs(it - current) < SPEED_PICK_EPSILON }
        val custom = OptionChoice(
            if (preset) T.player.speed.custom else T.player.speed.customValue(PlayerText.speed(current)),
            detail = null,
            selected = !preset,
            PlayerCommand.OpenMenu(PlayerMenu.CUSTOM_SPEED),
        )
        return page(
            PlayerOptionId.SPEED,
            T.videoSettings.playbackSpeed,
            PlayerText.speed(current),
            adjusted = abs(current - 1.0) >= SPEED_PICK_EPSILON,
            PlayerMenu.SPEED,
            speeds.map { OptionChoice(PlayerText.speed(it), detail = null, selected = abs(it - current) < SPEED_PICK_EPSILON, PlayerCommand.SetSpeed(it)) } + custom,
        )
    }

    /** The version and quality sheet's row: the quality playing, else the version. */
    private fun versions(menu: VersionsMenu) = page(
        PlayerOptionId.VERSIONS,
        T.videoControls.versionQualityButton,
        (menu.qualities.firstOrNull { it.selected } ?: menu.versions.firstOrNull { it.selected })?.label.orEmpty(),
        adjusted = false,
        PlayerMenu.VERSIONS,
        emptyList(),
    )

    fun fitLabel(fit: VideoFit): String = when (fit) {
        VideoFit.CONTAIN -> T.player.options.fit.contain
        VideoFit.COVER -> T.player.options.fit.cover
        VideoFit.FILL -> T.player.options.fit.fill
    }

    /** In a room, its session sheet is a page of its own ([PlayerMenu.WATCH_TOGETHER]), its value the participant count. */
    private fun watchTogether(watch: PlayerWatchUi) = page(
        PlayerOptionId.WATCH_TOGETHER,
        watch.room.title,
        watch.room.participantCount,
        adjusted = true,
        PlayerMenu.WATCH_TOGETHER,
        emptyList(),
    )

    /** "120%". */
    fun zoomLabel(zoom: Double): String = T.player.options.percent(PlayerText.decimal(VideoLayout.percent(zoom).toDouble(), 0, 0))

    private fun zoom(zoom: Double) = page(
        PlayerOptionId.ZOOM,
        T.player.options.zoom,
        zoomLabel(zoom),
        adjusted = zoom != 1.0,
        PlayerMenu.ZOOM,
        listOf(OptionChoice(T.player.options.resetZoom, detail = null, selected = false, PlayerCommand.ResetZoom)) +
            VideoLayout.ZOOM_PRESETS.map { OptionChoice(zoomLabel(it), detail = null, selected = abs(it - zoom) < ZOOM_EPSILON, PlayerCommand.SetZoom(it)) },
    )

    /** The [available] presets, the imported ones deletable, and the import entry where [imports]. */
    private fun shaders(current: ShaderPreset, available: List<ShaderPreset>, imports: Boolean) = page(
        PlayerOptionId.SHADERS,
        T.player.options.shaders,
        shaderLabel(current),
        adjusted = current != ShaderPreset.Off,
        PlayerMenu.SHADERS,
        available.map { preset ->
            OptionChoice(
                shaderLabel(preset),
                shaderDetail(preset),
                selected = preset == current,
                PlayerCommand.SetShaderPreset(preset.id),
                delete = (preset as? ShaderPreset.Custom)?.let { PlayerCommand.DeleteShader(it.id) },
            )
        },
    ).copy(importLabel = if (imports) T.player.options.shader.importShader else null)

    /**
     * "NVScaler", "ArtCNN C4F16 Denoise", "Anime4K Fast A", an imported shader's name: the shaders' own names stay as
     * they are, their variants' and qualities' words are translated.
     */
    fun shaderLabel(preset: ShaderPreset): String = when (preset) {
        ShaderPreset.Off -> T.player.options.off
        ShaderPreset.NvScaler -> "NVScaler"
        is ShaderPreset.ArtCnn ->
            if (preset.variant == ArtCnnVariant.NEUTRAL) "ArtCNN ${preset.model.label}" else "ArtCNN ${preset.model.label} ${variantLabel(preset.variant)}"
        is ShaderPreset.Anime4k -> "Anime4K ${qualityLabel(preset.quality)} ${preset.mode.label}"
        is ShaderPreset.Custom -> preset.shader.name
    }

    private fun shaderDetail(preset: ShaderPreset): String? = with(T.player.options.shader) {
        when (preset) {
            ShaderPreset.Off -> null
            ShaderPreset.NvScaler -> nvscalerDetail
            is ShaderPreset.ArtCnn -> "${preset.model.label}$SEPARATOR${variantLabel(preset.variant)}"
            is ShaderPreset.Anime4k -> modeDetail(qualityLabel(preset.quality), preset.mode.label)
            is ShaderPreset.Custom -> customDetail
        }
    }

    private fun variantLabel(variant: ArtCnnVariant) = with(T.player.options.shader) {
        when (variant) {
            ArtCnnVariant.NEUTRAL -> neutral
            ArtCnnVariant.DENOISE -> denoise
            ArtCnnVariant.DENOISE_SHARPEN -> denoiseSharpen
        }
    }

    private fun qualityLabel(quality: Anime4kQuality) = when (quality) {
        Anime4kQuality.FAST -> T.player.options.shader.fast
        Anime4kQuality.HQ -> T.player.options.shader.highQuality
    }

    private fun sleepTimer(values: Values): PlayerOption {
        val minutes = values.sleepMinutes
        val value = when {
            minutes != null -> T.player.options.sleepLeft(formatTimecode(values.sleepSecondsLeft.coerceAtLeast(0).toDouble()))
            values.sleepAtEndOfVideo -> T.player.options.sleepEndOfVideo
            else -> T.player.options.off
        }
        val offered = sleepTimerMinutes(values.sleepDefaultMinutes)
        return page(
            PlayerOptionId.SLEEP_TIMER,
            T.player.options.sleepTimer,
            value,
            adjusted = minutes != null || values.sleepAtEndOfVideo,
            PlayerMenu.SLEEP_TIMER,
            listOf(
                OptionChoice(T.player.options.off, detail = null, selected = minutes == null && !values.sleepAtEndOfVideo, PlayerCommand.CancelSleepTimer),
                OptionChoice(T.player.options.sleepEndOfVideo, detail = null, selected = values.sleepAtEndOfVideo, PlayerCommand.SleepAtEndOfVideo),
            ) + offered.map {
                OptionChoice(T.player.options.sleepMinutes(it), detail = null, selected = it == minutes, PlayerCommand.SetSleepTimer(it))
            },
        ).copy(
            valueForms = listOf(
                T.player.options.off,
                T.player.options.sleepEndOfVideo,
                // The longest countdown: its digits as wide as any it counts through.
                T.player.options.sleepLeft(formatTimecode(maxOf(offered.max(), minutes ?: 0) * 60.0)),
            ),
        )
    }

    /**
     * The outputs the engine lists, from the system's choice on; while it lists none, the page says so ("No audio devices
     * available"). A device mpv lists through several audio drivers (the Mac's Core Audio and AVFoundation both list the
     * speakers) is told apart by its driver: the choice's detail and the option's value ("MacBook Air Speakers ·
     * AVFoundation", the device's name isolated).
     */
    private fun audioOutput(devices: List<AudioDevice>, current: String): PlayerOption {
        fun label(device: AudioDevice) = if (device.name == AUTO_DEVICE) T.player.options.systemOutput else device.description.ifBlank { device.name }
        val shared = devices.groupingBy(::label).eachCount().filterValues { it > 1 }.keys
        fun driver(device: AudioDevice) = if (label(device) in shared) audioDriver(device.name) else null
        fun value(device: AudioDevice) = driver(device)?.let { isolate(label(device)) + SEPARATOR + it } ?: label(device)
        return page(
            PlayerOptionId.AUDIO_OUTPUT,
            T.player.options.audioOutput,
            devices.firstOrNull { it.name == current }?.let(::value) ?: if (current == AUTO_DEVICE) T.player.options.systemOutput else current,
            adjusted = current != AUTO_DEVICE,
            PlayerMenu.AUDIO_OUTPUT,
            devices.map { OptionChoice(label(it), detail = driver(it), selected = it.name == current, PlayerCommand.SetAudioDevice(it.name)) },
        ).copy(empty = T.videoControls.noAudioDevicesAvailable)
    }

    /** The audio driver of mpv's device [name] (`coreaudio/BuiltInSpeakerDevice`), by its own name. */
    private fun audioDriver(name: String): String? =
        name.substringBefore('/', missingDelimiterValue = "").ifBlank { null }?.let(CodecNames::audioDriver)

    /**
     * How the system renders the audio, as Dolby's application guide asks a player to show it: a row to read, with no
     * page or switch, marked for Dolby Audio and Dolby Atmos.
     */
    private fun audioRendering(rendering: AudioRendering): PlayerOption {
        val text = T.videoSettings
        val value = when (rendering) {
            AudioRendering.DOLBY_ATMOS -> text.audioOutputDolbyAtmos
            AudioRendering.DOLBY_AUDIO -> text.audioOutputDolbyAudio
            AudioRendering.SURROUND -> text.audioOutputSurround
            AudioRendering.SPATIAL_AUDIO -> text.audioOutputSpatial
            AudioRendering.STEREO -> text.audioOutputStereo
        }
        val dolby = rendering == AudioRendering.DOLBY_ATMOS || rendering == AudioRendering.DOLBY_AUDIO
        return PlayerOption(PlayerOptionId.AUDIO_RENDERING, text.audioOutput, value, dolby, page = null, choices = emptyList(), on = null, toggle = null)
    }

    /** The channel limits, named and described as Settings has them. */
    private fun audioChannels(channels: AudioChannels, passthroughSupported: Boolean): PlayerOption {
        val text = T.settings
        fun label(limit: AudioChannels) = when (limit) {
            AudioChannels.ORIGINAL -> text.audioChannelLimitOriginal
            AudioChannels.SURROUND_51 -> text.audioChannelLimitSurround51
            AudioChannels.STEREO -> text.audioChannelLimitStereo
        }
        fun detail(limit: AudioChannels) = when (limit) {
            AudioChannels.ORIGINAL -> text.audioChannelLimitOriginalDescription
            AudioChannels.SURROUND_51 -> text.audioChannelLimitSurround51Description
            AudioChannels.STEREO -> if (passthroughSupported) text.audioChannelLimitStereoDescription else null
        }
        return page(
            PlayerOptionId.AUDIO_CHANNELS,
            T.player.options.audioChannels,
            label(channels),
            adjusted = channels != AudioChannels.ORIGINAL,
            PlayerMenu.AUDIO_CHANNELS,
            AudioChannels.entries.map { OptionChoice(label(it), detail(it), selected = it == channels, PlayerCommand.SetAudioChannels(it)) },
        )
    }

    /** A development build's page: what Dolby Vision Profile 7 becomes, each mode with what it does. */
    private fun dolbyVisionConversion(current: DolbyVisionConversion): PlayerOption {
        val text = T.settings
        fun label(mode: DolbyVisionConversion) = when (mode) {
            DolbyVisionConversion.AUTO -> text.dvConversionAuto
            DolbyVisionConversion.DISABLED -> text.dvConversionNative
            DolbyVisionConversion.DV81 -> text.dvConversionDv81
            DolbyVisionConversion.HEVC_STRIP -> text.dvConversionHevcStrip
        }
        fun detail(mode: DolbyVisionConversion) = when (mode) {
            DolbyVisionConversion.AUTO -> text.dvConversionAutoDescription
            DolbyVisionConversion.DISABLED -> text.dvConversionNativeDescription
            DolbyVisionConversion.DV81 -> text.dvConversionDv81Description
            DolbyVisionConversion.HEVC_STRIP -> text.dvConversionHevcStripDescription
        }
        return page(
            PlayerOptionId.DOLBY_VISION_CONVERSION,
            text.dvConversionMode,
            label(current),
            adjusted = current != DolbyVisionConversion.AUTO,
            PlayerMenu.DOLBY_VISION_CONVERSION,
            DolbyVisionConversion.entries.map { OptionChoice(label(it), detail(it), selected = it == current, PlayerCommand.SetDolbyVisionConversion(it)) },
        )
    }

    /** A development build's page: fail the playback as the server answering one of [SIMULATED_STATUSES] would. */
    private fun httpStatus() = page(
        PlayerOptionId.HTTP_STATUS,
        HTTP_STATUS_LABEL,
        "",
        adjusted = false,
        PlayerMenu.HTTP_STATUS,
        SIMULATED_STATUSES.map { OptionChoice("HTTP $it", detail = null, selected = false, PlayerCommand.SimulateHttpStatus(it)) },
    )

    private fun page(id: PlayerOptionId, label: String, value: String, adjusted: Boolean, page: PlayerMenu, choices: List<OptionChoice>) =
        PlayerOption(id, label, value, adjusted, page, choices, on = null, toggle = null)

    private fun switch(id: PlayerOptionId, label: String, on: Boolean, adjusted: Boolean, toggle: PlayerCommand) = PlayerOption(
        id,
        label,
        if (on) T.player.options.on else T.player.options.off,
        adjusted,
        page = null,
        choices = emptyList(),
        on = on,
        toggle = toggle,
    )

    /** The development entries' names, as the earlier releases' debug builds had them: English only. */
    const val HTTP_STATUS_LABEL = "Simulate HTTP status from server"

    /** The statuses a development build simulates: the ones the playback words differently. */
    private val SIMULATED_STATUSES = listOf(403, 500, 404, 503)

    /** mpv's `audio-device` for the system's choice. */
    const val AUTO_DEVICE = "auto"

    private const val SEPARATOR = " · "

    private const val ZOOM_EPSILON = 0.005

    /** The speed playing is the page's speed within a hundredth. */
    private const val SPEED_PICK_EPSILON = 0.01
}
