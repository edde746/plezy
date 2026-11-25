package com.edde746.plezy.desktop

import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.nio.file.Path

/**
 * The ids a native library's debug file is found by, read from the library itself: an ELF's GNU build id, a PE's
 * CodeView record (the PDB's GUID and age). The crash tracker matches a crash's images to the uploaded debug files by
 * [debugId].
 */
internal object NativeImages {
    data class Ids(val kind: String, val debugId: String, val codeId: String?, val debugFile: String?)

    /** [file]'s ids; null when it isn't a 64-bit little-endian ELF or a PE with a CodeView record, or can't be read. */
    fun read(file: Path): Ids? = try {
        FileChannel.open(file).use { channel ->
            val magic = channel.at(0, 4)
            when {
                magic.int == ELF_MAGIC -> elf(channel)
                magic.getShort(0) == DOS_MAGIC -> pe(channel)
                else -> null
            }
        }
    } catch (_: IOException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }

    /** The build id from the first `PT_NOTE` segment that holds a `GNU` build-id note. */
    private fun elf(channel: FileChannel): Ids? {
        val header = channel.at(0, 64)
        if (header.get(4).toInt() != 2 || header.get(5).toInt() != 1) return null
        val phoff = header.getLong(0x20)
        val phentsize = header.getShort(0x36).toInt() and 0xffff
        val phnum = header.getShort(0x38).toInt() and 0xffff
        for (i in 0 until phnum) {
            val ph = channel.at(phoff + i.toLong() * phentsize, 56)
            if (ph.getInt(0) != PT_NOTE) continue
            val notes = channel.at(ph.getLong(8), ph.getLong(32).toInt())
            while (notes.remaining() >= 12) {
                val nameSize = notes.int
                val descSize = notes.int
                val type = notes.int
                val name = ByteArray(nameSize).also(notes::get)
                notes.position(notes.position() + pad(nameSize))
                val desc = ByteArray(descSize).also(notes::get)
                notes.position(notes.position() + pad(descSize))
                if (type == NT_GNU_BUILD_ID && name.decodeToString().trimEnd('\u0000') == "GNU") {
                    val guid = desc.copyOf(16)
                    return Ids("elf", guid(guid), desc.toHex(), debugFile = null)
                }
            }
        }
        return null
    }

    /** The CodeView (`RSDS`) record of the debug directory, and the code id Windows' symbol servers use. */
    private fun pe(channel: FileChannel): Ids? {
        val pe = channel.at(0x3c, 4).int.toLong()
        val coff = channel.at(pe, 24)
        if (coff.getInt(0) != PE_SIGNATURE) return null
        val sections = coff.getShort(6).toInt() and 0xffff
        val timestamp = coff.getInt(8)
        val optionalSize = coff.getShort(20).toInt() and 0xffff
        val optional = channel.at(pe + 24, optionalSize)
        val directories = when (optional.getShort(0).toInt() and 0xffff) {
            0x20b -> 112
            0x10b -> 96
            else -> return null
        }
        val sizeOfImage = optional.getInt(56)
        val debugRva = optional.getInt(directories + 6 * 8)
        val debugSize = optional.getInt(directories + 6 * 8 + 4)
        if (debugRva == 0) return null
        val table = channel.at(pe + 24 + optionalSize, sections * 40)
        val debugOffset = (0 until sections).firstNotNullOfOrNull { s ->
            val va = table.getInt(s * 40 + 12)
            val size = maxOf(table.getInt(s * 40 + 8), table.getInt(s * 40 + 16))
            if (debugRva - va in 0 until size) table.getInt(s * 40 + 20).toLong() + (debugRva - va) else null
        } ?: return null
        val entries = channel.at(debugOffset, debugSize)
        for (e in 0 until debugSize / 28) {
            if (entries.getInt(e * 28 + 12) != IMAGE_DEBUG_TYPE_CODEVIEW) continue
            val record = channel.at(entries.getInt(e * 28 + 24).toLong(), entries.getInt(e * 28 + 16))
            if (record.int != RSDS) continue
            val guid = ByteArray(16).also(record::get)
            val age = record.int
            val path = ByteArray(record.remaining()).also(record::get).takeWhile { it != 0.toByte() }.toByteArray().decodeToString()
            val codeId = "%08X%x".format(timestamp, sizeOfImage)
            return Ids("pe", "${guid(guid)}-${Integer.toHexString(age)}", codeId, path)
        }
        return null
    }

    /** 16 bytes as a GUID whose first three fields are little-endian, as Sentry writes debug ids. */
    private fun guid(bytes: ByteArray): String {
        val b = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        return "%08x-%04x-%04x-%s-%s".format(
            b.getInt(0),
            b.getShort(4).toInt() and 0xffff,
            b.getShort(6).toInt() and 0xffff,
            bytes.copyOfRange(8, 10).toHex(),
            bytes.copyOfRange(10, 16).toHex(),
        )
    }

    private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

    private fun pad(size: Int): Int = (4 - size % 4) % 4

    /** [size] bytes of the file from [offset], little-endian; throws when the file ends before. */
    private fun FileChannel.at(offset: Long, size: Int): ByteBuffer {
        require(offset >= 0 && size in 0..MAX_READ)
        val buffer = ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN)
        while (buffer.hasRemaining()) if (read(buffer, offset + buffer.position()) < 0) throw IOException("truncated")
        return buffer.flip()
    }

    private const val ELF_MAGIC = 0x464c457f
    private const val DOS_MAGIC: Short = 0x5a4d
    private const val PE_SIGNATURE = 0x00004550
    private const val PT_NOTE = 4
    private const val NT_GNU_BUILD_ID = 3
    private const val IMAGE_DEBUG_TYPE_CODEVIEW = 2
    private const val RSDS = 0x53445352
    private const val MAX_READ = 1 shl 20
}
