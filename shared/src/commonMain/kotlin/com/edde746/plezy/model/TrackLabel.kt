package com.edde746.plezy.model

import com.edde746.plezy.format.formatAudioChannels
import com.edde746.plezy.format.formatAudioCodec
import com.edde746.plezy.format.formatSubtitleCodec
import com.edde746.plezy.format.subtitleExtension
import com.edde746.plezy.lang.LanguageTags
import com.edde746.plezy.lang.localizedLanguageName
import com.edde746.plezy.strings.T

/**
 * Two-part track label: [primary] carries the human-readable name (language first when known), [secondary] the
 * de-emphasized technical detail, null when there is none. Sheet rows render the parts on two lines; single-line
 * contexts (track cycling toasts) use [joined].
 */
data class TrackLabel(val primary: String, val secondary: String? = null) {
    val joined: String get() = if (secondary == null) primary else "$primary · $secondary"
}

/**
 * Builds the labels of server-reported audio and subtitle streams. Primary ladder: language → title → display title →
 * "Audio Track N"/"Track N"; a display title, the server's own description, stands without the codec line. The title
 * joins the secondary line only when the language took the primary slot and the title says more than the language or
 * the forced flag already do; a forced track's primary reads "English (Forced)".
 */
object TrackLabelBuilder {
    fun audioLabel(
        title: String? = null,
        language: String? = null,
        languageCode: String? = null,
        codec: String? = null,
        /** The player's codec profile; names the DTS variant. */
        codecProfile: String? = null,
        channels: Int? = null,
        displayTitle: String? = null,
        index: Int,
    ): TrackLabel {
        val tech = buildList {
            if (!codec.isNullOrEmpty()) add(formatAudioCodec(codec, codecProfile))
            formatAudioChannels(channels)?.let(::add)
        }
        return compose(
            languageDisplay = resolveTrackLanguageDisplay(language, languageCode),
            title = cleanTrackMetadataValue(title),
            displayTitle = cleanTrackMetadataValue(displayTitle),
            rawLanguageValues = listOf(language, languageCode),
            techParts = tech,
            fallbackLabel = { T.audioTracks.track(it.toString()) },
            index = index,
        )
    }

    fun subtitleLabel(
        title: String? = null,
        language: String? = null,
        languageCode: String? = null,
        codec: String? = null,
        forced: Boolean = false,
        displayTitle: String? = null,
        index: Int,
    ): TrackLabel {
        val cleanedTitle = cleanSubtitleTitle(title, codec)
        return compose(
            languageDisplay = resolveTrackLanguageDisplay(language, languageCode),
            title = cleanedTitle,
            displayTitle = cleanSubtitleTitle(displayTitle, codec),
            rawLanguageValues = listOf(language, languageCode),
            techParts = listOfNotNull(codec?.takeIf { it.isNotEmpty() }?.let(::formatSubtitleCodec)),
            fallbackLabel = { T.videoControls.subtitleTrack(it.toString()) },
            index = index,
            forced = forced || titleSaysForced(cleanedTitle),
        )
    }

    private fun compose(
        languageDisplay: String?,
        title: String?,
        displayTitle: String?,
        rawLanguageValues: List<String?>,
        techParts: List<String>,
        fallbackLabel: (Int) -> String,
        index: Int,
        forced: Boolean = false,
    ): TrackLabel {
        var secondaryTitle: String? = null
        var tech = techParts
        var primary = when {
            languageDisplay != null -> {
                if (title != null && metadataToken(title) != "FORCED" && !restatesLanguage(title, languageDisplay, rawLanguageValues)) {
                    secondaryTitle = title
                }
                languageDisplay
            }
            title != null -> title
            // The server's display title already names the codec and channels ("AAC - Stereo").
            displayTitle != null -> displayTitle.also { tech = emptyList() }
            else -> fallbackLabel(index + 1)
        }
        if (forced && !titleSaysForced(primary)) primary = T.videoControls.forcedTrack(primary)
        val secondaryParts = listOfNotNull(secondaryTitle) + tech
        return TrackLabel(primary, secondaryParts.takeIf { it.isNotEmpty() }?.joinToString(" · "))
    }

