//
//  AppearanceSettingsView.swift
//  boringNotch
//
//  Extracted from SettingsView.swift
//

import AVFoundation
import Defaults
import SwiftUI

struct Appearance: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Default(.mirrorShape) var mirrorShape
    @Default(.sliderColor) var sliderColor
    @Default(.useMusicVisualizer) var useMusicVisualizer
    @Default(.customVisualizers) var customVisualizers
    @Default(.selectedVisualizer) var selectedVisualizer
    @Default(.notchBackgroundStyle) var notchBackgroundStyle
    @Default(.liquidGlassOpacity) var liquidGlassOpacity
    @Default(.notchCornerRadius) var notchCornerRadius
    @Default(.showDateTimeWhenIdle) var showDateTimeWhenIdle
    @Default(.idleClockTimeout) var idleClockTimeout
    @Default(.dateTimeFontStyle) var dateTimeFontStyle
    @Default(.dateTimeFontWeight) var dateTimeFontWeight
    @Default(.dateTimeLayoutStyle) var dateTimeLayoutStyle
    @Default(.dateTimeColorStyle) var dateTimeColorStyle
    @Default(.dateTimeCustomColorHex) var dateTimeCustomColorHex
    @Default(.dateTimeClockScale) var dateTimeClockScale
    @Default(.dateTimeTextOpacity) var dateTimeTextOpacity
    @Default(.dateTimeShowSeconds) var dateTimeShowSeconds
    @Default(.dateTime24Hour) var dateTime24Hour
    @Default(.dateTimeShowDayOfWeek) var dateTimeShowDayOfWeek

    private var formattedTimeout: String {
        if idleClockTimeout <= 0 {
            return "Immediately on pause"
        }
        let totalSec = Int(idleClockTimeout)
        let minutes = totalSec / 60
        let seconds = totalSec % 60
        if minutes == 0 {
            return "\(seconds) sec"
        } else if seconds == 0 {
            return "\(minutes) min"
        } else {
            return "\(minutes) min \(seconds) sec"
        }
    }

    let icons: [String] = ["logo2"]
    @State private var selectedIcon: String = "logo2"
    @State private var selectedListVisualizer: CustomVisualizer? = nil
    @State private var isPresented: Bool = false
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var speed: CGFloat = 1.0

    var body: some View {
        Form {
            Section {
                Picker("Notch background style", selection: $notchBackgroundStyle) {
                    ForEach(NotchBackgroundStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Liquid glass effect / Opacity")
                        Spacer()
                        Text("\(Int(liquidGlassOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $liquidGlassOpacity, in: 0.0...1.0, step: 0.05)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Corner radius")
                        Spacer()
                        Text("\(Int(notchCornerRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $notchCornerRadius, in: 8.0...36.0, step: 1.0)
                }

                Defaults.Toggle(key: .continuousCorners) {
                    Text("Continuous corners (.continuous Apple superellipse)")
                }
            } header: {
                Text("Notch Appearance")
            } footer: {
                Text("Adjusts the background fill and glass blur across the entire notch (Liquid Glass, Dark Surface, Gradient Glow, Accent Tint, or Ultra Transparent). When closed on a MacBook display with a physical camera notch, it seamlessly hides under the notch hardware.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Show clock and date when idle", isOn: $showDateTimeWhenIdle)

                if showDateTimeWhenIdle {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Idle timeout before showing clock")
                            Spacer()
                            Text(formattedTimeout)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $idleClockTimeout, in: 0.0...600.0, step: 10.0)
                    }

                    Picker("Font design", selection: $dateTimeFontStyle) {
                        ForEach(DateTimeFontStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    Picker("Clock font weight", selection: $dateTimeFontWeight) {
                        ForEach(DateTimeFontWeight.allCases) { weight in
                            Text(weight.rawValue).tag(weight)
                        }
                    }

                    Picker("Widget layout style", selection: $dateTimeLayoutStyle) {
                        ForEach(DateTimeLayoutStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    Picker("Color & gradient fill", selection: $dateTimeColorStyle) {
                        ForEach(DateTimeColorStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    if dateTimeColorStyle == .palette {
                        HStack {
                            Text("Custom color palette")
                            Spacer()
                            ColorPicker("", selection: Binding(
                                get: {
                                    Color(hex: dateTimeCustomColorHex)
                                },
                                set: { newColor in
                                    let nsColor = NSColor(newColor)
                                    if let rgb = nsColor.usingColorSpace(.sRGB) {
                                        let r = Int(rgb.redComponent * 255)
                                        let g = Int(rgb.greenComponent * 255)
                                        let b = Int(rgb.blueComponent * 255)
                                        dateTimeCustomColorHex = String(format: "#%02X%02X%02X", r, g, b)
                                    }
                                }
                            ), supportsOpacity: false)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Clock size")
                            Spacer()
                            Text("\(Int(dateTimeClockScale * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $dateTimeClockScale, in: 0.7...1.5, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Clock & date opacity")
                            Spacer()
                            Text("\(Int(dateTimeTextOpacity * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $dateTimeTextOpacity, in: 0.2...1.0, step: 0.05)
                    }

                    Toggle("24-hour time", isOn: $dateTime24Hour)
                    Toggle("Show seconds", isOn: $dateTimeShowSeconds)
                    Toggle("Show day of week", isOn: $dateTimeShowDayOfWeek)
                }
            } header: {
                Text("Clock & Date (Idle Screen)")
            } footer: {
                Text("Displays the current time and date when there is no active media playback session, blending natively into the notch background.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Always show tabs", isOn: $coordinator.alwaysShowTabs)
                Defaults.Toggle(key: .settingsIconInNotch) {
                    Text("Show settings icon in notch")
                }
            } header: {
                Text("General")
            }

            Section {
                Defaults.Toggle(key: .coloredSpectrogram) {
                    Text("Colored spectrogram")
                }
                Defaults.Toggle("Player tinting", key: .playerColorTinting)
                Defaults.Toggle(key: .lightingEffect) {
                    Text("Enable blur effect behind album art")
                }
                Picker("Slider color", selection: $sliderColor) {
                    ForEach(SliderColorEnum.allCases, id: \.self) { option in
                        Text(option.rawValue)
                    }
                }
            } header: {
                Text("Media")
            }

            Section {
                Toggle(
                    "Use music visualizer spectrogram",
                    isOn: $useMusicVisualizer.animation()
                )
                .disabled(true)
                if !useMusicVisualizer {
                    if !customVisualizers.isEmpty {
                        Picker(
                            "Selected animation",
                            selection: $selectedVisualizer
                        ) {
                            ForEach(customVisualizers, id: \.self) { visualizer in
                                Text(visualizer.name)
                                    .tag(visualizer)
                            }
                        }
                    } else {
                        HStack {
                            Text("Selected animation")
                            Spacer()
                            Text("No custom animation available")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Custom music live activity animation")
                    customBadge(text: "Coming soon")
                }
            }

            Section {
                List {
                    ForEach(customVisualizers, id: \.self) { visualizer in
                        HStack {
                            LottieView(
                                url: visualizer.url, speed: visualizer.speed,
                                loopMode: .loop
                            )
                            .frame(width: 30, height: 30, alignment: .center)
                            Text(visualizer.name)
                            Spacer(minLength: 0)
                            if selectedVisualizer == visualizer {
                                Text("selected")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        .background(
                            selectedListVisualizer == visualizer
                                ? Color.effectiveAccent : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedListVisualizer == visualizer {
                                selectedListVisualizer = nil
                                return
                            }
                            selectedListVisualizer = visualizer
                        }
                    }
                }
                .safeAreaPadding(
                    EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                )
                .frame(minHeight: 120)
                .actionBar {
                    HStack(spacing: 5) {
                        Button {
                            name = ""
                            url = ""
                            speed = 1.0
                            isPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.secondary)
                                .contentShape(Rectangle())
                        }
                        Divider()
                        Button {
                            if let visualizer = selectedListVisualizer,
                               let index = customVisualizers.firstIndex(of: visualizer) {
                                selectedListVisualizer = nil
                                customVisualizers.remove(at: index)
                                if visualizer == selectedVisualizer {
                                    selectedVisualizer = customVisualizers.first
                                }
                            }
                        } label: {
                            Image(systemName: "minus")
                                .foregroundStyle(.secondary)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .controlSize(.small)
                .buttonStyle(PlainButtonStyle())
                .overlay {
                    if customVisualizers.isEmpty {
                        Text("No custom visualizer")
                            .foregroundStyle(Color(.secondaryLabelColor))
                            .padding(.bottom, 22)
                    }
                }
                .sheet(isPresented: $isPresented) {
                    VStack(alignment: .leading) {
                        Text("Add new visualizer")
                            .font(.largeTitle.bold())
                            .padding(.vertical)
                        TextField("Name", text: $name)
                        TextField("Lottie JSON URL", text: $url)
                        HStack {
                            Text("Speed")
                            Spacer(minLength: 80)
                            Text("\(speed, specifier: "%.1f")s")
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                            Slider(value: $speed, in: 0...2, step: 0.1)
                        }
                        .padding(.vertical)
                        HStack {
                            Button {
                                isPresented.toggle()
                            } label: {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            Button {
                                guard let parsedURL = URL(string: url), !name.isEmpty else { return }
                                let visualizer: CustomVisualizer = .init(
                                    UUID: UUID(),
                                    name: name,
                                    url: parsedURL,
                                    speed: speed
                                )

                                if !customVisualizers.contains(visualizer) {
                                    customVisualizers.append(visualizer)
                                }

                                isPresented.toggle()
                            } label: {
                                Text("Add")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(BorderedProminentButtonStyle())
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .controlSize(.extraLarge)
                    .padding()
                }
            } header: {
                HStack(spacing: 0) {
                    Text("Custom vizualizers (Lottie)")
                    if !Defaults[.customVisualizers].isEmpty {
                        Text(" – \(Defaults[.customVisualizers].count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Defaults.Toggle(key: .showMirror) {
                    Text("Enable boring mirror")
                }
                .disabled(!checkVideoInput())
                Picker("Mirror shape", selection: $mirrorShape) {
                    Text("Circle")
                        .tag(MirrorShapeEnum.circle)
                    Text("Square")
                        .tag(MirrorShapeEnum.rectangle)
                }
                Defaults.Toggle(key: .showNotHumanFace) {
                    Text("Show cool face animation while inactive")
                }
            } header: {
                HStack {
                    Text("Additional features")
                }
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Appearance")
    }

    func checkVideoInput() -> Bool {
        AVCaptureDevice.default(for: .video) != nil
    }
}
