//
//  AppIconManager.swift
//  boringNotch
//
//  Created for Custom App Icon Management on 2026-11-01.
//

import AppKit
import Defaults
import Foundation

final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    private init() {}

    var customIconsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("boringNotch/CustomIcons", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func loadImage(for item: CustomAppIconItem) -> NSImage? {
        let fileURL = customIconsDirectory.appendingPathComponent(item.fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let loaded = NSImage(contentsOf: fileURL) else { return nil }
        return normalizeIconToStandardSize(loaded)
    }

    func normalizeIconToStandardSize(_ image: NSImage) -> NSImage {
        // If already standard 1024x1024 with margins, return as-is
        if image.size.width == 1024 && image.size.height == 1024 {
            return image
        }

        let canvasPixelSize = 1024
        let targetSize = NSSize(width: canvasPixelSize, height: canvasPixelSize)
        let squircleRect = NSRect(x: 74, y: 64, width: 876, height: 864)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: canvasPixelSize,
            pixelsHigh: canvasPixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return image }
        bitmapRep.size = targetSize

        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context?.imageInterpolation = .high

        // Drop shadow behind squircle
        let squirclePath = NSBezierPath(roundedRect: squircleRect, xRadius: 196, yRadius: 196)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.shadowBlurRadius = 22
        shadow.set()
        NSColor.black.setFill()
        squirclePath.fill()

        let noShadow = NSShadow()
        noShadow.set()
        squirclePath.addClip()

        image.draw(in: squircleRect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)

        NSGraphicsContext.restoreGraphicsState()

        let output = NSImage(size: targetSize)
        output.addRepresentation(bitmapRep)
        return output
    }

    @discardableResult
    func saveCustomIcon(image: NSImage, name: String) -> CustomAppIconItem? {
        let normalized = normalizeIconToStandardSize(image)
        let id = UUID().uuidString
        let fileName = "icon_\(id).png"
        let fileURL = customIconsDirectory.appendingPathComponent(fileName)

        let pngData: Data? = {
            if let bitmap = normalized.representations.compactMap({ $0 as? NSBitmapImageRep }).first,
               let data = bitmap.representation(using: .png, properties: [:]) {
                return data
            }
            if let tiffData = normalized.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData) {
                return bitmap.representation(using: .png, properties: [:])
            }
            return nil
        }()

        guard let data = pngData else { return nil }

        do {
            try data.write(to: fileURL)
            let item = CustomAppIconItem(id: id, name: name, fileName: fileName, dateAdded: Date())
            var currentIcons = Defaults[.customAppIcons]
            currentIcons.append(item)
            Defaults[.customAppIcons] = currentIcons
            applyIcon(id: id)
            return item
        } catch {
            print("Failed to save custom icon: \(error)")
            return nil
        }
    }

    func deleteCustomIcon(item: CustomAppIconItem) {
        let fileURL = customIconsDirectory.appendingPathComponent(item.fileName)
        try? FileManager.default.removeItem(at: fileURL)

        var currentIcons = Defaults[.customAppIcons]
        currentIcons.removeAll { $0.id == item.id }
        Defaults[.customAppIcons] = currentIcons

        if Defaults[.selectedAppIconID] == item.id {
            applyIcon(id: "default", refreshDock: true)
        }
    }

    func applyIcon(id: String, refreshDock: Bool = true) {
        Defaults[.selectedAppIconID] = id

        let bundlePath = Bundle.main.bundlePath

        let targetImage: NSImage?
        let pngData: Data?

        if id == "default" {
            // Revert to original app icon from bundle assets
            targetImage = NSImage(named: "logo2") ?? NSImage(named: "AppIcon")
            pngData = nil
            if let targetImage {
                NSApp.applicationIconImage = targetImage
            } else {
                NSApp.applicationIconImage = nil
            }
        } else if let item = Defaults[.customAppIcons].first(where: { $0.id == id }),
                  let image = loadImage(for: item) {
            targetImage = image
            pngData = {
                if let bitmap = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first,
                   let data = bitmap.representation(using: .png, properties: [:]) {
                    return data
                }
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData) {
                    return bitmap.representation(using: .png, properties: [:])
                }
                return nil
            }()
            NSApp.applicationIconImage = image
        } else {
            targetImage = nil
            pngData = nil
            NSApp.applicationIconImage = nil
        }

        NSApp.dockTile.display()

        // 1. Direct attempt (works if running unsandboxed or bundle is directly writable)
        _ = NSWorkspace.shared.setIcon(id == "default" ? nil : targetImage, forFile: bundlePath, options: [])

        // 2. Persistent on-disk bundle update via unsandboxed BoringNotchXPCHelper
        Task {
            _ = await XPCHelperClient.shared.setApplicationBundleIcon(
                imageData: pngData,
                bundlePath: bundlePath,
                refreshDock: refreshDock
            )
        }
    }

    func restoreSavedAppIcon() {
        let currentID = Defaults[.selectedAppIconID]
        applyIcon(id: currentID, refreshDock: false)
    }
}
