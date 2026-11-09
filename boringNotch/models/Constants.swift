//
//  Constants.swift
//  boringNotch
//
//  Created by Richard Kunkli on 2024. 10. 17..
//

import SwiftUI
import Defaults

private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)
let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    ?? FileManager.default.temporaryDirectory
let bundleIdentifier = Bundle.main.bundleIdentifier ?? "theboringteam.boringnotch"
let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

let temporaryDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    ?? FileManager.default.temporaryDirectory
let spacing: CGFloat = 16

struct CustomVisualizer: Codable, Hashable, Equatable, Defaults.Serializable {
    let UUID: UUID
    var name: String
    var url: URL
    var speed: CGFloat = 1.0
}

enum CalendarSelectionState: Codable, Defaults.Serializable {
    case all
    case selected(Set<String>)
}

enum HideNotchOption: String, Defaults.Serializable {
    case always
    case nowPlayingOnly
    case never
}

// Define notification names at file scope
extension Notification.Name {
    static let mediaControllerChanged = Notification.Name("mediaControllerChanged")
}

// Media controller types for selection in settings
enum MediaControllerType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case nowPlaying = "Now Playing"
    case yandexMusic = "Yandex Music"
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case youtubeMusic = "YouTube Music"
    
    var id: String { self.rawValue }
}

// Sneak peek styles for selection in settings
enum SneakPeekStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
    case standard = "Default"
    case inline = "Inline"
    
    var id: String { self.rawValue }
}

// Action to perform when Option (⌥) is held while pressing media keys
enum OptionKeyAction: String, CaseIterable, Identifiable, Defaults.Serializable {
    case openSettings = "Open System Settings"
    case showHUD = "Show HUD"
    case none = "No Action"

    var id: String { self.rawValue }
}

// Font style options for Date & Time display
enum DateTimeFontStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
    case rounded = "Rounded"
    case system = "System"
    case monospaced = "Digital / Monospaced"
    case serif = "Serif"
    case heavy = "Heavy Display"
    case compact = "Compact"

    var id: String { rawValue }
}

// Layout / shape options for Date & Time display
enum DateTimeLayoutStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
    case stacked = "Stacked (Large Clock)"
    case horizontal = "Horizontal (One Line)"
    case capsule = "Capsule Badge"
    case digitalWidget = "Digital Card"
    case minimalist = "Minimalist"

    var id: String { rawValue }
}

// Background fill options for the entire Notch
enum NotchBackgroundStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
    case glass = "Liquid Glass"
    case solidDark = "Dark Surface"
    case gradientGlow = "Gradient Glow"
    case accent = "Accent Tint"
    case transparent = "Ultra Transparent"

    var id: String { rawValue }
}

// Color fill options for Date & Time clock display
enum DateTimeColorStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
    // Custom Solid Palette
    case palette = "Custom Color Palette"

    // Two-Tone / Multi-Color Gradients (Apple Style)
    case sunsetGlow = "Sunset Glow"
    case oceanBreeze = "Ocean Breeze"
    case lavenderDusk = "Lavender Dusk"
    case neonCyber = "Neon Cyber"
    case crimsonFire = "Crimson Fire"
    case aurora = "Cosmic Aurora"

    // Solid Presets
    case white = "Classic White"
    case accent = "System Accent"
    case cyan = "Neon Cyan"
    case orange = "Sunset Orange"
    case purple = "Electric Purple"
    case green = "Emerald Green"
    case gold = "Golden Amber"
    case rose = "Pastel Rose"

    var id: String { rawValue }
}

// Font weight (thickness) options for Date & Time clock display
enum DateTimeFontWeight: String, CaseIterable, Identifiable, Defaults.Serializable {
    case ultraLight = "Ultra Light"
    case thin = "Thin"
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"
    case heavy = "Heavy"
    case black = "Black"

    var id: String { rawValue }

    var fontWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

extension Defaults.Keys {
    // MARK: General
    static let menubarIcon = Key<Bool>("menubarIcon", default: true)
    static let showOnAllDisplays = Key<Bool>("showOnAllDisplays", default: false)
    static let automaticallySwitchDisplay = Key<Bool>("automaticallySwitchDisplay", default: true)
    static let releaseName = Key<String>("releaseName", default: "Flying Rabbit 🐇🪽")
    
