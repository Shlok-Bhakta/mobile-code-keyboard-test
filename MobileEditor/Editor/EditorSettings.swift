import Foundation

final class EditorSettings {
    static let shared = EditorSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let horizontalThreshold = "editor.horizontalThreshold"
        static let verticalThreshold = "editor.verticalThreshold"
        static let longPressDelay = "editor.longPressDelay"
        static let hapticsEnabled = "editor.hapticsEnabled"
        static let indentWidth = "editor.indentWidth"
        static let useTabs = "editor.useTabs"
        static let lineWrap = "editor.lineWrap"
        static let navMomentary = "editor.navMomentary"
        static let symMomentary = "editor.symMomentary"
        static let trackpadSelectWithNav = "editor.trackpadSelectWithNav"
        static let accelerationEnabled = "editor.accelerationEnabled"
        static let mediumVelocity = "editor.mediumVelocity"
        static let fastVelocity = "editor.fastVelocity"
        static let fontSize = "editor.fontSize"
    }

    private init() {
        defaults.register(defaults: [
            Key.horizontalThreshold: 12.0,
            Key.verticalThreshold: 24.0,
            Key.longPressDelay: 0.0,
            Key.hapticsEnabled: true,
            Key.indentWidth: 4,
            Key.useTabs: false,
            Key.lineWrap: false,
            Key.navMomentary: true,
            Key.symMomentary: true,
            Key.trackpadSelectWithNav: true,
            Key.accelerationEnabled: true,
            Key.mediumVelocity: 450.0,
            Key.fastVelocity: 900.0,
            Key.fontSize: 15.0,
        ])
    }

    var horizontalThreshold: Double {
        get { stored(Key.horizontalThreshold, fallback: 12) }
        set { defaults.set(newValue, forKey: Key.horizontalThreshold) }
    }

    var verticalThreshold: Double {
        get { stored(Key.verticalThreshold, fallback: 24) }
        set { defaults.set(newValue, forKey: Key.verticalThreshold) }
    }

    var longPressDelay: Double {
        get { stored(Key.longPressDelay, fallback: 0) }
        set { defaults.set(newValue, forKey: Key.longPressDelay) }
    }

    var hapticsEnabled: Bool {
        get { defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.hapticsEnabled) }
    }

    var indentWidth: Int {
        get { Int(stored(Key.indentWidth, fallback: 4)) }
        set { defaults.set(newValue, forKey: Key.indentWidth) }
    }

    var useTabs: Bool {
        get { defaults.bool(forKey: Key.useTabs) }
        set { defaults.set(newValue, forKey: Key.useTabs) }
    }

    var lineWrap: Bool {
        get { defaults.bool(forKey: Key.lineWrap) }
        set { defaults.set(newValue, forKey: Key.lineWrap) }
    }

    var navMomentary: Bool {
        get { defaults.object(forKey: Key.navMomentary) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.navMomentary) }
    }

    var symMomentary: Bool {
        get { defaults.object(forKey: Key.symMomentary) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.symMomentary) }
    }

    var trackpadSelectWithNav: Bool {
        get { defaults.object(forKey: Key.trackpadSelectWithNav) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.trackpadSelectWithNav) }
    }

    var accelerationEnabled: Bool {
        get { defaults.object(forKey: Key.accelerationEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.accelerationEnabled) }
    }

    var mediumVelocity: Double {
        get { stored(Key.mediumVelocity, fallback: 450) }
        set { defaults.set(newValue, forKey: Key.mediumVelocity) }
    }

    var fastVelocity: Double {
        get { stored(Key.fastVelocity, fallback: 900) }
        set { defaults.set(newValue, forKey: Key.fastVelocity) }
    }

    var fontSize: Double {
        get { stored(Key.fontSize, fallback: 15) }
        set { defaults.set(newValue, forKey: Key.fontSize) }
    }

    var indentString: String {
        useTabs ? "\t" : String(repeating: " ", count: max(1, indentWidth))
    }

    private func stored(_ key: String, fallback: Double) -> Double {
        let value = defaults.double(forKey: key)
        return value == 0 && defaults.object(forKey: key) == nil ? fallback : value
    }
}
