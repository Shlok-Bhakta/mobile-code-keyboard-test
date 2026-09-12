import UIKit

final class NavSelectPad: UIControl {
    var onNavDown: (() -> Void)?
    var onNavUp: (() -> Void)?
    var onSelectChanged: ((Bool) -> Void)?

    private let inner = UIView()
    private let moveIcon = UIImageView()
    private var inSelect = false
    private let corner: CGFloat = 4

    var isNavHeld = false {
        didSet { refresh() }
    }

    var isSelecting = false {
        didSet {
            refresh()
            layoutInner(animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
        isMultipleTouchEnabled = false
        isExclusiveTouch = false

        inner.layer.cornerRadius = 9
        inner.isUserInteractionEnabled = false
        addSubview(inner)

        let cfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        moveIcon.image = UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right", withConfiguration: cfg)
        moveIcon.contentMode = .scaleAspectFit
        moveIcon.isUserInteractionEnabled = false
        addSubview(moveIcon)

        moveIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            moveIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            moveIcon.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            moveIcon.widthAnchor.constraint(equalToConstant: 16),
            moveIcon.heightAnchor.constraint(equalToConstant: 16),
        ])
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutInner(animated: false)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        isNavHeld = true
        onNavDown?()
        updateSelect(at: touch.location(in: self))
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateSelect(at: touch.location(in: self))
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        finish()
    }

    override func cancelTracking(with event: UIEvent?) {
        finish()
    }

    private func finish() {
        if inSelect {
            inSelect = false
            onSelectChanged?(false)
        }
        isNavHeld = false
        isSelecting = false
        onNavUp?()
        refresh()
        layoutInner(animated: true)
    }

    private func updateSelect(at point: CGPoint) {
        let next = hitFrame.contains(point)
        guard next != inSelect else { return }
        inSelect = next
        isSelecting = next
        onSelectChanged?(next)
    }

    private func layoutInner(animated: Bool) {
        let frame = visualSelectFrame
        guard inner.frame != frame else { return }
        if animated {
            UIView.animate(withDuration: 0.12) { self.inner.frame = frame }
        } else {
            inner.frame = frame
        }
    }

    /// Bottom-left corner to enter. Once in, a larger sticky region to stay in.
    private var hitFrame: CGRect {
        inSelect ? stickyHitFrame : idleHitFrame
    }

    private var visualSelectFrame: CGRect {
        inSelect ? activeSelectFrame : idleSelectFrame
    }

    private var idleSelectFrame: CGRect {
        let size = max(34, min(bounds.width, bounds.height) * 0.40)
        return CGRect(
            x: corner,
            y: bounds.height - size - corner,
            width: size,
            height: size
        )
    }

    private var activeSelectFrame: CGRect {
        let size = max(48, min(bounds.width, bounds.height) * 0.56)
        return CGRect(
            x: 3,
            y: bounds.height - size - 3,
            width: size,
            height: size
        )
    }

    private var idleHitFrame: CGRect {
        idleSelectFrame.insetBy(dx: -6, dy: -6)
    }

    private var stickyHitFrame: CGRect {
        activeSelectFrame.insetBy(dx: -12, dy: -12)
    }

    private func refresh() {
        if isSelecting {
            backgroundColor = UIColor.systemOrange.withAlphaComponent(0.5)
            inner.backgroundColor = UIColor.systemOrange
            moveIcon.tintColor = UIColor.black.withAlphaComponent(0.4)
        } else if isNavHeld {
            backgroundColor = UIColor.systemBlue
            inner.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.95)
            moveIcon.tintColor = .white
        } else {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.28)
            inner.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
            moveIcon.tintColor = .systemBlue
        }
    }
}
