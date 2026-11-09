//
//  YandexMusicHelper.swift
//  boringNotch
//
//  Created for Yandex Music Integration on 2026-11-01.
//

import AppKit
import ApplicationServices
import Foundation

final class YandexMusicHelper {
    static let shared = YandexMusicHelper()
    static let bundleIdentifier = "ru.yandex.desktop.music"
    static let appPath = "/Applications/Яндекс Музыка.app"

    private(set) var isRunning: Bool = false
    private var workspaceObservers: [NSObjectProtocol] = []

    init() {
        self.isRunning = Self.findRunningYandexApp() != nil
        setupWorkspaceObservers()
    }

    deinit {
        let nc = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            nc.removeObserver(observer)
        }
    }

    private func setupWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter

        let launchObs = nc.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               Self.matchesYandexApp(app) {
                self?.isRunning = true
            }
        }

        let terminateObs = nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               Self.matchesYandexApp(app) {
                self?.isRunning = Self.findRunningYandexApp() != nil
            }
        }

        workspaceObservers = [launchObs, terminateObs]
    }

    private static func matchesYandexApp(_ app: NSRunningApplication) -> Bool {
        app.bundleIdentifier == bundleIdentifier ||
        app.localizedName == "Яндекс Музыка" ||
        app.localizedName == "Yandex Music"
    }

    private static func findRunningYandexApp() -> NSRunningApplication? {
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            return app
        }
        return NSWorkspace.shared.runningApplications.first { matchesYandexApp($0) }
    }

    func getRunningYandexApp() -> NSRunningApplication? {
        guard isRunning else { return nil }
        return Self.findRunningYandexApp()
    }

    // MARK: - Accessibility Like / Dislike
    @discardableResult
    func triggerAccessibilityAction(isLike: Bool) -> Bool {
        guard AXIsProcessTrusted(), let app = getRunningYandexApp() else { return false }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
              let windows = windowsValue as? [AXUIElement] else {
            return false
        }

        let keywords = isLike
            ? ["нравится", "like", "любим", "favorite"]
            : ["не нравится", "dislike", "не рекомендовать"]
        let negativePrefix = "не нравится"

        for window in windows {
            if let button = findButton(in: window, matching: keywords, isLike: isLike, negativePrefix: negativePrefix, depth: 0) {
                return AXUIElementPerformAction(button, kAXPressAction as CFString) == .success
            }
        }
        return false
    }

    private func findButton(
        in element: AXUIElement,
        matching keywords: [String],
        isLike: Bool,
        negativePrefix: String,
        depth: Int
    ) -> AXUIElement? {
        guard depth < 12 else { return nil }

        var roleValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String,
           role == (kAXButtonRole as String) || role == (kAXCheckBoxRole as String) {
            let desc = (copyStringAttribute(element, kAXDescriptionAttribute as CFString) ?? "").lowercased()
            let title = (copyStringAttribute(element, kAXTitleAttribute as CFString) ?? "").lowercased()
            let help = (copyStringAttribute(element, kAXHelpAttribute as CFString) ?? "").lowercased()
            let combined = "\(desc) \(title) \(help)"

            if isLike && combined.contains(negativePrefix) {
                // Skip dislike button when searching for like button
            } else if keywords.contains(where: { combined.contains($0) }) {
                return element
            }
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findButton(in: child, matching: keywords, isLike: isLike, negativePrefix: negativePrefix, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    private func copyStringAttribute(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value as? String
    }

    // MARK: - Open & Bring to Front
    func openAndActivateApp() {
        let workspace = NSWorkspace.shared
        var targetURL: URL? = workspace.urlForApplication(withBundleIdentifier: Self.bundleIdentifier)

        if targetURL == nil {
            let directURL = URL(fileURLWithPath: Self.appPath)
            if FileManager.default.fileExists(atPath: directURL.path) {
                targetURL = directURL
            }
        }

        guard let appURL = targetURL else {
            Logger.log("Yandex Music app not found at bundle identifier \(Self.bundleIdentifier) or path \(Self.appPath)", category: .warning)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        configuration.allowsRunningApplicationSubstitution = true

        workspace.openApplication(at: appURL, configuration: configuration) { app, error in
            DispatchQueue.main.async {
                if let runningApp = app ?? NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier).first {
                    runningApp.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
                }
            }
            if let error = error {
                Logger.log("Failed to activate Yandex Music: \(error.localizedDescription)", category: .error)
            }
        }
    }
}
