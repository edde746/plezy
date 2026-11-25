package com.edde746.plezy.model

import com.edde746.plezy.log.Log
import kotlin.concurrent.Volatile

/**
 * The device's region as streams' `behaviorHints.countryWhitelist` writes countries (ISO 3166-1 alpha-3, lowercase:
 * `usa`). The platform reports the region the system is set to as it starts, before any stream is looked at
 * ([com.edde746.plezy.app.SystemInputs.report]), and again when it changes ([setSystemRegion]): not the region of
 * the language the app is shown in (Android's and Apple's per-app language). Null when the system names no country (or
 * an area such as `419`, Latin America).
 */
object DeviceRegion {
    @Volatile
    internal var alpha3: String? = null
        private set

    /** The system's region as ISO 3166-1 alpha-2 (`US`, any case); null when the system names none. */
    fun setSystemRegion(alpha2: String?) {
        alpha3 = alpha2?.let(::alpha3)
        Log.i("DeviceRegion") { "system region ${alpha2 ?: "none"}: streams' country lists checked against ${alpha3 ?: "nothing"}" }
    }

    /** [alpha2] (`US`, any case) as alpha-3 (`usa`); null for a code ISO 3166-1 doesn't assign. */
    internal fun alpha3(alpha2: String): String? = CODES[alpha2.uppercase()]

    /** Every assigned ISO 3166-1 country: alpha-2 then alpha-3, as the JDK's `Locale.getISOCountries()` lists them. */
    private val CODES: Map<String, String> by lazy {
        TABLE.split(' ').associate { it.substring(0, 2) to it.substring(2).lowercase() }
    }

    private const val TABLE =
        "ADAND AEARE AFAFG AGATG AIAIA ALALB AMARM AOAGO AQATA ARARG ASASM ATAUT AUAUS AWABW AXALA AZAZE BABIH BBBRB " +
            "BDBGD BEBEL BFBFA BGBGR BHBHR BIBDI BJBEN BLBLM BMBMU BNBRN BOBOL BQBES BRBRA BSBHS BTBTN BVBVT BWBWA BYBLR " +
            "BZBLZ CACAN CCCCK CDCOD CFCAF CGCOG CHCHE CICIV CKCOK CLCHL CMCMR CNCHN COCOL CRCRI CUCUB CVCPV CWCUW CXCXR " +
            "CYCYP CZCZE DEDEU DJDJI DKDNK DMDMA DODOM DZDZA ECECU EEEST EGEGY EHESH ERERI ESESP ETETH FIFIN FJFJI FKFLK " +
            "FMFSM FOFRO FRFRA GAGAB GBGBR GDGRD GEGEO GFGUF GGGGY GHGHA GIGIB GLGRL GMGMB GNGIN GPGLP GQGNQ GRGRC GSSGS " +
            "GTGTM GUGUM GWGNB GYGUY HKHKG HMHMD HNHND HRHRV HTHTI HUHUN IDIDN IEIRL ILISR IMIMN ININD IOIOT IQIRQ IRIRN " +
            "ISISL ITITA JEJEY JMJAM JOJOR JPJPN KEKEN KGKGZ KHKHM KIKIR KMCOM KNKNA KPPRK KRKOR KWKWT KYCYM KZKAZ LALAO " +
            "LBLBN LCLCA LILIE LKLKA LRLBR LSLSO LTLTU LULUX LVLVA LYLBY MAMAR MCMCO MDMDA MEMNE MFMAF MGMDG MHMHL MKMKD " +
            "MLMLI MMMMR MNMNG MOMAC MPMNP MQMTQ MRMRT MSMSR MTMLT MUMUS MVMDV MWMWI MXMEX MYMYS MZMOZ NANAM NCNCL NENER " +
            "NFNFK NGNGA NINIC NLNLD NONOR NPNPL NRNRU NUNIU NZNZL OMOMN PAPAN PEPER PFPYF PGPNG PHPHL PKPAK PLPOL PMSPM " +
            "PNPCN PRPRI PSPSE PTPRT PWPLW PYPRY QAQAT REREU ROROU RSSRB RURUS RWRWA SASAU SBSLB SCSYC SDSDN SESWE SGSGP " +
            "SHSHN SISVN SJSJM SKSVK SLSLE SMSMR SNSEN SOSOM SRSUR SSSSD STSTP SVSLV SXSXM SYSYR SZSWZ TCTCA TDTCD TFATF " +
            "TGTGO THTHA TJTJK TKTKL TLTLS TMTKM TNTUN TOTON TRTUR TTTTO TVTUV TWTWN TZTZA UAUKR UGUGA UMUMI USUSA UYURY " +
            "UZUZB VAVAT VCVCT VEVEN VGVGB VIVIR VNVNM VUVUT WFWLF WSWSM YEYEM YTMYT ZAZAF ZMZMB ZWZWE"
}
