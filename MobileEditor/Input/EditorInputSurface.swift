import UIKit

final class EditorInputSurface: UIInputView {
    let accessory = EditingAccessoryView()
    let letters = CompactLetterKeyboard()
    private let symbols = SymbolPadView()
    private let body = UIView()
    private var totalHeight: NSLayoutConstraint!

    static let bodyHeight: CGFloat = 120

    init() {
        let height = EditingAccessoryView.compactHeight + Self.bodyHeight
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height), inputViewStyle: .keyboard)
        allowsSelfSizing = true
        autoresizingMask = [.flexibleWidth]
        backgroundColor = .secondarySystemBackground
        isMultipleTouchEnabled = true

        accessory.usesInternalSymbolPad = false
        symbols.isHidden = true

        [accessory, body, letters, symbols].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(accessory)
        addSubview(body)
        body.addSubview(letters)
        body.addSubview(symbols)

        totalHeight = heightAnchor.constraint(equalToConstant: height)
        NSLayoutConstraint.activate([
            totalHeight,
            accessory.topAnchor.constraint(equalTo: topAnchor),
            accessory.leadingAnchor.constraint(equalTo: leadingAnchor),
            accessory.trailingAnchor.constraint(equalTo: trailingAnchor),

            body.topAnchor.constraint(equalTo: accessory.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: leadingAnchor),
            body.trailingAnchor.constraint(equalTo: trailingAnchor),
            body.bottomAnchor.constraint(equalTo: bottomAnchor),
            body.heightAnchor.constraint(equalToConstant: Self.bodyHeight),

            letters.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            letters.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            letters.topAnchor.constraint(equalTo: body.topAnchor),
            letters.bottomAnchor.constraint(equalTo: body.bottomAnchor),

            symbols.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            symbols.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            symbols.topAnchor.constraint(equalTo: body.topAnchor),
            symbols.bottomAnchor.constraint(equalTo: body.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: accessory.intrinsicContentSize.height + Self.bodyHeight
        )
    }

    func connect(textView: UITextView, delegate: EditingAccessoryDelegate) {
        accessory.delegate = delegate
        letters.textView = textView
        symbols.onInsert = { [weak delegate] text in
            delegate?.accessoryInsertText(text)
        }
    }

    func applyMode(_ mode: InputMode) {
        accessory.applyMode(mode)
        let sym = mode == .symbols
        letters.isHidden = sym
        symbols.isHidden = !sym
        let height = accessory.intrinsicContentSize.height + Self.bodyHeight
        if totalHeight.constant != height {
            totalHeight.constant = height
            invalidateIntrinsicContentSize()
        }
    }
}

final class EditorKeyboardController: UIInputViewController {
    let surface = EditorInputSurface()

    override var inputView: UIInputView? {
        get { surface }
        set {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
    }
}

final class SymbolPadView: UIView {
    var onInsert: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let rows: [[String]] = [
            ["!", "@", "#", "$", "%", "^", "&", "*", "|", "~", "?"],
            ["(", ")", "{", "}", "[", "]", "<", ">", "/", "\\"],
            ["=", "+", "-", "_", ".", ",", ":", ";", "`", "'", "\""],
        ]
        var stacks: [UIView] = []
        for symbols in rows {
            let buttons = symbols.map { s -> UIView in
                let button = KeyButton(title: s, mono: true)
                button.onTap = { [weak self] in self?.onInsert?(s) }
                return button
            }
            let row = UIStackView(arrangedSubviews: buttons)
            row.axis = .horizontal
            row.spacing = 3
            row.distribution = .fillEqually
            stacks.append(row)
        }
        let stack = UIStackView(arrangedSubviews: stacks)
        stack.axis = .vertical
        stack.spacing = 3
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
