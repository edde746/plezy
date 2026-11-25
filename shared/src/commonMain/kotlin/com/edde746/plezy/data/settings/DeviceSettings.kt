package com.edde746.plezy.data.settings

import com.edde746.plezy.data.Db
import com.edde746.plezy.log.Log
import kotlinx.serialization.json.Json
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.DeinterlaceMode
import com.edde746.plezy.settings.HdrSdrConversion
import com.edde746.plezy.settings.HdrToneMapping
import com.edde746.plezy.settings.SubtitleRenderResolution
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer

/**
 * A setting of this device only: never synced, [default] while unset. A stored value that doesn't decode is logged
 * and reads as the default, and stays stored until the setting changes. Each [key] is one setting's: the device's own
 * settings are declared here, a profile's under the prefix of its kind (`navigation.stacks.<profile>`).
 */
abstract class DeviceSetting<T>(val key: String, val default: T, internal val serializer: KSerializer<T>) {
    open fun normalize(value: T): T = value

    /** The player's read-ahead cache in MiB, or `null` for Automatic (mpv's own size; `PlaybackOptions`). */
    data object CacheSizeMegabytes : DeviceSetting<Int?>("playback.cacheSizeMegabytes", null, Int.serializer().nullable) {
        val range = SettingRange(16, 4096)
        override fun normalize(value: Int?) = value?.let(range::clamp)
    }
}

/** What the decoder makes of Dolby Vision Profile 7 ([AppSettings.dvConversionMode]); [wire] is the engines' name. */
@Serializable
enum class DolbyVisionConversion(val wire: String) {
    /** The engine's choice for the device's decoders. */
    @SerialName("auto")
    AUTO("auto"),

    /** As the file has it. */
    @SerialName("disabled")
    DISABLED("disabled"),

    /** Profile 8.1. */
    @SerialName("dv81")
    DV81("dv81"),

    /** The HDR10 base layer, the Dolby Vision data stripped. */
    @SerialName("hevcStrip")
    HEVC_STRIP("hevc_strip"),
}

/**
 * Every device setting, resolved against its default. [audioNormalization], [audioChannels] and [customShaders] are
 * the player's own choices, made in its options and kept for the next video (`PlayerPreferences`); [brightnessSwipe],
 * [volumeSwipe] and [pinchToZoom] go to the player the same way.
 */
