import UIKit

protocol EditingAccessoryDelegate: AnyObject {
    var inputMode: InputMode { get }
    var isTrackpadSelecting: Bool { get }
    func accessoryNavDown()
    func accessoryNavUp()
    func accessorySelectDown()
    func accessorySelectUp()
    func accessorySymDown()
    func accessorySymUp()
    func accessoryIndent()
    func accessoryOutdent()
    func accessoryInsertPair(open: String, close: String)
    func accessoryInsertText(_ text: String)
    func accessoryUndo()
    func accessoryRedo()
    func accessoryCopy()
    func accessoryCut()
    func accessoryPaste()
    func accessoryMoveLeft(extending: Bool)
    func accessoryMoveRight(extending: Bool)
    func accessoryMoveUp(extending: Bool)
    func accessoryMoveDown(extending: Bool)
    func accessoryMoveWordLeft(extending: Bool)
    func accessoryMoveWordRight(extending: Bool)
    func accessoryHome(extending: Bool)
    func accessoryEnd(extending: Bool)
    func accessoryPageUp(extending: Bool)
    func accessoryPageDown(extending: Bool)
    func accessoryExpandSelection()
    func accessoryTrackpadBegan()
    func accessoryTrackpadChanged(dx: CGFloat, dy: CGFloat, velocity: CGPoint)
    func accessoryTrackpadEnded()
}

final class EditingAccessoryView: UIView {
    weak var delegate: EditingAccessoryDelegate?

    private let modeStrip = UILabel()
    private let navButton = HoldButton(title: "NAV", font: UIFont.systemFont(ofSize: 16, weight: .bold))
    private let symButton = HoldButton(title: "SYM", font: UIFont.systemFont(ofSize: 16, weight: .bold))
    private let selectButton = HoldButton(title: "SELECT", font: UIFont.systemFont(ofSize: 14, weight: .bold))
    private let normalPanel = UIView()
    private let navPanel = UIView()
    private let symPanel = UIView()
    private let centerHost = UIView()
    private let trackpad = CursorTrackpadView()

