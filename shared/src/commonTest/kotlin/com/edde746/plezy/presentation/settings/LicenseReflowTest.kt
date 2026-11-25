package com.edde746.plezy.presentation.settings

import kotlin.test.Test
import kotlin.test.assertEquals

/** Licence files hard-wrapped at about 80 columns read as paragraphs that wrap to the screen, their lists and headings kept. */
class LicenseReflowTest {
    /** The file's lines as they are, indentation included. */
    private fun file(vararg lines: String) = lines.joinToString("\n", postfix = "\n")

    @Test
    fun apacheTwoKeepsItsCentredHeadingAndJoinsItsDefinitions() {
        val opening = file(
            "                                 Apache License",
            "                           Version 2.0, January 2004",
            "                        http://www.apache.org/licenses/",
            "",
            "   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION",
            "",
            "   1. Definitions.",
            "",
            "      \"License\" shall mean the terms and conditions for use, reproduction,",
            "      and distribution as defined by Sections 1 through 9 of this document.",
            "",
            "      \"Licensor\" shall mean the copyright owner or entity authorized by",
            "      the copyright owner that is granting the License.",
        )
        assertEquals(
            listOf(
                "Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/",
                "TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION",
                "1. Definitions.",
                "\"License\" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 " +
                    "through 9 of this document.",
                "\"Licensor\" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.",
            ),
            reflowLicense(opening),
        )
    }

    @Test
    fun anMitTextKeepsItsCopyrightListOnePerLine() {
        val expat = file(
            "Copyright (c) 1998-2000 Thai Open Source Software Center Ltd and Clark Cooper",
            "Copyright (c) 2001-2025 Expat maintainers",
            "",
            "Permission is hereby granted, free of charge, to any person obtaining",
            "a copy of this software and associated documentation files (the",
            "\"Software\"), to deal in the Software without restriction, including",
            "without limitation the rights to use, copy, modify, merge, publish,",
            "distribute, sublicense, and/or sell copies of the Software, and to",
            "permit persons to whom the Software is furnished to do so, subject to",
            "the following conditions:",
            "",
            "The above copyright notice and this permission notice shall be included",
            "in all copies or substantial portions of the Software.",
        )
        assertEquals(
            listOf(
                "Copyright (c) 1998-2000 Thai Open Source Software Center Ltd and Clark Cooper\nCopyright (c) 2001-2025 Expat maintainers",
                "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated " +
                    "documentation files (the \"Software\"), to deal in the Software without restriction, including without " +
                    "limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of " +
                    "the Software, and to permit persons to whom the Software is furnished to do so, subject to the following " +
                    "conditions:",
                "The above copyright notice and this permission notice shall be included in all copies or substantial portions " +
                    "of the Software.",
            ),
            reflowLicense(expat),
        )
    }

    /** Clauses with no blank line between them: each starts a line, its wrapped lines joined to it. */
    @Test
    fun aBsdClauseListKeepsOneClausePerLine() {
        val bsdiff = file(
            "Copyright 2003-2005 Colin Percival",
            "All rights reserved",
            "",
            "Redistribution and use in source and binary forms, with or without",
            "modification, are permitted providing that the following conditions ",
            "are met:",
            "1. Redistributions of source code must retain the above copyright",
            "   notice, this list of conditions and the following disclaimer.",
            "2. Redistributions in binary form must reproduce the above copyright",
            "   notice, this list of conditions and the following disclaimer in the",
            "   documentation and/or other materials provided with the distribution.",
        )
        assertEquals(
            listOf(
                "Copyright 2003-2005 Colin Percival\nAll rights reserved",
                "Redistribution and use in source and binary forms, with or without modification, are permitted providing that " +
                    "the following conditions are met:\n" +
                    "1. Redistributions of source code must retain the above copyright notice, this list of conditions and the " +
                    "following disclaimer.\n" +
                    "2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the " +
                    "following disclaimer in the documentation and/or other materials provided with the distribution.",
            ),
            reflowLicense(bsdiff),
        )
    }
}
