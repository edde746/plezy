package com.edde746.plezy.settings

import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.playback.VideoFit
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

/**
 * One of Plezy's settings of this device ([AppSettings]), under the key Plezy's earlier releases stored it as, so an
 * upgrade imports it as it is. [normalize] runs on every value stored and read back (a clamp keeps a value in its
 * range both ways). [policy] says whether Reset All Settings clears it and whether a settings file carries it.
 */
class AppSetting<T>(
    key: String,
    default: T,
    serializer: KSerializer<T>,
    normalize: (T) -> T = { it },
    val policy: SettingPolicy = SettingPolicy.NONE,
) : DeviceSetting<T>(key, default, serializer) {
    private val normalizeValue = normalize

    override fun normalize(value: T): T = normalizeValue(value)

    override fun toString(): String = "AppSetting($key)"
}

/**
 * Which of the two bulk surfaces a setting takes part in: Reset All Settings ([reset]) and the settings file
 * ([export], export and import alike). Credentials, runtime state and migration markers take part in neither.
 */
enum class SettingPolicy(val reset: Boolean, val export: Boolean) {
    RESET_AND_EXPORT(reset = true, export = true),

    /** Device-local: paths, endpoints, this machine's state, the user's own player configuration. */
    RESET(reset = true, export = false),

    /** Carried by the settings file, but kept by a reset (patterns, quality presets, opt-in toggles). */
    EXPORT(reset = false, export = true),
    NONE(reset = false, export = false),
}

/**
 * An enum stored as the name Plezy's earlier releases gave each value ([nameOf]); a name this build doesn't know
 * doesn't decode, so the setting reads as its default.
 */
internal class StoredNameSerializer<E : Enum<E>>(
    serialName: String,
    private val entries: List<E>,
    private val nameOf: (E) -> String,
) : KSerializer<E> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(serialName, PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: E) = encoder.encodeString(nameOf(value))

    override fun deserialize(decoder: Decoder): E {
        val name = decoder.decodeString()
        return entries.firstOrNull { nameOf(it) == name } ?: throw SerializationException("No $name in ${descriptor.serialName}")
    }
}

/** `SURROUND_51` → `surround51`, `SERIES_POSTER` → `seriesPoster`: the stored name of an entry named in camel case. */
internal fun camelName(entry: Enum<*>): String {
    val words = entry.name.lowercase().split('_')
    return words.first() + words.drop(1).joinToString("") { word -> word.replaceFirstChar { it.uppercaseChar() } }
}

/** [VideoFit] stored as the box-fit index Plezy's earlier releases kept (0 contain, 1 cover, 2 fill), clamped on read. */
internal object VideoFitIndexSerializer : KSerializer<VideoFit> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("com.edde746.plezy.settings.VideoFitIndex", PrimitiveKind.INT)

    override fun serialize(encoder: Encoder, value: VideoFit) = encoder.encodeInt(value.ordinal)

    override fun deserialize(decoder: Decoder): VideoFit = VideoFit.entries[decoder.decodeInt().coerceIn(0, VideoFit.entries.lastIndex)]
}