data class DeviceSettings(
    val hardwareDecoding: Boolean,
    val hdr: Boolean,
    val matchFrameRate: Boolean,
    /** [AppSettings.audioPassthrough]: null for the form factor's default ([audioPassthroughOn]). */
    val audioPassthrough: Boolean?,
    val cacheSizeMegabytes: Int?,
    val subtitles: SubtitleAppearance,
    val audioNormalization: Boolean,
    val audioChannels: AudioChannels,
    /** [AppSettings.gestureBrightnessSwipe]. */
    val brightnessSwipe: Boolean,
    /** [AppSettings.gestureVolumeSwipe]. */
    val volumeSwipe: Boolean,
    /** [AppSettings.gesturePinchToZoom]. */
    val pinchToZoom: Boolean,
    /** [AppSettings.watchPartyRelayUrl]. */
    val watchRelay: String?,
    /** [AppSettings.downloadOnWifiOnly]. */
    val downloadWifiOnly: Boolean,
    /** [AppSettings.enableDiscordRpc]. */
    val discordPresence: Boolean = false,
    /** [AppSettings.crashReporting]. */
    val crashReports: Boolean = AppSettings.crashReporting.default,
    /** [AppSettings.customShaderPresets]. */
    val customShaders: List<CustomShader> = emptyList(),
    /** [AppSettings.dvConversionMode]. */
    val dvConversionMode: DolbyVisionConversion = AppSettings.dvConversionMode.default,
    /** `AppSettings.autoPip`: null for the device's default (`AppSettings.autoPipOn`). */
    val autoPip: Boolean? = null,
    /** [AppSettings.matchContentResolution]: an Android TV switches to the video's resolution too. */
    val matchResolution: Boolean = AppSettings.matchContentResolution.default,
    /** [AppSettings.matchRefreshRate]: Windows and macOS switch the refresh rate while fullscreen. */
    val matchRefreshRate: Boolean = AppSettings.matchRefreshRate.default,
    /** [AppSettings.matchDynamicRange]: Windows turns the display's HDR on for HDR video while fullscreen. */
    val matchDynamicRange: Boolean = AppSettings.matchDynamicRange.default,
    /** [AppSettings.displaySwitchDelay], in seconds. */
    val displaySwitchDelaySeconds: Int = AppSettings.displaySwitchDelay.default,
    /** [AppSettings.disableDolbyVision]. */
    val disableDolbyVision: Boolean = AppSettings.disableDolbyVision.default,
    /** [AppSettings.hdrSdrConversion]. */
    val hdrSdrConversion: HdrSdrConversion = AppSettings.hdrSdrConversion.default,
    /** [AppSettings.enableDebugLogging]. */
    val debugLogging: Boolean = AppSettings.enableDebugLogging.default,
    /** [AppSettings.deinterlaceMode]. */
    val deinterlace: DeinterlaceMode = AppSettings.deinterlaceMode.default,
    /** [AppSettings.maxVolume], in percent: mpv's `volume-max`. */
    val maxVolume: Int = AppSettings.maxVolume.default,
    /** [AppSettings.volume]: the video player's volume as it opens. */
    val volume: Double = AppSettings.volume.default,
    /** [AppSettings.audioOutputDevice]: mpv's `audio-device` as the player opens. */
    val audioOutputDevice: String = AppSettings.audioOutputDevice.default,
    /** [AppSettings.subtitleRenderResolution]. */
    val subtitleRenderResolution: SubtitleRenderResolution = AppSettings.subtitleRenderResolution.default,
    /** [AppSettings.hdrToneMapping]. */
    val hdrToneMapping: HdrToneMapping = AppSettings.hdrToneMapping.default,
    /** [AppSettings.mpvConfigText]: the user's mpv.conf, which a video engine applies after its own options (`MpvUserConfig`). */
    val mpvConfigText: String = AppSettings.mpvConfigText.default,
) {
    /**
     * Whether passthrough is on for a [formFactor] device: the stored choice, else on for a TV (Android TV, Apple TV),
     * which hands the bitstream to the TV or receiver over HDMI, and off on phones, tablets and desktops, whose routes
     * (headphones, speakers) are verified less.
     */
    fun audioPassthroughOn(formFactor: FormFactor): Boolean = audioPassthrough ?: (formFactor == FormFactor.TV)

    companion object {
        val DEFAULT: DeviceSettings = fromStored(emptyMap())

        internal fun fromStored(values: Map<String, String>): DeviceSettings {
            fun <T> DeviceSetting<T>.value() = decodeSetting(values[key])
            return DeviceSettings(
                hardwareDecoding = AppSettings.enableHardwareDecoding.value(),
                hdr = AppSettings.enableHdr.value(),
                matchFrameRate = AppSettings.matchContentFrameRate.value(),
                audioPassthrough = AppSettings.audioPassthrough.value(),
                cacheSizeMegabytes = DeviceSetting.CacheSizeMegabytes.value(),
                subtitles = SubtitleAppearance(
                    fontSize = AppSettings.subtitleFontSize.value(),
                    textColor = AppSettings.subtitleTextColor.value(),
                    borderSize = AppSettings.subtitleBorderSize.value(),
                    borderColor = AppSettings.subtitleBorderColor.value(),
                    backgroundColor = AppSettings.subtitleBackgroundColor.value(),
                    backgroundOpacity = AppSettings.subtitleBackgroundOpacity.value(),
                    bold = AppSettings.subtitleBold.value(),
                    italic = AppSettings.subtitleItalic.value(),
                    assOverride = AppSettings.subAssOverride.value(),
                    position = AppSettings.subtitlePosition.value(),
                    useMargins = AppSettings.subtitleUseMargins.value(),
                ),
                audioNormalization = AppSettings.audioNormalization.value(),
                audioChannels = AppSettings.audioChannelLimit.value(),
                brightnessSwipe = AppSettings.gestureBrightnessSwipe.value(),
                volumeSwipe = AppSettings.gestureVolumeSwipe.value(),
                pinchToZoom = AppSettings.gesturePinchToZoom.value(),
                watchRelay = AppSettings.watchPartyRelayUrl.value(),
                downloadWifiOnly = AppSettings.downloadOnWifiOnly.value(),
                discordPresence = AppSettings.enableDiscordRpc.value(),
                crashReports = AppSettings.crashReporting.value(),
                customShaders = AppSettings.customShaderPresets.value(),
                dvConversionMode = AppSettings.dvConversionMode.value(),
                autoPip = AppSettings.autoPip.value(),
                matchResolution = AppSettings.matchContentResolution.value(),
                matchRefreshRate = AppSettings.matchRefreshRate.value(),
                matchDynamicRange = AppSettings.matchDynamicRange.value(),
                displaySwitchDelaySeconds = AppSettings.displaySwitchDelay.value(),
                disableDolbyVision = AppSettings.disableDolbyVision.value(),
                hdrSdrConversion = AppSettings.hdrSdrConversion.value(),
                debugLogging = AppSettings.enableDebugLogging.value(),
                deinterlace = AppSettings.deinterlaceMode.value(),
                maxVolume = AppSettings.maxVolume.value(),
                volume = AppSettings.volume.value(),
                audioOutputDevice = AppSettings.audioOutputDevice.value(),
                subtitleRenderResolution = AppSettings.subtitleRenderResolution.value(),
                hdrToneMapping = AppSettings.hdrToneMapping.value(),
                mpvConfigText = AppSettings.mpvConfigText.value(),
            )
        }
    }
}

