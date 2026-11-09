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

    var supportsVolumeControl: Bool { false }
    var supportsFavorite: Bool { false }

    private var cancellables = Set<AnyCancellable>()
    private var nowPlayingController: NowPlayingController?

    init?() {
        guard let controller = NowPlayingController() else {
            return nil
        }
        self.nowPlayingController = controller
        controller.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                var updated = state
                let lowerBundle = state.bundleIdentifier.lowercased()
                if lowerBundle.contains("yandex") || (state.bundleIdentifier.isEmpty && YandexMusicHelper.shared.isRunning) {
                    updated.bundleIdentifier = YandexMusicHelper.bundleIdentifier
                }
                self.playbackState = updated
            }
            .store(in: &cancellables)
    }

    func updatePlaybackInfo() async {
        await nowPlayingController?.updatePlaybackInfo()
    }

    func isActive() -> Bool {
        YandexMusicHelper.shared.isRunning
    }

    func play() async {
        await nowPlayingController?.play()
    }

    func pause() async {
        await nowPlayingController?.pause()
    }

    func togglePlay() async {
        await nowPlayingController?.togglePlay()
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
        if !YandexMusicHelper.shared.triggerAccessibilityAction(isLike: true) {
            await nowPlayingController?.setFavorite(favorite)
        }
    }

    func dislike() async {
        if !YandexMusicHelper.shared.triggerAccessibilityAction(isLike: false) {
            await nowPlayingController?.dislike()
        }
    }

    func setVolume(_ level: Double) async {
        let clampedLevel = max(0.0, min(1.0, level))
        playbackState.volume = clampedLevel
        await nowPlayingController?.setVolume(clampedLevel)
    }
}
