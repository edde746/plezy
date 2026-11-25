package com.edde746.plezy.playback

import kotlin.io.encoding.Base64
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Picks a video's intro and credits chapter from its chapter list alone: titles plus start and end times.
 *
 * A boosted-tree ensemble scores every chapter as other, intro or credits from 48 numbers: where the chapter sits and
 * how long it and its neighbours run, whether its title is generic ("Chapter 3", a timestamp, empty), intro and
 * credits keywords in its own and its neighbours' titles, and a 24-number embedding of its title's character n-grams.
 * Timing finds the 90-second opening of an episode whose chapters are all "Chapter N"; context passes over a cold open
 * titled "Intro" before an explicit "OP". The model (`src/commonMain/models/chapter_marker_model.bin`, 164 KB) was
 * trained on the chapter lists of its author's libraries (titles and times only); the feature code mirrors the training
 * script line for line, and `ChapterMarkerClassifierTest` holds the script's probabilities for its reference inputs.
 */
internal class ChapterMarkerClassifier private constructor(
    private val featureCount: Int,
    private val buckets: Int,
    private val embedDim: Int,
    private val baseline: DoubleArray,
    private val scale: DoubleArray,
    private val idf: FloatArray,
    /** Projection rows of the buckets that have one, [embedDim] values each; every other bucket's row is zeros. */
    private val table: ByteArray,
    /** Per bucket, the offset of its row in [table], or -1 for an all-zero row. */
    private val tableRow: IntArray,
    private val treeStarts: IntArray,
    private val nodeFeature: IntArray,
    /** The split threshold of a split node, the contribution of a leaf. */
    private val nodeValue: DoubleArray,
    private val nodeRight: IntArray,
) {
    /** A chapter as the classifier sees it: its title and its span in milliseconds, [endMs] ≥ [startMs]. */
    data class Span(val title: String?, val startMs: Long, val endMs: Long)

    /**
     * The chapters picked, as indices into the spans given ([intro], [credits]), and whether the model is as sure of
     * another chapter ([isIntro], [isCredits]: an intro or credits split over chapters), the duration rules applied.
     */
    class Picks(val intro: Int?, val credits: Int?, private val probabilities: List<DoubleArray>) {
        fun isIntro(index: Int): Boolean = probabilities[index][INTRO] >= THRESHOLD

        fun isCredits(index: Int): Boolean = probabilities[index][CREDITS] >= THRESHOLD
    }

    /**
     * The intro and credits chapters, if the model is confident: per kind, the most probable chapter that lasts at
     * least [MIN_MARKER_MS] (and at most [MAX_INTRO_MS] for an intro), when its probability reaches [THRESHOLD]. One
     * chapter is never both.
     */
    fun pick(spans: List<Span>): Picks {
        if (spans.isEmpty()) return Picks(null, null, emptyList())
        val probs = probabilities(spans)
        spans.forEachIndexed { i, span ->
            val duration = span.endMs - span.startMs
            if (duration < MIN_MARKER_MS) {
                probs[i][INTRO] = 0.0
                probs[i][CREDITS] = 0.0
            } else if (duration > MAX_INTRO_MS) {
                probs[i][INTRO] = 0.0
            }
        }
        fun best(cls: Int, taken: Int?): Int? {
            var at = 0
            for (i in 1 until probs.size) if (probs[i][cls] > probs[at][cls]) at = i
            return at.takeIf { probs[at][cls] >= THRESHOLD && at != taken }
        }
        val intro = best(INTRO, null)
        return Picks(intro, best(CREDITS, intro), probs)
    }

    /** Per chapter, the `[other, intro, credits]` probabilities, before the duration rules [pick] applies. */
    internal fun probabilities(spans: List<Span>): List<DoubleArray> {
        val x = features(spans)
        return List(spans.size) { i -> softmax(raw(x, i * featureCount)) }
    }

    private fun raw(x: FloatArray, row: Int): DoubleArray {
        val raw = baseline.copyOf()
        for (t in treeStarts.indices) {
            var i = treeStarts[t]
            var f = nodeFeature[i]
            while (f != LEAF) {
                i = if (x[row + f].toDouble() <= nodeValue[i]) i + 1 else nodeRight[i]
                f = nodeFeature[i]
            }
            raw[t % raw.size] += nodeValue[i]
        }
        return raw
    }

    // Features: mirror `features` in the training script.

    /**
     * Features rounded to float32 as the script's are: split thresholds can sit exactly on a value that repeats in the
     * training data, and the rounding absorbs last-bit differences in the arithmetic.
     */
    private fun features(spans: List<Span>): FloatArray {
        val n = spans.size
        val runtime = max(spans.maxOf { it.endMs }, 1L)
        val titles = spans.map { clean(it.title) }
        val keywords = titles.map { doubleArrayOf(if (INTRO_WORDS.containsMatchIn(it)) 1.0 else 0.0, if (CREDITS_WORDS.containsMatchIn(it)) 1.0 else 0.0) }
        val durations = spans.map { (it.endMs - it.startMs) / 1000.0 }
        val none = doubleArrayOf(-1.0, -1.0)
        val x = FloatArray(n * featureCount)
        for (i in 0 until n) {
            val s = spans[i].startMs.toDouble()
            val e = spans[i].endMs.toDouble()
            val d = durations[i]
            val t = titles[i]
            val before = if (i > 0) keywords[i - 1] else none
            val after = if (i + 1 < n) keywords[i + 1] else none
            val row = doubleArrayOf(
                s / runtime,
                e / runtime,
                (e - s) / runtime,
                ln(1 + d) / LOG_HOUR,
                min(s / 1000, 900.0) / 900,
                min((runtime - e) / 1000, 900.0) / 900,
                min(abs(d - 90), 300.0) / 300,
                i.toDouble() / max(n - 1, 1),
                if (i == 0) 1.0 else 0.0,
                if (i == n - 1) 1.0 else 0.0,
                min(n, 40) / 40.0,
                ln(1 + runtime / 1000.0) / LOG_4_HOURS,
                if (d in 84.0..96.0) 1.0 else 0.0,
                if (i > 0) min(durations[i - 1], 900.0) / 900 else -1.0,
                if (i + 1 < n) min(durations[i + 1], 900.0) / 900 else -1.0,
                if (GENERIC_TITLE.containsMatchIn(t)) 1.0 else 0.0,
                if (t.isEmpty()) 1.0 else 0.0,
                keywords[i][0], keywords[i][1],
                before[0], before[1],
                after[0], after[1],
                codePoints(t).size / 40.0,
            )
            val at = i * featureCount
            row.forEachIndexed { k, v -> x[at + k] = v.toFloat() }
            embed(t).forEachIndexed { k, v -> x[at + TITLE_FEATURES + k] = v.toFloat() }
        }
        return x
    }

    /**
     * Hashed n-gram counts, idf weights, L2 normalised, through the int8 projection, summed in ascending bucket order
     * as the script's sparse product is. A bucket without a table row only adds to the norm.
     */
    private fun embed(cleaned: String): DoubleArray {
        val out = DoubleArray(embedDim)
        val counts = titleBuckets(cleaned)
        if (counts.isEmpty()) return out
        val sorted = counts.keys.sorted()
        var squares = 0.0
        for (b in sorted) {
            val w = counts.getValue(b) * idf[b].toDouble()
            squares += w * w
        }
        val inverseNorm = 1 / sqrt(squares)
        for (b in sorted) {
            val row = tableRow[b]
            if (row < 0) continue
            val w = counts.getValue(b) * idf[b].toDouble() * inverseNorm
            for (k in 0 until embedDim) out[k] += w * (table[row + k] * scale[k])
        }
        return out
    }

    /** Counts of FNV-1a-hashed 1–3 character n-grams of each space-padded word, digits folded to 0. */
    private fun titleBuckets(cleaned: String): Map<Int, Int> {
        val counts = HashMap<Int, Int>()
        for (word in cleaned.replace(DIGIT, "0").split(' ')) {
            if (word.isEmpty()) continue
            val padded = listOf(SPACE) + codePoints(word).map { it.encodeToByteArray() } + listOf(SPACE)
            for (n in 1..3) {
                for (i in 0..padded.size - n) {
                    var h = 0x811C9DC5L
                    for (k in i until i + n) for (byte in padded[k]) h = ((h xor (byte.toLong() and 0xFF)) * 0x01000193L) and 0xFFFFFFFFL
                    val bucket = (h % buckets).toInt()
                    counts[bucket] = (counts[bucket] ?: 0) + 1
                }
            }
        }
        return counts
    }

    companion object {
        /** The model that ships with the app, decoded on first use. */
        val bundled: ChapterMarkerClassifier by lazy { decode(Base64.decode(ChapterMarkerModel.base64())) }

        /** The least probability a pick needs. */
        const val THRESHOLD = 0.8

        /** A chapter shorter than this is never picked. */
        const val MIN_MARKER_MS = 5_000L

        /** A chapter longer than this is never the intro: a movie's "Opening Credits" can run 5–10 minutes of picture. */
        const val MAX_INTRO_MS = 180_000L

        private const val LEAF = 0xFF
        private const val INTRO = 1
        private const val CREDITS = 2
        private const val TITLE_FEATURES = 24

        private val SPACE = byteArrayOf(0x20)
        private val LOG_HOUR = ln(3600.0)
        private val LOG_4_HOURS = ln(4 * 3600.0)

        // The script's patterns with its explicit character lists, and `\b` spelled out as ASCII lookarounds, since
        // the platforms' regex engines disagree on what a word character is.
        private val WHITESPACE = Regex("[\t\n\u000B\u000C\r \u0085\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+")
        private val DIGIT = Regex("[0-9]")
        private const val NOT_WORD_BEFORE = "(?<![A-Za-z0-9_])"
        private const val NOT_WORD_AFTER = "(?![A-Za-z0-9_])"
        private val INTRO_WORDS = Regex("$NOT_WORD_BEFORE(?:intro(?:duction)?|opening)$NOT_WORD_AFTER|^op(?: ?[0-9]+)?$")
        private val CREDITS_WORDS = Regex("$NOT_WORD_BEFORE(?:outro|credits?|ending)$NOT_WORD_AFTER|^ed(?: ?[0-9]+)?$")
        private const val GW = "(?:(?:chapter|chapitre|kapitel|cap[ií]tulo|capitolo|hoofdstuk|глава|チャプター|scene|part) ?[#\\-_.]? ?)?"
        private val GENERIC_TITLE = Regex(
            "^$GW[0-9]+(?: $GW[0-9]+)*$" +
                "|^(?:\\([0-9]+\\))? ?[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?(?:[.,:][0-9]+)?$" +
                "|^\\(unnamed scene\\)$|^(?:chapter)?$",
        )

        /** Fullwidth ASCII to ASCII, whitespace runs to one space, trimmed of spaces, lower case. */
        private fun clean(title: String?): String {
            if (title.isNullOrEmpty()) return ""
            val ascii = buildString(title.length) { for (c in title) append(if (c in '\uFF01'..'\uFF5E') c - 0xFEE0 else c) }
            return WHITESPACE.replace(ascii, " ").trim(' ').lowercase()
        }

        /** [text]'s code points, each as a string. */
        private fun codePoints(text: String): List<String> {
            val out = ArrayList<String>(text.length)
            var i = 0
            while (i < text.length) {
                val pair = text[i].isHighSurrogate() && i + 1 < text.length && text[i + 1].isLowSurrogate()
                val end = if (pair) i + 2 else i + 1
                out += text.substring(i, end)
                i = end
            }
            return out
        }

        private fun softmax(raw: DoubleArray): DoubleArray {
            val top = raw.max()
            val out = DoubleArray(raw.size) { exp(raw[it] - top) }
            val sum = out[0] + out[1] + out[2]
            for (k in out.indices) out[k] /= sum
            return out
        }

        /** Reads the little-endian layout the training script's `serialize` writes. */
        internal fun decode(bytes: ByteArray): ChapterMarkerClassifier {
            var at = 0
            fun u8(): Int = bytes[at++].toInt() and 0xFF
            fun u16(): Int = u8() or (u8() shl 8)
            fun u32(): Long = (u16().toLong()) or (u16().toLong() shl 16)
            fun f32(): Float = Float.fromBits(u32().toInt())
            fun f64(): Double = Double.fromBits(u32() or (u32() shl 32))

            require(bytes.size >= 4 && bytes.decodeToString(0, 4) == "PCM2") { "Not a chapter marker model" }
            at = 4
            val featureCount = u16()
            val buckets = u32().toInt()
            val embedDim = u8()
            val classes = u8()
            require(classes == 3 && featureCount == TITLE_FEATURES + embedDim) {
                "Unsupported chapter marker model: $classes classes, $featureCount features"
            }
            val baseline = DoubleArray(classes) { f64() }
            val scale = DoubleArray(embedDim) { f64() }
            val idf = FloatArray(buckets) { f32() }
            val bitmap = at
            at += (buckets + 7) shr 3
            var rows = 0
            val tableRow = IntArray(buckets) { b ->
                if ((bytes[bitmap + (b shr 3)].toInt() shr (b and 7)) and 1 == 1) embedDim * rows++ else -1
            }
            val table = bytes.copyOfRange(at, at + rows * embedDim)
            at += table.size
            val thresholds = Array(featureCount) { DoubleArray(u8()) { f64() } }
            val treeCount = u16()
            val nodeCount = u32().toInt()
            val treeStarts = IntArray(treeCount)
            val nodeFeature = IntArray(nodeCount)
            val nodeValue = DoubleArray(nodeCount)
            val nodeRight = IntArray(nodeCount)
            var node = 0
            for (t in 0 until treeCount) {
                val start = node
                treeStarts[t] = start
                repeat(u16()) {
                    val feature = u8()
                    nodeFeature[node] = feature
                    if (feature == LEAF) {
                        nodeValue[node] = f32().toDouble()
                    } else {
                        nodeValue[node] = thresholds[feature][u8()]
                        nodeRight[node] = start + u16()
                    }
                    node++
                }
            }
            require(node == nodeCount && at == bytes.size) { "Truncated chapter marker model" }
            return ChapterMarkerClassifier(
                featureCount, buckets, embedDim, baseline, scale, idf, table, tableRow, treeStarts, nodeFeature, nodeValue, nodeRight,
            )
        }
    }
}
