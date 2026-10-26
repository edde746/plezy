package com.bbflight.background_downloader

import java.io.IOException
import java.io.OutputStream

internal data class DownloadVolumeCapacity(val available: Long, val total: Long)

internal class DownloadStorageException(message: String, cause: Throwable? = null) :
    IOException(message, cause)

internal fun isDownloadStorageFailure(description: String?): Boolean =
    description?.startsWith("Insufficient space to store") == true ||
        description?.startsWith("Download storage capacity could not be determined") == true

/** Guards the actual output, including unknown-length downloads and copy fallbacks. */
internal class DownloadStorageGuard(
    private val output: OutputStream,
    private val checkValue: Int,
    contentLength: Long,
    private val capacity: () -> DownloadVolumeCapacity,
    private val removeIncomplete: () -> Unit,
    private val isCapacityError: (IOException) -> Boolean = { false }
) : OutputStream() {
    private var closed = false

    init {
        checkCapacity(contentLength.coerceAtLeast(0))
    }

    private fun checkCapacity(bytes: Long) {
        if (checkValue == 0) return
        val volume = try {
            capacity().also {
                require(it.total > 0 && it.available >= 0 && it.available <= it.total)
            }
        } catch (e: Exception) {
            fail(DownloadStorageException(
                "Download storage capacity could not be determined", e
            ))
        }
        val floor = if (checkValue < 0) {
            maxOf(256L * 1024 * 1024, volume.total / 100)
        } else {
            checkValue.toLong() * 1024 * 1024
        }
        // Subtraction avoids overflow for very large advertised lengths.
        if (volume.available < floor || bytes > volume.available - floor) {
            fail(DownloadStorageException("Insufficient space to store the file to be downloaded"))
        }
    }

    private fun fail(error: DownloadStorageException): Nothing {
        try {
            close()
        } catch (e: Exception) {
            error.addSuppressed(e)
        }
        try {
            removeIncomplete()
        } catch (e: Exception) {
            error.addSuppressed(e)
        }
        throw error
    }

    override fun write(value: Int) {
        check(!closed) { "Download output is closed" }
        checkCapacity(1)
        try {
            output.write(value)
        } catch (e: IOException) {
            handleWriteFailure(e)
        }
    }

    override fun write(bytes: ByteArray, offset: Int, length: Int) {
        if (offset < 0 || length < 0 || offset > bytes.size - length) {
            throw IndexOutOfBoundsException()
        }
        check(!closed) { "Download output is closed" }
        var position = offset
        var remaining = length
        while (remaining > 0) {
            val count = minOf(remaining, 64 * 1024)
            checkCapacity(count.toLong())
            try {
                output.write(bytes, position, count)
            } catch (e: IOException) {
                handleWriteFailure(e)
            }
            position += count
            remaining -= count
        }
    }

    private fun handleWriteFailure(error: IOException): Nothing {
        if (isCapacityError(error)) {
            fail(DownloadStorageException("Insufficient space to store the file to be downloaded", error))
        }
        // A failed write may be the first observation of capacity consumed concurrently.
        checkCapacity(1)
        throw error
    }

    override fun flush() {
        if (!closed) output.flush()
    }

    override fun close() {
        if (!closed) {
            closed = true
            output.close()
        }
    }
}
