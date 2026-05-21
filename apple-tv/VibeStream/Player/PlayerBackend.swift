import Foundation

/// Abstraction layer for video playback backends (MPV, AVPlayer).
protocol PlayerBackend: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: Double { get }
    var duration: Double { get }

    func loadFile(url: URL)
    func play()
    func pause()
    func seek(to seconds: Double)
    func stop()

    func selectAudioTrack(index: Int)
    func selectSubtitleTrack(index: Int?)
    func addExternalSubtitle(url: String, flag: String)
    func getProperty(_ name: String) -> String?

    var onTimeUpdate: ((Double) -> Void)? { get set }
    var onDurationUpdate: ((Double) -> Void)? { get set }
    var onPlaybackStateChange: ((Bool) -> Void)? { get set }
    var onBufferingChange: ((Bool) -> Void)? { get set }
    var onEndOfFile: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onFileLoaded: (() -> Void)? { get set }
    var onPlaybackRestart: (() -> Void)? { get set }
}
