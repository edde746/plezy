package com.edde746.plezy.ui.image

import coil3.EventListener
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.Uri
import coil3.annotation.ExperimentalCoilApi
import coil3.disk.DiskCache
import coil3.fetch.Fetcher
import coil3.key.Keyer
import coil3.memory.MemoryCache
import coil3.network.NetworkClient
import coil3.network.NetworkFetcher
import coil3.network.NetworkRequest
import coil3.network.NetworkResponse
import coil3.network.ktor3.asNetworkClient
import coil3.request.ImageRequest
import coil3.request.Options
import coil3.request.SuccessResult
import coil3.request.crossfade
import coil3.request.transformations
import coil3.transform.Transformation
import com.edde746.plezy.crash.MemoryPressure
import com.edde746.plezy.image.ArtworkCache
import com.edde746.plezy.image.ImageMemoryBudget
import io.ktor.client.HttpClient
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import okio.FileSystem
import coil3.network.NetworkResponseBody
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okio.Buffer
import okio.BufferedSink
import okio.ForwardingFileSystem
import okio.ForwardingSink
import okio.IOException
import okio.Sink
import okio.buffer
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource
import okio.Path
import kotlin.concurrent.Volatile
import kotlin.time.Clock
import coil3.network.CacheStrategy
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.UrlTokens
import java.io.File
import java.io.RandomAccessFile
import java.nio.channels.FileChannel
import java.nio.channels.OverlappingFileLockException
import java.util.concurrent.atomic.AtomicReference
import kotlin.time.TimeMark
import okio.Path.Companion.toOkioPath

/**
 * The app's [ImageLoader], caching as [ArtworkCache] says: a web image downloads through [http] (`AppGraph.http`: its
 * User-Agent, proxy and TLS settings), at most [ArtworkCache.downloadConcurrency] at once ([reduced]: the reduced
 * effects tier), and is kept in memory (within [memory], [ImageMemory]) and on disk in [directory] under
 * [ArtworkCache.key], without its token ([openArtworkDiskCache]); Coil's disk cache names the entry's files by that
 * key's SHA-256. Only a successful response is cached, and a cached failure is asked for again. Artwork is asked for at
 * the size Coil measures ([SizedArtworkMapper]); images decode through the platform's [addDecoders], with a short
 * crossfade. The mapping, keys and memory cache lookups run off the main thread; each image's memory cache key is kept
 * for the request asking for it again ([LoadedImageKeys]).
 */
// NetworkFetcher.Factory's constructor names Coil's cache strategy, which is marked experimental.
@OptIn(ExperimentalCoilApi::class)
internal fun artworkImageLoader(
    context: PlatformContext,
    http: HttpClient,
    reduced: Boolean,
    memory: ImageMemoryBudget,
    directory: File,
): ImageLoader {
    val network = NetworkFetcher.Factory(
        networkClient = { LimitedNetworkClient(http.asNetworkClient(), ArtworkCache.downloadConcurrency(reduced)) },
        cacheStrategy = { SuccessOnlyCacheStrategy },
    )
    return ImageLoader.Builder(context)
        .components {
            add(SizedArtworkMapper)
            add(ArtworkKeyer)
            add(ArtworkFetcherFactory(network))
            addDecoders()
        }
        .memoryCache {
            CountedMemoryCache(MemoryCache.Builder().maxSizeBytes(memory.bytes).build(), memory.images).also { ImageMemory.cache = it }
        }
        .diskCache { openArtworkDiskCache(directory) }
        .crossfade(true)
        .interceptorCoroutineContext(Dispatchers.Default)
        .eventListener(
            object : EventListener() {
                override fun onSuccess(request: ImageRequest, result: SuccessResult) {
                    result.memoryCacheKey?.let { LoadedImageKeys.put(request.data, request.transformations, it) }
                }
            },
        )
        .build()
}

/**
 * Coil's disk cache in [directory], which is created readable by its owner alone, once this process holds
 * `<directory>.lock` beside it: the entries [ArtworkCache.evictions] names go first ([sweepArtworkCache]). Null while
 * another loader holds it, in this process or another (a second Plezy running at once): that loader keeps its artwork
 * in memory only. The hold ends when the disk cache shuts down.
 */
internal fun openArtworkDiskCache(directory: File): DiskCache? {
    directory.mkdirs()
    directory.setReadable(false, false)
    directory.setWritable(false, false)
    directory.setExecutable(false, false)
    directory.setReadable(true, true)
    directory.setWritable(true, true)
    directory.setExecutable(true, true)
    val channel = RandomAccessFile(File(directory.parentFile, "${directory.name}.lock"), "rw").channel
    val lock = try {
        channel.tryLock()
    } catch (e: OverlappingFileLockException) {
        null
    }
    if (lock == null) {
        channel.close()
        Log.i(TAG) { "the artwork disk cache is in use by another Plezy: artwork stays in memory" }
        return null
    }
    val path = directory.toOkioPath()
    sweepArtworkCache(FileSystem.SYSTEM, path, Clock.System.now().toEpochMilliseconds())
    return HeldDiskCache(DiskCache.Builder().directory(path).build(), channel)
}

