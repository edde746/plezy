package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.model.FilterEditorKind
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterUnit
import com.edde746.plezy.model.clausesFor
import com.edde746.plezy.model.withField
import com.edde746.plezy.strings.T

// The filter editor's edits on a selection (a list of clauses), and how a selection reads back. The editor stages its
// edits and Browse commits them once, when the editor closes.

/** How many fields are filtered: a range is two clauses on one field and counts once. */
fun activeFilterFieldCount(filters: List<LibraryFilter>): Int = filters.mapTo(HashSet()) { it.field }.size

/** A yes/no filter's state. */
enum class BooleanFilterState { ANY, YES, NO }

fun booleanFilterState(filters: List<LibraryFilter>, field: String): BooleanFilterState {
    val clause = filters.clausesFor(field).firstOrNull() ?: return BooleanFilterState.ANY
    return if (clause.op.isNegated) BooleanFilterState.NO else BooleanFilterState.YES
}

/** [state] for [field]: Yes is `is 1`, No `isNot 1`, Any no clause. */
fun withBooleanFilter(filters: List<LibraryFilter>, field: String, state: BooleanFilterState): List<LibraryFilter> =
    filters.withField(
        field,
        when (state) {
            BooleanFilterState.ANY -> emptyList()
            BooleanFilterState.YES -> listOf(LibraryFilter(field, listOf("1")))
            BooleanFilterState.NO -> listOf(LibraryFilter(field, listOf("1"), LibraryFilterOperator.IS_NOT))
        },
    )

/** The state Select moves a boolean row to: Any → Yes → No → Any (Any ↔ Yes without exclusion). */
fun nextBooleanFilterState(state: BooleanFilterState, supportsExclusion: Boolean): BooleanFilterState = when (state) {
    BooleanFilterState.ANY -> BooleanFilterState.YES
    BooleanFilterState.YES -> if (supportsExclusion) BooleanFilterState.NO else BooleanFilterState.ANY
    BooleanFilterState.NO -> BooleanFilterState.ANY
}

/** The values selected for a value-list [field] (one clause, its values ORed). */
fun selectedFilterValues(filters: List<LibraryFilter>, field: String): List<String> = filters.clausesFor(field).firstOrNull()?.values.orEmpty()

/** Whether [field]'s clause excludes its values. */
fun isFilterExcluded(filters: List<LibraryFilter>, field: String): Boolean = filters.clausesFor(field).firstOrNull()?.op?.isNegated == true

/**
 * [value] added to or removed from [field]'s values, the clause's include/exclude kept ([exclude] for a new clause);
 * the last value removed clears the field.
 */
fun toggleFilterValue(filters: List<LibraryFilter>, field: String, value: String, exclude: Boolean): List<LibraryFilter> {
    val current = selectedFilterValues(filters, field)
    val values = if (value in current) current - value else current + value
    val op = if (exclude) LibraryFilterOperator.IS_NOT else LibraryFilterOperator.IS
    return filters.withField(field, if (values.isEmpty()) emptyList() else listOf(LibraryFilter(field, values, op)))
}

/** [field]'s clause turned to include or exclude its values, which stay. */
fun withFilterExcluded(filters: List<LibraryFilter>, field: String, exclude: Boolean): List<LibraryFilter> {
    val values = selectedFilterValues(filters, field)
    if (values.isEmpty()) return filters
    val op = if (exclude) LibraryFilterOperator.IS_NOT else LibraryFilterOperator.IS
    return filters.withField(field, listOf(LibraryFilter(field, values, op)))
}

/** [field] bounded by [from] and [to] as typed in [unit]: `atLeast`/`atMost` clauses in the server's unit. */
fun withNumberRange(filters: List<LibraryFilter>, field: String, from: Long?, to: Long?, unit: MediaFilterUnit): List<LibraryFilter> =
    filters.withField(
        field,
        listOfNotNull(
            from?.let { LibraryFilter(field, listOf((it * unit.scale).toString()), LibraryFilterOperator.AT_LEAST) },
            to?.let { LibraryFilter(field, listOf((it * unit.scale).toString()), LibraryFilterOperator.AT_MOST) },
        ),
    )

/** [field]'s lower ([op] `atLeast`) or upper bound as typed: the stored value in [unit]. */
fun numberBound(filters: List<LibraryFilter>, field: String, op: LibraryFilterOperator, unit: MediaFilterUnit): Long? =
    filters.clausesFor(field).firstOrNull { it.op == op }?.values?.firstOrNull()?.toLongOrNull()?.let { it / unit.scale }

/** The date editor's relative windows, in Plex's relative syntax (`addedAt>>=-30d`). */
val RELATIVE_DATE_WINDOWS = listOf("-7d", "-30d", "-90d", "-1y")

/** [field] within the last [window] (or, [older], before it); null [window] clears it. One clause. */
fun withDateWindow(filters: List<LibraryFilter>, field: String, window: String?, older: Boolean): List<LibraryFilter> =
    filters.withField(
        field,
        listOfNotNull(
            window?.let { LibraryFilter(field, listOf(it), if (older) LibraryFilterOperator.AT_MOST else LibraryFilterOperator.AT_LEAST) },
        ),
    )

