package com.edde746.plezy.watch

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpStatusCode
import io.ktor.utils.io.ByteReadChannel
import io.ktor.websocket.Frame
import io.ktor.websocket.WebSocketExtension
import io.ktor.websocket.WebSocketSession
import io.ktor.websocket.readText
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.channels.SendChannel
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import kotlin.coroutines.CoroutineContext
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * An Open Watch Party relay inside the test, holding one room, reached through [http]'s WebSockets (a mock engine). It
 * answers enough of the protocol for parties to create and join the room, share and clear media, play, pause, seek,
 * change the rate, report status, hand over the host, kick, lock, end and leave. The readiness barrier releases as soon
 * as every counted participant is ready, at once, and a release at the media's end pauses there in the same event, with
 * the action `ended`; no barrier or end-of-media timer runs. Relay time is [now], the test's virtual clock.
 */
internal class FakeOwpRelay(private val scope: CoroutineScope, dispatcher: CoroutineDispatcher, private val now: () -> Long) {
    val http = HttpClient(
        MockEngine.create {
            this.dispatcher = dispatcher
            reuseHandlers = true
            addHandler { request ->
                if (request.url.protocol.name != "ws" && request.url.protocol.name != "wss") return@addHandler respond("", HttpStatusCode.NotFound)
                val toClient = Channel<Frame>(Channel.UNLIMITED)
                val fromClient = Channel<Frame>(Channel.UNLIMITED)
                val base = respond(ByteReadChannel.Empty, HttpStatusCode.SwitchingProtocols)
                val connection = Connection(toClient)
                scope.launch { serve(connection, fromClient) }
                HttpResponseData(
                    base.statusCode,
                    base.requestTime,
                    base.headers,
                    base.version,
                    PipeSession(base.callContext, toClient, fromClient),
                    base.callContext,
                )
            }
        },
    ) { install(WebSockets) }

    /** The room's code: [CODE] until a join with `create` makes the room again under the code it names. */
    var roomCode = CODE
        private set

    /** Every client message but pings, with its sender's peer ID (null before it joined), in order. */
    val received = mutableListOf<Pair<String?, JsonObject>>()

    fun sent(type: String): List<JsonObject> = received.map { it.second }.filter { it.string("type") == type }

    /** When set, the relay refuses every join with this error code. */
    var refuseJoins: String? = null

    /** While true the relay leaves joins unanswered, as a slow relay would; [releaseJoins] answers the held ones. */
    var holdJoins = false
    private val heldJoins = mutableListOf<Pair<Connection, JsonObject>>()

    fun releaseJoins() {
        holdJoins = false
        val held = heldJoins.toList()
        heldJoins.clear()
        for ((conn, message) in held) if (!conn.closed) join(conn, message)
    }

    private val members = mutableListOf<Member>()
    private var nextPeer = 1
    private var rev = 0L
    private var epoch = 0L
    var phase = "idle"
        private set
    private var positionMs = 0L
    private var atMs = 0L
    private var rate = 1.0
    private var control = "host"
    private var locked = false
    var media: JsonObject? = null
        private set
    private var waitingOn = emptyList<String>()
    private var open = true

    /** A release reached the media's end: the next snapshot carries the action `ended` instead of its own. */
    private var ended = false

    val peerIds: List<String> get() = members.map { it.peerId }

    /** Drops [peerId]'s connection without a status, as a network loss would. */
    fun drop(peerId: String) {
        val member = member(peerId) ?: return
        member.conn.closed = true
        member.conn.socket.close()
        member.connected = false
        broadcast()
    }

    private suspend fun serve(conn: Connection, fromClient: ReceiveChannel<Frame>) {
        try {
            for (frame in fromClient) {
                when (frame) {
                    is Frame.Text -> onText(conn, frame.readText())
                    is Frame.Close -> {
                        if (!conn.closed) conn.socket.trySend(Frame.Close())
                        break
                    }
                    else -> Unit
                }
            }
        } finally {
            conn.closed = true
            conn.socket.close()
            val member = members.firstOrNull { it.conn === conn }
            if (member != null && member.connected) {
                member.connected = false
                broadcast()
            }
        }
    }

    private fun onText(conn: Connection, text: String) {
        val message = Json.parseToJsonElement(text).jsonObject
        val type = message.string("type")
        if (type == "ping") {
            conn.send(buildJsonObject { put("type", "pong"); put("id", message.long("id")); put("serverTime", now()) })
            return
        }
        val me = members.firstOrNull { it.conn === conn }
        received += me?.peerId to message
        when (type) {
            "create" -> if (me != null || members.isNotEmpty()) {
                refuse(conn, "create", "rate_limited")
            } else {
                makeRoom(CODE)
                add(conn, message, host = true)
            }
            "join" -> when {
                me != null -> Unit
                holdJoins -> heldJoins += conn to message
                else -> join(conn, message)
            }
            "resume" -> if (me == null) resume(conn, message)
            "leave" -> if (me != null) {
                remove(me)
                broadcast()
            }
            "status" -> if (me != null) {
                me.statusEpoch = message.long("epoch") ?: -1
                me.player = message.string("player") ?: "idle"
                me.match = message["match"] as? JsonObject
                me.offsetMs = message.long("offsetMs") ?: 0
                peerEvent()
                broadcast()
            }
            else -> if (me != null) command(me, type, message)
        }
    }

