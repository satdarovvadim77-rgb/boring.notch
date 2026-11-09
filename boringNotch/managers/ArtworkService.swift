//
//  ArtworkService.swift
//  boringNotch
//
//  Extracted from MusicManager.swift
//

import AppKit
import Foundation

@MainActor
final class ArtworkService {
    static let shared = ArtworkService()

    init() {}

    func decodeArtworkImage(from data: Data) async -> NSImage? {
        await Task.detached(priority: .userInitiated) {
            NSImage(data: data)
        }.value
    }

    func calculateAverageColor(for image: NSImage, isEnergySaverActive: Bool) async -> NSColor {
        if isEnergySaverActive {
            return .white
        }
        return await withCheckedContinuation { continuation in
            image.averageColor { color in
                continuation.resume(returning: color ?? .white)
            }
        }
    }
}
