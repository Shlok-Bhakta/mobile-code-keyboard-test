import UIKit

final class LineNumberGutter: UIView {
    weak var textView: UITextView?
    var onSelectLines: ((_ from: Int, _ to: Int) -> Void)?

    private var dragStartLine: Int?
    private let numberFont = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        isOpaque = true
        isMultipleTouchEnabled = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let tv = textView, let context = UIGraphicsGetCurrentContext() else { return }
        let bg = UIColor.secondarySystemBackground
        bg.setFill()
        context.fill(rect)

        UIColor.separator.setStroke()
        context.setLineWidth(1.0 / UIScreen.main.scale)
        context.move(to: CGPoint(x: bounds.maxX - 0.5, y: 0))
        context.addLine(to: CGPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        context.strokePath()

        let ns = (tv.text ?? "") as NSString
        guard ns.length >= 0 else { return }

        let layout = tv.layoutManager
        let container = tv.textContainer
        layout.ensureLayout(for: container)

        let inset = tv.textContainerInset
        let offsetY = tv.contentOffset.y
        let visible = CGRect(
            x: 0,
            y: offsetY,
            width: tv.bounds.width,
            height: tv.bounds.height
        )
        let glyphRange = layout.glyphRange(forBoundingRect: visible, in: container)

        var lineNumber = 1
        if glyphRange.location > 0 {
            let prefix = ns.substring(to: min(layout.characterIndexForGlyph(at: glyphRange.location), ns.length))
            lineNumber = prefix.reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: UIColor.secondaryLabel,
        ]

        var lastChar = -1
        layout.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, glyphRange, _ in
            let charIndex = layout.characterIndexForGlyph(at: glyphRange.location)
            let isWrapContinuation = charIndex > 0 && ns.character(at: charIndex - 1) != 10 && charIndex == lastChar
            lastChar = charIndex

            if !isWrapContinuation {
                let y = usedRect.minY + inset.top - offsetY + (usedRect.height - self.numberFont.lineHeight) / 2
                if y + self.numberFont.lineHeight > 0 && y < self.bounds.height {
                    let label = "\(lineNumber)" as NSString
                    let size = label.size(withAttributes: attrs)
                    let point = CGPoint(x: self.bounds.width - 8 - size.width, y: y)
                    label.draw(at: point, withAttributes: attrs)
                }
                lineNumber += 1
            }
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let line = lineNumber(at: gesture.location(in: self).y)
        onSelectLines?(line, line)
        EditorLog.event("GUTTER_TAP", "line=\(line)")
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let line = lineNumber(at: gesture.location(in: self).y)
        switch gesture.state {
        case .began:
            dragStartLine = line
            onSelectLines?(line, line)
        case .changed, .ended:
            if let start = dragStartLine {
                onSelectLines?(start, line)
            }
            if gesture.state == .ended {
                EditorLog.event("GUTTER_DRAG", "to=\(line)")
                dragStartLine = nil
            }
        default:
            dragStartLine = nil
        }
    }

    private func lineNumber(at y: CGFloat) -> Int {
        guard let tv = textView else { return 1 }
        let ns = (tv.text ?? "") as NSString
        if ns.length == 0 { return 1 }
        let layout = tv.layoutManager
        let container = tv.textContainer
        let inset = tv.textContainerInset
        let pointInText = CGPoint(
            x: 8,
            y: y + tv.contentOffset.y - inset.top
        )
        var fraction: CGFloat = 0
        let glyph = layout.glyphIndex(for: pointInText, in: container, fractionOfDistanceThroughGlyph: &fraction)
        let charIndex = min(layout.characterIndexForGlyph(at: glyph), max(ns.length - 1, 0))
        let prefix = ns.substring(to: charIndex)
        return prefix.reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
    }
}
