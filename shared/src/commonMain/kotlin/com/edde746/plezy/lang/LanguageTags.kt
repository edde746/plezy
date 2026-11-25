package com.edde746.plezy.lang

/**
 * Language codes as BCP 47 tags, reduced to their shortest form so codes from different sources compare equal.
 *
 * Sources and what they send:
 * - mpv reports what the container says: ISO 639-2 codes, terminologic (`deu`) or bibliographic (`ger`, which
 *   Matroska uses), ISO 639-1 codes, or BCP 47 tags (`pt-BR`, Matroska's `LanguageIETF`).
 * - Subtitle services (OpenSubtitles) send ISO 639-2 codes, bibliographic or terminologic (`cze`, `ell`), and their
 *   own codes for variants: `pob` (Portuguese, Brazil), `zht` (Chinese, traditional), `ea` (Spanish, Latin America)
 *   and a few legacy ones ([VARIANT_CODES]).
 * - Language preferences are stored as ISO 639-2 codes ([preferenceCodes]).
 */
internal object LanguageTags {
    /** ISO 639-2 codes that don't name a language: undetermined, multiple, no linguistic content, uncoded. */
    private val NOT_A_LANGUAGE = setOf("und", "mul", "zxx", "mis")

    /**
     * ISO 639-1 code, ISO 639-2/T code and, where it differs, the ISO 639-2/B code of every language with a
     * two-letter code.
     */
    private const val ISO_639 =
        "aa:aar ab:abk ae:ave af:afr ak:aka am:amh an:arg ar:ara as:asm av:ava ay:aym az:aze ba:bak be:bel " +
            "bg:bul bh:bih bi:bis bm:bam bn:ben bo:bod:tib br:bre bs:bos ca:cat ce:che ch:cha co:cos cr:cre " +
            "cs:ces:cze cu:chu cv:chv cy:cym:wel da:dan de:deu:ger dv:div dz:dzo ee:ewe el:ell:gre en:eng eo:epo " +
            "es:spa et:est eu:eus:baq fa:fas:per ff:ful fi:fin fj:fij fo:fao fr:fra:fre fy:fry ga:gle gd:gla " +
            "gl:glg gn:grn gu:guj gv:glv ha:hau he:heb hi:hin ho:hmo hr:hrv ht:hat hu:hun hy:hye:arm hz:her " +
            "ia:ina id:ind ie:ile ig:ibo ii:iii ik:ipk io:ido is:isl:ice it:ita iu:iku ja:jpn jv:jav ka:kat:geo " +
            "kg:kon ki:kik kj:kua kk:kaz kl:kal km:khm kn:kan ko:kor kr:kau ks:kas ku:kur kv:kom kw:cor ky:kir " +
            "la:lat lb:ltz lg:lug li:lim ln:lin lo:lao lt:lit lu:lub lv:lav mg:mlg mh:mah mi:mri:mao mk:mkd:mac " +
            "ml:mal mn:mon mr:mar ms:msa:may mt:mlt my:mya:bur na:nau nb:nob nd:nde ne:nep ng:ndo nl:nld:dut " +
            "nn:nno no:nor nr:nbl nv:nav ny:nya oc:oci oj:oji om:orm or:ori os:oss pa:pan pi:pli pl:pol ps:pus " +
            "pt:por qu:que rm:roh rn:run ro:ron:rum ru:rus rw:kin sa:san sc:srd sd:snd se:sme sg:sag si:sin " +
            "sk:slk:slo sl:slv sm:smo sn:sna so:som sq:sqi:alb sr:srp ss:ssw st:sot su:sun sv:swe sw:swa ta:tam " +
            "te:tel tg:tgk th:tha ti:tir tk:tuk tl:tgl tn:tsn to:ton tr:tur ts:tso tt:tat tw:twi ty:tah ug:uig " +
            "uk:ukr ur:urd uz:uzb ve:ven vi:vie vo:vol wa:wln wo:wol xh:xho yi:yid yo:yor za:zha zh:zho:chi " +
            "zu:zul"

