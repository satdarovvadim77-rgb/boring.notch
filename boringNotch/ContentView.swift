//
//  ContentView.swift
//  boringNotchApp
//
//  Created by Harsh Vardhan Goswami  on 02/08/24
//  Modified by Richard Kunkli on 24/08/2024.
//

import AVFoundation
import Combine
import Defaults
import KeyboardShortcuts
import SwiftUI
import SwiftUIIntrospect

@MainActor
struct ContentView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var webcamManager = WebcamManager.shared

    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var brightnessManager = BrightnessManager.shared
    @ObservedObject var volumeManager = VolumeManager.shared
    @State var hoverTask: Task<Void, Never>?
    @State var isHovering: Bool = false
    @State var anyDropDebounceTask: Task<Void, Never>?

    @State var gestureProgress: CGFloat = .zero
    @State var haptics: Bool = false

    @Namespace var albumArtNamespace

    @Default(.useMusicVisualizer) var useMusicVisualizer
    @Default(.showNotHumanFace) var showNotHumanFace
    @Default(.notchCornerRadius) var customCornerRadius
    @Default(.notchBackgroundStyle) var notchBackgroundStyle
    @Default(.liquidGlassOpacity) var liquidGlassOpacity
    @Default(.continuousCorners) var continuousCorners

    // Shared interactive spring for movement/resizing to avoid conflicting animations
    let animationSpring = Animation.interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)

    private var hasPhysicalNotch: Bool {
        (NSScreen.screen(withUUID: coordinator.selectedScreenUUID)?.safeAreaInsets.top ?? 0) > 0
    }

    private var topCornerRadius: CGFloat {
        if vm.notchState == .open {
            return Defaults[.cornerRadiusScaling]
                ? (customCornerRadius * (19.0 / 24.0))
                : cornerRadiusInsets.closed.top
        } else {
            return cornerRadiusInsets.closed.top
        }
    }

    private var bottomCornerRadius: CGFloat {
        if vm.notchState == .open {
            return Defaults[.cornerRadiusScaling]
                ? customCornerRadius
                : cornerRadiusInsets.closed.bottom
        } else {
            return cornerRadiusInsets.closed.bottom
        }
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius,
            isContinuous: continuousCorners
        )
    }

    @ViewBuilder
    private var notchBackground: some View {
        let glassOpacity = liquidGlassOpacity
        if vm.notchState == .closed && hasPhysicalNotch {
            Color.black
        } else if vm.notchState == .open {
            switch notchBackgroundStyle {
            case .glass:
                if glassOpacity > 0 {
                    ZStack {
                        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        Color.black.opacity(1.0 - (glassOpacity * 0.72))
                    }
                } else {
                    Color.black
                }
            case .solidDark:
                Color.black.opacity(max(0.25, 1.0 - (glassOpacity * 0.65)))
            case .gradientGlow:
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    LinearGradient(
                        colors: [
                            Color.effectiveAccent.opacity(0.35 * max(0.3, glassOpacity)),
                            Color.black.opacity(1.0 - (glassOpacity * 0.5)),
                            Color.black.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            case .accent:
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color.effectiveAccent.opacity(0.25 * max(0.2, glassOpacity))
                        .background(Color.black.opacity(1.0 - (glassOpacity * 0.5)))
                }
            case .transparent:
                Color.black.opacity(max(0.08, 0.45 * (1.0 - glassOpacity)))
            }
        } else {
            Color.black
        }
    }

    private var computedChinWidth: CGFloat {
        var chinWidth: CGFloat = vm.closedNotchSize.width

        if coordinator.expandingView.type == .battery && coordinator.expandingView.show
            && vm.notchState == .closed && Defaults[.showPowerStatusNotifications]
        {
            chinWidth = openNotchWidth
        } else if (!coordinator.expandingView.show || coordinator.expandingView.type == .music)
            && vm.notchState == .closed && (musicManager.isPlaying || !musicManager.isPlayerIdle)
            && coordinator.musicLiveActivityEnabled && !vm.hideOnClosed
        {
            chinWidth += (2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20)
        } else if !coordinator.expandingView.show && vm.notchState == .closed
            && (!musicManager.isPlaying && musicManager.isPlayerIdle) && Defaults[.showNotHumanFace]
            && !vm.hideOnClosed
        {
            chinWidth += (2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20)
        }

        return chinWidth
    }

    var body: some View {
        let gestureScale: CGFloat = {
            guard gestureProgress != 0 else { return 1.0 }
            let scaleFactor = 1.0 + gestureProgress * 0.01
            return max(0.6, scaleFactor)
        }()
        
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                let mainLayout = NotchLayout()
                    .frame(alignment: .top)
                    .padding(
                        .horizontal,
                        vm.notchState == .open
                        ? Defaults[.cornerRadiusScaling]
                        ? (cornerRadiusInsets.opened.top) : (cornerRadiusInsets.opened.bottom)
                        : cornerRadiusInsets.closed.bottom
                    )
                    .padding([.horizontal, .bottom], vm.notchState == .open ? 12 : 0)
                    .background(notchBackground)
                    .clipShape(currentNotchShape)
                    .overlay {
                        let shouldShowStroke = (notchBackgroundStyle == .glass || notchBackgroundStyle == .gradientGlow || liquidGlassOpacity > 0) && vm.notchState == .open
                        if shouldShowStroke {
                            let strokeOpacity = max(0.2, liquidGlassOpacity)
                            currentNotchShape
                                .stroke(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.white.opacity(0.38 * strokeOpacity), location: 0.0),
                                            .init(color: Color.white.opacity(0.12 * strokeOpacity), location: 0.18),
                                            .init(color: Color.white.opacity(0.04 * strokeOpacity), location: 0.70),
                                            .init(color: Color.white.opacity(0.16 * strokeOpacity), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                                .allowsHitTesting(false)
                        }
                    }
                    .overlay(alignment: .top) {
                        let isNonBlack = (liquidGlassOpacity > 0 || notchBackgroundStyle != .solidDark) && vm.notchState == .open
                        Rectangle()
                            .fill(isNonBlack ? Color.clear : Color.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: ((vm.notchState == .open || isHovering) && Defaults[.enableShadow])
                            ? .black.opacity(0.7) : .clear, radius: Defaults[.cornerRadiusScaling] ? 6 : 4
                    )
                    .padding(
                        .bottom,
                        vm.effectiveClosedNotchHeight == 0 ? 10 : 0
                    )
                
                mainLayout
                    .frame(height: vm.notchState == .open ? vm.notchSize.height : nil)
                    .conditionalModifier(true) { view in
                        let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
                        let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)
                        
                        return view
                            .animation(vm.notchState == .open ? openAnimation : closeAnimation, value: vm.notchState)
                            .animation(.smooth, value: gestureProgress)
                    }
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        handleHover(hovering)
                    }
                    .onTapGesture {
                        doOpen()
                    }
                    .conditionalModifier(Defaults[.enableGestures]) { view in
                        view
                            .panGesture(direction: .down) { translation, phase in
                                handleDownGesture(translation: translation, phase: phase)
                            }
                    }
                    .conditionalModifier(Defaults[.closeGestureEnabled] && Defaults[.enableGestures]) { view in
                        view
                            .panGesture(direction: .up) { translation, phase in
                                handleUpGesture(translation: translation, phase: phase)
                            }
                    }
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(1))
                            if coordinator.firstLaunch {
                                withAnimation(vm.animation) {
                                    doOpen()
                                }
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .sharingDidFinish)) { _ in
                        if vm.notchState == .open && !isHovering && !vm.isBatteryPopoverActive {
                            hoverTask?.cancel()
                            hoverTask = Task {
                                try? await Task.sleep(for: .milliseconds(100))
                                guard !Task.isCancelled else { return }
                                if self.vm.notchState == .open && !self.isHovering && !self.vm.isBatteryPopoverActive && !SharingStateManager.shared.preventNotchClose {
                                    self.vm.close()
                                }
                            }
                        }
                    }
                    .onChange(of: vm.notchState) { _, newState in
                        if newState == .closed && isHovering {
                            withAnimation {
                                isHovering = false
                            }
                        }
                    }
                    .onChange(of: vm.isBatteryPopoverActive) {
                        if !vm.isBatteryPopoverActive && !isHovering && vm.notchState == .open && !SharingStateManager.shared.preventNotchClose {
                            hoverTask?.cancel()
                            hoverTask = Task {
                                try? await Task.sleep(for: .milliseconds(100))
                                guard !Task.isCancelled else { return }
                                if !self.vm.isBatteryPopoverActive && !self.isHovering && self.vm.notchState == .open && !SharingStateManager.shared.preventNotchClose {
                                    self.vm.close()
                                }
                            }
                        }
                    }
                    .sensoryFeedback(.alignment, trigger: haptics)
                    .contextMenu {
                        Button("Settings") {
                            SettingsWindowController.shared.showWindow()
                        }
                        .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
                    }
                if vm.chinHeight > 0 {
                    Rectangle()
                        .fill(Color.black.opacity(0.01))
                        .frame(width: computedChinWidth, height: vm.chinHeight)
                }
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: windowSize.width, maxHeight: windowSize.height, alignment: .top)
        .compositingGroup()
        .scaleEffect(
            x: gestureScale,
            y: gestureScale,
            anchor: .top
        )
        .animation(.smooth, value: gestureProgress)
        .background(dragDetector)
        .environmentObject(vm)
        .onChange(of: vm.anyDropZoneTargeting) { _, isTargeted in
            anyDropDebounceTask?.cancel()

            if isTargeted {
                if vm.notchState == .closed {
                    coordinator.currentView = .shelf
                    doOpen()
                }
                return
            }

            anyDropDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                if vm.dropEvent {
                    vm.dropEvent = false
                    return
                }

                vm.dropEvent = false
                if !SharingStateManager.shared.preventNotchClose {
                    vm.close()
                }
            }
        }
    }

    func doOpen() {
        GameModeManager.shared.evaluateGameModeState()
        if GameModeManager.shared.isGameModeActive && Defaults[.disableHoverInGameMode] {
            return
        }
        withAnimation(animationSpring) {
            vm.open()
        }
    }

    // MARK: - Hover Management

    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        
        GameModeManager.shared.evaluateGameModeState()
        if GameModeManager.shared.isGameModeActive && Defaults[.disableHoverInGameMode] {
            if isHovering {
                isHovering = false
            }
            if vm.notchState == .open && !SharingStateManager.shared.preventNotchClose {
                vm.close()
            }
            return
        }

        if hovering {
            withAnimation(animationSpring) {
                isHovering = true
            }
            
            if vm.notchState == .closed && Defaults[.enableHaptics] {
                haptics.toggle()
            }
            
            guard vm.notchState == .closed,
                  !coordinator.sneakPeek.show,
                  Defaults[.openNotchOnHover] else { return }
            
            hoverTask = Task {
                try? await Task.sleep(for: .seconds(Defaults[.minimumHoverDuration]))
                guard !Task.isCancelled else { return }
                
                GameModeManager.shared.evaluateGameModeState()
                if GameModeManager.shared.isGameModeActive && Defaults[.disableHoverInGameMode] {
                    self.isHovering = false
                    return
                }

                guard self.vm.notchState == .closed,
                      self.isHovering,
                      !self.coordinator.sneakPeek.show else { return }
                
                self.doOpen()
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                
                withAnimation(animationSpring) {
                    self.isHovering = false
                }
                
                if self.vm.notchState == .open && !self.vm.isBatteryPopoverActive && !SharingStateManager.shared.preventNotchClose {
                    self.vm.close()
                }
            }
        }
    }

    // MARK: - Gesture Handling

    private func handleDownGesture(translation: CGFloat, phase: NSEvent.Phase) {
        GameModeManager.shared.evaluateGameModeState()
        if GameModeManager.shared.isGameModeActive && Defaults[.disableHoverInGameMode] {
            return
        }
        guard vm.notchState == .closed else { return }

        if phase == .ended {
            withAnimation(animationSpring) { gestureProgress = .zero }
            return
        }

        withAnimation(animationSpring) {
            gestureProgress = (translation / Defaults[.gestureSensitivity]) * 20
        }

        if translation > Defaults[.gestureSensitivity] {
            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
            withAnimation(animationSpring) {
                gestureProgress = .zero
            }
            doOpen()
        }
    }

    private func handleUpGesture(translation: CGFloat, phase: NSEvent.Phase) {
        guard vm.notchState == .open && !vm.isHoveringCalendar else { return }

        withAnimation(animationSpring) {
            gestureProgress = (translation / Defaults[.gestureSensitivity]) * -20
        }

        if phase == .ended {
            withAnimation(animationSpring) {
                gestureProgress = .zero
            }
        }

        if translation > Defaults[.gestureSensitivity] {
            withAnimation(animationSpring) {
                isHovering = false
            }
            if !SharingStateManager.shared.preventNotchClose { 
                gestureProgress = .zero
                vm.close()
            }

            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
        }
    }
}

#Preview {
    let vm = BoringViewModel()
    vm.open()
    return ContentView()
        .environmentObject(vm)
        .frame(width: vm.notchSize.width, height: vm.notchSize.height)
}