/** [delegate], its directory held through [lock] (its lock file's channel) until it shuts down. */
private class HeldDiskCache(private val delegate: DiskCache, private val lock: FileChannel) : DiskCache by delegate {
    override fun shutdown() {
        delegate.shutdown()
        lock.close()
    }
}

/**
 * Coil's cache strategy for responses that succeeded alone: a failure (a 404 from a proxy that comes back) is never
 * written, and one found cached is asked for again instead of read.
 */
@OptIn(ExperimentalCoilApi::class)
private object SuccessOnlyCacheStrategy : CacheStrategy {
    override suspend fun read(cacheResponse: NetworkResponse, networkRequest: NetworkRequest, options: Options) =
        if (cacheResponse.code in 200..299) CacheStrategy.ReadResult(cacheResponse) else CacheStrategy.ReadResult(networkRequest)

    override suspend fun write(cacheResponse: NetworkResponse?, networkRequest: NetworkRequest, networkResponse: NetworkResponse, options: Options) =
        if (networkResponse.code in 200..299) CacheStrategy.WriteResult(networkResponse) else CacheStrategy.WriteResult.DISABLED
}

private const val TAG = "artwork"

/**
 * The app's decoded images in memory (the [ProvideImageLoader] loader's memory cache), for memory pressure and the
 * memory watchdog: callable from any thread, outside composition; empty until the first image loads.
 */
object ImageMemory {
    @Volatile
    internal var cache: MemoryCache? = null

    /** The bitmaps' size in bytes. */
    val bytes: Long get() = cache?.size ?: 0

    /** The images held, those still drawn included. */
    val images: Int get() = cache?.keys?.size ?: 0

    /** Drops every image; those on screen stay drawn and load again from the disk cache when next asked for. */
    fun evict() {
        cache?.clear()
    }

    /** What the cache holds as [MemoryPressure.imageCacheData], [after] a release or before it. */
    fun pressureData(after: Boolean): Map<String, Any> = MemoryPressure.imageCacheData(bytes, images, after)
}

/**
 * The memory cache key each image last loaded under, by what its request asks for before its size is known (its data
 * and transformations): a request for it again starts on that image while the loader looks it up
 * ([ImageRequest.Builder.placeholderMemoryCacheKey]), so a card composed again shows its picture in its first frame. A
 * key whose image the memory cache has dropped finds nothing. The last [MAX_KEYS] kept; callable from any thread.
 */
internal object LoadedImageKeys {
    private const val MAX_KEYS = 1000

    /** Least recently used first. */
    private val keys = LinkedHashMap<Pair<Any, List<String>>, MemoryCache.Key>(16, 0.75f, true)

    operator fun get(data: Any, transformations: List<Transformation>): MemoryCache.Key? =
        synchronized(keys) { keys[data to transformations.map { it.cacheKey }] }

    fun put(data: Any, transformations: List<Transformation>, key: MemoryCache.Key) {
        synchronized(keys) {
            keys[data to transformations.map { it.cacheKey }] = key
            if (keys.size > MAX_KEYS) keys.remove(keys.keys.first())
        }
    }
}

/**
 * [delegate] (bounded by size) holding at most [maxImages] images: past that the least recently used goes. An image
 * [delegate] dropped for its size is forgotten when its turn comes.
 */
// Delegating MemoryCache forwards its experimental initialMaxSize too.
@OptIn(ExperimentalCoilApi::class)
internal class CountedMemoryCache(private val delegate: MemoryCache, private val maxImages: Int) : MemoryCache by delegate {
    /** The keys set, least recently used first. */
    private val used = LinkedHashMap<MemoryCache.Key, Unit>(16, 0.75f, true)

    override fun get(key: MemoryCache.Key): MemoryCache.Value? =
        delegate[key]?.also { synchronized(used) { used[key] = Unit } }

    override fun set(key: MemoryCache.Key, value: MemoryCache.Value) {
        delegate[key] = value
        synchronized(used) {
            used[key] = Unit
            while (used.size > maxImages) {
                val oldest = used.keys.first()
                used.remove(oldest)
                delegate.remove(oldest)
            }
        }
    }

    override fun remove(key: MemoryCache.Key): Boolean {
        synchronized(used) { used.remove(key) }
        return delegate.remove(key)
    }

    override fun clear() {
        synchronized(used) { used.clear() }
        delegate.clear()
    }
}

