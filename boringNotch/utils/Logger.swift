import Foundation
import os
import SwiftUI

enum LogCategory: String {
    case lifecycle = "lifecycle"
    case memory = "memory"
    case performance = "performance"
    case ui = "ui"
    case network = "network"
    case media = "media"
    case system = "system"
    case shelf = "shelf"
    case error = "error"
    case warning = "warning"
    case success = "success"
    case debug = "debug"
}

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "theboringteam.boringnotch"

    private static let loggers: [LogCategory: os.Logger] = {
        var dict: [LogCategory: os.Logger] = [:]
        let all: [LogCategory] = [
            .lifecycle, .memory, .performance, .ui, .network,
            .media, .system, .shelf, .error, .warning, .success, .debug
        ]
        for category in all {
            dict[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
        return dict
    }()

    static func logger(for category: LogCategory) -> os.Logger {
        loggers[category] ?? os.Logger(subsystem: subsystem, category: category.rawValue)
    }

    static func log(
        _ message: String,
        category: LogCategory = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let osLogger = logger(for: category)
        switch category {
        case .error:
            osLogger.error("[\(fileName, privacy: .public):\(line)] \(function, privacy: .public) - \(message, privacy: .public)")
        case .warning:
            osLogger.warning("[\(fileName, privacy: .public):\(line)] \(function, privacy: .public) - \(message, privacy: .public)")
        case .debug, .memory:
            osLogger.debug("[\(fileName, privacy: .public):\(line)] \(function, privacy: .public) - \(message, privacy: .public)")
        default:
            osLogger.info("[\(fileName, privacy: .public):\(line)] \(function, privacy: .public) - \(message, privacy: .public)")
        }
    }

    static func trackMemory(
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            log(
                String(format: "Memory used: %.2f MB", usedMB),
                category: .memory,
                file: file,
                function: function,
                line: line
            )
        }
    }
}

extension View {
    func trackLifecycle(_ identifier: String) -> some View {
        self.modifier(ViewLifecycleTracker(identifier: identifier))
    }
}

struct ViewLifecycleTracker: ViewModifier {
    let identifier: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                Logger.log("\(identifier) appeared", category: .lifecycle)
                Logger.trackMemory()
            }
            .onDisappear {
                Logger.log("\(identifier) disappeared", category: .lifecycle)
                Logger.trackMemory()
            }
    }
}