    /**
     * OpenSubtitles' codes for language variants, and legacy codes still in use: Brazilian Portuguese, traditional
     * and bilingual Chinese, Latin American Spanish, Montenegrin, and the withdrawn ISO 639-2 codes for Serbian,
     * Croatian and Moldavian.
     */
    private val VARIANT_CODES = mapOf(
        "pob" to "pt-BR",
        "pb" to "pt-BR",
        "zht" to "zh-Hant",
        "zhe" to "zh",
        "ea" to "es-419",
        "mne" to "cnr",
        "scc" to "sr",
        "scr" to "hr",
        "mol" to "ro",
    )

    /** Three-letter code → two-letter code. */
    private val shortCodes: Map<String, String> by lazy {
        buildMap {
            for (entry in ISO_639.split(' ')) {
                val codes = entry.split(':')
                for (long in codes.drop(1)) put(long, codes[0])
            }
        }
    }

    /** Two-letter code → ISO 639-2/T code. */
    private val terminologicCodes: Map<String, String> by lazy {
        ISO_639.split(' ').associate { entry -> entry.split(':').let { it[0] to it[1] } }
    }

    /** The ISO 639-2/T code of a two-letter [code1] (`fr` → `fra`, `de` → `deu`), or null when unknown. */
    fun terminologic(code1: String): String? = terminologicCodes[code1.trim().lowercase()]

    /**
     * Every language an audio or subtitle preference can name, as the codes it stores: the ISO 639-2 code of each
     * language with a two-letter code (the bibliographic one where it differs, `ger`, as OpenSubtitles writes them),
     * then OpenSubtitles' codes for the variants it has subtitles in: Brazilian Portuguese, traditional Chinese and
     * Latin American Spanish.
     */
    val preferenceCodes: List<String> by lazy {
        ISO_639.split(' ').map { it.split(':').last() } + listOf("pob", "zht", "ea")
    }

    /**
     * The canonical BCP 47 form of [language] (`ger` → `de`, `pt_br` → `pt-BR`, `pob` → `pt-BR`), or null when it
     * doesn't name a language (missing, blank, `und`, not a language tag).
     */
    fun canonical(language: String?): String? {
        val parts = language?.trim()?.split('-', '_')?.takeIf { it.isNotEmpty() } ?: return null
        val primary = parts[0].lowercase()
        if (primary.length !in 2..3 || !primary.all { it in 'a'..'z' } || primary in NOT_A_LANGUAGE) return null
        val subtags = parts.drop(1)
        if (subtags.any { it.isEmpty() || it.length > 8 || !it.all(Char::isLetterOrDigit) }) return null
        val base = if (subtags.isEmpty()) VARIANT_CODES[primary] else null
        return base ?: (listOf(shortCodes[primary] ?: primary) + subtags.map(::canonicalSubtag)).joinToString("-")
    }

    /**
     * Whether [value] is written as a language code (`eng`, `pt-BR`, `und`), whether or not it names a language;
     * otherwise it is text ("English", "Português (Brasil)").
     */
    fun isCode(value: String): Boolean {
        val primary = value.trim().split('-', '_')[0]
        return primary.length in 2..3 && primary.all { it in 'a'..'z' || it in 'A'..'Z' }
    }

    /** The language subtag of a canonical [tag] (`pt` for `pt-BR`). */
    fun primary(tag: String): String = tag.substringBefore('-')

    /**
     * How well [candidate] serves a wish for [wanted] (both canonical tags): 2 for the same tag, 1 for the same
     * language with another or no region or script (`pt` for `pt-BR`), 0 for another language.
     */
    fun match(wanted: String, candidate: String): Int = when {
        wanted == candidate -> 2
        primary(wanted) == primary(candidate) -> 1
        else -> 0
    }

    /** Scripts in title case (`Hant`), regions in capitals (`BR`, `419`), anything else lowercase. */
    private fun canonicalSubtag(subtag: String): String = when {
        subtag.length == 4 && subtag.all(Char::isLetter) -> subtag.lowercase().replaceFirstChar(Char::uppercaseChar)
        subtag.length == 2 && subtag.all(Char::isLetter) -> subtag.uppercase()
        else -> subtag.lowercase()
    }
}
