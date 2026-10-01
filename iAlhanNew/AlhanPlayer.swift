//
//  AlhanPlayer.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/21/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import AVFoundation
@preconcurrency import MediaPlayer
import UIKit

extension Notification.Name {
    static let alhanPlayerCurrentTrackDidChange = Notification.Name("AlhanPlayerCurrentTrackDidChange")
}

@MainActor
final class AlhanPlayer: NSObject {
    enum PlaybackContext {
        case singleHymn
        case playlist
    }

    struct Track {
        let url: URL
        let title: String
        let systemTitle: String
        let albumTitle: String?

        init(
            url: URL,
            title: String = "iAlhan",
            systemTitle: String? = nil,
            albumTitle: String? = nil
        ) {
            self.url = url
            self.title = title
            self.systemTitle = systemTitle ?? title
            self.albumTitle = albumTitle
        }
    }

    static let sharedInstance = AlhanPlayer()

    /// Compatibility access for existing screens. New code should use the
    /// playback methods on this type instead of manipulating AVPlayer directly.
    var player: AVPlayer { queuePlayer }
    let queuePlayer = AVQueuePlayer()

    var isPlaying: Bool { queuePlayer.timeControlStatus == .playing }
    private(set) var intendsToPlay = false
    var currentTime: TimeInterval { queuePlayer.currentTime().seconds.finiteValue }
    var duration: TimeInterval { queuePlayer.currentItem?.duration.seconds.finiteValue ?? 0 }
    var currentTrackURL: URL? { currentTrack?.url }
    var currentTrackTitle: String? { currentTrack?.title }
    var hasCurrentItem: Bool { queuePlayer.currentItem != nil }
    var canAdvance: Bool { currentQueueIndex + 1 < queuedTracks.count }
    var canGoBack: Bool { playbackContext == .playlist && currentQueueIndex > 0 }
    private(set) var playbackContext: PlaybackContext = .singleHymn
    var playbackRate: Float = 1 {
        didSet {
            guard playbackRate > 0 else {
                playbackRate = oldValue
                return
            }
            if isPlaying {
                queuePlayer.rate = playbackRate
            }
            updateNowPlayingInfo()
        }
    }

    private var tracksByItem = [ObjectIdentifier: Track]()
    private var indicesByItem = [ObjectIdentifier: Int]()
    private var queuedTracks = [Track]()
    private var currentQueueIndex = 0
    private var lastNotifiedTrackURL: URL?
    private var artworkTrackURL: URL?
    private var timeObserver: Any?
    private var notificationTokens = [NSObjectProtocol]()
    private var remoteCommandTargets = [(MPRemoteCommand, Any)]()

    private override init() {
        super.init()
        queuePlayer.actionAtItemEnd = .advance
        queuePlayer.automaticallyWaitsToMinimizeStalling = true
        configureAudioSession()
        configureObservers()
        configureRemoteCommands()
    }

    func load(_ track: Track, autoplay: Bool = false) {
        playbackContext = .singleHymn
        queuedTracks = [track]
        replaceQueue(startingAt: 0, autoplay: autoplay)
    }

    func loadQueue(
        _ tracks: [Track],
        startingAt index: Int = 0,
        autoplay: Bool = false
    ) {
        playbackContext = .playlist
        queuedTracks = tracks
        replaceQueue(startingAt: index, autoplay: autoplay)
    }

    private func replaceQueue(startingAt index: Int, autoplay: Bool) {
        queuePlayer.pause()
        queuePlayer.removeAllItems()
        tracksByItem.removeAll()
        indicesByItem.removeAll()
        currentQueueIndex = index

        guard queuedTracks.indices.contains(index) else {
            updateNowPlayingInfo()
            updateRemoteCommandAvailability()
            return
        }

        for trackIndex in index..<queuedTracks.count {
            let track = queuedTracks[trackIndex]
            let item = AVPlayerItem(url: track.url)
            let identifier = ObjectIdentifier(item)
            tracksByItem[identifier] = track
            indicesByItem[identifier] = trackIndex
            queuePlayer.insert(item, after: nil)
        }

        updateNowPlayingInfo()
        updateRemoteCommandAvailability()

        if autoplay {
            play()
        }
    }

