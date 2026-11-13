//
//  GameModeManager.swift
//  boringNotch
//
//  Created for Game Mode Detection & Function Minimization on 2026-11-01.
//

import AppKit
import Combine
import Defaults
import Foundation

@MainActor
final class GameModeManager: ObservableObject {
    static let shared = GameModeManager()

    @Published private(set) var isGameModeActive: Bool = false
    @Published private(set) var activeGameName: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private var periodicCheckTimer: Timer?

    private init() {
        setupObservers()
        evaluateGameModeState()
    }

    private func setupObservers() {
        // 1. Observe application activation / deactivation
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluateGameModeState()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluateGameModeState()
        }

        // 2. Observe space changes (entering/exiting full screen spaces)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluateGameModeState()
        }

        // 3. Observe FullscreenMediaDetector changes
        FullscreenMediaDetector.shared.$fullscreenStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.evaluateGameModeState()
            }
            .store(in: &cancellables)

        // 4. Periodic lightweight fallback timer
        setupPeriodicTimer()

        // 5. Update timer interval if energy saver state changes
        NotificationCenter.default.addObserver(
            forName: .energySaverStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupPeriodicTimer()
        }
    }

    private func setupPeriodicTimer() {
        periodicCheckTimer?.invalidate()
        let interval: TimeInterval = EnergySaverManager.shared.isEnergySaverActive ? 15.0 : 6.0
        periodicCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateGameModeState()
            }
        }
    }

    func evaluateGameModeState() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }

        // Ignore our own app
        if frontApp.bundleIdentifier == Bundle.main.bundleIdentifier {
            return
        }

        let isGame = isGameApp(frontApp)
        let isFullScreen = isFullScreenActive(for: frontApp)

        // Game mode is active when a game is in the foreground and occupying the full screen
        let shouldBeActive = isGame && isFullScreen

        if shouldBeActive != self.isGameModeActive {
            self.isGameModeActive = shouldBeActive
            self.activeGameName = shouldBeActive ? (frontApp.localizedName ?? frontApp.bundleIdentifier) : nil
            NotificationCenter.default.post(name: .gameModeStateChanged, object: nil)

            if shouldBeActive {
                handleGameModeEngaged()
            } else {
                handleGameModeDisengaged()
            }
        }
    }

    private func handleGameModeEngaged() {
        // 1. Close notch if open
        BoringViewCoordinator.shared.currentView = .home
        BoringViewCoordinator.shared.sneakPeek.show = false
        BoringViewCoordinator.shared.expandingView.show = false

        // 2. Stop camera session to conserve GPU/hardware resources
        WebcamManager.shared.stopSession()

        // 3. Minimize background activity if enabled
        if Defaults[.minimizeActivityInGameMode] {
            // Cancel any pending heavy lyric web fetch
            MusicManager.shared.isFetchingLyrics = false
        }
    }

    private func handleGameModeDisengaged() {
        // Notification posted above allows UI and managers to restore normal operation
    }

    private func isGameApp(_ app: NSRunningApplication) -> Bool {
        // 1. Check bundle's LSApplicationCategoryType & Game Mode flags
        if let bundleURL = app.bundleURL,
           let bundle = Bundle(url: bundleURL) {
            if let category = bundle.infoDictionary?["LSApplicationCategoryType"] as? String,
               category.lowercased().contains("game") {
                return true
            }
            if let supportsGameMode = bundle.infoDictionary?["LSSupportsGameMode"] as? Bool, supportsGameMode {
                return true
            }
            if let supportsGameModeInt = bundle.infoDictionary?["LSSupportsGameMode"] as? Int, supportsGameModeInt == 1 {
                return true
            }
            if let supportsGC = bundle.infoDictionary?["GCSupportsGameMode"] as? Bool, supportsGC {
                return true
            }
            if let supportsGCInt = bundle.infoDictionary?["GCSupportsGameMode"] as? Int, supportsGCInt == 1 {
                return true
            }
        }

        // 2. Check bundle identifier keywords for games, game stores, and emulators
        if let bundleID = app.bundleIdentifier?.lowercased() {
            let gameKeywords = [
                "steam", "epicgames", "gog", "battlenet", "battle.net", "riotgames", "riot",
                "blizzard", "ea.desktop", "origin", "roblox", "minecraft", "mojang",
                "unity", "unreal", "whisky", "crossover", "wine", "portingkit",
                "heroic", "geforcenow", "retroarch", "dolphin", "ryujinx",
                "pcsx2", "rpcs3", "ppsspp", "mame", "game", "gaming", "emulator"
            ]
            if gameKeywords.contains(where: { bundleID.contains($0) }) {
                return true
            }
        }

        // 3. Check executable path for games directories
        if let execURL = app.executableURL {
            let path = execURL.path.lowercased()
            let gamePaths = [
                "/steamapps/", "/games/", "/gog games/", "/epic games/",
                "/whisky/", "/crossover/", "/wine/", "/porting kit/",
                "wine-preloader", "wineserver"
            ]
            if gamePaths.contains(where: { path.contains($0) }) {
                return true
            }
        }

        // 4. Check localized name for game keywords
        if let name = app.localizedName?.lowercased() {
            if name.contains("game") || name.contains("steam") {
                return true
            }
        }

        return false
    }

    private func isFullScreenActive(for app: NSRunningApplication) -> Bool {
        // 1. Check FullscreenMediaDetector space detection
        if FullscreenMediaDetector.shared.isAppFullscreen(app.bundleIdentifier) {
            return true
        }

        if FullscreenMediaDetector.shared.fullscreenStatus.values.contains(true) {
            return true
        }

        // 2. Check system presentation options (set by macOS when frontmost app enters full screen)
        let presentationOptions = NSApp.currentSystemPresentationOptions
        if presentationOptions.contains(.fullScreen) || presentationOptions.contains(.autoHideMenuBar) {
            return true
        }

        // 3. Check if main screen has menu bar / dock hidden (standard full screen)
        if let screen = NSScreen.main {
            let safeTop = screen.safeAreaInsets.top
            let menuBarHidden = (screen.frame.maxY - screen.visibleFrame.maxY) <= (safeTop + 1)
            let dockHidden = screen.visibleFrame.minY <= (screen.frame.minY + 1) &&
                             screen.visibleFrame.height >= (screen.frame.height - safeTop - 1)
            if menuBarHidden && dockHidden {
                return true
            }
        }

        // 4. Check CGWindowList for a window owned by this app covering the screen
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for info in windowList {
                guard let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid == app.processIdentifier else {
                    continue
                }

                var bounds = CGRect.zero
                if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                   CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds) {
                    for screen in NSScreen.screens {
                        let screenFrame = screen.frame
                        let safeTop = screen.safeAreaInsets.top
                        let matchesWidth = abs(bounds.width - screenFrame.width) < 15
                        let matchesFullHeight = abs(bounds.height - screenFrame.height) < 15
                        let matchesNotchHeight = abs(bounds.height - (screenFrame.height - safeTop)) < 15
                        let matchesVisibleHeight = abs(bounds.height - screen.visibleFrame.height) < 15

                        if matchesWidth && (matchesFullHeight || matchesNotchHeight || matchesVisibleHeight) {
                            return true
                        }
                    }
                }
            }
        }

        return false
    }
}
