//
//  main.swift
//  BoringNotchXPCHelper
//
//  Created by Alexander on 2025-11-16.
//

import AppKit
import Foundation
import Security

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    private static let allowedBundleIdentifier = "theboringteam.boringnotch"

    /// Path to the parent .app bundle enclosing Contents/XPCServices/BoringNotchXPCHelper.xpc
    static var enclosingAppBundleURL: URL {
        Bundle.main.bundleURL
            .deletingLastPathComponent() // XPCServices
            .deletingLastPathComponent() // Contents
            .deletingLastPathComponent() // boringNotch.app
            .standardizedFileURL
    }

    /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Verify caller process belongs to the parent application bundle
        guard isAuthorizedClient(pid: newConnection.processIdentifier) else {
            newConnection.invalidate()
            return false
        }

        // Apply code signing requirement on macOS 13+ when a non-adhoc requirement is available
        if #available(macOS 13.0, *), let requirement = Self.parentCodeSigningRequirement() {
            newConnection.setCodeSigningRequirement(requirement)
        }

        newConnection.exportedInterface = NSXPCInterface(with: (any BoringNotchXPCHelperProtocol).self)

        let exportedObject = BoringNotchXPCHelper()
        newConnection.exportedObject = exportedObject

        newConnection.resume()
        return true
    }

    private func isAuthorizedClient(pid: pid_t) -> Bool {
        guard pid > 0, let runningApp = NSRunningApplication(processIdentifier: pid) else {
            return false
        }
        guard runningApp.bundleIdentifier == Self.allowedBundleIdentifier else {
            return false
        }
        if let clientBundleURL = runningApp.bundleURL?.standardizedFileURL {
            return clientBundleURL.path == Self.enclosingAppBundleURL.path
        }
        return false
    }

    private static func parentCodeSigningRequirement() -> String? {
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(enclosingAppBundleURL as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else { return nil }

        var requirement: SecRequirement?
        guard SecCodeCopyDesignatedRequirement(code, [], &requirement) == errSecSuccess,
              let req = requirement else { return nil }

        var reqString: CFString?
        guard SecRequirementCopyString(req, [], &reqString) == errSecSuccess,
              let requirementStr = reqString as String?,
              // Only enforce requirement string if it's not an ad-hoc cdhash requirement
              requirementStr.contains("identifier \"\(allowedBundleIdentifier)\"") else {
            return nil
        }
        return requirementStr
    }
}

// Create the delegate for the service.
let delegate = ServiceDelegate()

// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate

// Resuming the serviceListener starts this service. This method does not return.
listener.resume()
