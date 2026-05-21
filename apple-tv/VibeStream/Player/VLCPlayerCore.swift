import UIKit
import VLCKitSPM

/// VLC-based video playback backend for tvOS.
/// Can direct play MKV and most container formats with hardware decoding.
class VLCPlayerCore: NSObject, PlayerBackend, VLCMediaPlayerDelegate {

    private var mediaPlayer: VLCMediaPlayer?
    private var drawableView: UIView?
    private var timeUpdateTimer: Timer?

    // PlayerBackend state
    var isPlaying: Bool { mediaPlayer?.isPlaying ?? false }
    var currentTime: Double {
        guard let player = mediaPlayer else { return 0 }
        let ms = player.time.intValue
        guard ms > 0 else { return 0 }
        return Double(ms) / 1000.0
    }
    var duration: Double {
        guard let player = mediaPlayer, let media = player.media else { return 0 }
        let ms = media.length.intValue
        guard ms > 0 else { return 0 }
        return Double(ms) / 1000.0
    }

    // PlayerBackend callbacks
    var onTimeUpdate: ((Double) -> Void)?
    var onDurationUpdate: ((Double) -> Void)?
    var onPlaybackStateChange: ((Bool) -> Void)?
    var onBufferingChange: ((Bool) -> Void)?
    var onEndOfFile: (() -> Void)?
    var onError: ((String) -> Void)?
    var onFileLoaded: (() -> Void)?
    var onPlaybackRestart: (() -> Void)?

    func initialize(in view: UIView) {
        let player = VLCMediaPlayer()
        player.delegate = self
        player.drawable = view
        self.mediaPlayer = player
        self.drawableView = view

        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let player = self.mediaPlayer, player.isPlaying else { return }
            let time = self.currentTime
            self.onTimeUpdate?(time)
            let dur = self.duration
            if dur > 0 {
                self.onDurationUpdate?(dur)
            }
        }
    }

    // MARK: - PlayerBackend

    func loadFile(url: URL) {
        let media = VLCMedia(url: url)
        mediaPlayer?.media = media
    }

    func play() {
        mediaPlayer?.play()
    }

    func pause() {
        mediaPlayer?.pause()
    }

    func seek(to seconds: Double) {
        guard let player = mediaPlayer else { return }
        let dur = duration
        if dur > 0 && seconds <= dur {
            player.position = Float(seconds / dur)
        } else {
            player.time = VLCTime(int: Int32(clamping: Int(seconds * 1000)))
        }
    }

    func stop() {
        mediaPlayer?.stop()
    }

    func selectAudioTrack(index: Int) {
        guard let player = mediaPlayer else { return }
        let tracks = player.audioTrackIndexes as? [Int] ?? []
        // VLC track arrays include "Disable" at index 0, so offset by 1
        let vlcIndex = index + 1
        if vlcIndex < tracks.count {
            player.currentAudioTrackIndex = Int32(tracks[vlcIndex])
        }
    }

    func selectSubtitleTrack(index: Int?) {
        guard let player = mediaPlayer else { return }
        if let index {
            let tracks = player.videoSubTitlesIndexes as? [Int] ?? []
            // VLC track arrays include "Disable" at index 0, so offset by 1
            let vlcIndex = index + 1
            if vlcIndex < tracks.count {
                player.currentVideoSubTitleIndex = Int32(tracks[vlcIndex])
            }
        } else {
            player.currentVideoSubTitleIndex = -1
        }
    }

    func addExternalSubtitle(url: String, flag: String) {
        guard let player = mediaPlayer, let fileURL = URL(string: url) else { return }
        player.addPlaybackSlave(fileURL, type: .subtitle, enforce: false)
    }

    func getProperty(_ name: String) -> String? {
        return nil
    }

    // MARK: - VLCMediaPlayerDelegate

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let player = mediaPlayer else { return }
        DispatchQueue.main.async {
            switch player.state {
            case .playing:
                self.onPlaybackStateChange?(true)
                self.onBufferingChange?(false)
                let dur = self.duration
                if dur > 0 {
                    self.onDurationUpdate?(dur)
                }
                self.onPlaybackRestart?()
            case .paused:
                self.onPlaybackStateChange?(false)
            case .stopped:
                self.onPlaybackStateChange?(false)
            case .ended:
                self.onEndOfFile?()
            case .error:
                self.onError?("VLC playback error. Try switching to MPV in Settings.")
            case .buffering:
                break
            case .opening:
                self.onFileLoaded?()
            default:
                break
            }
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        // Time updates handled by timer for consistent frequency
    }

    // MARK: - Cleanup

    func dispose() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
        mediaPlayer?.stop()
        mediaPlayer?.delegate = nil
        mediaPlayer?.drawable = nil
        mediaPlayer = nil
        drawableView = nil
    }

    deinit {
        dispose()
    }
}
