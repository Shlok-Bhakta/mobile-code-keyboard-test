import Foundation

enum EditorLog {
    static func event(_ name: String, _ extra: String = "") {
        if extra.isEmpty {
            print("[Editor] \(name)")
        } else {
            print("[Editor] \(name) \(extra)")
        }
    }
}
