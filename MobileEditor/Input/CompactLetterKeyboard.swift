import UIKit

final class CompactLetterKeyboard: UIView {
    weak var textView: UITextView?

    private var shifted = false
    private var capsLock = false
    private var letterButtons: [UIButton] = []
    private var shiftButton: UIButton?
    private var deleteTimer: Timer?

    static let preferredHeight: CGFloat = 132

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: Self.preferredHeight))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.preferredHeight)
    }

    private func commonInit() {
        autoresizingMask = [.flexibleWidth]
        backgroundColor = .secondarySystemBackground
        build()
    }

    private func build() {
        let rows = [
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ]
        var stacks: [UIView] = []
        for keys in rows {
            stacks.append(letterRow(keys))
        }
        stacks.append(letterRow(["z", "x", "c", "v", "b", "n", "m"]))
        stacks.append(spaceRow())

        let stack = UIStackView(arrangedSubviews: stacks)
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
        refreshShift()
    }

    private func letterRow(_ keys: [String]) -> UIStackView {
        let buttons = keys.map { key -> UIButton in
            let button = glyph(key)
            button.addAction(UIAction { [weak self] _ in self?.type(key) }, for: .touchUpInside)
            letterButtons.append(button)
            return button
        }
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = 3
        stack.distribution = .fillEqually
        return stack
    }

    private func spaceRow() -> UIStackView {
        let shift = iconKey("shift")
        shiftButton = shift
        shift.addAction(UIAction { [weak self] _ in self?.toggleShift() }, for: .touchUpInside)
        let shift2 = UITapGestureRecognizer(target: self, action: #selector(shiftDouble))
        shift2.numberOfTapsRequired = 2
        shift.addGestureRecognizer(shift2)

        let space = iconKey("space")
        space.addAction(UIAction { [weak self] _ in self?.textView?.insertText(" ") }, for: .touchUpInside)

        let del = iconKey("delete.left")
        del.addTarget(self, action: #selector(deleteDown), for: .touchDown)
        del.addTarget(self, action: #selector(deleteUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        let ret = iconKey("return")
        ret.addAction(UIAction { [weak self] _ in self?.textView?.insertText("\n") }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [shift, space, del, ret])
        stack.axis = .horizontal
        stack.spacing = 3
        stack.distribution = .fill
        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        for key in [shift, del, ret] {
            key.setContentHuggingPriority(.required, for: .horizontal)
            key.widthAnchor.constraint(equalToConstant: 46).isActive = true
        }
        return stack
    }

    private func glyph(_ title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .tertiarySystemFill
        config.baseForegroundColor = .label
        config.cornerStyle = .small
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return out
        }
        let button = UIButton(configuration: config)
        button.isExclusiveTouch = false
        return button
    }

    private func iconKey(_ system: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemFill
        config.baseForegroundColor = .label
        config.cornerStyle = .small
        config.image = UIImage(systemName: system)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let button = UIButton(configuration: config)
        button.isExclusiveTouch = false
        return button
    }

    private func type(_ key: String) {
        let ch = (shifted || capsLock) ? key.uppercased() : key
        textView?.insertText(ch)
        if shifted && !capsLock {
            shifted = false
            refreshShift()
        }
    }

    private func toggleShift() {
        if capsLock {
            capsLock = false
            shifted = false
        } else {
            shifted.toggle()
        }
        refreshShift()
    }

    @objc private func shiftDouble() {
        capsLock = true
        shifted = true
        refreshShift()
    }

    @objc private func deleteDown() {
        textView?.deleteBackward()
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.38, repeats: false) { [weak self] _ in
            self?.textView?.deleteBackward()
            self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
                self?.textView?.deleteBackward()
            }
        }
    }

    @objc private func deleteUp() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    private func refreshShift() {
        for button in letterButtons {
            guard var config = button.configuration, let title = config.title?.lowercased() else { continue }
            config.title = (shifted || capsLock) ? title.uppercased() : title
            button.configuration = config
        }
        if var config = shiftButton?.configuration {
            config.baseBackgroundColor = (shifted || capsLock) ? .systemBlue : .systemFill
            config.baseForegroundColor = (shifted || capsLock) ? .white : .label
            config.image = UIImage(systemName: capsLock ? "capslock.fill" : (shifted ? "shift.fill" : "shift"))
            shiftButton?.configuration = config
        }
    }
}
