import Cocoa
import Defaults
import Foundation
import IOKit.ps
import SwiftUI

/// A view model that manages and monitors the battery status of the device
class BatteryStatusViewModel: ObservableObject {

    private var wasCharging: Bool = false
    private var powerSourceChangedCallback: IOPowerSourceCallbackType?
    private var runLoopSource: Unmanaged<CFRunLoopSource>?

    private let coordinator: BoringViewCoordinator

    @Published private(set) var levelBattery: Float = 0.0
    @Published private(set) var maxCapacity: Float = 0.0
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isInLowPowerMode: Bool = false
    @Published private(set) var isInitial: Bool = false
    @Published private(set) var timeToFullCharge: Int = 0
    @Published private(set) var statusText: String = ""

    private let managerBattery: BatteryActivityManager
    private var managerBatteryId: Int?

    static let shared = BatteryStatusViewModel()

    init(
        coordinator: BoringViewCoordinator = .shared,
        managerBattery: BatteryActivityManager = .shared
    ) {
        self.coordinator = coordinator
        self.managerBattery = managerBattery
        setupPowerStatus()
        setupMonitor()
    }

    /// Sets up the initial power status by fetching battery information
    private func setupPowerStatus() {
        let batteryInfo = managerBattery.initializeBatteryInfo()
        updateBatteryInfo(batteryInfo)
    }

    /// Sets up the monitor to observe battery events
    private func setupMonitor() {
        managerBatteryId = managerBattery.addObserver { [weak self] event in
            guard let self = self else { return }
            self.handleBatteryEvent(event)
        }
    }

    /// Handles battery events and updates the corresponding properties
    /// - Parameter event: The battery event to handle
    private func handleBatteryEvent(_ event: BatteryActivityManager.BatteryEvent) {
        switch event {
        case .powerSourceChanged(let isPluggedIn):
            Logger.log("🔌 Power source: \(isPluggedIn ? "Connected" : "Disconnected")", category: .debug)
            withAnimation {
                self.isPluggedIn = isPluggedIn
                self.statusText = isPluggedIn ? "Plugged In" : "Unplugged"
                self.notifyImportanChangeStatus()
            }

        case .batteryLevelChanged(let level):
            Logger.log("🔋 Battery level: \(Int(level))%", category: .debug)
            withAnimation {
                self.levelBattery = level
            }

        case .lowPowerModeChanged(let isEnabled):
            Logger.log("⚡ Low power mode: \(isEnabled ? "Enabled" : "Disabled")", category: .debug)
            self.notifyImportanChangeStatus()
            withAnimation {
                self.isInLowPowerMode = isEnabled
                self.statusText = "Low Power: \(self.isInLowPowerMode ? "On" : "Off")"
            }

        case .isChargingChanged(let isCharging):
            Logger.log("🔌 Charging: \(isCharging ? "Yes" : "No")", category: .debug)
            Logger.log("maxCapacity: \(self.maxCapacity)", category: .debug)
            Logger.log("levelBattery: \(self.levelBattery)", category: .debug)
            self.notifyImportanChangeStatus()
            withAnimation {
                self.isCharging = isCharging
                self.statusText =
                    isCharging
                    ? "Charging battery"
                    : (self.levelBattery < self.maxCapacity ? "Not charging" : "Full charge")
            }

        case .timeToFullChargeChanged(let time):
            Logger.log("🕒 Time to full charge: \(time) minutes", category: .debug)
            withAnimation {
                self.timeToFullCharge = time
            }

        case .maxCapacityChanged(let capacity):
            Logger.log("🔋 Max capacity: \(capacity)", category: .debug)
            withAnimation {
                self.maxCapacity = capacity
            }

        case .error(let description):
            Logger.log("⚠️ Error: \(description)", category: .debug)
        }
    }

    /// Updates the battery information with the given BatteryInfo instance
    /// - Parameter batteryInfo: The BatteryInfo instance containing the battery data
    private func updateBatteryInfo(_ batteryInfo: BatteryInfo) {
        withAnimation {
            self.levelBattery = batteryInfo.currentCapacity
            self.isPluggedIn = batteryInfo.isPluggedIn
            self.isCharging = batteryInfo.isCharging
            self.isInLowPowerMode = batteryInfo.isInLowPowerMode
            self.timeToFullCharge = batteryInfo.timeToFullCharge
            self.maxCapacity = batteryInfo.maxCapacity
            self.statusText = batteryInfo.isPluggedIn ? "Plugged In" : "Unplugged"
        }
    }

    /// Notifies important changes in the battery status with an optional delay
    /// - Parameter delay: The delay before notifying the change, default is 0.0
    private func notifyImportanChangeStatus(delay: Double = 0.0) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            self?.coordinator.toggleExpandingView(status: true, type: .battery)
        }
    }

    deinit {
        Logger.log("🔌 Cleaning up battery monitoring...", category: .debug)
        if let managerBatteryId: Int = managerBatteryId {
            managerBattery.removeObserver(byId: managerBatteryId)
        }
    }

}
