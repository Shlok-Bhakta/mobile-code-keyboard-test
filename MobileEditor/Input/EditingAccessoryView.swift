import UIKit

protocol EditingAccessoryDelegate: AnyObject {
    var inputMode: InputMode { get }
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
}

final class EditingAccessoryView: UIInputView {
    weak var delegate: EditingAccessoryDelegate?

    var usesInternalSymbolPad = true
    private let navPad = NavSelectPad()
    private let symButton = HoldButton(systemImage: "number")
    private let symbolPicker = SymbolPickerView()
    private let compactSymbolPicker = SymbolPickerView(rows: [[",", "_", "/", "-", ";", "'", "\""]])
    private let normalPanel = UIView()
    private let navPanel = UIView()
    private let symPanel = UIView()
    private let expandedNavPanel = UIView()
    private let compactNavPanel = UIView()
    private let centerHost = UIView()
    private var heightConstraint: NSLayoutConstraint!
    private var navWidthConstraint: NSLayoutConstraint!
    private var symWidthConstraint: NSLayoutConstraint!
    private var desiredHeight: CGFloat = EditingAccessoryView.compactHeight
    private var language: RunLanguage = .python

    static let compactHeight: CGFloat = 50
    static let navHeight: CGFloat = 108
    static let symbolHeight: CGFloat = 122
    static let padWidth: CGFloat = 96

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: desiredHeight)
    }

    override var safeAreaInsets: UIEdgeInsets { .zero }

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: Self.compactHeight), inputViewStyle: .default)
        allowsSelfSizing = true
        autoresizingMask = [.flexibleWidth]
        isMultipleTouchEnabled = true
        backgroundColor = .secondarySystemBackground

        navPad.onNavDown = { [weak self] in self?.delegate?.accessoryNavDown() }
        navPad.onNavUp = { [weak self] in self?.delegate?.accessoryNavUp() }
        navPad.onSelectChanged = { [weak self] on in
            if on { self?.delegate?.accessorySelectDown() }
            else { self?.delegate?.accessorySelectUp() }
        }

        symButton.activeBackground = .systemPurple
        symButton.idleBackground = UIColor.systemPurple.withAlphaComponent(0.28)
        symButton.onDown = { [weak self] in self?.delegate?.accessorySymDown() }
        symButton.onMoved = { [weak self] point in self?.hoverSym(at: point) }
        symButton.onUp = { [weak self] in self?.finishSym(commit: true) }
        symButton.onCancel = { [weak self] in self?.finishSym(commit: false) }
        symbolPicker.onHover = { [weak self] symbol in
            self?.symButton.setPreviewSymbol(symbol)
        }
        symbolPicker.onPick = { [weak self] symbol in
            self?.delegate?.accessoryInsertText(symbol)
            self?.symbolPicker.clearHover()
            self?.symButton.setPreviewSymbol(nil)
        }
        compactSymbolPicker.onHover = { [weak self] symbol in
            self?.symButton.setPreviewSymbol(symbol)
        }
        compactSymbolPicker.onPick = { [weak self] symbol in
            self?.delegate?.accessoryInsertText(symbol)
            self?.compactSymbolPicker.clearHover()
            self?.symButton.setPreviewSymbol(nil)
        }

        buildNormalPanel()
        buildNavPanel()
        buildSymPanel()

        [navPad, centerHost, symButton, normalPanel, navPanel, symPanel].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            if view === normalPanel || view === navPanel || view === symPanel {
                centerHost.addSubview(view)
            } else {
                addSubview(view)
            }
        }

        heightConstraint = heightAnchor.constraint(equalToConstant: Self.compactHeight)
        heightConstraint.priority = .required
        navWidthConstraint = navPad.widthAnchor.constraint(equalToConstant: Self.padWidth)
        symWidthConstraint = symButton.widthAnchor.constraint(equalToConstant: 56)
        NSLayoutConstraint.activate([
            heightConstraint,
            navPad.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            navPad.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            navPad.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            navWidthConstraint,

            symButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            symButton.topAnchor.constraint(equalTo: navPad.topAnchor),
            symButton.bottomAnchor.constraint(equalTo: navPad.bottomAnchor),
            symWidthConstraint,

            centerHost.leadingAnchor.constraint(equalTo: navPad.trailingAnchor, constant: 4),
            centerHost.trailingAnchor.constraint(equalTo: symButton.leadingAnchor, constant: -4),
            centerHost.topAnchor.constraint(equalTo: navPad.topAnchor),
            centerHost.bottomAnchor.constraint(equalTo: navPad.bottomAnchor),

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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        syncKeyboardHeight(desiredHeight)
    }

    func configure(language: RunLanguage) {
        self.language = language
        buildNormalPanel()
        applyMode(delegate?.inputMode ?? .normal)
    }

    func applyMode(_ mode: InputMode) {
        switch mode {
        case .normal:
            backgroundColor = .secondarySystemBackground
        case .navigation:
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.16)
        case .navigationSelecting:
            backgroundColor = UIColor.systemOrange.withAlphaComponent(0.20)
        case .symbols:
            backgroundColor = UIColor.systemPurple.withAlphaComponent(0.16)
        }

        let nav = mode.isNavigating
        let sym = mode == .symbols
        let fixedBar = EditorSettings.shared.experimentFixedBar
        normalPanel.isHidden = nav || (sym && usesInternalSymbolPad)
        navPanel.isHidden = !nav
        symPanel.isHidden = !(sym && usesInternalSymbolPad)
        expandedNavPanel.isHidden = fixedBar
        compactNavPanel.isHidden = !fixedBar
        symbolPicker.isHidden = fixedBar
        compactSymbolPicker.isHidden = !fixedBar
        navPad.isNavHeld = nav
        navPad.isSelecting = mode.isSelecting
        navPad.isUserInteractionEnabled = !sym
        let compactControls = EditorSettings.shared.experimentCompactControls
        navWidthConstraint.constant = (sym && usesInternalSymbolPad) ? 0 : (compactControls ? 78 : Self.padWidth)
        symWidthConstraint.constant = compactControls ? 48 : 56
        navPad.alpha = (sym && usesInternalSymbolPad) ? 0 : 1
        symButton.isHeld = sym
        if !sym {
            symbolPicker.clearHover()
            compactSymbolPicker.clearHover()
            symButton.setPreviewSymbol(nil)
        }
        let height: CGFloat
        if fixedBar {
            height = Self.compactHeight
        } else if sym && usesInternalSymbolPad {
            height = Self.symbolHeight
        } else if nav {
            height = Self.navHeight
        } else {
            height = Self.compactHeight
        }
        setHeight(height)
    }

    private func hoverSym(at point: CGPoint) {
        guard !symPanel.isHidden else { return }
        let picker = EditorSettings.shared.experimentFixedBar ? compactSymbolPicker : symbolPicker
        if symButton.bounds.insetBy(dx: 2, dy: 2).contains(point) {
            picker.clearHover()
            symButton.setPreviewSymbol(nil)
            return
        }
        picker.hover(at: symButton.convert(point, to: picker))
    }

    private func finishSym(commit: Bool) {
        let picker = EditorSettings.shared.experimentFixedBar ? compactSymbolPicker : symbolPicker
        if commit, let symbol = picker.commit() {
            delegate?.accessoryInsertText(symbol)
        }
        picker.clearHover()
        symButton.setPreviewSymbol(nil)
        delegate?.accessorySymUp()
    }

    private func setHeight(_ height: CGFloat) {
        guard desiredHeight != height else { return }
        desiredHeight = height
        heightConstraint.constant = height
        invalidateIntrinsicContentSize()
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.45,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.syncKeyboardHeight(height)
            self.window?.layoutIfNeeded()
        }
    }

    /// iOS installs its own height lock when the accessory attaches. Update that
    /// too or the bar stays at the compact frame forever.
    private func syncKeyboardHeight(_ height: CGFloat) {
        allowsSelfSizing = true
        bounds.size.height = height
        var next = frame
        next.size.height = height
        frame = next
        for constraint in constraints where constraint.firstAttribute == .height {
            constraint.constant = height
        }
        if let superview {
            for constraint in superview.constraints where constraint.firstAttribute == .height {
                let first = constraint.firstItem as? UIView
                let second = constraint.secondItem as? UIView
                if first === self || first === superview || second === self {
                    constraint.constant = height
                }
            }
        }
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    private func buildNormalPanel() {
        normalPanel.subviews.forEach { $0.removeFromSuperview() }
        let settings = EditorSettings.shared
        let indent = KeyButton(systemImage: "increase.indent")
        indent.enableSwipeAndLongPress()
        indent.onTap = { [weak self] in self?.delegate?.accessoryIndent() }
        indent.onSwipeLeft = { [weak self] in self?.delegate?.accessoryOutdent() }
        indent.onLongPress = { [weak self] in self?.delegate?.accessoryOutdent() }
        indent.accessibilityLabel = "Indent"
        indent.accessibilityHint = "Swipe left or hold to outdent"

        var buttons: [UIView] = [indent]
        if !settings.experimentCompactControls {
            let outdent = KeyButton(systemImage: "decrease.indent")
            outdent.onTap = { [weak self] in self?.delegate?.accessoryOutdent() }
            outdent.accessibilityLabel = "Outdent"
            buttons.append(outdent)
        }

        func pair(_ title: String, _ open: String, _ close: String) -> KeyButton {
            let button = KeyButton(title: title, mono: true)
            button.onTap = { [weak self] in self?.delegate?.accessoryInsertPair(open: open, close: close) }
            button.accessibilityLabel = "Insert \(title) pair"
            return button
        }

        if settings.experimentCodeKeys {
            buttons.append(pair("()", "(", ")"))

            let dot = KeyButton(title: ".", mono: true)
            dot.onTap = { [weak self] in self?.delegate?.accessoryInsertText(".") }
            buttons.append(dot)

            let equals = KeyButton(title: "=", mono: true)
            equals.onTap = { [weak self] in self?.delegate?.accessoryInsertText("=") }
            if settings.experimentOperatorSwipes {
                equals.enableSwipeAndLongPress()
                equals.onSwipeRight = { [weak self] in self?.delegate?.accessoryInsertText("==") }
                equals.onSwipeLeft = { [weak self] in self?.delegate?.accessoryInsertText("=>") }
                equals.accessibilityHint = "Swipe right for == or left for =>"
            }
            buttons.append(equals)

            let colon = KeyButton(title: ":", mono: true)
            colon.onTap = { [weak self] in self?.delegate?.accessoryInsertText(":") }
            if settings.experimentOperatorSwipes {
                colon.enableSwipeAndLongPress()
                colon.onSwipeRight = { [weak self] in self?.delegate?.accessoryInsertText("::") }
                colon.onSwipeLeft = { [weak self] in self?.delegate?.accessoryInsertText(":=") }
                colon.accessibilityHint = "Swipe right for :: or left for :="
            }
            buttons.append(colon)

            switch language {
            case .python, .markdown:
                buttons.append(pair("[]", "[", "]"))
            case .typescript, .rust:
                buttons.append(pair("{}", "{", "}"))
            }
        } else {
            for (title, open, close) in [
                ("()", "(", ")"), ("{}", "{", "}"), ("[]", "[", "]"),
                ("\"\"", "\"", "\""), ("''", "'", "'"), ("``", "`", "`")
            ] {
                buttons.append(pair(title, open, close))
            }
        }

        let undo = KeyButton(systemImage: "arrow.uturn.backward")
        undo.onTap = { [weak self] in self?.delegate?.accessoryUndo() }
        undo.accessibilityLabel = "Undo"
        if settings.experimentCompactControls {
            undo.enableSwipeAndLongPress()
            undo.onSwipeRight = { [weak self] in self?.delegate?.accessoryRedo() }
            undo.onLongPress = { [weak self] in self?.delegate?.accessoryRedo() }
            undo.accessibilityHint = "Swipe right or hold to redo"
        }
        buttons.append(undo)
        if !settings.experimentCompactControls {
            let redo = KeyButton(systemImage: "arrow.uturn.forward")
            redo.onTap = { [weak self] in self?.delegate?.accessoryRedo() }
            redo.accessibilityLabel = "Redo"
            buttons.append(redo)
        }

        let stack = row(buttons)
        stack.translatesAutoresizingMaskIntoConstraints = false
        normalPanel.addSubview(stack)
        pin(stack, to: normalPanel)
    }

    private func buildNavPanel() {
        func nav(_ image: String, _ action: @escaping (EditingAccessoryDelegate, Bool) -> Void) -> KeyButton {
            let button = KeyButton(systemImage: image, pointSize: 18)
            button.onTap = { [weak self] in
                guard let self, let delegate = self.delegate else { return }
                action(delegate, delegate.inputMode.isSelecting)
            }
            return button
        }

        let r1 = row([
            nav("chevron.left.2") { $0.accessoryMoveWordLeft(extending: $1) },
            nav("chevron.up") { $0.accessoryMoveUp(extending: $1) },
            nav("chevron.right.2") { $0.accessoryMoveWordRight(extending: $1) },
            nav("arrow.left.to.line") { $0.accessoryHome(extending: $1) },
            nav("arrow.right.to.line") { $0.accessoryEnd(extending: $1) },
            nav("doc.on.doc") { delegate, _ in delegate.accessoryCopy() },
        ], spacing: 5)
        let r2 = row([
            nav("chevron.left") { $0.accessoryMoveLeft(extending: $1) },
            nav("chevron.down") { $0.accessoryMoveDown(extending: $1) },
            nav("chevron.right") { $0.accessoryMoveRight(extending: $1) },
            nav("scissors") { delegate, _ in delegate.accessoryCut() },
            nav("doc.on.clipboard") { delegate, _ in delegate.accessoryPaste() },
            nav("arrow.up.left.and.arrow.down.right") { delegate, _ in delegate.accessoryExpandSelection() },
        ], spacing: 5)

        let stack = UIStackView(arrangedSubviews: [r1, r2])
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        expandedNavPanel.translatesAutoresizingMaskIntoConstraints = false
        navPanel.addSubview(expandedNavPanel)
        pin(expandedNavPanel, to: navPanel)
        expandedNavPanel.addSubview(stack)
        pin(stack, to: expandedNavPanel)

        let left = nav("chevron.left") { $0.accessoryMoveLeft(extending: $1) }
        left.enableSwipeAndLongPress()
        left.onSwipeLeft = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.accessoryMoveWordLeft(extending: delegate.inputMode.isSelecting)
        }
        left.onLongPress = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.accessoryHome(extending: delegate.inputMode.isSelecting)
        }
        left.accessibilityHint = "Swipe left for previous word; hold for line start"

        let up = nav("chevron.up") { $0.accessoryMoveUp(extending: $1) }
        up.enableSwipeAndLongPress()
        up.onLongPress = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.accessoryPageUp(extending: delegate.inputMode.isSelecting)
        }

        let down = nav("chevron.down") { $0.accessoryMoveDown(extending: $1) }
        down.enableSwipeAndLongPress()
        down.onLongPress = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.accessoryPageDown(extending: delegate.inputMode.isSelecting)
        }

        let right = nav("chevron.right") { $0.accessoryMoveRight(extending: $1) }
        right.enableSwipeAndLongPress()
        right.onSwipeRight = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.accessoryMoveWordRight(extending: delegate.inputMode.isSelecting)
        }
        right.onLongPress = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.accessoryEnd(extending: delegate.inputMode.isSelecting)
        }
        right.accessibilityHint = "Swipe right for next word; hold for line end"

        let more = KeyButton(systemImage: "ellipsis")
        more.accessibilityLabel = "More editing actions"
        more.menu = UIMenu(children: [
            UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in self?.delegate?.accessoryCopy() },
            UIAction(title: "Cut", image: UIImage(systemName: "scissors")) { [weak self] _ in self?.delegate?.accessoryCut() },
            UIAction(title: "Paste", image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in self?.delegate?.accessoryPaste() },
            UIAction(title: "Expand selection", image: UIImage(systemName: "arrow.up.left.and.arrow.down.right")) { [weak self] _ in self?.delegate?.accessoryExpandSelection() },
        ])
        more.showsMenuAsPrimaryAction = true

        let compact = row([left, up, down, right, more], spacing: 3)
        compact.translatesAutoresizingMaskIntoConstraints = false
        compactNavPanel.translatesAutoresizingMaskIntoConstraints = false
        navPanel.addSubview(compactNavPanel)
        pin(compactNavPanel, to: navPanel)
        compactNavPanel.addSubview(compact)
        pin(compact, to: compactNavPanel)
    }

    private func buildSymPanel() {
        symbolPicker.translatesAutoresizingMaskIntoConstraints = false
        compactSymbolPicker.translatesAutoresizingMaskIntoConstraints = false
        symPanel.addSubview(symbolPicker)
        symPanel.addSubview(compactSymbolPicker)
        pin(symbolPicker, to: symPanel)
        pin(compactSymbolPicker, to: symPanel)
    }

    private func row(_ views: [UIView], spacing: CGFloat = 3) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = spacing
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
