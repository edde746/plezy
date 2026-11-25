package com.edde746.plezy.model

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

const val DEFAULT_MEDIA_SEARCH_LIMIT = 100

/**
 * A person's name scores 95% of a title's. Within one match class (prefix, substring, tokens) the shorter candidate
 * earns the larger closeness bonus, and names are shorter than titles, so at full weight "Rick" ranked every actor
 * named Rick above *Rick and Morty*. At 0.95 a title beats a person in the same class, while an exact name (950) still
 * beats every partial title match and a name prefix still beats a title that merely contains the query.
 */
private const val PERSON_NAME_WEIGHT = 0.95

private val searchSeparators = Regex("[^\\p{L}\\p{N}\\p{M}]+")

/** [items] most relevant to [query] first; equal scores keep input order. */
fun rankMediaSearchResults(items: List<MediaItem>, query: String, limit: Int? = null): List<MediaItem> =
    rankBySearchRelevance(items, query, limit, ::mediaScore)

fun rankPeopleSearchResults(people: List<MediaPerson>, query: String, limit: Int? = null): List<MediaPerson> =
    rankBySearchRelevance(people, query, limit, ::personScore)

/** Titles and people on one scale; equal scores keep input order, so listing titles first breaks ties toward them. */
fun rankSearchHits(hits: List<SearchHit>, query: String, limit: Int? = null): List<SearchHit> =
    rankBySearchRelevance(hits, query, limit) { hit, normalized ->
        when (hit) {
            is SearchHit.Media -> mediaScore(hit.item, normalized)
            is SearchHit.Person -> personScore(hit.person, normalized)
        }
    }

/**
 * An accent-sensitive search key: NFKC, lower-cased, every run of characters that aren't letters, numbers or marks a
 * single space, trimmed. Canonical and compatibility equivalents and typographic variants (dashes, non-breaking
 * spaces, full-width forms) compare alike; diacritics are kept.
 */
fun normalizeSearchText(value: String?): String {
    if (value == null) return ""
    return normalizeNfkc(value).lowercase().replace(searchSeparators, " ").trim()
}

/**
 * The best [limit] of [items] by score, best first; a blank query keeps input order. A negative [limit] throws
 * [IllegalArgumentException].
 */
private fun <T> rankBySearchRelevance(items: List<T>, query: String, limit: Int?, scoreOf: (T, NormalizedSearchQuery) -> Double): List<T> {
    if (limit != null) {
        require(limit >= 0) { "limit must not be negative: $limit" }
        if (limit == 0) return emptyList()
    }
    if (items.isEmpty()) return emptyList()
    val normalized = NormalizedSearchQuery(query)
    if (normalized.text.isEmpty()) return if (limit == null) items.toList() else items.take(limit)
    // Stable sort: equal scores keep input order, so a bounded result is the full ranking's prefix.
    val ranked = items.map { it to scoreOf(it, normalized) }.sortedByDescending { it.second }.map { it.first }
    return if (limit == null) ranked else ranked.take(limit)
}

private fun mediaScore(item: MediaItem, query: NormalizedSearchQuery): Double = maxOf(
    query.score(item.title, 1.0),
    query.score(item.titleSort, 0.98),
    query.score(item.originalTitle, 0.96),
    query.score(item.grandparentTitle, 0.9),
    // An album's parent is its artist, which a track carries as grandparentTitle.
    query.score(item.parentTitle, if (item.kind == MediaKind.ALBUM) 0.9 else 0.8),
)

private fun personScore(person: MediaPerson, query: NormalizedSearchQuery): Double = query.score(person.name, PERSON_NAME_WEIGHT)

private class NormalizedSearchQuery(value: String) {
    val text = normalizeSearchText(value)
    val tokens = splitTokens(text)
    val sortedTokens = joinSortedTokens(tokens)

    /** [value]'s relevance on the 0–1000 scale, times [weight]. */
    fun score(value: String?, weight: Double): Double {
        val candidate = normalizeSearchText(value)
        if (candidate.isEmpty()) return 0.0
        return scoreNormalizedField(candidate) * weight
    }

    /**
     * Exact 1000; prefix 900 and substring 800, each plus up to 50 for length closeness; every query token present
     * 700 plus token similarity × 100; some tokens 400 plus their share × 100; else fuzzy similarity × 650 (the
     * token classes never score below it).
     */
    private fun scoreNormalizedField(candidate: String): Double {
        if (candidate == text) return 1000.0
        if (candidate.startsWith(text)) return 900 + lengthCloseness(text, candidate, 50.0)
        if (candidate.contains(text)) return 800 + lengthCloseness(text, candidate, 50.0)

        val candidateTokens = splitTokens(candidate)
        if (tokens.isEmpty() || candidateTokens.isEmpty()) return 0.0
        val candidateTokenSet = candidateTokens.toSet()
        val matchingTokens = tokens.count { it in candidateTokenSet }
        val tokenSimilarity = diceCoefficient(sortedTokens, joinSortedTokens(candidateTokens))
        val rawSimilarity = diceCoefficient(text, candidate)
        val fuzzyScore = max(rawSimilarity, tokenSimilarity) * 650
        if (matchingTokens == tokens.size) return max(700 + tokenSimilarity * 100, fuzzyScore)
        if (matchingTokens > 0) return max(400 + matchingTokens.toDouble() / tokens.size * 100, fuzzyScore)
        return fuzzyScore
    }
}

private fun splitTokens(value: String): List<String> = value.split(' ').filter { it.isNotEmpty() }

private fun joinSortedTokens(tokens: List<String>): String = tokens.sorted().joinToString(" ")

private fun lengthCloseness(query: String, candidate: String, maxBonus: Double): Double {
    val longest = max(query.length, candidate.length)
    if (longest == 0) return 0.0
    val distance = abs(candidate.length - query.length)
    return maxBonus * max(0.0, min(1.0, 1 - distance.toDouble() / longest))
}

/**
 * Dice's coefficient over the UTF-16 bigrams of [first] and [second] with whitespace removed: 1 for identical
 * strings, 0 when either has fewer than two characters.
 */
private fun diceCoefficient(first: String, second: String): Double {
    val a = first.filterNot { it.isWhitespace() }
    val b = second.filterNot { it.isWhitespace() }
    if (a.isEmpty() && b.isEmpty()) return 1.0
    if (a.isEmpty() || b.isEmpty()) return 0.0
    if (a == b) return 1.0
    if (a.length < 2 || b.length < 2) return 0.0
    val firstBigrams = HashMap<Int, Int>()
    for (i in 0 until a.length - 1) {
        val key = (a[i].code shl 16) or a[i + 1].code
        firstBigrams[key] = (firstBigrams[key] ?: 0) + 1
    }
    var intersection = 0
    for (i in 0 until b.length - 1) {
        val key = (b[i].code shl 16) or b[i + 1].code
        val count = firstBigrams[key] ?: 0
        if (count > 0) {
            firstBigrams[key] = count - 1
            intersection++
        }
    }
    return 2.0 * intersection / (a.length + b.length - 2)
}
