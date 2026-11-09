//
//  YandexMusicHelper.swift
//  boringNotch
//
//  Created for Yandex Music Integration on 2026-11-01.
//

import AppKit
import Foundation

final class YandexMusicHelper {
    static let shared = YandexMusicHelper()
    static let bundleIdentifier = "ru.yandex.desktop.music"
    static let appPath = "/Applications/Яндекс Музыка.app"

    private init() {}

    func getRunningYandexApp() -> NSRunningApplication? {
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier).first {
            return app
        }
        return NSWorkspace.shared.runningApplications.first { app in
            app.bundleIdentifier == Self.bundleIdentifier ||
            app.localizedName == "Яндекс Музыка" ||
            app.localizedName == "Yandex Music"
        }
    }

    var isRunning: Bool {
        getRunningYandexApp() != nil
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
            print("Yandex Music app not found at bundle identifier \(Self.bundleIdentifier) or path \(Self.appPath)")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        configuration.allowsRunningApplicationSubstitution = true

        workspace.openApplication(at: appURL, configuration: configuration) { (app, error) in
            DispatchQueue.main.async {
                if let runningApp = app ?? NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier).first {
                    runningApp.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
                }
            }
            if let error = error {
                print("Failed to activate Yandex Music: \(error.localizedDescription)")
            }
        }
    }
}
