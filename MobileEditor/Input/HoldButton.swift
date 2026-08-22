import UIKit

final class HoldButton: UIControl {
    var onDown: (() -> Void)?
    var onUp: (() -> Void)?

    private let label = UILabel()
    var title: String {
        get { label.text ?? "" }
        set { label.text = newValue }
    }

    var activeBackground: UIColor = .systemBlue
    var idleBackground: UIColor = .tertiarySystemFill
    var activeTitleColor: UIColor = .white
    var idleTitleColor: UIColor = .label

    override var isHighlighted: Bool {
        didSet { refresh() }
    }

    var isHeld: Bool = false {
        didSet { refresh() }
    }

    init(title: String, font: UIFont = UIFont.systemFont(ofSize: 15, weight: .semibold)) {
        super.init(frame: .zero)
        label.text = title
        label.font = font
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.numberOfLines = 2
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
        layer.cornerRadius = 8
        clipsToBounds = true
        isMultipleTouchEnabled = true
        isExclusiveTouch = false
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        isHeld = true
        onDown?()
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isHeld = false
        onUp?()
    }

    override func cancelTracking(with event: UIEvent?) {
        isHeld = false
        onUp?()
    }

    private func refresh() {
        let on = isHeld || isHighlighted
        backgroundColor = on ? activeBackground : idleBackground
        label.textColor = on ? activeTitleColor : idleTitleColor
    }
}

final class KeyButton: UIButton {
    var onTap: (() -> Void)?
    var onSwipeLeft: (() -> Void)?
    var onLongPress: (() -> Void)?

    private var swiped = false
    private var longTimer: Timer?
    private var swipeEnabled = false
    private var startPoint: CGPoint?

    init(title: String, mono: Bool = false) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .tertiarySystemFill
        config.baseForegroundColor = .label
        config.cornerStyle = .small
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = mono
                ? UIFont.monospacedSystemFont(ofSize: 16, weight: .medium)
                : UIFont.systemFont(ofSize: 14, weight: .semibold)
            return out
        }
        configuration = config
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        isExclusiveTouch = false
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        if swiped { return }
        onTap?()
    }

    func enableSwipeAndLongPress() {
        swipeEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        swiped = false
        startPoint = touches.first?.location(in: self)
        guard swipeEnabled else { return }
        longTimer?.invalidate()
        longTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            guard let self, !self.swiped else { return }
            self.onLongPress?()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard swipeEnabled, let touch = touches.first, let start = startPoint else { return }
        let x = touch.location(in: self).x - start.x
        if x < -22, !swiped {
            swiped = true
            longTimer?.invalidate()
            onSwipeLeft?()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        longTimer?.invalidate()
        longTimer = nil
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        longTimer?.invalidate()
        longTimer = nil
        super.touchesCancelled(touches, with: event)
    }
}
