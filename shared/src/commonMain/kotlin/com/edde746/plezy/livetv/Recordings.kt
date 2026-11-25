package com.edde746.plezy.livetv

import com.edde746.plezy.model.firstFlexibleMap
import com.edde746.plezy.model.flexibleBool
import com.edde746.plezy.model.flexibleBoolNullable
import com.edde746.plezy.model.flexibleDouble
import com.edde746.plezy.model.flexibleInt
import com.edde746.plezy.model.parseFlexibleJsonList
import com.edde746.plezy.model.parseFlexibleJsonObject
import com.edde746.plezy.model.readStringField
import io.ktor.http.decodeURLPart
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.intOrNull

// Recording payloads in Plex's wire shapes (`/media/subscriptions`, `/media/grabbers`). Jellyfin and Emby synthesize
// the same shapes from their timers.

/** One recording, scheduled or running (`MediaGrabOperation`). Its airing is [metadata] (`Metadata`, else `Video`). */
data class MediaGrabOperation(
    val id: String,
    val mediaSubscriptionId: Int? = null,
    val mediaIndex: Int? = null,
    val key: String? = null,
    val grabberIdentifier: String? = null,
    val grabberProtocol: String? = null,
    val percent: Double? = null,
    val currentSize: Int? = null,
    /** `scheduled`, `grabbing`, `recording`, `error`, `complete`… */
    val status: String? = null,
    val provider: String? = null,
    val rolling: Boolean? = null,
    val error: String? = null,
    val linkedKey: String? = null,
    val metadata: JsonObject? = null,
) {
    /** What cancels it: [key] when set, else [id]. */
    val operationKey: String get() = key?.takeIf { it.isNotEmpty() } ?: id

    val program: LiveTvProgram? get() = parseFlexibleJsonObject(metadata, LiveTvProgram::fromJson)

    companion object {
        fun fromJson(json: JsonObject): MediaGrabOperation = MediaGrabOperation(
            id = readStringField(json, "id") ?: "",
            mediaSubscriptionId = flexibleInt(json["mediaSubscriptionID"]),
            mediaIndex = flexibleInt(json["mediaIndex"]),
            key = json.string("key"),
            grabberIdentifier = json.string("grabberIdentifier"),
            grabberProtocol = json.string("grabberProtocol"),
            percent = flexibleDouble(json["percent"]),
            currentSize = flexibleInt(json["currentSize"]),
            status = json.string("status"),
            provider = json.string("provider"),
            rolling = flexibleBoolNullable(json["rolling"]),
            error = json.string("error"),
            linkedKey = json.string("linkedKey"),
            metadata = firstFlexibleMap(json["Metadata"] ?: json["Video"]),
        )
    }
}

/** A recording template (`SubscriptionTemplate`): the rules a program can be recorded with. */
data class SubscriptionTemplate(val subscriptions: List<MediaSubscription> = emptyList()) {
    companion object {
        fun fromJson(json: JsonObject): SubscriptionTemplate =
            SubscriptionTemplate(parseFlexibleJsonList(json["MediaSubscription"], MediaSubscription::fromJson))
    }
}

/** A recording rule (`MediaSubscription`), or one entry of a [SubscriptionTemplate]. */
data class MediaSubscription(
    val key: String,
    val type: Int? = null,
    val provider: String? = null,
    val targetLibrarySectionId: Int? = null,
    val targetSectionLocationId: Int? = null,
    val title: String? = null,
    val selected: Boolean? = null,
    /** The template's query parameters, already URL-encoded; MediaBrowser stashes its timer defaults JSON here. */
    val parameters: String? = null,
    val createdAt: Int? = null,
    val storageTotal: Int? = null,
    val durationTotal: Int? = null,
    val airingsType: String? = null,
    val librarySectionTitle: String? = null,
    val locationPath: String? = null,
    val video: JsonObject? = null,
    val directory: JsonObject? = null,
    val playlist: JsonObject? = null,
    val settings: List<SubscriptionSetting> = emptyList(),
    val grabOperations: List<MediaGrabOperation> = emptyList(),
) {
    /**
     * [prefs] when every key is an editable setting and every value valid for it; throws [UnsupportedOperationException]
     * for an unknown or uneditable setting and [IllegalArgumentException] for an invalid value.
     */
    fun validatePrefs(prefs: Map<String, Any?>): Map<String, Any?> {
        for ((id, value) in prefs) {
            val setting = settings.firstOrNull { it.id == id }
            if (setting == null || !setting.isEditable) throw UnsupportedOperationException("Unsupported recording rule option")
            setting.validateValue(value)
        }
        return prefs.toMap()
    }

    companion object {
        const val TYPE_SERIES = 2
        const val TYPE_EPISODE = 4

        /** A rule row: a non-string text field (`title`, `provider`, `parameters`, …) rejects it. */
        fun fromJson(json: JsonObject): MediaSubscription = MediaSubscription(
            key = readStringField(json, "key") ?: readStringField(json, "id") ?: "",
            type = flexibleInt(json["type"]),
            provider = json.strictString("provider"),
            targetLibrarySectionId = flexibleInt(json["targetLibrarySectionID"]),
            targetSectionLocationId = flexibleInt(json["targetSectionLocationID"]),
            title = json.strictString("title"),
            selected = flexibleBoolNullable(json["selected"]),
            parameters = json.strictString("parameters"),
            createdAt = flexibleInt(json["createdAt"]),
            storageTotal = flexibleInt(json["storageTotal"]),
            durationTotal = flexibleInt(json["durationTotal"]),
            airingsType = json.strictString("airingsType"),
            librarySectionTitle = json.strictString("librarySectionTitle"),
            locationPath = json.strictString("locationPath"),
            video = firstFlexibleMap(json["Video"]),
            directory = firstFlexibleMap(json["Directory"]),
            playlist = firstFlexibleMap(json["Playlist"]),
            settings = parseFlexibleJsonList(json["Setting"], SubscriptionSetting::fromJson),
            grabOperations = parseFlexibleJsonList(json["MediaGrabOperation"], MediaGrabOperation::fromJson),
        )
    }
}

