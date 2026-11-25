package com.edde746.plezy.desktop.updates

import com.edde746.plezy.ui.updates.InstallerUpdate
import org.w3c.dom.Element
import org.xml.sax.InputSource
import org.xml.sax.SAXException
import java.io.StringReader
import javax.xml.XMLConstants
import javax.xml.parsers.DocumentBuilderFactory

/** One release in the update feed with an installer for this OS: what the update dialog offers and installs. */
internal data class AppcastItem(
    /** The release's build number (`sparkle:version`, CURRENT_PROJECT_VERSION), compared with the running build's. */
    val build: Long,
    /** The release's version (`sparkle:shortVersionString`, "2.26.0"). */
    override val version: String,
    /** Its release notes' page (`sparkle:releaseNotesLink`). */
    override val notesUrl: String?,
    val installer: AppcastEnclosure,
) : InstallerUpdate

/** An item's installer: where it is, its size in bytes and its EdDSA (Ed25519) signature. */
internal data class AppcastEnclosure(
    val url: String,
    val length: Long,
    /** `sparkle:edSignature`: the installer's Ed25519 signature, base64. */
    val signature: String,
)

/** The feed is not an appcast this updater reads: not XML, or an item for this OS without what installing needs. */
internal class AppcastException(message: String, cause: Throwable? = null) : Exception(message, cause)

/**
 * The update feed: an RSS 2.0 channel with Sparkle's namespace, which the release workflow writes (`appcast.xml`), one
 * `item` per release, each with `sparkle:version`, `sparkle:shortVersionString`, `sparkle:releaseNotesLink` and an
 * `enclosure` per OS (`sparkle:os`, `url`, `length`, `sparkle:edSignature`). The feed's `sparkle:installerArguments`
 * is for WinSparkle-based installs; this updater ignores it, since the feed isn't signed.
 */
internal object Appcast {
    const val SPARKLE_NAMESPACE = "http://www.andymatuschak.org/xml-namespaces/sparkle"

    /**
     * The items of [xml] with an enclosure for [os] (`windows`), the newest build first. An item for [os] without its
     * build number, version, URL, size or signature throws [AppcastException], as does a document that isn't XML.
     */
    fun parse(xml: String, os: String): List<AppcastItem> {
        val document = try {
            builderFactory.newDocumentBuilder().parse(InputSource(StringReader(xml)))
        } catch (e: SAXException) {
            throw AppcastException("the update feed isn't XML", e)
        }
        val items = document.getElementsByTagName("item")
        return (0 until items.length).mapNotNull { item(items.item(it) as Element, os) }.sortedByDescending { it.build }
    }

    private fun item(item: Element, os: String): AppcastItem? {
        val enclosure = item.children("enclosure").firstOrNull { it.getAttributeNS(SPARKLE_NAMESPACE, "os") == os } ?: return null
        val build = item.sparkleText("version")
        return AppcastItem(
            build = build.toLongOrNull() ?: throw AppcastException("the build number $build isn't a number"),
            version = item.sparkleText("shortVersionString"),
            notesUrl = item.sparkleChildren("releaseNotesLink").firstOrNull()?.textContent?.trim()?.takeIf(String::isNotEmpty),
            installer = AppcastEnclosure(
                url = enclosure.required("url", null),
                length = enclosure.required("length", null).toLongOrNull()?.takeIf { it > 0 }
                    ?: throw AppcastException("the installer's length isn't a size"),
                signature = enclosure.required("edSignature", SPARKLE_NAMESPACE),
            ),
        )
    }

    private fun Element.children(name: String): List<Element> =
        (0 until childNodes.length).map(childNodes::item).filterIsInstance<Element>().filter { it.namespaceURI == null && it.localName == name }

    private fun Element.sparkleChildren(name: String): List<Element> =
        (0 until childNodes.length).map(childNodes::item).filterIsInstance<Element>().filter { it.namespaceURI == SPARKLE_NAMESPACE && it.localName == name }

    private fun Element.sparkleText(name: String): String =
        sparkleChildren(name).firstOrNull()?.textContent?.trim()?.takeIf(String::isNotEmpty)
            ?: throw AppcastException("an item has no sparkle:$name")

    private fun Element.required(name: String, namespace: String?): String =
        (if (namespace == null) getAttribute(name) else getAttributeNS(namespace, name)).takeIf(String::isNotEmpty)
            ?: throw AppcastException("an enclosure has no $name")

    /** Namespace-aware, with no DTDs or external entities: the feed comes from the network. */
    private val builderFactory: DocumentBuilderFactory = DocumentBuilderFactory.newInstance().apply {
        isNamespaceAware = true
        setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)
        setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
        isExpandEntityReferences = false
    }
}
