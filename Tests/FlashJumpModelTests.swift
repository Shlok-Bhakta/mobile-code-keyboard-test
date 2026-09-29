import Foundation

@main
struct FlashJumpModelTests {
    static func main() {
        let unicode = FlashJumpModel.targets(
            in: "😀 alpha ALPHA",
            query: "al",
            visibleRange: NSRange(location: 0, length: 14),
            caretOffset: 0
        )
        assert(unicode.map(\.range.location) == [3, 9], "case-insensitive UTF-16 offsets")

        let visible = FlashJumpModel.targets(
            in: "one one one",
            query: "one",
            visibleRange: NSRange(location: 4, length: 7),
            caretOffset: 0
        )
        assert(visible.map(\.range.location) == [4, 8], "only visible matches")

        let horizontallyVisible = FlashJumpModel.targets(
            in: "one one one",
            query: "one",
            visibleRange: NSRange(location: 0, length: 11),
            caretOffset: 11,
            isVisible: { $0.location < 5 }
        )
        assert(horizontallyVisible.map(\.range.location) == [4, 0], "skip matches outside the viewport")

        let overlaps = FlashJumpModel.targets(
            in: "aaaa",
            query: "aa",
            visibleRange: NSRange(location: 0, length: 4),
            caretOffset: 4
        )
        assert(overlaps.map(\.range.location) == [2, 1, 0], "overlapping matches ordered by caret distance")

        let labeled = FlashJumpModel.targets(
            in: "cat cap car",
            query: "ca",
            visibleRange: NSRange(location: 0, length: 11),
            caretOffset: 11
        )
        assert(labeled.count == 3)
        assert(labeled.allSatisfy { !["t", "p", "r"].contains($0.label ?? "") }, "labels cannot extend a match")
        assert(FlashJumpModel.target(for: labeled[0].label ?? "", among: labeled)?.range.location == 8)
        assert(FlashJumpModel.automaticTarget(query: "ca", targets: labeled) == nil)
        assert(FlashJumpModel.automaticTarget(query: "x", targets: [labeled[0]]) == nil)
        assert(FlashJumpModel.automaticTarget(query: "xy", targets: [labeled[0]])?.range.location == 8)
        print("FlashJumpModelTests passed")
    }
}
