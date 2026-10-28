PlezyNG's native torrent bridge links libtorrent-rasterbar 2.0.11 (BSD 3-Clause)
and Boost 1.86.0 (Boost Software License 1.0). The exact, SHA-256 verified source
archives and versions are pinned in src/CMakeLists.txt. Preserve libtorrent's
COPYING and Boost's LICENSE_1_0.txt with redistributed binaries. CMake installs
these notices beside the library. No binary downloads are used.

The packaged backend supports BitTorrent v1 magnets, DHT, peer exchange,
verified piece reads and protocol encryption. HTTPS-only trackers and v2-only
magnets are not supported by this build; cloud resolvers remain available.
Native sessions require explicit per-profile opt-in, use bounded storage and
upload bandwidth, and stop all traffic when their playback lease is released.
