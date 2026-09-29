import UIKit

final class FlashJumpTextField: UITextField {
    var onEscape: (() -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        (super.keyCommands ?? []) + [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapePressed))
        ]
    }

    @objc private func escapePressed() {
        onEscape?()
    }
}

final class FlashJumpOverlay: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ targets: [FlashJumpTarget], in textView: UITextView) {
        subviews.forEach { $0.removeFromSuperview() }
        for target in targets {
            guard let start = textView.position(from: textView.beginningOfDocument, offset: target.range.location),
                  let end = textView.position(from: start, offset: target.range.length),
                  let range = textView.textRange(from: start, to: end)
            else { continue }
            let rect = textView.firstRect(for: range)
            guard rect.intersects(bounds), rect.width > 0, rect.height > 0 else { continue }

            let highlight = UIView(frame: rect.insetBy(dx: -1, dy: 0))
            highlight.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.28)
            highlight.layer.cornerRadius = 3
            addSubview(highlight)

            if let label = target.label {
                let width = min(max(rect.width, 9), 14)
                let badge = UILabel(frame: CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
                badge.text = label
                badge.textAlignment = .center
                badge.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
                badge.textColor = .black
                badge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.92)
                badge.layer.cornerRadius = 2
                badge.clipsToBounds = true
                badge.accessibilityIdentifier = "flashTarget-\(label)"
                addSubview(badge)
            }
        }
    }

    func clear() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}
