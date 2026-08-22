import UIKit

final class CursorTrackpadView: UIView {
    var onBegan: (() -> Void)?
    var onChanged: ((_ dx: CGFloat, _ dy: CGFloat, _ velocity: CGPoint) -> Void)?
    var onEnded: (() -> Void)?

    private let caption = UILabel()
    private var lastPoint: CGPoint = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.tertiarySystemFill
        layer.cornerRadius = 10
        clipsToBounds = true
        isMultipleTouchEnabled = false

        caption.text = "CURSOR"
        caption.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        caption.textColor = .secondaryLabel
        caption.textAlignment = .center
        caption.isUserInteractionEnabled = false
        addSubview(caption)
        caption.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            caption.centerXAnchor.constraint(equalTo: centerXAnchor),
            caption.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastPoint = gesture.location(in: self)
            backgroundColor = UIColor.secondarySystemFill
            onBegan?()
        case .changed:
            let point = gesture.location(in: self)
            let dx = point.x - lastPoint.x
            let dy = point.y - lastPoint.y
            lastPoint = point
            onChanged?(dx, dy, gesture.velocity(in: self))
        default:
            backgroundColor = UIColor.tertiarySystemFill
            onEnded?()
        }
    }
}
