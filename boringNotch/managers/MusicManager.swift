//
//  MusicManager.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 03/08/24.
//
import AppKit
import Combine
import Defaults
import SwiftUI

let defaultImage: NSImage = .init(
    systemSymbolName: "heart.fill",
    accessibilityDescription: "Album Art"
) ?? NSImage()

@MainActor
class MusicManager: ObservableObject {
    // MARK: - Properties
    static let shared = MusicManager()
    private var cancellables = Set<AnyCancellable>()
    private var controllerCancellables = Set<AnyCancellable>()
    private var debounceIdleTask: Task<Void, Never>?

    // Helper to check if macOS has removed support for NowPlayingController
    public private(set) var isNowPlayingDeprecated: Bool = false
    private let mediaChecker: MediaChecker
    private let lyricsService: LyricsService
    private let artworkService: ArtworkService
    let coordinator: BoringViewCoordinator

    // Active controller
    private var activeController: (any MediaControllerProtocol)?

    // Published properties for UI
    @Published var songTitle: String = "I'm Handsome"
    @Published var artistName: String = "Me"
    @Published var albumArt: NSImage = defaultImage
    @Published var isPlaying = false
    @Published var album: String = "Self Love"
    @Published var isPlayerIdle: Bool = true
    @Published var animations: BoringAnimations = .init()
    @Published var avgColor: NSColor = .white
    @Published var bundleIdentifier: String? = nil
    @Published var songDuration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = .init()
    @Published var playbackRate: Double = 1
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Double = 0.5
    @Published var volumeControlSupported: Bool = true
    @Published var isMuted: Bool = false
    private var lastNonZeroVolume: Double = 0.5
    @Published var usingAppIconForArtwork: Bool = false
    @Published var currentLyrics: String = ""
    @Published var isFetchingLyrics: Bool = false
    @Published var syncedLyrics: [(time: Double, text: String)] = []
    @Published var canFavoriteTrack: Bool = false
    @Published var isFavoriteTrack: Bool = false
    @Published var canDislikeTrack: Bool = false
    @Published var isDislikedTrack: Bool = false
    @Published var lastActivePlaybackDate: Date = Date.distantPast
    @Published var isTrackTransitioning: Bool = false
    private var trackTransitionTask: Task<Void, Never>?
    private var idleClockTimerTask: Task<Void, Never>?
    private var flipTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var lyricsTask: Task<Void, Never>?

    private var artworkData: Data? = nil

    // Store last values at the time artwork was changed
    private var lastArtworkTitle: String = "I'm Handsome"
    private var lastArtworkArtist: String = "Me"
    private var lastArtworkAlbum: String = "Self Love"
    private var lastArtworkBundleIdentifier: String? = nil

    @Published var isFlipping: Bool = false
    @Published var isTransitioning: Bool = false

    // MARK: - Initialization
    init(
        coordinator: BoringViewCoordinator? = nil,
        lyricsService: LyricsService = .shared,
        artworkService: ArtworkService = .shared,
        mediaChecker: MediaChecker? = nil
    ) {
        self.coordinator = coordinator ?? .shared
        self.lyricsService = lyricsService
        self.artworkService = artworkService
        self.mediaChecker = mediaChecker ?? MediaChecker()

        NotificationCenter.default.publisher(for: Notification.Name.mediaControllerChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setActiveControllerBasedOnPreference()
            }
            .store(in: &cancellables)

        Task { @MainActor in
            do {
                self.isNowPlayingDeprecated = try await self.mediaChecker.checkDeprecationStatus()
                Logger.log("Deprecation check completed: \(self.isNowPlayingDeprecated)", category: .media)
            } catch {
                Logger.log("Failed to check deprecation status: \(error.localizedDescription). Defaulting to false.", category: .warning)
                self.isNowPlayingDeprecated = false
            }
            self.setActiveControllerBasedOnPreference()
        }
    }

    deinit {
        debounceIdleTask?.cancel()
        trackTransitionTask?.cancel()
        idleClockTimerTask?.cancel()
        flipTask?.cancel()
        artworkTask?.cancel()
        lyricsTask?.cancel()
    }
    
