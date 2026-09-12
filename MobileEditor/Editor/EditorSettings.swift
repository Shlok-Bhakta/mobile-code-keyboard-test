import Foundation

final class EditorSettings {
    static let shared = EditorSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let longPressDelay = "editor.longPressDelay"
        static let hapticsEnabled = "editor.hapticsEnabled"
        static let indentWidth = "editor.indentWidth"
        static let useTabs = "editor.useTabs"
        static let lineWrap = "editor.lineWrap"
        static let navMomentary = "editor.navMomentary"
        static let symMomentary = "editor.symMomentary"
        static let fontSize = "editor.fontSize"
    }

    private init() {
        defaults.register(defaults: [
            Key.longPressDelay: 0.0,
            Key.hapticsEnabled: true,
            Key.indentWidth: 4,
            Key.useTabs: false,
            Key.lineWrap: false,
            Key.navMomentary: true,
            Key.symMomentary: true,
            Key.fontSize: 15.0,
        ])
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
