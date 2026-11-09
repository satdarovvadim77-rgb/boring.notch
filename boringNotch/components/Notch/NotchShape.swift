//
//  NotchShape.swift
//  boringNotch
//
// Created by Kai Azim on 2023-08-24.
// Original source: https://github.com/MrKai77/DynamicNotchKit
// Modified by Alexander on 2025-05-18.
// Enhanced with Apple .continuous superellipse curve support on 2026-11-01.
//

import Defaults
import SwiftUI

struct NotchShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    var isContinuous: Bool

    init(
        topCornerRadius: CGFloat? = nil,
        bottomCornerRadius: CGFloat? = nil,
        isContinuous: Bool? = nil
    ) {
        self.topCornerRadius = topCornerRadius ?? 6
        self.bottomCornerRadius = bottomCornerRadius ?? 14
        self.isContinuous = isContinuous ?? Defaults[.continuousCorners]
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(
                topCornerRadius,
                bottomCornerRadius
            )
        }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start top-left ear base
        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        // Top-left corner ("ear")
        if isContinuous {
            path.addCurve(
                to: CGPoint(
                    x: rect.minX + topCornerRadius,
                    y: rect.minY + topCornerRadius
                ),
                control1: CGPoint(
                    x: rect.minX + topCornerRadius * 0.448,
                    y: rect.minY
                ),
                control2: CGPoint(
                    x: rect.minX + topCornerRadius,
                    y: rect.minY + topCornerRadius * 0.552
                )
            )
        } else {
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.minX + topCornerRadius,
                    y: rect.minY + topCornerRadius
                ),
                control: CGPoint(
                    x: rect.minX + topCornerRadius,
                    y: rect.minY
                )
            )
        }

        // Left vertical edge
        path.addLine(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            )
        )

        // Bottom-left corner
        if isContinuous {
            path.addCurve(
                to: CGPoint(
                    x: rect.minX + topCornerRadius + bottomCornerRadius,
                    y: rect.maxY
                ),
                control1: CGPoint(
                    x: rect.minX + topCornerRadius,
                    y: rect.maxY - bottomCornerRadius * 0.448
                ),
                control2: CGPoint(
                    x: rect.minX + topCornerRadius + bottomCornerRadius * 0.552,
                    y: rect.maxY
                )
            )
        } else {
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.minX + topCornerRadius + bottomCornerRadius,
                    y: rect.maxY
                ),
                control: CGPoint(
                    x: rect.minX + topCornerRadius,
                    y: rect.maxY
                )
            )
        }

        // Bottom horizontal edge
        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius - bottomCornerRadius,
                y: rect.maxY
            )
        )

        // Bottom-right corner
        if isContinuous {
            path.addCurve(
                to: CGPoint(
                    x: rect.maxX - topCornerRadius,
                    y: rect.maxY - bottomCornerRadius
                ),
                control1: CGPoint(
                    x: rect.maxX - topCornerRadius - bottomCornerRadius * 0.552,
                    y: rect.maxY
                ),
                control2: CGPoint(
                    x: rect.maxX - topCornerRadius,
                    y: rect.maxY - bottomCornerRadius * 0.448
                )
            )
        } else {
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.maxX - topCornerRadius,
                    y: rect.maxY - bottomCornerRadius
                ),
                control: CGPoint(
                    x: rect.maxX - topCornerRadius,
                    y: rect.maxY
                )
            )
        }

        // Right vertical edge
        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY + topCornerRadius
            )
        )

        // Top-right corner ("ear")
        if isContinuous {
            path.addCurve(
                to: CGPoint(
                    x: rect.maxX,
                    y: rect.minY
                ),
                control1: CGPoint(
                    x: rect.maxX - topCornerRadius,
                    y: rect.minY + topCornerRadius * 0.552
                ),
                control2: CGPoint(
                    x: rect.maxX - topCornerRadius * 0.448,
                    y: rect.minY
                )
            )
        } else {
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.maxX,
                    y: rect.minY
                ),
                control: CGPoint(
                    x: rect.maxX - topCornerRadius,
                    y: rect.minY
                )
            )
        }

        // Close back across top to start
        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        return path
    }
}

#Preview {
    NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
        .frame(width: 200, height: 32)
        .padding(10)
}
