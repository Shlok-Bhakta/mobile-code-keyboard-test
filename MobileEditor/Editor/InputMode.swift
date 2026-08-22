import Foundation

enum InputMode: Equatable {
    case normal
    case navigation
    case navigationSelecting
    case symbols

    var title: String {
        switch self {
        case .normal: return "TYPE"
        case .navigation: return "NAV"
        case .navigationSelecting: return "NAV  SELECT"
        case .symbols: return "SYM"
        }
    }

    var isNavigating: Bool {
        self == .navigation || self == .navigationSelecting
    }

    var isSelecting: Bool {
        self == .navigationSelecting
    }
}