    // MARK: Behavior
    static let minimumHoverDuration = Key<TimeInterval>("minimumHoverDuration", default: 0.3)
    static let enableHaptics = Key<Bool>("enableHaptics", default: true)
    static let openNotchOnHover = Key<Bool>("openNotchOnHover", default: true)
    static let extendHoverArea = Key<Bool>("extendHoverArea", default: false)
    static let notchHeightMode = Key<WindowHeightMode>(
        "notchHeightMode",
        default: WindowHeightMode.matchRealNotchSize
    )
    static let nonNotchHeightMode = Key<WindowHeightMode>(
        "nonNotchHeightMode",
        default: WindowHeightMode.matchMenuBar
    )
    static let nonNotchHeight = Key<CGFloat>("nonNotchHeight", default: 32)
    static let notchHeight = Key<CGFloat>("notchHeight", default: 32)
    static let openNotchWidth = Key<CGFloat>("openNotchWidth", default: 640)
    static let nonNotchWidth = Key<CGFloat>("nonNotchWidth", default: 185)

    // MARK: Game Mode
    static let disableHoverInGameMode = Key<Bool>("disableHoverInGameMode", default: true)
    static let minimizeActivityInGameMode = Key<Bool>("minimizeActivityInGameMode", default: true)

    // MARK: Energy & Performance
    static let energySaverMode = Key<Bool>("energySaverMode", default: false)
    static let reduceLoadOnBattery = Key<Bool>("reduceLoadOnBattery", default: true)
    //static let openLastTabByDefault = Key<Bool>("openLastTabByDefault", default: false)
    static let showOnLockScreen = Key<Bool>("showOnLockScreen", default: true)
    static let didMigrateLockScreenDefaultV1 = Key<Bool>("didMigrateLockScreenDefault_v1", default: false)
    static let hideFromScreenRecording = Key<Bool>("hideFromScreenRecording", default: false)
    
    // MARK: Appearance
    static let showEmojis = Key<Bool>("showEmojis", default: false)
    //static let alwaysShowTabs = Key<Bool>("alwaysShowTabs", default: true)
    static let showMirror = Key<Bool>("showMirror", default: false)
    static let mirrorShape = Key<MirrorShapeEnum>("mirrorShape", default: MirrorShapeEnum.rectangle)
    static let settingsIconInNotch = Key<Bool>("settingsIconInNotch", default: true)
    static let lightingEffect = Key<Bool>("lightingEffect", default: true)
    static let enableShadow = Key<Bool>("enableShadow", default: true)
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    static let notchBackgroundStyle = Key<NotchBackgroundStyle>("notchBackgroundStyle", default: .glass)
    static let liquidGlassOpacity = Key<Double>("liquidGlassOpacity", default: 0.0)
    static let notchCornerRadius = Key<CGFloat>("notchCornerRadius", default: 24.0)
    static let continuousCorners = Key<Bool>("continuousCorners", default: true)

    // MARK: Date & Time Display
    static let showDateTimeWhenIdle = Key<Bool>("showDateTimeWhenIdle", default: true)
    static let idleClockTimeout = Key<Double>("idleClockTimeout", default: 60.0)
    static let dateTimeFontStyle = Key<DateTimeFontStyle>("dateTimeFontStyle", default: .rounded)
    static let dateTimeFontWeight = Key<DateTimeFontWeight>("dateTimeFontWeight", default: .bold)
    static let dateTimeLayoutStyle = Key<DateTimeLayoutStyle>("dateTimeLayoutStyle", default: .stacked)
    static let dateTimeColorStyle = Key<DateTimeColorStyle>("dateTimeColorStyle", default: .sunsetGlow)
    static let dateTimeCustomColorHex = Key<String>("dateTimeCustomColorHex", default: "#00E5FF")
    static let dateTimeClockScale = Key<Double>("dateTimeClockScale", default: 1.0)
    static let dateTimeTextOpacity = Key<Double>("dateTimeTextOpacity", default: 1.0)
    static let dateTimeShowSeconds = Key<Bool>("dateTimeShowSeconds", default: false)
    static let dateTime24Hour = Key<Bool>("dateTime24Hour", default: true)
    static let dateTimeShowDayOfWeek = Key<Bool>("dateTimeShowDayOfWeek", default: true)

    static let showNotHumanFace = Key<Bool>("showNotHumanFace", default: false)
    static let tileShowLabels = Key<Bool>("tileShowLabels", default: false)
    static let showCalendar = Key<Bool>("showCalendar", default: false)
    static let hideCompletedReminders = Key<Bool>("hideCompletedReminders", default: true)
    static let sliderColor = Key<SliderColorEnum>(
        "sliderUseAlbumArtColor",
        default: SliderColorEnum.white
    )
    static let playerColorTinting = Key<Bool>("playerColorTinting", default: true)
    static let useMusicVisualizer = Key<Bool>("useMusicVisualizer", default: true)
    static let customVisualizers = Key<[CustomVisualizer]>("customVisualizers", default: [])
    static let selectedVisualizer = Key<CustomVisualizer?>("selectedVisualizer", default: nil)
    
