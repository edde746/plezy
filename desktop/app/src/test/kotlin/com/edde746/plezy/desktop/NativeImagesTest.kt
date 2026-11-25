package com.edde746.plezy.desktop

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.writeBytes
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The ids a library's debug file is found by, as Sentry writes them, read from minimal ELF and PE files. */
class NativeImagesTest {
    private val root = Files.createTempDirectory("native-images")

    @AfterTest
    fun cleanUp() {
        root.toFile().deleteRecursively()
    }

    /** Bytes 0 to [count] - 1. */
    private fun counting(count: Int) = ByteArray(count) { it.toByte() }

    private fun file(name: String, size: Int, write: ByteBuffer.() -> Unit): Path {
        val bytes = ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN).apply(write).array()
        return root.resolve(name).also { it.writeBytes(bytes) }
    }

    @Test
    fun anElfsDebugIdIsItsBuildIdAsALittleEndianGuid() {
        val buildId = counting(20)
        val elf = file("libmpv.so.2.5.0", 156) {
            put(0, byteArrayOf(0x7f, 'E'.code.toByte(), 'L'.code.toByte(), 'F'.code.toByte(), 2, 1, 1))
            putLong(0x20, 64)
            putShort(0x36, 56)
            putShort(0x38, 1)
            // The one program header: a PT_NOTE segment at 120.
            putInt(64, 4)
            putLong(64 + 8, 120)
            putLong(64 + 32, 36)
            // The note: GNU's build id.
            putInt(120, 4)
            putInt(124, 20)
            putInt(128, 3)
            put(132, "GNU\u0000".encodeToByteArray())
            put(136, buildId)
        }
        assertEquals(
            NativeImages.Ids("elf", "03020100-0504-0706-0809-0a0b0c0d0e0f", "000102030405060708090a0b0c0d0e0f10111213", null),
            NativeImages.read(elf),
        )
    }

    @Test
    fun aPesDebugIdIsItsCodeViewGuidAndAge() {
        val dll = file("libmpv-2.dll", 0x260) {
            put(0, "MZ".encodeToByteArray())
            putInt(0x3c, 0x40)
            put(0x40, "PE\u0000\u0000".encodeToByteArray())
            putShort(0x46, 1)
            putInt(0x48, 0x5F3E2A1B)
            putShort(0x54, 240)
            // The optional header (PE32+): its image size and the debug directory's entry.
            putShort(0x58, 0x20b)
            putInt(0x58 + 56, 0x123000)
            putInt(0x58 + 112 + 48, 0x1000)
            putInt(0x58 + 112 + 52, 28)
            // One section, mapping RVA 0x1000 to file offset 0x200.
            putInt(0x148 + 8, 0x200)
            putInt(0x148 + 12, 0x1000)
            putInt(0x148 + 16, 0x200)
            putInt(0x148 + 20, 0x200)
            // The debug directory: a CodeView record at 0x220.
            putInt(0x200 + 12, 2)
            putInt(0x200 + 16, 37)
            putInt(0x200 + 24, 0x220)
            put(0x220, "RSDS".encodeToByteArray())
            put(0x224, counting(16))
            putInt(0x234, 1)
            put(0x238, "libmpv-2.pdb\u0000".encodeToByteArray())
        }
        assertEquals(
            NativeImages.Ids("pe", "03020100-0504-0706-0809-0a0b0c0d0e0f-1", "5F3E2A1B123000", "libmpv-2.pdb"),
            NativeImages.read(dll),
        )
    }

    @Test
    fun aFileThatIsNeitherOrIsGoneHasNoIds() {
        assertNull(NativeImages.read(file("notes.txt", 16) { put(0, "not a library".encodeToByteArray()) }))
        assertNull(NativeImages.read(root.resolve("missing.dll")))
    }
}