/** This device's settings. */
class DeviceSettingsRepository internal constructor(private val db: Db) {
    /** Every setting now and after every change: each write to a device setting reads them all again, so a reader of a few takes [observe] of them. */
    fun observe(): Flow<DeviceSettings> =
        db.observeList(db.database.deviceSettingQueries.selectAll()).map { it.toSettings() }.distinctUntilChanged()

    suspend fun settings(): DeviceSettings = db.read { deviceSettingQueries.selectAll().executeAsList().toSettings() }

    /** One setting's value, its default while unset. */
    suspend fun <T> value(setting: DeviceSetting<T>): T =
        setting.decodeSetting(db.read { deviceSettingQueries.selectByKey(setting.key).executeAsOneOrNull() })

    /** [settings]' values, in their order, each its default while unset: one read of the database. */
    suspend fun values(settings: List<DeviceSetting<*>>): List<Any?> =
        settings.decode(db.read { deviceSettingQueries.selectByKeys(settings.map { it.key }).executeAsList() })

    /** [settings]' values ([values]) now and after every change to one of them: one query for them all. */
    fun observe(settings: List<DeviceSetting<*>>): Flow<List<Any?>> =
        db.observeList(db.database.deviceSettingQueries.selectByKeys(settings.map { it.key })).map { settings.decode(it) }.distinctUntilChanged()

    /** One setting's value now and after every change, its default while unset. */
    fun <T> observe(setting: DeviceSetting<T>): Flow<T> =
        db.observeOneOrNull(db.database.deviceSettingQueries.selectByKey(setting.key)).map { setting.decodeSetting(it) }.distinctUntilChanged()

    /** Stores [value]; a nullable setting set to `null` is removed, as unset. */
    suspend fun <T> set(setting: DeviceSetting<T>, value: T) {
        db.write { writeSetting(setting, value) }
    }

    /** Stores two settings in one transaction: a reader sees both new values or neither. */
    suspend fun <A, B> set(first: DeviceSetting<A>, firstValue: A, second: DeviceSetting<B>, secondValue: B) {
        db.write {
            writeSetting(first, firstValue)
            writeSetting(second, secondValue)
        }
    }

    /**
     * Stores what [change] makes of the stored value (the default while unset), read in the same transaction: edits
     * made one after another (two quick steps, two list edits) each start from the one before. Nothing is written when
     * the value stays the same.
     */
    suspend fun <T> update(setting: DeviceSetting<T>, change: (T) -> T) {
        db.write { updateSetting(setting, change) }
    }

    suspend fun reset(setting: DeviceSetting<*>) {
        db.write { q.deviceSettingQueries.delete(setting.key) }
    }

    /** Removes every setting whose key starts with [prefix]. */
    suspend fun removeWithPrefix(prefix: String) {
        db.write { q.deviceSettingQueries.deleteByPrefix(prefix) }
    }
}

/** [DeviceSettingsRepository.update] in a transaction of the caller's. */
internal fun <T> Tx.updateSetting(setting: DeviceSetting<T>, change: (T) -> T) {
    val current = readSetting(setting)
    val next = setting.normalize(change(current))
    if (next == current) return
    writeSetting(setting, next)
}

/** [setting]'s value in a transaction of the caller's, its default while unset. */
internal fun <T> Tx.readSetting(setting: DeviceSetting<T>): T =
    setting.decodeSetting(q.deviceSettingQueries.selectByKey(setting.key).executeAsOneOrNull())

/** [DeviceSettingsRepository.set] in a transaction of the caller's. */
internal fun <T> Tx.writeSetting(setting: DeviceSetting<T>, value: T) {
    val next = setting.normalize(value)
    if (next == null) {
        q.deviceSettingQueries.delete(setting.key)
    } else {
        q.deviceSettingQueries.upsert(Device_setting(setting.key, settingsJson.encodeToString(setting.serializer, next)))
    }
}

private fun <T> DeviceSetting<T>.decodeSetting(json: String?): T {
    val decoded = json?.let { decodeStored(key, it, serializer) } ?: return default
    return normalize(decoded.value)
}

private fun List<Device_setting>.toSettings() = DeviceSettings.fromStored(associate { it.setting_key to it.value_json })

private fun List<DeviceSetting<*>>.decode(rows: List<Device_setting>): List<Any?> {
    val stored = rows.associate { it.setting_key to it.value_json }
    return map { it.decodeSetting(stored[it.key]) }
}

internal val settingsJson = Json { ignoreUnknownKeys = true }

/** A decoded value; lets a setting whose values include `null` tell a stored `null` from an unreadable value. */
internal class Decoded<T>(val value: T)

/** The setting [key]'s stored [json] decoded as [serializer]'s type; `null` when it doesn't decode, which is logged. */
internal fun <T> decodeStored(key: String, json: String, serializer: KSerializer<T>): Decoded<T>? = try {
    Decoded(settingsJson.decodeFromString(serializer, json))
} catch (e: IllegalArgumentException) {
    // SerializationException is one too.
    Log.w(TAG, e) { "the stored value of $key doesn't decode: its default reads in its place" }
    null
}

private const val TAG = "settings"
