package com.edde746.plezy.format

import kotlin.test.Test
import kotlin.test.assertEquals

class ByteSizeTest {
    private val kib = 1024L
    private val mib = kib * 1024
    private val gib = mib * 1024

    @Test
    fun picksTheLargestUnitBelow1024() {
        assertEquals("0 B", formatByteSize(0))
        assertEquals("1023 B", formatByteSize(1023))
        assertEquals("1 KB", formatByteSize(kib))
        assertEquals("1.5 KB", formatByteSize(1536))
        assertEquals("850 MB", formatByteSize(850 * mib))
        assertEquals("12.3 GB", formatByteSize((12.3 * gib).toLong()))
        assertEquals("1.5 TB", formatByteSize(1536 * gib))
        assertEquals("2048 TB", formatByteSize(2048 * 1024 * gib))
    }

    @Test
    fun oneDecimalBelowAHundredAndNoneFromIt() {
        assertEquals("4 GB", formatByteSize(4 * gib))
        assertEquals("99.9 MB", formatByteSize((99.94 * mib).toLong()))
        assertEquals("100 MB", formatByteSize((99.96 * mib).toLong()))
        assertEquals("101 MB", formatByteSize((100.6 * mib).toLong()))
    }

    @Test
    fun roundingUpTo1024MovesToTheNextUnit() {
        assertEquals("1 GB", formatByteSize((1023.6 * mib).toLong()))
        assertEquals("1023 MB", formatByteSize((1023.4 * mib).toLong()))
    }

    @Test
    fun negativeCountsReadAsZero() {
        assertEquals("0 B", formatByteSize(-5))
    }
}
