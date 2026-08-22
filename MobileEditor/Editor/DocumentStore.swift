import Foundation

enum DocumentStore {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("scratch.txt")
    }

    static func load() -> String? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    static func save(_ text: String) {
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
