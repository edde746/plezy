package com.edde746.plezy.desktop.updates

import com.edde746.plezy.net.PlezyHttpClient
import com.sun.net.httpserver.HttpServer
import kotlinx.coroutines.runBlocking
import java.net.InetSocketAddress
import java.nio.file.Files
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import java.util.Base64
import kotlin.io.path.createTempDirectory
import kotlin.io.path.exists
import kotlin.io.path.readBytes
import kotlin.io.path.writeBytes
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WindowsUpdaterTest {
    private val key = KeyPairGenerator.getInstance("Ed25519").generateKeyPair()
    private val otherKey = KeyPairGenerator.getInstance("Ed25519").generateKeyPair()
    private val installer = Random(7).nextBytes(300_000)
    private val directory = createTempDirectory("plezy-updater-test")
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
    private val http = PlezyHttpClient.create("test")
    private var feed = ""

    init {
        server.createContext("/appcast.xml") { exchange ->
            val body = feed.toByteArray()
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { it.write(body) }
        }
        server.createContext("/plezy-windows-installer.exe") { exchange ->
            exchange.sendResponseHeaders(200, installer.size.toLong())
            exchange.responseBody.use { it.write(installer) }
        }
        server.start()
    }

    @AfterTest
    fun stop() {
        server.stop(0)
        http.close()
        directory.toFile().deleteRecursively()
    }

    private val base get() = "http://127.0.0.1:${server.address.port}"

    /** Sparkle's form of [pair]'s public key: the raw 32 bytes, the end of its X.509 encoding. */
    private fun sparkleKey(pair: KeyPair): String = Base64.getEncoder().encodeToString(pair.public.encoded.copyOfRange(12, 44))

    private fun sign(bytes: ByteArray, pair: KeyPair = key): String =
        Base64.getEncoder().encodeToString(Signature.getInstance("Ed25519").run { initSign(pair.private); update(bytes); sign() })

    private fun appcast(
        signature: String = sign(installer),
        length: Long = installer.size.toLong(),
        arguments: String = "/SILENT /SP-",
    ) = """
        <?xml version="1.0" encoding="utf-8"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <title>Plezy Updates</title>
            <item>
              <title>Version 2.26.0</title>
              <sparkle:version>160</sparkle:version>
              <sparkle:shortVersionString>2.26.0</sparkle:shortVersionString>
              <sparkle:releaseNotesLink>$base/notes</sparkle:releaseNotesLink>
              <enclosure url="$base/plezy-windows-installer.exe"
                         length="$length" type="application/octet-stream"
                         sparkle:edSignature="$signature"
                         sparkle:installerArguments="$arguments"
                         sparkle:os="windows" />
            </item>
          </channel>
        </rss>
    """.trimIndent()

    private val started = mutableListOf<Pair<ByteArray, List<String>>>()
    private var exits = 0

    private fun updater(currentBuild: Long = 159) = WindowsUpdater(
        http = http,
        currentBuild = currentBuild,
        feedUrl = "$base/appcast.xml",
        publicKey = sparkleKey(key),
        directory = directory,
        start = { file, arguments -> started += file.readBytes() to arguments },
        exit = { exits++ },
    )

    @Test
    fun aSignatureVerifiesOnlyForItsFileAndKey() {
        val file = directory.resolve("file.bin").also { it.writeBytes(installer) }
        val signature = sign(installer)

        assertTrue(UpdateSignature.verify(file, signature, sparkleKey(key)))
        assertFalse(UpdateSignature.verify(file, signature, sparkleKey(otherKey)))
        assertFalse(UpdateSignature.verify(file, sign(installer, otherKey), sparkleKey(key)))
        file.writeBytes(installer.copyOf().also { it[1000] = (it[1000] + 1).toByte() })
        assertFalse(UpdateSignature.verify(file, signature, sparkleKey(key)))
    }

    @Test
    fun plezysUpdateKeyIsAnEd25519Key() {
        val file = directory.resolve("file.bin").also { it.writeBytes(installer) }
        assertFalse(UpdateSignature.verify(file, sign(installer), UpdateSignature.PUBLIC_KEY))
    }

    @Test
    fun aMalformedSignatureOrKeyThrows() {
        val file = directory.resolve("file.bin").also { it.writeBytes(installer) }
        assertFailsWith<IllegalArgumentException> { UpdateSignature.verify(file, "c2hvcnQ=", sparkleKey(key)) }
        assertFailsWith<IllegalArgumentException> { UpdateSignature.verify(file, sign(installer), "c2hvcnQ=") }
    }

    @Test
    fun onlyANewerBuildIsOffered() = runBlocking {
        feed = appcast()

        assertEquals("2.26.0", updater(currentBuild = 159).check()?.version)
        assertEquals("$base/notes", updater(currentBuild = 159).check()?.notesUrl)
        assertNull(updater(currentBuild = 160).check())
        assertNull(updater(currentBuild = 161).check())
    }

    @Test
    fun aSignedInstallerIsDownloadedStartedSilentlyAndTheAppLeaves() = runBlocking {
        feed = appcast()
        val updater = updater()
        val progress = mutableListOf<Float>()

        updater.install(updater.check()!!) { progress += it }

        val (bytes, arguments) = started.single()
        assertContentEquals(installer, bytes)
        assertEquals(listOf("/SILENT", "/SP-"), arguments)
        assertEquals(1, exits)
        assertEquals(1f, progress.last())
        assertEquals(progress.sorted(), progress)
    }

    @Test
    fun theInstallerRunsWithItsOwnArgumentsNotTheFeeds() = runBlocking {
        feed = appcast(arguments = """/DIR=C:\x /LOG=C:\x\log.txt /VERYSILENT""")
        val updater = updater()

        updater.install(updater.check()!!) {}

        assertEquals(listOf("/SILENT", "/SP-"), started.single().second)
    }

    @Test
    fun anInstallerWithAnotherKeysSignatureIsRefusedAndDeleted() = runBlocking {
        feed = appcast(signature = sign(installer, otherKey))
        val updater = updater()

        assertFailsWith<UpdateRejectedException> { updater.install(updater.check()!!) {} }

        assertTrue(started.isEmpty())
        assertEquals(0, exits)
        assertFalse(directory.resolve("plezy-windows-installer.exe").exists())
    }

    @Test
    fun anInstallerOfAnotherSizeIsRefusedAndDeleted() = runBlocking {
        for (length in listOf(installer.size + 1L, installer.size - 1L)) {
            feed = appcast(length = length)
            val updater = updater()

            assertFailsWith<UpdateRejectedException> { updater.install(updater.check()!!) {} }

            assertTrue(started.isEmpty())
            assertFalse(Files.exists(directory.resolve("plezy-windows-installer.exe")))
        }
    }

    @Test
    fun anUnreadableFeedThrows() {
        feed = "<html>"
        assertFailsWith<AppcastException> { runBlocking { updater().check() } }
    }
}
