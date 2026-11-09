//
//  EnergySaverManager.swift
//  boringNotch
//
//  Created for Energy Saver & Battery Load Optimization on 2026-11-02.
//

import AppKit
import Combine
import Defaults
import Foundation

@MainActor
final class EnergySaverManager: ObservableObject {
    static let shared = EnergySaverManager()

    @Published private(set) var isEnergySaverActive: Bool = false
    @Published private(set) var isRunningOnBattery: Bool = false
    @Published private(set) var isSystemLowPowerMode: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var batteryObserverId: Int?

    private init() {
        setupObservers()
        evaluateState()
    }

    private func setupObservers() {
        // 1. Observe user defaults settings
        Defaults.publisher(.energySaverMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.evaluateState()
            }
            .store(in: &cancellables)

        Defaults.publisher(.reduceLoadOnBattery)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.evaluateState()
            }
            .store(in: &cancellables)

        // 2. Observe battery events via BatteryActivityManager
        let currentInfo = BatteryActivityManager.shared.initializeBatteryInfo()
        self.isRunningOnBattery = !currentInfo.isPluggedIn
        self.isSystemLowPowerMode = currentInfo.isInLowPowerMode

        batteryObserverId = BatteryActivityManager.shared.addObserver { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                switch event {
                case .powerSourceChanged(let isPluggedIn):
                    self.isRunningOnBattery = !isPluggedIn
                    self.evaluateState()
                case .lowPowerModeChanged(let isEnabled):
                    self.isSystemLowPowerMode = isEnabled
                    self.evaluateState()
                default:
                    break
                }
            }
        }

        // 3. Observe macOS system ProcessInfo PowerState
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSystemLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
                self?.evaluateState()
            }
        }
    }

    func evaluateState() {
        let manualEnergySaver = Defaults[.energySaverMode]
        let reduceOnBattery = Defaults[.reduceLoadOnBattery] && isRunningOnBattery
        let systemLowPower = isSystemLowPowerMode || ProcessInfo.processInfo.isLowPowerModeEnabled

        let shouldBeActive = manualEnergySaver || reduceOnBattery || systemLowPower

        if shouldBeActive != self.isEnergySaverActive {
            self.isEnergySaverActive = shouldBeActive
            NotificationCenter.default.post(name: .energySaverStateChanged, object: nil)

            if shouldBeActive {
                handleEnergySaverEngaged()
            } else {
                handleEnergySaverDisengaged()
            }
        }
    }

    private func handleEnergySaverEngaged() {
        // 1. If camera is running and not currently in active view, stop session to save power
        if BoringViewCoordinator.shared.currentView != .home {
            WebcamManager.shared.stopSession()
        }

        // 2. Suspend background lyrics fetching
        MusicManager.shared.isFetchingLyrics = false
    }

    private func handleEnergySaverDisengaged() {
        // Normal operation resumes
    }
}
