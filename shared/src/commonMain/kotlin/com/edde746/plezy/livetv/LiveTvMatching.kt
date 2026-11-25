package com.edde746.plezy.livetv

import com.edde746.plezy.strings.T

/**
 * Whether [program] airs on [channel]: its channel identifier (trimmed, non-empty) is the channel's key or
 * identifier; server and DVR agree when both sides name one; the EPG provider agrees when both are known.
 */
fun liveTvProgramMatchesChannel(program: LiveTvProgram, channel: LiveTvChannel): Boolean {
    val programChannel = liveTvNonEmpty(program.channelIdentifier) ?: return false
    if (programChannel != channel.key && programChannel != channel.identifier) return false
    if (!nullableIdsMatch(program.serverId, channel.serverId)) return false
    if (!nullableIdsMatch(program.liveDvrKey, channel.liveDvrKey)) return false
    val programProvider = liveTvNonEmpty(program.providerIdentifier)
    val channelProvider = liveTvProviderIdentifierForChannel(channel)
    return programProvider == null || channelProvider == null || programProvider == channelProvider
}

/** The channel's EPG provider: the last path segment of its favourite source URI, else its lineup. */
fun liveTvProviderIdentifierForChannel(channel: LiveTvChannel): String? {
    val source = liveTvNonEmpty(channel.favoriteSource)
    if (source != null) {
        val segments = uriPathSegments(source)
        if (segments.isNotEmpty()) return liveTvNonEmpty(segments.last())
    }
    return liveTvNonEmpty(channel.lineup)
}

/** [value] trimmed; null when null, empty or blank. */
fun liveTvNonEmpty(value: String?): String? = value?.trim()?.takeIf { it.isNotEmpty() }

private fun nullableIdsMatch(a: String?, b: String?): Boolean {
    val left = liveTvNonEmpty(a)
    val right = liveTvNonEmpty(b)
    return left == null || right == null || left == right
}

/** The path segments of a URI reference: `server://id/a/b` → `[a, b]`, `a/b/` → `[a, b, ""]`, `server://id` → `[]`. */
private fun uriPathSegments(uri: String): List<String> {
    var rest = uri.substringBefore('#').substringBefore('?')
    val schemeEnd = rest.indexOf("://")
    if (schemeEnd >= 0) {
        rest = rest.substring(schemeEnd + 3)
        val pathStart = rest.indexOf('/')
        rest = if (pathStart < 0) "" else rest.substring(pathStart)
    }
    val path = rest.removePrefix("/")
    if (path.isEmpty()) return emptyList()
    return path.split('/')
}

/** Channels of one guide source, under the label its header shows. */
data class LiveTvChannelGroup(val key: String, val label: String, val channels: List<LiveTvChannel>)

/**
 * [channels] grouped by source (server, provider, DVR) in first-appearance order. Groups whose labels collide get a
 * suffix: the first of the source title, the DVR key and the provider not already in the label.
 */
fun groupLiveTvChannelsBySource(channels: List<LiveTvChannel>): List<LiveTvChannelGroup> {
    val bySource = LinkedHashMap<String, MutableList<LiveTvChannel>>()
    val labels = HashMap<String, String>()
    for (channel in channels) {
        val key = liveTvChannelSourceKey(channel)
        bySource.getOrPut(key) {
            labels[key] = liveTvChannelSourceLabel(channel)
            mutableListOf()
        } += channel
    }
    val groups = bySource.map { (key, list) -> LiveTvChannelGroup(key, labels.getValue(key), list.toList()) }
    val labelCounts = groups.groupingBy { it.label }.eachCount()
    return groups.map { if ((labelCounts[it.label] ?: 0) > 1) it.copy(label = deduplicatedLabel(it)) else it }
}

/** `{serverId}\0{favoriteSource ?? lineup}\0{dvrKey}`. */
fun liveTvChannelSourceKey(channel: LiveTvChannel): String {
    val serverId = liveTvNonEmpty(channel.serverId).orEmpty()
    val providerSource = (liveTvNonEmpty(channel.favoriteSource) ?: liveTvNonEmpty(channel.lineup)).orEmpty()
    val dvrSource = liveTvNonEmpty(channel.liveDvrKey).orEmpty()
    return "$serverId\u0000$providerSource\u0000$dvrSource"
}

/** The server's name (else id, else "Live TV"), plus ` - {source title}` when that differs. */
fun liveTvChannelSourceLabel(channel: LiveTvChannel): String {
    val serverLabel = liveTvNonEmpty(channel.serverName) ?: liveTvNonEmpty(channel.serverId) ?: T.liveTv.title
    val sourceTitle = liveTvNonEmpty(channel.liveTvSourceTitle)
    if (sourceTitle == null || sourceTitle == serverLabel) return serverLabel
    return "$serverLabel - $sourceTitle"
}

private fun deduplicatedLabel(group: LiveTvChannelGroup): String {
    val first = group.channels.firstOrNull() ?: return group.label
    val suffix = listOf(liveTvNonEmpty(first.liveTvSourceTitle), liveTvNonEmpty(first.liveDvrKey), liveTvProviderIdentifierForChannel(first))
        .firstOrNull { it != null && it !in group.label } ?: return group.label
    return "${group.label} - $suffix"
}