    private fun restatesLanguage(title: String, languageDisplay: String, rawLanguageValues: List<String?>): Boolean {
        val normalized = title.trim().lowercase()
        if (normalized == languageDisplay.trim().lowercase()) return true
        return rawLanguageValues.any { raw -> cleanTrackMetadataValue(raw)?.lowercase() == normalized }
    }
}

/**
 * The display name for a track's language. A mappable code wins ([languageCode] is the reliable field on server
 * streams, [language] carries the container code on player tracks). When neither maps, a server-provided display name
 * ("Filipino") beats an unmappable code, and bare codes show in capitals ("und" → "UND").
 */
internal fun resolveTrackLanguageDisplay(language: String?, languageCode: String?): String? {
    val code = cleanTrackMetadataValue(languageCode)
    val lang = cleanTrackMetadataValue(language)
    mappedLanguageName(code)?.let { return it }
    mappedLanguageName(lang)?.let { return it }
    val fallback = lang ?: code ?: return null
    return if (LANGUAGE_CODE.matches(fallback)) fallback.uppercase() else fallback
}

private fun mappedLanguageName(value: String?): String? {
    val tag = LanguageTags.canonical(value) ?: return null
    val name = localizedLanguageName(tag, T.locale) ?: return null
    return name.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
}

private val LANGUAGE_CODE = Regex("^[A-Za-z]{2,3}([-_][A-Za-z0-9]{2,8})?$")
private val METADATA_PREFIX = Regex("^(?:title|lang|language)\\s*=\\s*(.*)$", RegexOption.IGNORE_CASE)

/** [value] trimmed, without a `title=`/`lang=`/`language=` prefix or surrounding quotes; null when nothing is left. */
internal fun cleanTrackMetadataValue(value: String?): String? {
    var cleaned = value?.trim()?.takeIf { it.isNotEmpty() } ?: return null
    METADATA_PREFIX.find(cleaned)?.let { cleaned = it.groupValues[1].trim() }
    if (cleaned.length >= 2 &&
        ((cleaned.startsWith('"') && cleaned.endsWith('"')) || (cleaned.startsWith('\'') && cleaned.endsWith('\'')))
    ) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim()
    }
    return cleaned.takeIf { it.isNotEmpty() }
}

/**
 * A subtitle title cleaned like [cleanTrackMetadataValue], with trailing ` - SRT`-style codec segments and a server's
 * trailing ` - External` removed: the track's own codec and External flag say those ("English - SUBRIP - External" is
 * "English").
 */
internal fun cleanSubtitleTitle(title: String?, codec: String?): String? {
    val cleaned = cleanTrackMetadataValue(title) ?: return null
    val aliases = buildSet {
        addAll(SUBTITLE_CODEC_ALIASES)
        add("EXTERNAL")
        if (!codec.isNullOrEmpty()) {
            add(metadataToken(codec))
            add(metadataToken(formatSubtitleCodec(codec)))
            add(metadataToken(subtitleExtension(codec)))
        }
    }
    val parts = cleaned.split(DASH_SEPARATOR).toMutableList()
    while (parts.isNotEmpty() && metadataToken(parts.last()) in aliases) parts.removeAt(parts.lastIndex)
    return parts.joinToString(" - ").trim().takeIf { it.isNotEmpty() }
}

/**
 * Whether a track title declares the stream forced ("FR Forced [ASS]", "French (Forced)"). Whole-token match, so
 * "unforced" does not qualify. Plex itself treats such streams as forced even when the API flag is false.
 */
internal fun titleSaysForced(value: String?): Boolean = "FORCED" in metadataToken(value ?: "").split('_')

private val DASH_SEPARATOR = Regex("\\s+-\\s+")
private val NON_TOKEN = Regex("[^A-Z0-9]+")

private val SUBTITLE_CODEC_ALIASES = setOf(
    "SUBRIP", "SRT", "WEBVTT", "VTT", "ASS", "SSA", "PGS", "PGSSUB", "HDMV_PGS_SUBTITLE",
    "DVD", "DVDSUB", "DVD_SUBTITLE", "DVB_SUB", "DVB_SUBTITLE",
)

private fun metadataToken(value: String): String = value.trim().uppercase().replace(NON_TOKEN, "_")
