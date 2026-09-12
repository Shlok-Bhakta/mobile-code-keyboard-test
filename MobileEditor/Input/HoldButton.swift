import UIKit

final class HoldButton: UIControl {
    var onDown: (() -> Void)?
    var onMoved: ((CGPoint) -> Void)?
    var onUp: (() -> Void)?
    var onCancel: (() -> Void)?

    private let icon = UIImageView()
    private let preview = UILabel()
    var activeBackground: UIColor = .systemBlue
    var idleBackground: UIColor = .tertiarySystemFill
    var activeTint: UIColor = .white
    var idleTint: UIColor = .label

    override var isHighlighted: Bool {
        didSet { refresh() }
    }

    var isHeld: Bool = false {
        didSet { refresh() }
    }

    init(systemImage: String, pointSize: CGFloat = 16) {
        super.init(frame: .zero)
        let cfg = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        icon.image = UIImage(systemName: systemImage, withConfiguration: cfg)
        icon.contentMode = .scaleAspectFit
        addSubview(icon)
        preview.font = UIFont.monospacedSystemFont(ofSize: 26, weight: .bold)
        preview.textAlignment = .center
        preview.isHidden = true
        preview.adjustsFontSizeToFitWidth = true
        preview.minimumScaleFactor = 0.4
        addSubview(preview)
        icon.translatesAutoresizingMaskIntoConstraints = false
        preview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -8),
            icon.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -8),
            preview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            preview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            preview.topAnchor.constraint(equalTo: topAnchor),
            preview.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        onMoved?(touch.location(in: self))
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let touch {
            onMoved?(touch.location(in: self))
        }
        isHeld = false
        onUp?()
    }

    override func cancelTracking(with event: UIEvent?) {
        isHeld = false
        setPreviewSymbol(nil)
        onCancel?()
    }

    func setPreviewSymbol(_ symbol: String?) {
        if let symbol, !symbol.isEmpty {
            preview.text = symbol
            preview.isHidden = false
            icon.isHidden = true
        } else {
            preview.text = nil
            preview.isHidden = true
            icon.isHidden = false
        }
        refresh()
    }

    private func refresh() {
        let on = isHeld || isHighlighted
        backgroundColor = on ? activeBackground : idleBackground
        icon.tintColor = on ? activeTint : idleTint
        preview.textColor = on ? activeTint : idleTint
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
        applyFilled()
        setGlyph(title, mono: mono)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        isExclusiveTouch = false
        isMultipleTouchEnabled = true
    }

    init(systemImage: String, pointSize: CGFloat = 14) {
        super.init(frame: .zero)
        applyFilled()
        var config = configuration ?? .filled()
        config.image = UIImage(systemName: systemImage)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        config.title = nil
        configuration = config
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        isExclusiveTouch = false
        isMultipleTouchEnabled = true
    }

    private func applyFilled() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .tertiarySystemFill
        config.baseForegroundColor = .label
        config.cornerStyle = .small
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        configuration = config
    }

    private func setGlyph(_ title: String, mono: Bool) {
        var config = configuration ?? .filled()
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = mono
                ? UIFont.monospacedSystemFont(ofSize: 15, weight: .medium)
                : UIFont.systemFont(ofSize: 13, weight: .semibold)
            return out
        }
        configuration = config
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
