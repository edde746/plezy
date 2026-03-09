import SwiftUI

/// Debug view for diagnosing playback and API issues on-device
struct DebugView: View {
    @State private var logs: [String] = []
    @State private var isRunning = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(Array(logs.enumerated()), id: \.offset) { _, log in
                    Text(log)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(log.contains("ERR") || log.contains("FAIL") ? .red :
                                        log.contains("OK") ? .green : .primary)
                }

                if isRunning {
                    ProgressView()
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Debug")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Run") { runDiagnostics() }
                    .disabled(isRunning)
            }
        }
        .onAppear { runDiagnostics() }
    }

    private func log(_ msg: String) {
        logs.append(msg)
    }

    private func runDiagnostics() {
        logs = []
        isRunning = true

        Task {
            let client = PlexWatchClient.shared

            // 1. Check credentials
            await MainActor.run {
                if let creds = client.credentials {
                    log("OK creds: \(creds.serverUrl)")
                    log("   token: \(creds.token.prefix(8))...")
                    log("   machineId: \(creds.machineIdentifier ?? "none")")
                } else {
                    log("ERR no credentials stored")
                }
                log("   clientId: \(client.clientIdentifier)")
            }

            // 2. Test server connectivity
            log("--- Testing server ---")
            let libs = await client.getLibraries()
            await MainActor.run {
                if libs.isEmpty {
                    log("ERR getLibraries returned empty")
                } else {
                    log("OK \(libs.count) libraries")
                    for lib in libs {
                        log("   \(lib.title) (\(lib.type), key=\(lib.key))")
                    }
                }
            }

            // 3. Test machine identifier
            let machineId = await client.fetchMachineIdentifier()
            await MainActor.run {
                if let mid = machineId {
                    log("OK machineId: \(mid)")
                } else {
                    log("ERR fetchMachineIdentifier failed")
                }
            }

            // 4. Find a music library and test artist browsing
            let musicLibs = await client.getMusicLibraries()
            guard let musicLib = musicLibs.first else {
                await MainActor.run {
                    log("ERR no music libraries found")
                    isRunning = false
                }
                return
            }

            await MainActor.run { log("--- Music lib: \(musicLib.title) ---") }

            let artists = await client.getArtists(sectionId: musicLib.key)
            guard let artist = artists.first else {
                await MainActor.run {
                    log("ERR no artists in library")
                    isRunning = false
                }
                return
            }

            await MainActor.run {
                log("OK \(artists.count) artists, first: \(artist.title)")
            }

            // 5. Test radio station creation
            await MainActor.run { log("--- Radio test: \(artist.title) ---") }
            let (radioResult, radioError) = await client.createRadioStation(ratingKey: artist.ratingKey)

            if let result = radioResult {
                await MainActor.run {
                    log("OK radio queue: \(result.playQueueId)")
                    log("   \(result.items.count) items from API")
                    for (i, item) in result.items.prefix(3).enumerated() {
                        log("   [\(i)] \(item.title)")
                        log("      ratingKey=\(item.ratingKey)")
                        log("      partKey=\(item.partKey ?? "nil")")
                        log("      type=\(item.type)")
                    }
                }

                // 6. Test enrichment + toQueueItem conversion
                await MainActor.run { log("   Enriching with partKeys...") }
                let queueItems = await result.toQueueItems(client: client)
                await MainActor.run {
                    log("   \(queueItems.count) converted to QueueItem")
                    if let first = queueItems.first {
                        log("   streamUrl: \(first.streamUrl.prefix(80))...")
                    }
                    if queueItems.isEmpty && !result.items.isEmpty {
                        log("ERR toQueueItems returned 0!")
                    }
                }

                // 6b. Test single fetchPartKey
                if let firstItem = result.items.first, firstItem.partKey == nil {
                    await MainActor.run { log("   Testing fetchPartKey(\(firstItem.ratingKey))...") }
                    let pk = await client.fetchPartKey(ratingKey: firstItem.ratingKey)
                    await MainActor.run {
                        if let pk {
                            log("   OK partKey: \(pk.prefix(60))")
                        } else {
                            log("   ERR fetchPartKey returned nil")
                        }
                    }
                }
            } else {
                await MainActor.run { log("FAIL radio: \(radioError ?? "unknown")") }
            }

            // 7. Test album playback path
            let albums = await client.getAlbums(ratingKey: artist.ratingKey)
            if let album = albums.first {
                await MainActor.run { log("--- Album test: \(album.title) ---") }

                let albumResult = await client.createPlayAllQueue(ratingKey: album.ratingKey)
                if let result = albumResult {
                    await MainActor.run {
                        log("OK album queue: \(result.playQueueId)")
                        log("   \(result.items.count) items")
                    }
                    let queueItems = await result.toQueueItems(client: client)
                    await MainActor.run {
                        log("   \(queueItems.count) converted")
                        if let first = queueItems.first {
                            log("   url: \(first.streamUrl.prefix(80))...")
                        }
                    }
                } else {
                    await MainActor.run { log("FAIL createPlayAllQueue")
                    }
                }
            }

            // 8. Test HTTP fetch of a stream URL
            if let testTrack = albums.flatMap({ _ in [MusicItem]() }).first ?? artists.first {
                // Skip — no easy test track
            }

            // 8b. Test direct HTTP HEAD on a stream URL
            await MainActor.run { log("--- Stream URL test ---") }
            if let firstLib = musicLibs.first {
                let tracks = await client.getTracks(ratingKey: albums.first?.ratingKey ?? musicLib.key)
                if let track = tracks.first, let pk = track.partKey {
                    if let streamUrl = client.streamUrl(partKey: pk),
                       let url = URL(string: streamUrl) {
                        await MainActor.run { log("   Testing: \(streamUrl.prefix(70))...") }
                        do {
                            var req = URLRequest(url: url)
                            req.httpMethod = "HEAD"
                            let (_, resp) = try await URLSession.shared.data(for: req)
                            if let http = resp as? HTTPURLResponse {
                                await MainActor.run {
                                    log("   HTTP \(http.statusCode)")
                                    log("   Content-Type: \(http.value(forHTTPHeaderField: "Content-Type") ?? "?")")
                                    log("   Content-Length: \(http.value(forHTTPHeaderField: "Content-Length") ?? "?")")
                                }
                            }
                        } catch {
                            await MainActor.run { log("   ERR stream test: \(error.localizedDescription)") }
                        }
                    } else {
                        await MainActor.run { log("   No streamUrl for track \(track.title)") }
                    }
                } else {
                    await MainActor.run { log("   No tracks with partKey found") }
                }
            }

            // 9. Test audio session & player state
            await MainActor.run {
                log("--- Audio session ---")
                let session = AVAudioSession.sharedInstance()
                log("   category: \(session.category.rawValue)")
                log("   mode: \(session.mode.rawValue)")
                log("   isOtherPlaying: \(session.isOtherAudioPlaying)")

                let player = WatchAudioPlayer.shared
                log("--- Player state ---")
                log("   queue: \(player.queue.count) items")
                log("   isPlaying: \(player.isPlaying)")
                log("   isLoading: \(player.isLoading)")
                log("   error: \(player.error ?? "none")")
                if let item = player.currentItem {
                    log("   current: \(item.title)")
                    log("   streamUrl: \(item.streamUrl)")
                }

                isRunning = false
            }
        }
    }
}

import AVFoundation
