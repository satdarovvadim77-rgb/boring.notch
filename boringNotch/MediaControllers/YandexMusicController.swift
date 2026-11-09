//
//  YandexMusicController.swift
//  boringNotch
//
//  Created for Yandex Music Integration on 2026-11-01.
//

import AppKit
import Combine
import Foundation

final class YandexMusicController: ObservableObject, MediaControllerProtocol {
    @Published private(set) var playbackState: PlaybackState = .init(
        bundleIdentifier: YandexMusicHelper.bundleIdentifier
    )

    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        $playbackState.eraseToAnyPublisher()
    }

    var supportsVolumeControl: Bool { true }
    var supportsFavorite: Bool { true }

    private var cancellables = Set<AnyCancellable>()
    private var nowPlayingController: NowPlayingController?

    init() {
        if let controller = NowPlayingController() {
            self.nowPlayingController = controller
            controller.playbackStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    guard let self = self else { return }
                    // If the update comes from Yandex Music, or if Yandex Music is running and this is the active track
                    if state.bundleIdentifier == YandexMusicHelper.bundleIdentifier ||
                       (state.bundleIdentifier.isEmpty && YandexMusicHelper.shared.isRunning) {
                        var updated = state
                        updated.bundleIdentifier = YandexMusicHelper.bundleIdentifier
                        self.playbackState = updated
                    }
                }
                .store(in: &cancellables)
        }
    }

    func updatePlaybackInfo() async {
        await nowPlayingController?.updatePlaybackInfo()
    }

    func isActive() -> Bool {
        return YandexMusicHelper.shared.isRunning
    }

    func play() async {
        await nowPlayingController?.play()
        playbackState.isPlaying = true
    }

    func pause() async {
        await nowPlayingController?.pause()
        playbackState.isPlaying = false
    }

    func togglePlay() async {
        await nowPlayingController?.togglePlay()
        playbackState.isPlaying.toggle()
    }

    func nextTrack() async {
        await nowPlayingController?.nextTrack()
    }

    func previousTrack() async {
        await nowPlayingController?.previousTrack()
    }

    func seek(to time: Double) async {
        await nowPlayingController?.seek(to: time)
    }

    func skipForward() async {
        await nowPlayingController?.seek(to: playbackState.currentTime + 15)
    }

    func rewind() async {
        await nowPlayingController?.seek(to: max(0, playbackState.currentTime - 15))
    }

    func mute() async {
        await setVolume(0)
    }

    func volumeUp() async {
        await setVolume(min(1.0, playbackState.volume + 0.05))
    }

    func volumeDown() async {
        await setVolume(max(0.0, playbackState.volume - 0.05))
    }

    func toggleShuffle() async {
        await nowPlayingController?.toggleShuffle()
    }

    func toggleRepeat() async {
        await nowPlayingController?.toggleRepeat()
    }

    func setFavorite(_ favorite: Bool) async {
        playbackState.isFavorite = favorite
    }

    func dislike() async {
        playbackState.isFavorite = false
    }

    func setVolume(_ level: Double) async {
        let clampedLevel = max(0.0, min(1.0, level))
        playbackState.volume = clampedLevel
        await nowPlayingController?.setVolume(clampedLevel)
    }
}
