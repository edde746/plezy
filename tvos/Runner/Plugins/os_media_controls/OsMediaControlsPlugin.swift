import Flutter
import UIKit
import MediaPlayer
import AVFoundation

public class OsMediaControlsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()

    private var currentMetadata: [String: Any] = [:]


    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.edde746.os_media_controls/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.edde746.os_media_controls/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = OsMediaControlsPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public override init() {
        super.init()

        // Ensure app receives remote control events for Now Playing controls
        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }

        setupRemoteCommandCenter()
    }

    private func setupRemoteCommandCenter() {
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.sendEvent(["type": "play"])
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.sendEvent(["type": "pause"])
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.sendEvent(["type": "togglePlayPause"])
            return .success
        }

        // Next track command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.sendEvent(["type": "next"])
            return .success
        }

        // Previous track command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.sendEvent(["type": "previous"])
            return .success
        }

        // Change playback position command (seek)
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.sendEvent([
                    "type": "seek",
                    "position": positionEvent.positionTime
                ])
            }
            return .success
        }

        // Skip forward command
        commandCenter.skipForwardCommand.isEnabled = false // Disabled by default
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                self?.sendEvent([
                    "type": "skipForward",
                    "interval": skipEvent.interval
                ])
            } else {
                self?.sendEvent(["type": "skipForward"])
            }
            return .success
        }

        // Skip backward command
        commandCenter.skipBackwardCommand.isEnabled = false // Disabled by default
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                self?.sendEvent([
                    "type": "skipBackward",
                    "interval": skipEvent.interval
                ])
            } else {
                self?.sendEvent(["type": "skipBackward"])
            }
            return .success
        }

        // Change playback rate command
        commandCenter.changePlaybackRateCommand.isEnabled = true
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 1.0, 1.5, 2.0]
        commandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
            if let rateEvent = event as? MPChangePlaybackRateCommandEvent {
                self?.sendEvent([
                    "type": "setSpeed",
                    "speed": rateEvent.playbackRate
                ])
            }
            return .success
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setMetadata":
            setMetadata(arguments: call.arguments as? [String: Any])
            result(nil)

        case "setPlaybackState":
            setPlaybackState(arguments: call.arguments as? [String: Any])
            result(nil)

        case "enableControls":
            enableControls(arguments: call.arguments as? [String])
            result(nil)

        case "disableControls":
            disableControls(arguments: call.arguments as? [String])
            result(nil)

        case "setSkipIntervals":
            setSkipIntervals(arguments: call.arguments as? [String: Any])
            result(nil)

        case "setQueueInfo":
            setQueueInfo(arguments: call.arguments as? [String: Any])
            result(nil)

        case "clear":
            clear()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setMetadata(arguments: [String: Any]?) {
        guard let args = arguments else { return }

        // Reactivate audio session to ensure media controls work after being cleared
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to reactivate audio session: \(error)")
        }

        // Store metadata for later use
        for (key, value) in args {
            if key != "artwork" {
                currentMetadata[key] = value
            }
        }

        var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]

        if let title = args["title"] as? String {
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
        }
        if let artist = args["artist"] as? String {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        if let album = args["album"] as? String {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }
        if let albumArtist = args["albumArtist"] as? String {
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = albumArtist
        }
        if let duration = args["duration"] as? Double {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        // Handle artwork from bytes (takes precedence over URL)
        if let artworkData = args["artwork"] as? FlutterStandardTypedData {
            if let image = UIImage(data: artworkData.data) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        } else if let artworkUrlString = args["artworkUrl"] as? String, let artworkUrl = URL(string: artworkUrlString) {
            // Handle artwork from URL - download asynchronously
            URLSession.shared.dataTask(with: artworkUrl) { [weak self] data, response, error in
                guard let self = self else { return }
                guard error == nil, let data = data, let image = UIImage(data: data) else {
                    return
                }

                DispatchQueue.main.async {
                    var updatedInfo = self.nowPlayingCenter.nowPlayingInfo ?? [:]
                    updatedInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    self.nowPlayingCenter.nowPlayingInfo = updatedInfo
                }
            }.resume()
        }

        nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func setPlaybackState(arguments: [String: Any]?) {
        guard let args = arguments,
              let stateString = args["state"] as? String,
              let position = args["position"] as? Double,
              let speed = args["speed"] as? Double else { return }

        // Reactivate audio session to ensure media controls work after being cleared
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to reactivate audio session: \(error)")
        }

        var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] =
            stateString == "playing" ? speed : 0.0

        nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func enableControls(arguments: [String]?) {
        guard let controls = arguments else { return }

        for control in controls {
            switch control {
            case "play":
                commandCenter.playCommand.isEnabled = true
            case "pause":
                commandCenter.pauseCommand.isEnabled = true
            case "stop":
                // iOS doesn't have a dedicated stop command
                break
            case "next":
                commandCenter.nextTrackCommand.isEnabled = true
            case "previous":
                commandCenter.previousTrackCommand.isEnabled = true
            case "seek":
                commandCenter.changePlaybackPositionCommand.isEnabled = true
            case "skipForward":
                commandCenter.skipForwardCommand.isEnabled = true
            case "skipBackward":
                commandCenter.skipBackwardCommand.isEnabled = true
            case "changeSpeed":
                commandCenter.changePlaybackRateCommand.isEnabled = true
            default:
                break
            }
        }
    }

    private func disableControls(arguments: [String]?) {
        guard let controls = arguments else { return }

        for control in controls {
            switch control {
            case "play":
                commandCenter.playCommand.isEnabled = false
            case "pause":
                commandCenter.pauseCommand.isEnabled = false
            case "next":
                commandCenter.nextTrackCommand.isEnabled = false
            case "previous":
                commandCenter.previousTrackCommand.isEnabled = false
            case "seek":
                commandCenter.changePlaybackPositionCommand.isEnabled = false
            case "skipForward":
                commandCenter.skipForwardCommand.isEnabled = false
            case "skipBackward":
                commandCenter.skipBackwardCommand.isEnabled = false
            case "changeSpeed":
                commandCenter.changePlaybackRateCommand.isEnabled = false
            default:
                break
            }
        }
    }

    private func setSkipIntervals(arguments: [String: Any]?) {
        guard let args = arguments else { return }

        if let forward = args["forward"] as? Int {
            commandCenter.skipForwardCommand.isEnabled = true
            commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: forward)]
        }

        if let backward = args["backward"] as? Int {
            commandCenter.skipBackwardCommand.isEnabled = true
            commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: backward)]
        }
    }

    private func setQueueInfo(arguments: [String: Any]?) {
        guard let args = arguments,
              let currentIndex = args["currentIndex"] as? Int,
              let queueLength = args["queueLength"] as? Int else { return }

        var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = currentIndex
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = queueLength

        nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func clear() {
        nowPlayingCenter.nowPlayingInfo = nil
        currentMetadata.removeAll()

        // Deactivate audio session to force iOS to remove controls from Control Center
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Audio session deactivation failed, but continue with cleanup
        }

        // Disable all command center buttons
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
    }


    private func sendEvent(_ event: [String: Any]) {
        eventSink?(event)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?,
                        eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