    static let preferredHeight: CGFloat = 176

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.preferredHeight)
    }

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: Self.preferredHeight))
        autoresizingMask = [.flexibleWidth]
        isMultipleTouchEnabled = true
        backgroundColor = .secondarySystemBackground

        let box = UILayoutGuide()
        addLayoutGuide(box)

        modeStrip.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        modeStrip.textAlignment = .center
        modeStrip.text = "TYPE"
        modeStrip.textColor = .secondaryLabel

        navButton.activeBackground = .systemBlue
        navButton.idleBackground = UIColor.systemBlue.withAlphaComponent(0.22)
        navButton.onDown = { [weak self] in self?.delegate?.accessoryNavDown() }
        navButton.onUp = { [weak self] in self?.delegate?.accessoryNavUp() }

        symButton.activeBackground = .systemPurple
        symButton.idleBackground = UIColor.systemPurple.withAlphaComponent(0.22)
        symButton.onDown = { [weak self] in self?.delegate?.accessorySymDown() }
        symButton.onUp = { [weak self] in self?.delegate?.accessorySymUp() }

        selectButton.activeBackground = .systemOrange
        selectButton.idleBackground = UIColor.systemOrange.withAlphaComponent(0.28)
        selectButton.activeTitleColor = .black
        selectButton.onDown = { [weak self] in self?.delegate?.accessorySelectDown() }
        selectButton.onUp = { [weak self] in self?.delegate?.accessorySelectUp() }

        buildNormalPanel()
        buildNavPanel()
        buildSymPanel()

        trackpad.onBegan = { [weak self] in self?.delegate?.accessoryTrackpadBegan() }
        trackpad.onChanged = { [weak self] dx, dy, vel in
            self?.delegate?.accessoryTrackpadChanged(dx: dx, dy: dy, velocity: vel)
        }
        trackpad.onEnded = { [weak self] in self?.delegate?.accessoryTrackpadEnded() }

        let views = [modeStrip, navButton, centerHost, symButton, selectButton, trackpad, normalPanel, navPanel, symPanel]
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            if view === normalPanel || view === navPanel || view === symPanel {
                centerHost.addSubview(view)
            } else {
                addSubview(view)
            }
        }

        let height = heightAnchor.constraint(equalToConstant: Self.preferredHeight)
        height.priority = .required

        NSLayoutConstraint.activate([
            height,
            modeStrip.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            modeStrip.leadingAnchor.constraint(equalTo: leadingAnchor),
            modeStrip.trailingAnchor.constraint(equalTo: trailingAnchor),
            modeStrip.heightAnchor.constraint(equalToConstant: 16),

            navButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            navButton.topAnchor.constraint(equalTo: modeStrip.bottomAnchor, constant: 4),
            navButton.bottomAnchor.constraint(equalTo: trackpad.topAnchor, constant: -6),
            navButton.widthAnchor.constraint(equalToConstant: 58),

            symButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            symButton.topAnchor.constraint(equalTo: navButton.topAnchor),
            symButton.bottomAnchor.constraint(equalTo: navButton.bottomAnchor),
            symButton.widthAnchor.constraint(equalToConstant: 58),

            selectButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            selectButton.topAnchor.constraint(equalTo: navButton.topAnchor),
            selectButton.bottomAnchor.constraint(equalTo: navButton.bottomAnchor),
            selectButton.widthAnchor.constraint(equalToConstant: 70),

            centerHost.leadingAnchor.constraint(equalTo: navButton.trailingAnchor, constant: 6),
            centerHost.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -76),
            centerHost.topAnchor.constraint(equalTo: navButton.topAnchor),
            centerHost.bottomAnchor.constraint(equalTo: navButton.bottomAnchor),

            trackpad.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            trackpad.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            trackpad.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            trackpad.heightAnchor.constraint(equalToConstant: 50),

            normalPanel.leadingAnchor.constraint(equalTo: centerHost.leadingAnchor),
            normalPanel.trailingAnchor.constraint(equalTo: centerHost.trailingAnchor),
            normalPanel.topAnchor.constraint(equalTo: centerHost.topAnchor),
            normalPanel.bottomAnchor.constraint(equalTo: centerHost.bottomAnchor),

            navPanel.leadingAnchor.constraint(equalTo: centerHost.leadingAnchor),
            navPanel.trailingAnchor.constraint(equalTo: centerHost.trailingAnchor),
            navPanel.topAnchor.constraint(equalTo: centerHost.topAnchor),
            navPanel.bottomAnchor.constraint(equalTo: centerHost.bottomAnchor),

            symPanel.leadingAnchor.constraint(equalTo: centerHost.leadingAnchor),
            symPanel.trailingAnchor.constraint(equalTo: centerHost.trailingAnchor),
            symPanel.topAnchor.constraint(equalTo: centerHost.topAnchor),
            symPanel.bottomAnchor.constraint(equalTo: centerHost.bottomAnchor),
        ])

        applyMode(.normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyMode(_ mode: InputMode) {
        modeStrip.text = mode.title
        switch mode {
        case .normal:
            backgroundColor = .secondarySystemBackground
            modeStrip.textColor = .secondaryLabel
        case .navigation:
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
            modeStrip.textColor = .systemBlue
        case .navigationSelecting:
            backgroundColor = UIColor.systemOrange.withAlphaComponent(0.22)
            modeStrip.textColor = .systemOrange
        case .symbols:
            backgroundColor = UIColor.systemPurple.withAlphaComponent(0.18)
            modeStrip.textColor = .systemPurple
        }

        let nav = mode.isNavigating
        let sym = mode == .symbols
        normalPanel.isHidden = nav || sym
        navPanel.isHidden = !nav
        symPanel.isHidden = !sym
        selectButton.isHidden = !nav
        selectButton.isHeld = mode.isSelecting
        navButton.isHeld = nav
        symButton.isHeld = sym
        symButton.isHidden = nav
        trackpad.alpha = 1
    }

    private func buildNormalPanel() {
        let tab = KeyButton(title: "TAB")
        tab.enableSwipeAndLongPress()
        tab.onTap = { [weak self] in self?.delegate?.accessoryIndent() }
        tab.onSwipeLeft = { [weak self] in self?.delegate?.accessoryOutdent() }
        tab.onLongPress = { [weak self] in self?.delegate?.accessoryOutdent() }

        let outdent = KeyButton(title: "⇤")
        outdent.onTap = { [weak self] in self?.delegate?.accessoryOutdent() }

        let pairs: [(String, String, String)] = [
            ("()", "(", ")"),
            ("{}", "{", "}"),
            ("[]", "[", "]"),
            ("\"\"", "\"", "\""),
            ("''", "'", "'"),
            ("``", "`", "`"),
        ]
        var pairButtons: [UIView] = []
        for (title, open, close) in pairs {
            let button = KeyButton(title: title, mono: true)
            button.onTap = { [weak self] in self?.delegate?.accessoryInsertPair(open: open, close: close) }
            pairButtons.append(button)
        }

        let singles = ["=", ";", ".", ","]
        var singleButtons: [UIView] = []
        for s in singles {
            let button = KeyButton(title: s, mono: true)
            button.onTap = { [weak self] in self?.delegate?.accessoryInsertText(s) }
            singleButtons.append(button)
        }

        let undo = KeyButton(title: "↶")
        undo.onTap = { [weak self] in self?.delegate?.accessoryUndo() }
        let redo = KeyButton(title: "↷")
        redo.onTap = { [weak self] in self?.delegate?.accessoryRedo() }

        let row1 = row([tab, outdent] + pairButtons)
        let row2 = row(singleButtons + [undo, redo])
        let stack = UIStackView(arrangedSubviews: [row1, row2])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        normalPanel.addSubview(stack)
        pin(stack, to: normalPanel)
    }

    private func buildNavPanel() {
        func nav(_ title: String, _ action: @escaping (EditingAccessoryDelegate, Bool) -> Void) -> KeyButton {
            let button = KeyButton(title: title)
            button.onTap = { [weak self] in
                guard let self, let delegate = self.delegate else { return }
                action(delegate, delegate.inputMode.isSelecting)
            }
            return button
        }

        let r1 = row([
            nav("W←") { $0.accessoryMoveWordLeft(extending: $1) },
            nav("↑") { $0.accessoryMoveUp(extending: $1) },
            nav("W→") { $0.accessoryMoveWordRight(extending: $1) },
            nav("HOME") { $0.accessoryHome(extending: $1) },
            nav("END") { $0.accessoryEnd(extending: $1) },
        ])
        let r2 = row([
            nav("←") { $0.accessoryMoveLeft(extending: $1) },
            nav("↓") { $0.accessoryMoveDown(extending: $1) },
            nav("→") { $0.accessoryMoveRight(extending: $1) },
            nav("PG↑") { $0.accessoryPageUp(extending: $1) },
            nav("PG↓") { $0.accessoryPageDown(extending: $1) },
        ])

        let undo = KeyButton(title: "UNDO")
        undo.onTap = { [weak self] in self?.delegate?.accessoryUndo() }
        let redo = KeyButton(title: "REDO")
        redo.onTap = { [weak self] in self?.delegate?.accessoryRedo() }
        let copy = KeyButton(title: "COPY")
        copy.onTap = { [weak self] in self?.delegate?.accessoryCopy() }
        let cut = KeyButton(title: "CUT")
        cut.onTap = { [weak self] in self?.delegate?.accessoryCut() }
        let paste = KeyButton(title: "PASTE")
        paste.onTap = { [weak self] in self?.delegate?.accessoryPaste() }
        let expand = KeyButton(title: "EXPAND")
        expand.onTap = { [weak self] in self?.delegate?.accessoryExpandSelection() }

        let r3 = row([undo, redo, copy, cut, paste, expand])
        let stack = UIStackView(arrangedSubviews: [r1, r2, r3])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        navPanel.addSubview(stack)
        pin(stack, to: navPanel)
    }

    private func buildSymPanel() {
        let rows: [[String]] = [
            ["!", "@", "#", "$", "%", "^", "&", "*", "|"],
            ["(", ")", "{", "}", "[", "]", "<", ">"],
            ["=", "+", "-", "_", "/", "\\", "~", "."],
            ["'", "\"", "`", ":", ";", "?"],
        ]
        var stacks: [UIView] = []
        for symbols in rows {
            var buttons: [UIView] = []
            for s in symbols {
                let button = KeyButton(title: s, mono: true)
                button.onTap = { [weak self] in self?.delegate?.accessoryInsertText(s) }
                buttons.append(button)
            }
            stacks.append(row(buttons))
        }
        let stack = UIStackView(arrangedSubviews: stacks)
        stack.axis = .vertical
        stack.spacing = 3
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        symPanel.addSubview(stack)
        pin(stack, to: symPanel)
    }

    private func row(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = 3
        stack.distribution = .fillEqually
        return stack
    }

    private func pin(_ child: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }
}