    private fun join(conn: Connection, message: JsonObject) {
        refuseJoins?.let { return refuse(conn, "join", it) }
        val code = message.string("code")
        if (message["create"]?.jsonPrimitive?.booleanOrNull == true && members.isEmpty() && code != null) makeRoom(code)
        if (!open || code != roomCode) return refuse(conn, "join", "room_not_found")
        if (locked) return refuse(conn, "join", "room_locked")
        add(conn, message, host = false)
        broadcast(except = members.last())
    }

    /** A join with `create` makes a new room with its code; one room, so only while nobody is in it. */
    private fun makeRoom(code: String) {
        roomCode = code
        open = true
        rev = 0
        epoch = 0
        phase = "idle"
        positionMs = 0
        atMs = now()
        rate = 1.0
        control = "host"
        locked = false
        media = null
        waitingOn = emptyList()
    }

    private fun resume(conn: Connection, message: JsonObject) {
        val member = member(message.string("peerId"))
        if (!open || message.string("code") != roomCode || member == null || message.string("token") != token(member)) {
            return refuse(conn, "resume", "resume_failed")
        }
        member.conn = conn
        member.connected = true
        rev++
        sendJoined(member)
        broadcast(except = member)
    }

    private fun command(me: Member, type: String?, message: JsonObject) {
        if (type in HOST_ONLY && !me.host) return refuse(me.conn, type!!, "forbidden")
        if (type in TRANSPORT) {
            if (!me.host && control != "everyone") return refuse(me.conn, type!!, "forbidden")
            if (media == null) return refuse(me.conn, type!!, "invalid_message")
        }
        val action = Action(type.orEmpty(), me.peerId)
        when (type) {
            "setMedia" -> {
                epoch++
                media = message["media"]!!.jsonObject
                positionMs = min(message.long("positionMs") ?: 0, durationMs)
                enterWaiting(positionMs)
                broadcast(action.copy(kind = "media"), withMedia = true)
            }
            "clearMedia" -> {
                if (media == null) return
                epoch++
                media = null
                phase = "idle"
                positionMs = 0
                waitingOn = emptyList()
                broadcast(action.copy(kind = "media"), withMedia = true)
            }
            "play" -> {
                if (phase != "paused") return
                enterWaiting(positionMs)
                broadcast(action)
            }
            "pause" -> {
                if (phase == "paused") return
                val current = position()
                val at = message.long("positionMs")
                phase = "paused"
                positionMs = if (at != null && abs(at - current) <= 2000) min(at, durationMs) else current
                waitingOn = emptyList()
                broadcast(action)
            }
            "seek" -> {
                val target = min(message.long("positionMs")!!, durationMs)
                if (phase == "paused") positionMs = target else enterWaiting(target)
                broadcast(action)
            }
            "rate" -> {
                if (phase == "playing" && now() >= atMs) {
                    positionMs = position()
                    atMs = now()
                }
                rate = message["rate"]!!.jsonPrimitive.doubleOrNull!!
                broadcast(action)
            }
            "setControl" -> {
                control = message.string("mode")!!
                broadcast()
            }
            "lock" -> {
                locked = message["locked"]!!.jsonPrimitive.booleanOrNull!!
                broadcast()
            }
            "transferHost" -> {
                val target = member(message.string("peerId")) ?: return refuse(me.conn, "transferHost", "invalid_message")
                if (target.host) return
                me.host = false
                target.host = true
                broadcast(action.copy(kind = "host"))
            }
            "kick" -> {
                val target = member(message.string("peerId")) ?: return refuse(me.conn, "kick", "invalid_message")
                target.conn.send(buildJsonObject { put("type", "closed"); put("reason", "kicked") })
                remove(target)
                broadcast()
            }
            "end" -> {
                for (member in members) member.conn.send(buildJsonObject { put("type", "closed"); put("reason", "ended") })
                members.clear()
                open = false
            }
        }
    }

    private val durationMs: Long get() = media?.long("durationMs") ?: 0

    private fun position(): Long {
        if (phase != "playing") return positionMs
        val elapsed = max(0, now() - atMs)
        return min(durationMs, positionMs + (elapsed * rate).toLong())
    }

    private fun add(conn: Connection, message: JsonObject, host: Boolean) {
        val member = Member(conn, "p${nextPeer++}", message.string("name")!!, message.string("client")!!)
        member.host = host || members.none { it.host }
        members += member
        rev++
        sendJoined(member)
    }

    private fun token(member: Member): String = "token-${member.peerId}".padEnd(TOKEN_LENGTH, 'x')