    // MARK: Gestures
    static let enableGestures = Key<Bool>("enableGestures", default: true)
    static let closeGestureEnabled = Key<Bool>("closeGestureEnabled", default: true)
    static let gestureSensitivity = Key<CGFloat>("gestureSensitivity", default: 200.0)
    
    // MARK: Media playback
    static let coloredSpectrogram = Key<Bool>("coloredSpectrogram", default: true)
    static let enableSneakPeek = Key<Bool>("enableSneakPeek", default: true)
    static let sneakPeekStyles = Key<SneakPeekStyle>("sneakPeekStyles", default: .standard)
    static let waitInterval = Key<Double>("waitInterval", default: 3)
    static let showShuffleAndRepeat = Key<Bool>("showShuffleAndRepeat", default: false)
    static let enableLyrics = Key<Bool>("enableLyrics", default: false)
    static let musicControlSlots = Key<[MusicControlButton]>(
        "musicControlSlots",
        default: MusicControlButton.defaultLayout
    )
    static let musicControlSlotLimit = Key<Int>(
        "musicControlSlotLimit",
        default: MusicControlButton.defaultLayout.count
    )
    
    // MARK: Battery
    static let showPowerStatusNotifications = Key<Bool>("showPowerStatusNotifications", default: true)
    static let showBatteryIndicator = Key<Bool>("showBatteryIndicator", default: true)
    static let showBatteryPercentage = Key<Bool>("showBatteryPercentage", default: true)
    static let showPowerStatusIcons = Key<Bool>("showPowerStatusIcons", default: true)
    
    // MARK: Downloads
    static let enableDownloadListener = Key<Bool>("enableDownloadListener", default: true)
    static let enableSafariDownloads = Key<Bool>("enableSafariDownloads", default: true)
    static let selectedDownloadIndicatorStyle = Key<DownloadIndicatorStyle>("selectedDownloadIndicatorStyle", default: DownloadIndicatorStyle.progress)
    static let selectedDownloadIconStyle = Key<DownloadIconStyle>("selectedDownloadIconStyle", default: DownloadIconStyle.onlyAppIcon)
    
    // MARK: HUD
    static let hudReplacement = Key<Bool>("hudReplacement", default: true)
    static let inlineHUD = Key<Bool>("inlineHUD", default: false)
    static let enableGradient = Key<Bool>("enableGradient", default: false)
    static let systemEventIndicatorShadow = Key<Bool>("systemEventIndicatorShadow", default: false)
    static let systemEventIndicatorUseAccent = Key<Bool>("systemEventIndicatorUseAccent", default: false)
    // Option key modifier behaviour for media keys
    static let optionKeyAction = Key<OptionKeyAction>("optionKeyAction", default: OptionKeyAction.openSettings)
    
    // MARK: Shelf
    static let boringShelf = Key<Bool>("boringShelf", default: true)
    static let openShelfByDefault = Key<Bool>("openShelfByDefault", default: true)
    static let shelfTapToOpen = Key<Bool>("shelfTapToOpen", default: true)
    static let quickShareProvider = Key<String>("quickShareProvider", default: QuickShareProvider.defaultProvider.id)
    static let copyOnDrag = Key<Bool>("copyOnDrag", default: false)
    static let autoRemoveShelfItems = Key<Bool>("autoRemoveShelfItems", default: false)
    static let expandedDragDetection = Key<Bool>("expandedDragDetection", default: true)
    
    // MARK: Calendar
    static let calendarSelectionState = Key<CalendarSelectionState>("calendarSelectionState", default: .all)
    static let hideAllDayEvents = Key<Bool>("hideAllDayEvents", default: false)
    static let showFullEventTitles = Key<Bool>("showFullEventTitles", default: false)
    static let autoScrollToNextEvent = Key<Bool>("autoScrollToNextEvent", default: true)
    
    // MARK: Fullscreen Media Detection
    static let hideNotchOption = Key<HideNotchOption>("hideNotchOption", default: .nowPlayingOnly)
    
    // MARK: Media Controller
    static let mediaController = Key<MediaControllerType>("mediaController", default: defaultMediaController)
    
    // MARK: Advanced Settings
    static let useCustomAccentColor = Key<Bool>("useCustomAccentColor", default: false)
    static let customAccentColorData = Key<Data?>("customAccentColorData", default: nil)
    // Show or hide the title bar
    static let hideTitleBar = Key<Bool>("hideTitleBar", default: true)
    
    // Helper to determine the default media controller based on NowPlaying deprecation status
    static var defaultMediaController: MediaControllerType {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                MusicManager.shared.isNowPlayingDeprecated ? .appleMusic : .yandexMusic
            }
        }
        return .yandexMusic
    }

    static let didClearLegacyURLCacheV1 = Key<Bool>("didClearLegacyURLCache_v1", default: false)
}