    public func destroy() {
        debounceIdleTask?.cancel()
        trackTransitionTask?.cancel()
        idleClockTimerTask?.cancel()
        flipTask?.cancel()
        artworkTask?.cancel()
        lyricsTask?.cancel()
        cancellables.removeAll()
        controllerCancellables.removeAll()
        activeController = nil
    }

    // MARK: - Setup Methods
    private func createController(for type: MediaControllerType) -> (any MediaControllerProtocol)? {
        if activeController != nil {
            controllerCancellables.removeAll()
            activeController = nil
        }

        let newController: (any MediaControllerProtocol)?

        switch type {
        case .nowPlaying:
            if !self.isNowPlayingDeprecated {
                newController = NowPlayingController()
            } else {
                return nil
            }
        case .yandexMusic:
            if !self.isNowPlayingDeprecated {
                newController = YandexMusicController()
            } else {
                return nil
            }
        case .appleMusic:
            newController = AppleMusicController()
        case .spotify:
            newController = SpotifyController()
        case .youtubeMusic:
            newController = YouTubeMusicController()
        }

        if let controller = newController {
            controller.playbackStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    guard let self = self,
                          self.activeController === controller else { return }
                    self.updateFromPlaybackState(state)
                }
                .store(in: &controllerCancellables)
        }

