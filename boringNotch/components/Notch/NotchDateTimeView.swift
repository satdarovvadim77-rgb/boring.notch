//
//  NotchDateTimeView.swift
//  boringNotch
//
//  Created for Date & Time Idle Notch Display on 2026-11-01.
//

import Defaults
import SwiftUI

struct NotchDateTimeView: View {
    @Default(.dateTimeFontStyle) private var fontStyle
    @Default(.dateTimeFontWeight) private var fontWeight
    @Default(.dateTimeLayoutStyle) private var layoutStyle
    @Default(.dateTimeColorStyle) private var colorStyle
    @Default(.dateTimeCustomColorHex) private var customColorHex
    @Default(.dateTimeClockScale) private var clockScale
    @Default(.dateTimeTextOpacity) private var textOpacity
    @Default(.dateTimeShowSeconds) private var showSeconds
    @Default(.dateTime24Hour) private var is24Hour
    @Default(.dateTimeShowDayOfWeek) private var showDayOfWeek

    private var currentLocale: Locale {
        Locale.autoupdatingCurrent
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: showSeconds ? 1.0 : 10.0)) { context in
            content(for: context.date)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Layout Selector
    @ViewBuilder
    private func content(for date: Date) -> some View {
        switch layoutStyle {
        case .stacked:
            stackedLayout(for: date)
        case .horizontal:
            horizontalLayout(for: date)
        case .capsule:
            capsuleLayout(for: date)
        case .digitalWidget:
            digitalWidgetLayout(for: date)
        case .minimalist:
            minimalistLayout(for: date)
        }
    }

    // MARK: - 1. Stacked Layout
    private func stackedLayout(for date: Date) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeString(for: date))
                    .font(clockFont(size: 42 * clockScale))
                    .foregroundStyle(clockShapeStyle)

                if !is24Hour {
                    Text(amPmString(for: date))
                        .font(clockFont(size: 14 * clockScale))
                        .foregroundStyle(clockShapeStyle)
                        .opacity(0.8)
                }
            }

            Text(fullDateString(for: date))
                .font(dateFont(size: 13 * min(1.2, max(0.85, clockScale))))
                .foregroundStyle(dateShapeStyle)
        }
    }

    // MARK: - 2. Horizontal Layout
    private func horizontalLayout(for date: Date) -> some View {
        HStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeString(for: date))
                    .font(clockFont(size: 26 * clockScale))
                    .foregroundStyle(clockShapeStyle)

                if !is24Hour {
                    Text(amPmString(for: date))
                        .font(clockFont(size: 11 * clockScale))
                        .foregroundStyle(clockShapeStyle)
                        .opacity(0.8)
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 1, height: 24 * clockScale)

            Text(fullDateString(for: date))
                .font(dateFont(size: 15 * min(1.2, max(0.85, clockScale))))
                .foregroundStyle(dateShapeStyle)
        }
    }

    // MARK: - 3. Capsule Badge Layout
    private func capsuleLayout(for date: Date) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(timeString(for: date))
                    .font(clockFont(size: 32 * clockScale))
                    .foregroundStyle(clockShapeStyle)

                if !is24Hour {
                    Text(amPmString(for: date))
                        .font(clockFont(size: 12 * clockScale))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(fullDateString(for: date).uppercased())
                .font(dateFont(size: 11 * min(1.2, max(0.85, clockScale))))
                .tracking(1.2)
                .foregroundStyle(dateShapeStyle)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    // MARK: - 4. Digital Widget Layout
    private func digitalWidgetLayout(for date: Date) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                digitalTile(hoursString(for: date))

                Text(":")
                    .font(clockFont(size: 26 * clockScale))
                    .foregroundStyle(clockShapeStyle)
                    .opacity(0.8)

                digitalTile(minutesString(for: date))

                if showSeconds {
                    Text(":")
                        .font(clockFont(size: 26 * clockScale))
                        .foregroundStyle(clockShapeStyle)
                        .opacity(0.8)

                    digitalTile(secondsString(for: date))
                }

                if !is24Hour {
                    Text(amPmString(for: date))
                        .font(clockFont(size: 11 * clockScale))
                        .foregroundStyle(clockShapeStyle)
                        .opacity(0.7)
                        .padding(.leading, 2)
                }
            }

            Text(fullDateString(for: date))
                .font(dateFont(size: 12 * min(1.2, max(0.85, clockScale))))
                .foregroundStyle(dateShapeStyle)
        }
    }

    private func digitalTile(_ text: String) -> some View {
        Text(text)
            .font(clockFont(size: 26 * clockScale))
            .foregroundStyle(clockShapeStyle)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - 5. Minimalist Layout
    private func minimalistLayout(for date: Date) -> some View {
        VStack(spacing: 2) {
            Text(timeString(for: date))
                .font(clockFont(size: 38 * clockScale))
                .foregroundStyle(clockShapeStyle)

            Text(fullDateString(for: date))
                .font(dateFont(size: 13 * min(1.2, max(0.85, clockScale))))
                .foregroundStyle(dateShapeStyle)
        }
    }

    // MARK: - Shape Styles (Color, Gradients & Opacity)
    private var clockShapeStyle: AnyShapeStyle {
        resolveShapeStyle(opacityMultiplier: 1.0)
    }

    private var dateShapeStyle: AnyShapeStyle {
        resolveShapeStyle(opacityMultiplier: 0.85)
    }

    private func resolveShapeStyle(opacityMultiplier: Double) -> AnyShapeStyle {
        let opacity = textOpacity * opacityMultiplier

        switch colorStyle {
        case .palette:
            let col = Color(hex: customColorHex)
            return AnyShapeStyle(col.opacity(opacity))
        case .sunsetGlow:
            return AnyShapeStyle(sunsetGradient(opacity: opacity))
        case .oceanBreeze:
            return AnyShapeStyle(oceanGradient(opacity: opacity))
        case .lavenderDusk:
            return AnyShapeStyle(lavenderGradient(opacity: opacity))
        case .neonCyber:
            return AnyShapeStyle(neonCyberGradient(opacity: opacity))
        case .crimsonFire:
            return AnyShapeStyle(crimsonGradient(opacity: opacity))
        case .aurora:
            return AnyShapeStyle(auroraGradient(opacity: opacity))
        case .white:
            return AnyShapeStyle(Color.white.opacity(opacity))
        case .accent:
            return AnyShapeStyle(Color.effectiveAccent.opacity(opacity))
        case .cyan:
            return AnyShapeStyle(Color(red: 0.15, green: 0.88, blue: 1.0).opacity(opacity))
        case .orange:
            return AnyShapeStyle(Color(red: 1.0, green: 0.58, blue: 0.16).opacity(opacity))
        case .purple:
            return AnyShapeStyle(Color(red: 0.78, green: 0.45, blue: 1.0).opacity(opacity))
        case .green:
            return AnyShapeStyle(Color(red: 0.32, green: 0.92, blue: 0.52).opacity(opacity))
        case .gold:
            return AnyShapeStyle(Color(red: 1.0, green: 0.82, blue: 0.22).opacity(opacity))
        case .rose:
            return AnyShapeStyle(Color(red: 1.0, green: 0.45, blue: 0.68).opacity(opacity))
        }
    }

    // MARK: - Apple-Style Two-Tone Gradients
    private func sunsetGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.38, blue: 0.52).opacity(opacity),
                Color(red: 1.0, green: 0.74, blue: 0.24).opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func oceanGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.92, blue: 1.0).opacity(opacity),
                Color(red: 0.16, green: 0.44, blue: 0.98).opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func lavenderGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.76, green: 0.50, blue: 1.0).opacity(opacity),
                Color(red: 0.98, green: 0.35, blue: 0.72).opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func neonCyberGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.82, green: 1.0, blue: 0.22).opacity(opacity),
                Color(red: 0.15, green: 0.92, blue: 0.65).opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func crimsonGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.22, blue: 0.32).opacity(opacity),
                Color(red: 1.0, green: 0.60, blue: 0.12).opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func auroraGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.22, green: 0.88, blue: 0.95).opacity(opacity),
                Color(red: 0.68, green: 0.45, blue: 1.0).opacity(opacity),
                Color(red: 1.0, green: 0.48, blue: 0.68).opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Font Factory
    private func clockFont(size: CGFloat) -> Font {
        font(size: size, weight: fontWeight.fontWeight)
    }

    private func dateFont(size: CGFloat) -> Font {
        font(size: size, weight: .medium)
    }

    private func font(size: CGFloat, weight: Font.Weight) -> Font {
        switch fontStyle {
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .system:
            return .system(size: size, weight: weight, design: .default)
        case .monospaced:
            return .system(size: size, weight: weight, design: .monospaced)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .heavy:
            return .system(size: size, weight: weight, design: .rounded)
        case .compact:
            return .system(size: size, weight: weight, design: .default)
        }
    }

    // MARK: - Date Formatting Helpers
    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        if is24Hour {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss" : "h:mm"
        }
        return formatter.string(from: date)
    }

    private func hoursString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = is24Hour ? "HH" : "h"
        return formatter.string(from: date)
    }

    private func minutesString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter.string(from: date)
    }

    private func secondsString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: date)
    }

    private func amPmString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }

    private func fullDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        if showDayOfWeek {
            formatter.dateFormat = "EEEE, MMMM d"
        } else {
            formatter.dateFormat = "MMMM d"
        }
        let str = formatter.string(from: date)
        return str.prefix(1).uppercased() + str.dropFirst()
    }
}