/**
 * Deletes [ArtworkCache.evictions] from Coil's disk cache in [directory], which must not be open: an entry is
 * `<hash>.0` (its response's metadata) and `<hash>.1` (the image), the image's last-modified time when it was written.
 * Coil drops an entry from its journal once it finds the entry's files gone.
 */
internal fun sweepArtworkCache(fileSystem: FileSystem, directory: Path, nowMillis: Long) {
    val images = fileSystem.listOrNull(directory)?.filter { it.name.endsWith(".1") } ?: return
    val written = images.map { fileSystem.metadataOrNull(it)?.lastModifiedAtMillis ?: 0L }
    for (index in ArtworkCache.evictions(written, nowMillis)) {
        val image = images[index]
        fileSystem.delete(directory / (image.name.removeSuffix(".1") + ".0"))
        fileSystem.delete(image)
    }
}

/**
 * At most [permits] requests at once, each holding its permit until its body is read. A transfer that makes no progress
 * for [stall] (no headers yet, or no body bytes), by [time], is aborted with a [StalledTransferException], releasing its
 * permit: a dead connection never holds a download slot for good.
 */
internal class LimitedNetworkClient(
    private val delegate: NetworkClient,
    permits: Int,
    private val stall: Duration = ArtworkCache.STALL_TIMEOUT_MILLIS.milliseconds,
    private val time: TimeSource = TimeSource.Monotonic,
) : NetworkClient {
    private val permits = Semaphore(permits)

    override suspend fun <T> executeRequest(request: NetworkRequest, block: suspend (response: NetworkResponse) -> T): T =
        permits.withPermit {
            coroutineScope {
                // Set by the transfer's thread, read by the watch's.
                val progress = AtomicReference<TimeMark>(time.markNow())
                var stalled = false
                val transfer = async {
                    delegate.executeRequest(request) { response ->
                        progress.set(time.markNow())
                        block(response.copy(body = response.body?.let { ProgressBody(it) { progress.set(time.markNow()) } }))
                    }
                }
                val watch = launch {
                    while (true) {
                        val left = stall - progress.get().elapsedNow()
                        if (left <= Duration.ZERO) break
                        delay(left)
                    }
                    stalled = true
                    transfer.cancel()
                }
                try {
                    transfer.await()
                } catch (e: CancellationException) {
                    if (stalled) throw StalledTransferException(request.url, stall)
                    throw e
                } finally {
                    watch.cancel()
                }
            }
        }
}

/** An artwork transfer from [url] made no progress for [stall]; its message names the URL without its credentials. */
internal class StalledTransferException(url: String, stall: Duration) : IOException("no progress for $stall: ${UrlTokens.redact(url)}")

/** [delegate], calling [onProgress] whenever its bytes arrive. */
private class ProgressBody(private val delegate: NetworkResponseBody, private val onProgress: () -> Unit) : NetworkResponseBody {
    override suspend fun writeTo(sink: BufferedSink) {
        val counted = ProgressSink(sink, onProgress).buffer()
        delegate.writeTo(counted)
        // Into [sink], which stays open: its owner closes it.
        counted.emit()
    }

    override suspend fun writeTo(fileSystem: FileSystem, path: Path) {
        val counted = object : ForwardingFileSystem(fileSystem) {
            override fun sink(file: Path, mustCreate: Boolean): Sink = ProgressSink(super.sink(file, mustCreate), onProgress)

            override fun appendingSink(file: Path, mustExist: Boolean): Sink = ProgressSink(super.appendingSink(file, mustExist), onProgress)
        }
        delegate.writeTo(counted, path)
    }

    override fun close() = delegate.close()
}

private class ProgressSink(delegate: Sink, private val onProgress: () -> Unit) : ForwardingSink(delegate) {
    override fun write(source: Buffer, byteCount: Long) {
        super.write(source, byteCount)
        onProgress()
    }
}

/** A web image's memory cache key: [ArtworkCache.key]. */
private object ArtworkKeyer : Keyer<Uri> {
    override fun key(data: Uri, options: Options): String? = if (data.isWeb) ArtworkCache.key(data.toString()) else null
}

/** [network]'s fetcher for a web image, its disk cache key [ArtworkCache.key]. */
private class ArtworkFetcherFactory(private val network: Fetcher.Factory<Uri>) : Fetcher.Factory<Uri> {
    override fun create(data: Uri, options: Options, imageLoader: ImageLoader): Fetcher? {
        if (!data.isWeb) return null
        val keyed = options.copy(diskCacheKey = options.diskCacheKey ?: ArtworkCache.key(data.toString()))
        return network.create(data, keyed, imageLoader)
    }
}

private val Uri.isWeb: Boolean get() = scheme == "http" || scheme == "https"
