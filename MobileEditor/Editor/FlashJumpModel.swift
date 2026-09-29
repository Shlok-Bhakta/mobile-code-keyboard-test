import Foundation

struct FlashJumpTarget {
    let range: NSRange
    let label: String?
}

enum FlashJumpModel {
    private static let labelOrder = Array("asdfghjklqwertyuiopzxcvbnm")

    static func targets(
        in text: NSString,
        query: String,
        visibleRange: NSRange,
        caretOffset: Int,
        isVisible: ((NSRange) -> Bool)? = nil
    ) -> [FlashJumpTarget] {
        guard !query.isEmpty else { return [] }
        let start = min(max(visibleRange.location, 0), text.length)
        let end = min(max(NSMaxRange(visibleRange), start), text.length)
        guard start < end else { return [] }

        var ranges: [NSRange] = []
        var searchStart = start
        while searchStart < end {
            let found = text.range(
                of: query,
                options: [.caseInsensitive, .literal],
                range: NSRange(location: searchStart, length: end - searchStart)
            )
            guard found.location != NSNotFound else { break }
            if found.location != caretOffset && (isVisible?(found) ?? true) {
                ranges.append(found)
            }
            searchStart = found.location + 1
        }

        var continuations = Set<Character>()
        for range in ranges where NSMaxRange(range) < text.length {
            let unit = text.character(at: NSMaxRange(range))
            if unit < 128, let scalar = UnicodeScalar(Int(unit)) {
                continuations.insert(Character(String(scalar).lowercased()))
            }
        }
        let labels = labelOrder.filter { !continuations.contains($0) }
        ranges.sort {
            let left = abs($0.location - caretOffset)
            let right = abs($1.location - caretOffset)
            return left == right ? $0.location < $1.location : left < right
        }
        return ranges.enumerated().map { index, range in
            FlashJumpTarget(
                range: range,
                label: index < labels.count ? String(labels[index]) : nil
            )
        }
    }

    static func target(for typed: String, among targets: [FlashJumpTarget]) -> FlashJumpTarget? {
        guard typed.count == 1 else { return nil }
        let key = typed.lowercased()
        return targets.first { $0.label == key }
    }

    static func automaticTarget(query: String, targets: [FlashJumpTarget]) -> FlashJumpTarget? {
        query.utf16.count >= 2 && targets.count == 1 ? targets[0] : nil
    }
}
