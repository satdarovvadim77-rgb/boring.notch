//
//  AppIconManager.swift
//  boringNotch
//
//  Created for Custom App Icon Management on 2026-11-01.
//

import AppKit
import Defaults
import Foundation

@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    private var cachedIconID: String?
    private var cachedIconImage: NSImage?
    private var dockRefreshTask: Task<Void, Never>?

    init() {}

    var customIconsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
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
            Logger.log("Failed to save custom icon: \(error.localizedDescription)", category: .error)
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

    /// Applies the selected icon in runtime (Dock & application icon) without mutating the .app bundle on disk,
    /// preserving code signing integrity and Sparkle update compatibility.
    func applyIcon(id: String, refreshDock: Bool = true) {
        Defaults[.selectedAppIconID] = id
        cachedIconID = nil
        cachedIconImage = nil
        restoreSavedAppIcon()
    }

    func restoreSavedAppIcon() {
        let currentID = Defaults[.selectedAppIconID]
        applyRuntimeApplicationIcon(for: currentID)

        dockRefreshTask?.cancel()
        dockRefreshTask = Task { @MainActor [weak self] in
            for delayMs in [60, 180, 350] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                guard !Task.isCancelled, let self = self else { return }
                self.applyRuntimeApplicationIcon(for: Defaults[.selectedAppIconID])
            }
        }
    }

    private func resolveIconImage(for id: String) -> NSImage? {
        if cachedIconID == id, let cachedIconImage {
            return cachedIconImage
        }

        let resolved: NSImage?
        if id == "default" {
            resolved = NSImage(named: "logo2") ?? NSImage(named: "AppIcon")
        } else if let item = Defaults[.customAppIcons].first(where: { $0.id == id }),
                  let image = loadImage(for: item) {
            resolved = image
        } else {
            resolved = NSImage(named: "logo2") ?? NSImage(named: "AppIcon")
        }

        cachedIconID = id
        cachedIconImage = resolved
        return resolved
    }

    private func applyRuntimeApplicationIcon(for id: String) {
        if let image = resolveIconImage(for: id) {
            NSApp.applicationIconImage = nil
            NSApp.applicationIconImage = image

            if id == "default" {
                NSApp.dockTile.contentView = nil
            } else {
                let tileSize = NSApp.dockTile.size
                let frame = NSRect(
                    origin: .zero,
                    size: tileSize.width > 0 ? tileSize : NSSize(width: 128, height: 128)
                )
                let imageView = NSImageView(frame: frame)
                imageView.image = image
                imageView.imageScaling = .scaleProportionallyUpOrDown
                NSApp.dockTile.contentView = imageView
            }
        } else {
            NSApp.applicationIconImage = nil
            NSApp.dockTile.contentView = nil
        }

        NSApp.dockTile.display()
    }
}
