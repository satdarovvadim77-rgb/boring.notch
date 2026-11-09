//
//  AppIconCropSheet.swift
//  boringNotch
//
//  Created for Custom App Icon Cropping & Selection on 2026-11-01.
//

import AppKit
import Defaults
import SwiftUI

// MARK: - Crop Sheet Item Model
struct CropImageItem: Identifiable {
    let id = UUID()
    let image: NSImage
}

// MARK: - Crop Sheet Modal
struct AppIconCropSheet: View {
    let sourceImage: NSImage
    let onApply: (NSImage) -> Void
    let onCancel: () -> Void

    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    private let canvasSize: CGFloat = 280
    private let iconCornerRadius: CGFloat = 62

    private var currentScale: CGFloat {
        max(0.4, min(4.0, zoomScale))
    }

    private var currentOffset: CGSize {
        CGSize(
            width: offset.width + dragOffset.width,
            height: offset.height + dragOffset.height
        )
    }

    // MARK: - Image Normalization Helper (Downscales oversized photos off-thread)
    static func normalizeImageForCropping(_ image: NSImage, maxDimension: CGFloat = 1600) -> NSImage {
        var pixelWidth: CGFloat = image.size.width
        var pixelHeight: CGFloat = image.size.height

        for rep in image.representations {
            if rep.pixelsWide > 0 && rep.pixelsHigh > 0 {
                pixelWidth = max(pixelWidth, CGFloat(rep.pixelsWide))
                pixelHeight = max(pixelHeight, CGFloat(rep.pixelsHigh))
            }
        }

        guard pixelWidth > 0, pixelHeight > 0 else { return image }
        let maxSide = max(pixelWidth, pixelHeight)
        if maxSide <= maxDimension {
            return image
        }

        let scale = maxDimension / maxSide
        let newSize = NSSize(width: round(pixelWidth * scale), height: round(pixelHeight * scale))

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("Crop App Icon")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Drag the image to reposition, and use the slider to zoom.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Cropping Canvas with Squircle Mask
            ZStack {
                // Background backing
                RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.85))

                // Interactive Image
                Image(nsImage: sourceImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
                    .frame(width: canvasSize, height: canvasSize)
            }
            .frame(width: canvasSize, height: canvasSize)
            .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        offset = CGSize(
                            width: offset.width + value.translation.width,
                            height: offset.height + value.translation.height
                        )
                    }
            )

            // Zoom Controls
            HStack(spacing: 14) {
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        zoomScale = max(0.4, zoomScale - 0.2)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)

                Slider(value: $zoomScale, in: 0.4...4.0, step: 0.05)
                    .frame(width: 180)

                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        zoomScale = min(4.0, zoomScale + 0.2)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)

                Button("Reset") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = .zero
                        zoomScale = 1.0
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)

            Divider()
                .padding(.horizontal, 16)

            // Actions
            HStack {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Apply as App Icon") {
                    let cropped = renderCroppedImage()
                    onApply(cropped)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.effectiveAccent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(width: 440, height: 490)
    }

    // MARK: - Crop & Render to Standard 1024x1024 macOS App Icon
    private func renderCroppedImage() -> NSImage {
        let canvasPixelSize = 1024
        let targetSize = NSSize(width: canvasPixelSize, height: canvasPixelSize)

        // Exact standard macOS app icon squircle geometry matching BoringNotch original icon
        let squircleRect = NSRect(x: 74, y: 64, width: 876, height: 864)
        let squircleCornerRadius: CGFloat = 196

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
        ) else {
            return sourceImage
        }
        bitmapRep.size = targetSize

        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context?.imageInterpolation = .high

        // 1. Draw standard macOS drop shadow behind squircle
        let squirclePath = NSBezierPath(
            roundedRect: squircleRect,
            xRadius: squircleCornerRadius,
            yRadius: squircleCornerRadius
        )

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.shadowBlurRadius = 22

        shadow.set()
        NSColor.black.setFill()
        squirclePath.fill()

        // Reset shadow so it does not affect inner drawing
        let noShadow = NSShadow()
        noShadow.set()

        // 2. Clip drawing to the squircle
        squirclePath.addClip()

        // 3. Fill squircle background
        NSColor.black.setFill()
        squirclePath.fill()

        // 4. Compute drawing frame matching user's pan and zoom
        let srcSize = sourceImage.size
        guard srcSize.width > 0 && srcSize.height > 0 else {
            NSGraphicsContext.restoreGraphicsState()
            let outputImage = NSImage(size: targetSize)
            outputImage.addRepresentation(bitmapRep)
            return outputImage
        }

        let aspect = srcSize.width / srcSize.height
        var baseDrawWidth: CGFloat = 0
        var baseDrawHeight: CGFloat = 0

        if aspect > 1.0 {
            baseDrawHeight = canvasSize
            baseDrawWidth = canvasSize * aspect
        } else {
            baseDrawWidth = canvasSize
            baseDrawHeight = canvasSize / aspect
        }

        let factorX = squircleRect.width / canvasSize
        let factorY = squircleRect.height / canvasSize
        let factor = max(factorX, factorY)

        let drawWidth = baseDrawWidth * currentScale * factor
        let drawHeight = baseDrawHeight * currentScale * factor

        let centerX = squircleRect.midX + (currentOffset.width * factor)
        // In NSImage drawing coordinates, Y origin is at the bottom (+Y is up)
        let centerY = squircleRect.midY - (currentOffset.height * factor)

        let destRect = NSRect(
            x: centerX - (drawWidth / 2.0),
            y: centerY - (drawHeight / 2.0),
            width: drawWidth,
            height: drawHeight
        )

        sourceImage.draw(
            in: destRect,
            from: NSRect(origin: .zero, size: srcSize),
            operation: .sourceOver,
            fraction: 1.0
        )

        // 5. Subtle macOS icon inner highlight stroke
        let borderPath = NSBezierPath(
            roundedRect: squircleRect.insetBy(dx: 0.5, dy: 0.5),
            xRadius: squircleCornerRadius - 0.5,
            yRadius: squircleCornerRadius - 0.5
        )
        NSColor.white.withAlphaComponent(0.12).setStroke()
        borderPath.lineWidth = 1.0
        borderPath.stroke()

        NSGraphicsContext.restoreGraphicsState()

        let outputImage = NSImage(size: targetSize)
        outputImage.addRepresentation(bitmapRep)
        return outputImage
    }
}

// MARK: - App Icon Card Component
struct AppIconCard: View {
    let image: Image
    let title: String
    let isSelected: Bool
    let canDelete: Bool
    var onDelete: (() -> Void)? = nil
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(isHovering ? 0.08 : 0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    isSelected ? Color.effectiveAccent : Color.white.opacity(0.12),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )

                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                }
                .frame(width: 74, height: 74)
                .shadow(color: isSelected ? Color.effectiveAccent.opacity(0.35) : Color.clear, radius: 6)

                // Delete button for custom icons
                if canDelete && isHovering {
                    Button(action: {
                        onDelete?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white, Color.red)
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: -4)
                    .transition(.opacity)
                }
            }

            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.effectiveAccent : Color.clear)
                )
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Add Icon Card Button
struct AddAppIconCard: View {
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        Color.secondary.opacity(isHovering ? 0.6 : 0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(isHovering ? 0.08 : 0.03))
                    )
                    .frame(width: 74, height: 74)

                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isHovering ? Color.effectiveAccent : Color.secondary)
                }
            }

            Text("Add Icon")
                .font(.caption)
                .foregroundStyle(isHovering ? Color.primary : Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            action()
        }
    }
}