        return newController
    }

    private func setActiveControllerBasedOnPreference() {
        let preferredType = Defaults[.mediaController]
        Logger.log("Preferred Media Controller: \(preferredType.rawValue)", category: .media)

        let controllerType = (self.isNowPlayingDeprecated && (preferredType == .nowPlaying || preferredType == .yandexMusic))
            ? .appleMusic
            : preferredType

        if let controller = createController(for: controllerType) {
            setActiveController(controller)
        } else if controllerType != .appleMusic, let fallbackController = createController(for: .appleMusic) {
            setActiveController(fallbackController)
        }
    }

    private func setActiveController(_ controller: any MediaControllerProtocol) {
        flipTask?.cancel()
        activeController = controller
        self.canFavoriteTrack = controller.supportsFavorite
        self.canDislikeTrack = controller.supportsFavorite
        forceUpdate()
    }

    // MARK: - Update Methods
    private func updateFromPlaybackState(_ state: PlaybackState) {
        let newTitle = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let didChangeSongTitle = state.title != self.songTitle && !newTitle.isEmpty
        if didChangeSongTitle {
            self.songTitle = state.title
            self.isTrackTransitioning = false
            self.trackTransitionTask?.cancel()
        }

        let newArtist = state.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let didChangeArtistName = state.artist != self.artistName && !newArtist.isEmpty
        if didChangeArtistName {
            self.artistName = state.artist
        }

        let newAlbum = state.album.trimmingCharacters(in: .whitespacesAndNewlines)
        if state.album != self.album && !newAlbum.isEmpty {
            self.album = state.album
        }

        let didStartPlaying = state.isPlaying && !self.isPlaying
        if state.isPlaying != self.isPlaying {
            Logger.log("Playback state changed: \(state.isPlaying ? "Playing" : "Paused")", category: .media)
            withAnimation(.smooth) {
                self.isPlaying = state.isPlaying
                self.updateIdleState(state: state.isPlaying)
            }

            if state.isPlaying {
                self.lastActivePlaybackDate = Date()
                self.isTrackTransitioning = false
                self.trackTransitionTask?.cancel()
                self.idleClockTimerTask?.cancel()
                if !newTitle.isEmpty || !self.songTitle.isEmpty {
                    self.updateSneakPeek()
                }
            } else {
                self.lastActivePlaybackDate = Date()
                self.startTrackTransition(duration: 2.5)
                self.scheduleIdleClockTimer()
            }
        } else if state.isPlaying {
            self.lastActivePlaybackDate = Date()
        }

        let titleChanged = state.title != self.lastArtworkTitle && !newTitle.isEmpty
        let artistChanged = state.artist != self.lastArtworkArtist && !newArtist.isEmpty
        let albumChanged = state.album != self.lastArtworkAlbum && !newAlbum.isEmpty
        let bundleChanged = state.bundleIdentifier != self.lastArtworkBundleIdentifier

        let artworkChanged = state.artwork != nil && state.artwork != self.artworkData
        let hasContentChange = titleChanged || artistChanged || albumChanged || artworkChanged || bundleChanged || didChangeSongTitle || didChangeArtistName

        if hasContentChange {
            self.triggerFlipAnimation()

            if artworkChanged, let artwork = state.artwork {
                self.updateArtwork(artwork)
            } else if state.artwork == nil {
                if let appIconImage = AppIconAsNSImage(for: state.bundleIdentifier) {
                    self.usingAppIconForArtwork = true
                    self.updateAlbumArt(newAlbumArt: appIconImage)
                }
            }
            self.artworkData = state.artwork

            if !newTitle.isEmpty {
                self.lastArtworkTitle = state.title
            }
            if !newArtist.isEmpty {
                self.lastArtworkArtist = state.artist
            }
            if !newAlbum.isEmpty {
                self.lastArtworkAlbum = state.album
            }
            self.lastArtworkBundleIdentifier = state.bundleIdentifier

            if (titleChanged || artistChanged || didChangeSongTitle || didStartPlaying) && state.isPlaying && (!newTitle.isEmpty || !self.songTitle.isEmpty) {
                self.updateSneakPeek()
            }

            self.fetchLyricsIfAvailable(bundleIdentifier: state.bundleIdentifier, title: self.songTitle, artist: self.artistName)
        }

        let timeChanged = state.currentTime != self.elapsedTime
        let durationChanged = state.duration != self.songDuration
        let playbackRateChanged = state.playbackRate != self.playbackRate
        let shuffleChanged = state.isShuffled != self.isShuffled
        let repeatModeChanged = state.repeatMode != self.repeatMode
        let volumeChanged = state.volume != self.volume

        if timeChanged {
            self.elapsedTime = state.currentTime
        }

        if durationChanged {
            self.songDuration = state.duration
        }

        if playbackRateChanged {
            self.playbackRate = state.playbackRate
        }
        
        if shuffleChanged {
            self.isShuffled = state.isShuffled
        }

        if state.bundleIdentifier != self.bundleIdentifier {
            self.bundleIdentifier = state.bundleIdentifier
            self.volumeControlSupported = activeController?.supportsVolumeControl ?? false
            let supportsFav = activeController?.supportsFavorite ?? false
            self.canFavoriteTrack = supportsFav
            self.canDislikeTrack = supportsFav
        }

        if repeatModeChanged {
            self.repeatMode = state.repeatMode
        }
        if state.isFavorite != self.isFavoriteTrack {
            self.isFavoriteTrack = state.isFavorite
        }
        
        if volumeChanged {
            self.volume = state.volume
            if state.volume > 0.01 {
                self.lastNonZeroVolume = state.volume
                self.isMuted = false
            } else if state.volume <= 0.001 {
                self.isMuted = true
            }
        }
        
        self.timestampDate = state.lastUpdated
    }

    private var isYandexMusicTarget: Bool {
        if let bundle = bundleIdentifier?.lowercased(), bundle.contains("yandex") {
            return true
        }
        if activeController is YandexMusicController {
            return true
        }
        if let nowPlaying = activeController as? NowPlayingController,
           nowPlaying.playbackState.bundleIdentifier.lowercased().contains("yandex") {
            return true
        }
        return false
    }

    func toggleFavoriteTrack() {
        guard canFavoriteTrack else { return }
        setFavorite(!isFavoriteTrack)
    }

    func setFavorite(_ favorite: Bool) {
        guard canFavoriteTrack, let controller = activeController else { return }

        Task {
            await controller.setFavorite(favorite)
            try? await Task.sleep(for: .milliseconds(150))
            await controller.updatePlaybackInfo()
        }
    }

    func dislikeCurrentTrack() {
        guard canDislikeTrack, let controller = activeController else { return }
        isDislikedTrack.toggle()
        if isDislikedTrack {
            isFavoriteTrack = false
        }
        Task {
            await controller.dislike()
            try? await Task.sleep(for: .milliseconds(150))
            await controller.updatePlaybackInfo()
        }
    }

    // MARK: - Lyrics
    private func fetchLyricsIfAvailable(bundleIdentifier: String?, title: String, artist: String) {
        lyricsTask?.cancel()
        guard Defaults[.enableLyrics], !title.isEmpty, !EnergySaverManager.shared.isEnergySaverActive else {
            self.isFetchingLyrics = false
            self.currentLyrics = ""
            self.syncedLyrics = []
            return
        }

        isFetchingLyrics = true
        currentLyrics = ""
        lyricsTask = Task { [weak self] in
            guard let self = self else { return }
            let result = await self.lyricsService.fetchLyrics(
                bundleIdentifier: bundleIdentifier,
                title: title,
                artist: artist
            )
            guard !Task.isCancelled else { return }
            self.currentLyrics = result.plain
            self.syncedLyrics = result.synced
            self.isFetchingLyrics = false
        }
    }

    func lyricLine(at elapsed: Double) -> String {
        lyricsService.lyricLine(at: elapsed, in: syncedLyrics, fallback: currentLyrics)
    }

    private func triggerFlipAnimation() {
        flipTask?.cancel()
        flipTask = Task { [weak self] in
            self?.isFlipping = true
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            self?.isFlipping = false
        }
    }

    private func updateArtwork(_ artworkData: Data) {
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            guard let self = self else { return }
            if let artworkImage = await self.artworkService.decodeArtworkImage(from: artworkData),
               !Task.isCancelled {
                self.usingAppIconForArtwork = false
                self.updateAlbumArt(newAlbumArt: artworkImage)
            }
        }
    }

    private func updateIdleState(state: Bool) {
        if state {
            isPlayerIdle = false
            debounceIdleTask?.cancel()
        } else {
            debounceIdleTask?.cancel()
            debounceIdleTask = Task { [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(for: .seconds(Defaults[.waitInterval]))
                guard !Task.isCancelled else { return }
                withAnimation {
                    self.isPlayerIdle = !self.isPlaying
                }
            }
        }
    }

    func startTrackTransition(duration: TimeInterval = 3.0) {
        lastActivePlaybackDate = Date()
        isTrackTransitioning = true
        trackTransitionTask?.cancel()
        trackTransitionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.isTrackTransitioning = false
        }
    }

    private func scheduleIdleClockTimer() {
        idleClockTimerTask?.cancel()
        let timeout = Defaults[.idleClockTimeout]
        guard timeout > 0 else { return }

        idleClockTimerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled, let self = self, !self.isPlaying else { return }
            self.objectWillChange.send()
        }
    }

    func updateAlbumArt(newAlbumArt: NSImage) {
        withAnimation(.smooth) {
            self.albumArt = newAlbumArt
            if Defaults[.coloredSpectrogram] {
                self.calculateAverageColor()
            }
        }
    }

    // MARK: - Playback Position Estimation
    public func estimatedPlaybackPosition(at date: Date = Date()) -> TimeInterval {
        guard isPlaying else { return min(elapsedTime, songDuration) }

        let timeDifference = date.timeIntervalSince(timestampDate)
        let estimated = elapsedTime + (timeDifference * playbackRate)
        return min(max(0, estimated), songDuration)
    }

    func calculateAverageColor() {
        let currentArt = albumArt
        let isEnergySaver = EnergySaverManager.shared.isEnergySaverActive
        Task { [weak self] in
            guard let self = self else { return }
            let color = await self.artworkService.calculateAverageColor(
                for: currentArt,
                isEnergySaverActive: isEnergySaver
            )
            withAnimation(.smooth) {
                self.avgColor = color
            }
        }
    }

    private func updateSneakPeek() {
        if isPlaying && Defaults[.enableSneakPeek] {
            if Defaults[.sneakPeekStyles] == .standard {
                coordinator.toggleSneakPeek(status: true, type: .music)
            } else {
                coordinator.toggleExpandingView(status: true, type: .music)
            }
        }
    }

    // MARK: - Public Methods for controlling playback
    func playPause() {
        togglePlay()
    }

    func play() {
        Task {
            await activeController?.play()
        }
    }

    func pause() {
        Task {
            await activeController?.pause()
        }
    }

    func toggleShuffle() {
        Task {
            await activeController?.toggleShuffle()
        }
    }

    func toggleRepeat() {
        Task {
            await activeController?.toggleRepeat()
        }
    }
    
    func togglePlay() {
        Task {
            await activeController?.togglePlay()
        }
    }

    func nextTrack() {
        startTrackTransition()
        Task {
            await activeController?.nextTrack()
        }
    }

    func previousTrack() {
        startTrackTransition()
        Task {
            await activeController?.previousTrack()
        }
    }

    func seek(to position: TimeInterval) {
        Task {
            await activeController?.seek(to: position)
        }
    }

    func skip(seconds: TimeInterval) {
        let newPos = min(max(0, elapsedTime + seconds), songDuration)
        seek(to: newPos)
    }

    func toggleMute() {
        if volumeControlSupported {
            if isMuted || volume <= 0.01 {
                let restore = lastNonZeroVolume > 0.05 ? lastNonZeroVolume : 0.5
                setVolume(to: restore)
            } else {
                if volume > 0.01 {
                    lastNonZeroVolume = volume
                }
                setVolume(to: 0)
            }
        } else {
            VolumeManager.shared.toggleMuteAction()
            self.isMuted = VolumeManager.shared.isMuted
        }
    }
    
    func setVolume(to level: Double) {
        let clamped = max(0.0, min(1.0, level))
        if clamped > 0.01 {
            lastNonZeroVolume = clamped
            isMuted = false
        } else {
            isMuted = true
        }
        self.volume = clamped
        if let controller = activeController {
            Task {
                await controller.setVolume(clamped)
            }
        }
    }

    func openMusicApp() {
        let targetBundleID: String
        if let currentID = bundleIdentifier, !currentID.isEmpty {
            targetBundleID = currentID
        } else if isYandexMusicTarget {
            targetBundleID = YandexMusicHelper.bundleIdentifier
        } else {
            return
        }

        if targetBundleID == YandexMusicHelper.bundleIdentifier {
            YandexMusicHelper.shared.openAndActivateApp()
            return
        }

        let workspace = NSWorkspace.shared
        if let appURL = workspace.urlForApplication(withBundleIdentifier: targetBundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = false
            configuration.allowsRunningApplicationSubstitution = true
            workspace.openApplication(at: appURL, configuration: configuration) { app, error in
                DispatchQueue.main.async {
                    if let runningApp = app ?? NSRunningApplication.runningApplications(withBundleIdentifier: targetBundleID).first {
                        runningApp.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
                    }
                }
                if let error = error {
                    Logger.log("Failed to launch app with bundle ID: \(targetBundleID), error: \(error.localizedDescription)", category: .error)
                } else {
                    Logger.log("Launched app with bundle ID: \(targetBundleID)", category: .media)
                }
            }
        } else if isYandexMusicTarget {
            YandexMusicHelper.shared.openAndActivateApp()
        }
    }

    func forceUpdate() {
        Task { [weak self] in
            if self?.activeController?.isActive() == true {
                if let youtubeController = self?.activeController as? YouTubeMusicController {
                    await youtubeController.pollPlaybackState()
                } else {
                    await self?.activeController?.updatePlaybackInfo()
                }
                await self?.syncVolumeFromActiveApp()
            }
        }
    }
    
    func syncVolumeFromActiveApp() async {
        guard let bundleID = bundleIdentifier, !bundleID.isEmpty else { return }
        
        let script: String
        if bundleID == "com.apple.Music" {
            script = "tell application \"Music\" to get sound volume"
        } else if bundleID == "com.spotify.client" {
            script = "tell application \"Spotify\" to get sound volume"
        } else {
            return
        }
        
        if let result = try? await AppleScriptHelper.execute(script) {
            let volumeValue = result.int32Value
            let currentVolume = Double(volumeValue) / 100.0
            
            if abs(currentVolume - self.volume) > 0.01 {
                self.volume = currentVolume
                if currentVolume > 0.01 {
                    self.lastNonZeroVolume = currentVolume
                    self.isMuted = false
                } else if currentVolume <= 0.001 {
                    self.isMuted = true
                }
            }
        }
    }
}