/** What a [SubscriptionSetting]'s value is, for its editor and validation. */
enum class SettingDomainType { BOOLEAN, INTEGER, STRING }

/**
 * One recording option. [defaultValue] and [value] are the server's scalars as sent (String, Boolean, Int/Long,
 * Double, or null). [minimum] is set only by the MediaBrowser adapter.
 */
data class SubscriptionSetting(
    val id: String,
    val label: String? = null,
    val summary: String? = null,
    val type: String? = null,
    val defaultValue: Any? = null,
    val value: Any? = null,
    val hidden: Boolean = false,
    val advanced: Boolean = false,
    val group: String? = null,
    /** `value:label|value:label`, each part URL-encoded. */
    val enumValues: String? = null,
    val minimum: Int? = null,
) {
    val isEditable: Boolean
        get() = !hidden && id.isNotEmpty() && (type == null || type == "bool" || type == "int" || type == "string" || type == "text")

    val domainType: SettingDomainType
        get() = when {
            type == "bool" -> SettingDomainType.BOOLEAN
            options.isNotEmpty() -> SettingDomainType.STRING
            type == "int" -> SettingDomainType.INTEGER
            else -> SettingDomainType.STRING
        }

    /** Throws [UnsupportedOperationException] when not editable, [IllegalArgumentException] for an invalid [value]. */
    fun validateValue(value: Any?) {
        if (!isEditable) throw UnsupportedOperationException("Unsupported recording rule option")
        val valid = when (domainType) {
            SettingDomainType.BOOLEAN -> value is Boolean
            SettingDomainType.INTEGER -> value is Int && (minimum == null || value >= minimum)
            SettingDomainType.STRING -> value is String
        }
        if (!valid) throw IllegalArgumentException("Invalid recording rule option value")
        val choices = options
        if (choices.isNotEmpty() && choices.none { it.value == value.toString() }) {
            throw IllegalArgumentException("Invalid recording rule option choice")
        }
    }

    val options: List<SubscriptionSettingOption>
        get() {
            val raw = enumValues
            if (raw.isNullOrEmpty()) return emptyList()
            return raw.split('|').map { entry ->
                val separator = entry.indexOf(':')
                if (separator < 0) {
                    SubscriptionSettingOption(decodeUriComponent(entry), decodeUriComponent(entry))
                } else {
                    SubscriptionSettingOption(decodeUriComponent(entry.substring(0, separator)), decodeUriComponent(entry.substring(separator + 1)))
                }
            }
        }

    companion object {
        fun fromJson(json: JsonObject): SubscriptionSetting = SubscriptionSetting(
            id = json.string("id") ?: "",
            label = json.string("label"),
            summary = json.string("summary"),
            type = json.string("type"),
            defaultValue = scalar(json["default"]),
            value = scalar(json["value"]),
            hidden = flexibleBool(json["hidden"]),
            advanced = flexibleBool(json["advanced"]),
            group = json.string("group"),
            enumValues = json.string("enumValues"),
        )

        private fun scalar(element: JsonElement?): Any? {
            val primitive = element as? JsonPrimitive ?: return null
            if (primitive.isString) return primitive.content
            primitive.booleanOrNull?.let { return it }
            primitive.intOrNull?.let { return it }
            return primitive.content.toLongOrNull() ?: primitive.content.toDoubleOrNull()
        }
    }
}

data class SubscriptionSettingOption(val value: String, val label: String)

/** What `createRecordingRule` sends: the template's [parameters] and [prefs] overlaid with the user's edits. */
data class MediaSubscriptionCreateRequest(
    val targetLibrarySectionId: Int? = null,
    val targetSectionLocationId: Int? = null,
    val type: Int? = null,
    val parameters: String? = null,
    val prefs: Map<String, Any?> = emptyMap(),
) {
    companion object {
        /**
         * Every setting's value (else default) overlaid with [prefs]. A section other than the template's drops the
         * template's location.
         */
        fun fromTemplate(
            subscription: MediaSubscription,
            targetLibrarySectionId: Int? = null,
            targetSectionLocationId: Int? = null,
            prefs: Map<String, Any?> = emptyMap(),
        ): MediaSubscriptionCreateRequest {
            val templatePrefs = LinkedHashMap<String, Any?>()
            subscription.settings.forEach { if (it.id.isNotEmpty()) templatePrefs[it.id] = it.value ?: it.defaultValue }
            val overridingSection = targetLibrarySectionId != null && targetLibrarySectionId != subscription.targetLibrarySectionId
            return MediaSubscriptionCreateRequest(
                targetLibrarySectionId = targetLibrarySectionId ?: subscription.targetLibrarySectionId,
                targetSectionLocationId = targetSectionLocationId ?: if (overridingSection) null else subscription.targetSectionLocationId,
                type = subscription.type,
                parameters = subscription.parameters,
                prefs = templatePrefs + prefs,
            )
        }
    }
}

/** Dart's `Uri.decodeComponent`: percent escapes decoded as UTF-8; `+` stays a plus. */
private fun decodeUriComponent(text: String): String = text.decodeURLPart()