/** The match modes a text field offers, in the editor's order, as far as [filter] supports them. */
fun textMatchModes(filter: MediaFilter): List<LibraryFilterOperator> = listOf(
    LibraryFilterOperator.IS,
    LibraryFilterOperator.IS_NOT,
    LibraryFilterOperator.MATCHES,
    LibraryFilterOperator.NOT_MATCHES,
    LibraryFilterOperator.BEGINS_WITH,
    LibraryFilterOperator.ENDS_WITH,
).filter { it in filter.operators }

fun textMatchLabel(op: LibraryFilterOperator): String = when (op) {
    LibraryFilterOperator.IS -> T.libraries.advancedFilters.matchContains
    LibraryFilterOperator.IS_NOT -> T.libraries.advancedFilters.matchNotContains
    LibraryFilterOperator.MATCHES -> T.libraries.advancedFilters.matchIs
    LibraryFilterOperator.NOT_MATCHES -> T.libraries.advancedFilters.matchIsNot
    LibraryFilterOperator.BEGINS_WITH -> T.libraries.advancedFilters.matchBeginsWith
    LibraryFilterOperator.ENDS_WITH -> T.libraries.advancedFilters.matchEndsWith
    else -> op.id
}

/** [field] matching [text] by [op]; an empty text clears it. */
fun withTextMatch(filters: List<LibraryFilter>, field: String, text: String, op: LibraryFilterOperator): List<LibraryFilter> =
    filters.withField(field, if (text.isEmpty()) emptyList() else listOf(LibraryFilter(field, listOf(text), op)))

/**
 * The titles of filter values, which a summary shows: Plex's value ids are opaque, so a title is remembered when the
 * user sees it. Process-wide, at most about 1000 entries.
 */
object FilterValueNames {
    private const val MAX_ENTRIES = 1000
    private val names = HashMap<String, String>()

    fun remember(serverId: String, libraryKey: String, field: String, value: String, title: String) {
        if (names.size > MAX_ENTRIES) names.clear()
        names["$serverId:$libraryKey:$field:$value"] = title
    }

    fun lookup(serverId: String, libraryKey: String, field: String, value: String): String? = names["$serverId:$libraryKey:$field:$value"]
}

/** One line of what [filter] selects in [clauses], or null while it is unset. */
fun filterFieldSummary(filter: MediaFilter, clauses: List<LibraryFilter>, serverId: String, libraryKey: String): String? {
    val own = clauses.clausesFor(filter.filter)
    if (own.isEmpty()) return null
    if (filter.isBoolean) return if (own.first().op.isNegated) T.libraries.advancedFilters.no else T.libraries.advancedFilters.yes
    if (filter.editorKind == FilterEditorKind.NUMBER || filter.editorKind == FilterEditorKind.DATE) return boundsSummary(filter, own)
    return own.joinToString(" · ") { clauseSummary(filter, it, serverId, libraryKey) }
}

private fun clauseSummary(filter: MediaFilter, clause: LibraryFilter, serverId: String, libraryKey: String): String {
    val labels = if (filter.hasValueList) {
        val resolved = clause.values.map { FilterValueNames.lookup(serverId, libraryKey, filter.filter, it) }
        if (resolved.any { it == null }) {
            val count = clause.values.size.toString()
            return if (clause.op.isNegated) T.libraries.advancedFilters.valueCountExcluded(count) else T.libraries.advancedFilters.valueCount(count)
        }
        resolved.joinToString(", ")
    } else {
        clause.values.joinToString(", ")
    }
    val body = when (clause.op) {
        LibraryFilterOperator.BEGINS_WITH -> "$labels…"
        LibraryFilterOperator.ENDS_WITH -> "…$labels"
        else -> labels
    }
    return if (clause.op.isNegated) T.libraries.advancedFilters.not(body) else body
}

private fun boundsSummary(filter: MediaFilter, clauses: List<LibraryFilter>): String? {
    var lower: String? = null
    var upper: String? = null
    val exact = mutableListOf<String>()
    for (clause in clauses) {
        val value = clause.values.joinToString(", ")
        when (clause.op) {
            LibraryFilterOperator.AT_LEAST -> lower = value
            LibraryFilterOperator.AT_MOST -> upper = value
            else -> exact += if (clause.op.isNegated) T.libraries.advancedFilters.not(value) else value
        }
    }
    val date = filter.editorKind == FilterEditorKind.DATE
    val bound = when {
        lower != null && upper != null -> T.libraries.advancedFilters.range(
            if (date) relativeDateLabel(lower) else lower,
            if (date) relativeDateLabel(upper) else upper,
        )
        lower != null -> if (date) relativeDateLabel(lower) else T.libraries.advancedFilters.atLeast(lower)
        upper != null -> if (date) relativeDateLabel(upper, older = true) else T.libraries.advancedFilters.atMost(upper)
        else -> null
    }
    return (exact + listOfNotNull(bound)).takeIf { it.isNotEmpty() }?.joinToString(" · ")
}

/** A relative date window's label: "Last 30 days", "Older than a year". */
fun relativeDateLabel(value: String, older: Boolean = false): String {
    val days = when (value) {
        "-7d" -> 7
        "-30d" -> 30
        "-90d" -> 90
        else -> null
    }
    if (days != null) {
        return if (older) T.libraries.advancedFilters.dateOlderThanDays(days.toString()) else T.libraries.advancedFilters.dateLastDays(days.toString())
    }
    if (value == "-1y") return if (older) T.libraries.advancedFilters.dateOlderThanYear else T.libraries.advancedFilters.dateLastYear
    return value
}