    func play() {
        intendsToPlay = true
        activateSession { [weak self] success in
            guard let self, success, queuePlayer.currentItem != nil else { return }
            queuePlayer.playImmediately(atRate: playbackRate)
            updateNowPlayingInfo()
        }
    }

    func pause() {
        intendsToPlay = false
        queuePlayer.pause()
        updateNowPlayingInfo()
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func stop() {
        pause()
        seek(to: 0)
        deactivateSession()
    }

    func clear() {
        intendsToPlay = false
        queuePlayer.pause()
        queuePlayer.removeAllItems()
        tracksByItem.removeAll()
        indicesByItem.removeAll()
        queuedTracks.removeAll()
        currentQueueIndex = 0
        playbackContext = .singleHymn
        updateNowPlayingInfo()
        updateRemoteCommandAvailability()
        deactivateSession()
    }

    func seek(to seconds: TimeInterval) {
        let safeSeconds = max(0, min(seconds, duration > 0 ? duration : seconds))
        queuePlayer.seek(
            to: CMTime(seconds: safeSeconds, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            Task { @MainActor in self?.updateNowPlayingInfo() }
        }
    }

    func skip(by interval: TimeInterval) {
        seek(to: currentTime + interval)
    }

    func advanceToNextItem() {
        guard canAdvance else { return }
        queuePlayer.advanceToNextItem()
        updateNowPlayingInfo()
        if !isPlaying {
            play()
        }
    }

    func returnToPreviousItem() {
        guard canGoBack else { return }
        replaceQueue(startingAt: currentQueueIndex - 1, autoplay: intendsToPlay)
    }

    // MARK: - Compatibility API

    func playWithURL(playableURL: URL) {
        load(Track(url: playableURL), autoplay: true)
    }

    func playQueue(playerURL: URL) {
        let track = Track(url: playerURL)
        let item = AVPlayerItem(url: playerURL)
        tracksByItem[ObjectIdentifier(item)] = track
        queuePlayer.insert(item, after: nil)
        updateRemoteCommandAvailability()
    }

    func pauseQueue() {
        pause()
    }

    func nextHymnInQueue() {
        advanceToNextItem()
    }

    func resetTimer() {
        seek(to: 0)
    }

    func getQueueCurrentItem() -> String {
        currentTrack?.url.absoluteString ?? ""
    }

    func retrieveDuration(for url: URL, completion: @escaping @MainActor @Sendable (Double?) -> Void) {
        Task {
            do {
                let duration = try await AVAsset(url: url).load(.duration)
                completion(duration.seconds.finiteValue)
            } catch {
                completion(nil)
            }
        }
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay])
            } catch {
                print("Unable to configure audio session: \(error.localizedDescription)")
            }
        }
    }

    private func activateSession(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 27.0, *) {
            session.activate { success, error in
                if let error {
                    print("Unable to activate audio session: \(error.localizedDescription)")
                }
                Task { @MainActor in completion(success) }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try session.setActive(true)
                    DispatchQueue.main.async { completion(true) }
                } catch {
                    print("Unable to activate audio session: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(false) }
                }
            }
        }
    }

    private func deactivateSession() {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 27.0, *) {
            session.deactivate(options: .notifyOthersOnDeactivation) { _, error in
                if let error {
                    print("Unable to deactivate audio session: \(error.localizedDescription)")
                }
            }
        } else {
            DispatchQueue.global(qos: .utility).async {
                do {
                    try session.setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Unable to deactivate audio session: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Observers

    private func configureObservers() {
        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor in self?.handleInterruption(type: type, options: options) }
        })
        notificationTokens.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor in self?.handleRouteChange(reason: reason) }
        })
        notificationTokens.append(center.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateNowPlayingInfo()
                self?.updateRemoteCommandAvailability()
            }
        })

        timeObserver = queuePlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateNowPlayingInfo() }
        }
    }

    private func handleInterruption(type rawType: UInt?, options rawOptions: UInt?) {
        guard
            let rawType,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        if type == .began {
            pause()
        } else {
            if AVAudioSession.InterruptionOptions(rawValue: rawOptions ?? 0).contains(.shouldResume) {
                play()
            }
        }
    }

    private func handleRouteChange(reason rawReason: UInt?) {
        guard
            let rawReason,
            AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable
        else { return }
        pause()
    }

    // MARK: - Remote commands and Now Playing

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        addTarget(to: center.playCommand) { [weak self] _ in
            self?.play()
            return .success
        }
        addTarget(to: center.pauseCommand) { [weak self] _ in
            self?.pause()
            return .success
        }
        addTarget(to: center.togglePlayPauseCommand) { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
        addTarget(to: center.nextTrackCommand) { [weak self] _ in
            guard let self, queuePlayer.items().count > 1 else { return .noSuchContent }
            advanceToNextItem()
            return .success
        }
        addTarget(to: center.skipForwardCommand) { [weak self] event in
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 15
            self?.skip(by: interval)
            return .success
        }
        addTarget(to: center.skipBackwardCommand) { [weak self] event in
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 15
            self?.skip(by: -interval)
            return .success
        }
        addTarget(to: center.changePlaybackPositionCommand) { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.preferredIntervals = [15]
        updateRemoteCommandAvailability()
    }

    private func addTarget(
        to command: MPRemoteCommand,
        handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) {
        let target = command.addTarget(handler: handler)
        remoteCommandTargets.append((command, target))
    }

    private var currentTrack: Track? {
        guard let item = queuePlayer.currentItem else { return nil }
        return tracksByItem[ObjectIdentifier(item)]
    }

    private func updateRemoteCommandAvailability() {
        let center = MPRemoteCommandCenter.shared()
        let hasItem = queuePlayer.currentItem != nil
        center.playCommand.isEnabled = hasItem
        center.pauseCommand.isEnabled = hasItem
        center.togglePlayPauseCommand.isEnabled = hasItem
        center.nextTrackCommand.isEnabled = queuePlayer.items().count > 1
        center.skipForwardCommand.isEnabled = hasItem
        center.skipBackwardCommand.isEnabled = hasItem
        center.changePlaybackPositionCommand.isEnabled = hasItem
    }

    private func updateNowPlayingInfo() {
        if let item = queuePlayer.currentItem,
           let index = indicesByItem[ObjectIdentifier(item)] {
            currentQueueIndex = index
        }
        let trackURL = currentTrack?.url
        if trackURL != lastNotifiedTrackURL {
            lastNotifiedTrackURL = trackURL
            NotificationCenter.default.post(name: .alhanPlayerCurrentTrackDidChange, object: self)
        }

        guard queuePlayer.currentItem != nil else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            MPNowPlayingInfoCenter.default().playbackState = .stopped
            return
        }

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = currentTrack?.systemTitle ?? "iAlhan"
        info[MPMediaItemPropertyAlbumTitle] = currentTrack?.albumTitle
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate

        if artworkTrackURL != trackURL, let image = UIImage(named: "artworkCross") {
            artworkTrackURL = trackURL
            info[MPMediaItemPropertyArtwork] = makeNowPlayingArtwork(from: image)
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
}

private func makeNowPlayingArtwork(from image: UIImage) -> MPMediaItemArtwork {
    MPMediaItemArtwork(boundsSize: image.size) { requestedSize in
        guard requestedSize.width > 0, requestedSize.height > 0 else { return image }
        return UIGraphicsImageRenderer(size: requestedSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: requestedSize))
        }
    }
}

private extension Double {
    var finiteValue: Double { isFinite ? self : 0 }
}
