package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.liveTvNonEmpty
import com.edde746.plezy.livetv.liveTvProgramMatchesChannel
import com.edde746.plezy.livetv.scopeKey

/**
 * [programs] per channel of [channels] (by [LiveTvChannel.scopeKey]): the airings whose channel identifier is the
 * channel's key or identifier and that [liveTvProgramMatchesChannel], by start.
 */
fun indexGuidePrograms(programs: List<LiveTvProgram>, channels: List<LiveTvChannel>): Map<String, List<LiveTvProgram>> {
    val byIdentifier = HashMap<String, MutableList<LiveTvProgram>>()
    for (program in programs) {
        val identifier = liveTvNonEmpty(program.channelIdentifier) ?: continue
        byIdentifier.getOrPut(identifier) { mutableListOf() } += program
    }
    return channels.associate { channel ->
        val candidates = LinkedHashSet<LiveTvProgram>()
        byIdentifier[channel.key]?.let(candidates::addAll)
        val identifier = channel.identifier
        if (identifier != null && identifier != channel.key) byIdentifier[identifier]?.let(candidates::addAll)
        channel.scopeKey to candidates.filter { liveTvProgramMatchesChannel(it, channel) }.sortedBy { it.beginsAt ?: 0 }
    }
}

/** What a D-pad move onto a row lands on: the airing at [nowEpochSeconds], else the first still to come, else the first. */
fun guideCurrentProgram(programs: List<LiveTvProgram>, nowEpochSeconds: Long): LiveTvProgram? =
    programs.firstOrNull { (it.beginsAt ?: 0) <= nowEpochSeconds && (it.endsAt ?: 0) > nowEpochSeconds }
        ?: programs.firstOrNull { (it.endsAt ?: 0) > nowEpochSeconds }
        ?: programs.firstOrNull()

/** The time a vertical move keeps: [program]'s start, or [windowStart] when it began before the window. */
fun guideAnchorTime(program: LiveTvProgram, windowStart: Long): Long = maxOf(program.beginsAt ?: windowStart, windowStart)

/** The airing on at [epochSeconds], else the one closest to it; null without airings. */
fun guideProgramNear(programs: List<LiveTvProgram>, epochSeconds: Long): LiveTvProgram? {
    var nearest: LiveTvProgram? = null
    var nearestDistance = 0L
    for (program in programs) {
        val begin = program.beginsAt ?: 0
        val end = program.endsAt ?: begin
        if (begin <= epochSeconds && end > epochSeconds) return program
        val distance = if (begin > epochSeconds) begin - epochSeconds else epochSeconds - end
        if (nearest == null || distance < nearestDistance) {
            nearest = program
            nearestDistance = distance
        }
    }
    return nearest
}

/**
 * An airing's identity for a SELECT hold: the channel, the program's first id (ratingKey, guid, key) and its slot. Fresh
 * objects of the same airing (a reload) share it; a repeat of the program on another slot doesn't.
 */
data class GuideAiringIdentity(val channelScopeKey: String, val programId: String?, val beginsAt: Long?, val endsAt: Long?)

fun guideAiringIdentity(channel: LiveTvChannel, program: LiveTvProgram): GuideAiringIdentity {
    val programId = program.ratingKey?.takeIf { it.isNotEmpty() }?.let { "ratingKey:$it" }
        ?: program.guid?.takeIf { it.isNotEmpty() }?.let { "guid:$it" }
        ?: program.key?.takeIf { it.isNotEmpty() }?.let { "key:$it" }
    return GuideAiringIdentity(channel.scopeKey, programId, program.beginsAt, program.endsAt)
}

/**
 * The keys a recording matches an airing by: `{serverId}\0media\0{id}` for its ratingKey, guid and key, and
 * `{serverId}\0slot\0{channel}|{beginsAt}|{endsAt}`. The server is the airing's own, else [fallbackServerId]; none without
 * a server.
 */
fun guideRecordingKeys(program: LiveTvProgram, fallbackServerId: String? = null): Set<String> {
    val serverId = liveTvNonEmpty(program.serverId) ?: liveTvNonEmpty(fallbackServerId) ?: return emptySet()
    val keys = LinkedHashSet<String>()
    listOf(program.ratingKey, program.guid, program.key).forEach { id -> liveTvNonEmpty(id)?.let { keys += "$serverId\u0000media\u0000$it" } }
    val channel = liveTvNonEmpty(program.channelIdentifier)
    val beginsAt = program.beginsAt
    if (channel != null && beginsAt != null) keys += "$serverId\u0000slot\u0000$channel|$beginsAt|${program.endsAt ?: ""}"
    return keys
}

/** A grab that still records: no status, or scheduled, grabbing or recording. */
fun isActiveScheduledGrab(grab: MediaGrabOperation): Boolean {
    val status = grab.status?.trim()?.lowercase()
    return status.isNullOrEmpty() || status == "scheduled" || status == "grabbing" || status == "recording"
}

/** [grab]'s airing keys on [serverId] when it still records; none otherwise. */
fun guideRecordingKeys(grab: MediaGrabOperation, serverId: String): Set<String> {
    if (!isActiveScheduledGrab(grab)) return emptySet()
    return grab.program?.let { guideRecordingKeys(it, serverId) }.orEmpty()
}

/**
 * Whether the guide shows [program]'s recording dot: a local override on any of its keys decides (set by recording or
 * cancelling from the guide, kept until the next full load); else the grid's own subscription tag
 * ([LiveTvProgram.recordingRuleKey]); else any of its keys among the [scheduled] recordings' keys.
 */
fun guideIsRecordingScheduled(program: LiveTvProgram, overrides: Map<String, Boolean>, scheduled: Set<String>): Boolean {
    val keys = guideRecordingKeys(program)
    keys.firstNotNullOfOrNull { overrides[it] }?.let { return it }
    if (program.recordingRuleKey != null) return true
    return keys.any { it in scheduled }
}
