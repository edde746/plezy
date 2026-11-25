package com.edde746.plezy.presentation.seerr

/**
 * The Seerr request sheet: header [heading] ("Request") over the requested title [title], then [body].
 *
 * @param closed set once the sheet must go: the UI dismisses it and shows [SeerrRequestClosed.message] as a snackbar.
 * @param refocus set when a control the user could have focused vanished (the 4K toggle, the advanced section) after a
 *   permission change; the UI moves focus to its target when its focus went with the control. Each new request has a
 *   new [SeerrRequestRefocus.id].
 */
data class SeerrRequestUiState(
    val heading: String,
    val title: String,
    val body: SeerrRequestBody,
    val closed: SeerrRequestClosed? = null,
    val refocus: SeerrRequestRefocus? = null,
)

sealed interface SeerrRequestBody {
    /** The settings, the services and the title's availability are loading. */
    data object Loading : SeerrRequestBody

    /** The load failed: [message] and a Retry button ([retryLabel]) that takes focus. */
    data class LoadFailed(val message: String, val retryLabel: String) : SeerrRequestBody

    /** The movie, or every season, is already available or requested: [message] beside a check mark, and Close. */
    data class NothingToRequest(val message: String) : SeerrRequestBody

    /**
     * The request form.
     *
     * @param seasons a show's season choice; null for a movie or when the instance takes whole shows only.
     * @param request4k the "Request in 4K" switch's value; null when the switch is hidden.
     * @param advanced the destination pickers; null without the advanced permission or a server for the variant.
     * @param error the inline error under the controls.
     * @param submitting a request is on its way: every control is disabled and the button shows a spinner.
     * @param submitJumpSeason the season row from which dpad down jumps to the Request button (TV); null when that
     *   jump does not apply (a 4K switch or visible advanced controls sit between them, or nothing can be submitted).
     */
    data class Form(
        val seasons: SeerrSeasonSection?,
        val request4k: Boolean?,
        val request4kLabel: String,
        val advanced: SeerrAdvancedSection?,
        val error: String?,
        val submitting: Boolean,
        val canSubmit: Boolean,
        val submitLabel: String,
        val submitJumpSeason: Int?,
    ) : SeerrRequestBody
}

/** "Seasons" with an "All seasons" box ([allSelected]) over one row per requestable-or-blocked season. */
data class SeerrSeasonSection(val heading: String, val allLabel: String, val allSelected: Boolean, val rows: List<SeerrSeasonRow>)

/**
 * One season. A blocked season shows its state ([blockedLabel]: "Available", "Processing") in place of its box and
 * takes no change; [checked] is whether it is chosen for the request.
 *
 * @param subtitle "{n} episodes".
 */
data class SeerrSeasonRow(
    val seasonNumber: Int,
    val title: String,
    val subtitle: String?,
    val blockedLabel: String?,
    val checked: Boolean,
) {
    val enabled: Boolean get() = blockedLabel == null
}

/**
 * "Advanced": [pickers] in display order (destination server only with several servers, then quality profile, root
 * folder, language profile, each only when it has options), the inline [tags] multi-select and the anime note.
 *
 * @param loading the chosen server's options are loading (a small spinner beside the heading).
 */
data class SeerrAdvancedSection(
    val heading: String,
    val loading: Boolean,
    val pickers: List<SeerrPicker>,
    val tags: SeerrTagsPicker?,
    val animeNote: String?,
)

enum class SeerrPickerKind { SERVER, QUALITY_PROFILE, ROOT_FOLDER, LANGUAGE_PROFILE }

/** A "current value" row opening a menu of [options]; [value] is empty when nothing is chosen. */
data class SeerrPicker(val kind: SeerrPickerKind, val label: String, val value: String, val options: List<SeerrPickerOption>)

/** A picker option; the instance default is labelled "{name} (Default)". */
data class SeerrPickerOption(val id: Int, val label: String, val selected: Boolean)

/** The tags row ([summary]: the chosen labels, or "No tags"), expanded inline into one checkbox per tag. */
data class SeerrTagsPicker(val label: String, val summary: String, val expanded: Boolean, val options: List<SeerrPickerOption>)

enum class SeerrRequestCloseReason {
    /** The request went through. */
    SUBMITTED,

    /** The user lost the permission to request this kind while the sheet was open. */
    PERMISSION_REVOKED,

    /** The account was replaced or disconnected: the sheet closes without a word. */
    SILENT,
}

/** Why the sheet closed and the snackbar the screen beneath shows ([isError] for the error style); null for none. */
data class SeerrRequestClosed(val reason: SeerrRequestCloseReason, val message: String?, val isError: Boolean)

enum class SeerrRequestFocusTarget { SUBMIT, FIRST_SEASON }

data class SeerrRequestRefocus(val target: SeerrRequestFocusTarget, val id: Int)