    private fun sendJoined(member: Member) = member.conn.send(
        buildJsonObject {
            put("type", "joined")
            put("code", roomCode)
            put("you", buildJsonObject { put("peerId", member.peerId); put("token", token(member)) })
            put("room", snapshot())
            put("media", media ?: JsonNull)
            put("serverTime", now())
        },
    )

    private fun remove(member: Member) {
        members.remove(member)
        if (member.host && members.isNotEmpty()) members.first().host = true
        if (members.isEmpty()) open = false
        peerEvent()
    }

    private fun enterWaiting(position: Long) {
        phase = "waiting"
        positionMs = position
        recomputeWaiting()
    }

    /** A participant's player is `loading` until it reports on the room's epoch. */
    private fun effective(m: Member): String = if (m.statusEpoch == epoch) m.player else "loading"

    private fun recomputeWaiting() {
        waitingOn = members.filter { m ->
            m.connected &&
                effective(m) != "idle" &&
                !(m.statusEpoch == epoch && m.match?.string("state") == "unavailable") &&
                !(m.statusEpoch == epoch && m.player == "ready")
        }.map { it.peerId }
        if (waitingOn.isEmpty()) {
            phase = "playing"
            atMs = now()
            endAtEnd()
        }
    }

    /** A room released at its media's end pauses there at once. */
    private fun endAtEnd() {
        if (positionMs < durationMs) return
        phase = "paused"
        positionMs = durationMs
        ended = true
    }

    private fun peerEvent() {
        if ((phase == "playing" || phase == "waiting") && members.none { it.connected && effective(it) != "idle" }) {
            positionMs = position()
            phase = "paused"
            waitingOn = emptyList()
            return
        }
        if (phase == "waiting") recomputeWaiting()
    }

    private fun refuse(conn: Connection, re: String, code: String) = conn.send(
        buildJsonObject {
            put("type", "error")
            put("code", code)
            put("message", code)
            put("re", re)
        },
    )

    private fun member(peerId: String?): Member? = members.firstOrNull { it.peerId == peerId }

    private fun snapshot(): JsonObject = buildJsonObject { snapshotFields() }

    private fun kotlinx.serialization.json.JsonObjectBuilder.snapshotFields() {
        put("rev", rev)
        put("code", roomCode)
        put("epoch", epoch)
        put("phase", phase)
        put("positionMs", positionMs)
        put("atMs", atMs)
        put("rate", rate)
        put("control", control)
        put("locked", locked)
        put("waitingOn", buildJsonArray { waitingOn.forEach { add(JsonPrimitive(it)) } })
        put(
            "participants",
            JsonArray(
                members.map { m ->
                    buildJsonObject {
                        put("peerId", m.peerId)
                        put("name", m.name)
                        put("client", m.client)
                        put("host", m.host)
                        put("connected", m.connected)
                        put("player", m.player)
                        put("match", m.match ?: JsonNull)
                        put("offsetMs", m.offsetMs)
                    }
                },
            ),
        )
    }

    private fun broadcast(action: Action? = null, withMedia: Boolean = false, except: Member? = null) {
        rev++
        val sent = if (ended) Action("ended", null) else action
        ended = false
        val message = buildJsonObject {
            put("type", "room")
            snapshotFields()
            if (sent != null) put("action", buildJsonObject { put("kind", sent.kind); put("by", sent.by) })
            if (withMedia) put("media", media ?: JsonNull)
        }
        for (member in members) if (member !== except && member.connected) member.conn.send(message)
    }

    private data class Action(val kind: String, val by: String?)

    private class Connection(val socket: SendChannel<Frame>) {
        var closed = false

        fun send(message: JsonObject) {
            if (!closed) socket.trySend(Frame.Text(message.toString()))
        }
    }

    private class Member(var conn: Connection, val peerId: String, val name: String, val client: String) {
        var host = false
        var connected = true
        var player = "idle"
        var match: JsonObject? = null
        var offsetMs = 0L
        var statusEpoch = -1L
    }

    /** One side of an in-memory WebSocket: frames to the client and from it. */
    private class PipeSession(
        override val coroutineContext: CoroutineContext,
        override val incoming: ReceiveChannel<Frame>,
        override val outgoing: SendChannel<Frame>,
    ) : WebSocketSession {
        override var masking = false
        override var maxFrameSize = Long.MAX_VALUE
        override val extensions: List<WebSocketExtension<*>> = emptyList()

        override suspend fun flush() = Unit

        @Deprecated("Use cancel() instead.", ReplaceWith("cancel()", "kotlinx.coroutines.cancel"))
        override fun terminate() {
            outgoing.close()
        }
    }

    companion object {
        const val CODE = "K7MQ2X"
        private const val TOKEN_LENGTH = 43
        private val HOST_ONLY = setOf("setMedia", "clearMedia", "setControl", "transferHost", "kick", "lock", "end")
        private val TRANSPORT = setOf("play", "pause", "seek", "rate")
    }
}

private fun JsonObject.string(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

private fun JsonObject.long(key: String): Long? = (this[key] as? JsonPrimitive)?.takeIf { !it.isString }?.longOrNull
