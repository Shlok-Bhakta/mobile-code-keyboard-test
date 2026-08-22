import SwiftUI
import UIKit

final class EditorViewController: UIViewController, UITextViewDelegate, EditingAccessoryDelegate {
    let controller = EditorController()
    private let textView = CodeTextView()
    private let gutter = LineNumberGutter()
    private let accessory = EditingAccessoryView()
    private let chrome = UIView()
    private let findBar = FindBar()
    private var findHeight: NSLayoutConstraint?
    private var saveWork: DispatchWorkItem?
    private var navTimer: Timer?
    private var symTimer: Timer?
    private var navHeld = false
    private var selectHeld = false
    private var symHeld = false
    private(set) var inputMode: InputMode = .normal

    var isTrackpadSelecting: Bool {
        inputMode.isSelecting || (inputMode.isNavigating && EditorSettings.shared.trackpadSelectWithNav)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        controller.textView = textView
        textView.controller = controller
        textView.delegate = self
        textView.onFind = { [weak self] in self?.showFind(true) }
        textView.inputAccessoryView = accessory
        accessory.delegate = self

        gutter.textView = textView
        gutter.onSelectLines = { [weak self] from, to in
            self?.controller.selectLineRange(from: from, to: to)
        }

        findBar.isHidden = true
        findBar.onClose = { [weak self] in
            self?.showFind(false)
            self?.textView.becomeFirstResponder()
        }
        findBar.onNext = { [weak self] query in self?.controller.find(query: query, forward: true) }
        findBar.onPrev = { [weak self] query in self?.controller.find(query: query, forward: false) }

        buildChrome()
        layoutParts()
        loadDocument()
        observeLifecycle()
        EditorHaptics.prepare()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gutter.reload()
        textView.applyWrapping()
    }

    private func layoutParts() {
        chrome.translatesAutoresizingMaskIntoConstraints = false
        findBar.translatesAutoresizingMaskIntoConstraints = false
        gutter.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chrome)
        view.addSubview(findBar)
        view.addSubview(gutter)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            chrome.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chrome.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chrome.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chrome.heightAnchor.constraint(equalToConstant: 36),

            findBar.topAnchor.constraint(equalTo: chrome.bottomAnchor),
            findBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            findBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            gutter.topAnchor.constraint(equalTo: findBar.bottomAnchor),
            gutter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gutter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gutter.widthAnchor.constraint(equalToConstant: 46),

            textView.topAnchor.constraint(equalTo: gutter.topAnchor),
            textView.leadingAnchor.constraint(equalTo: gutter.trailingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let height = findBar.heightAnchor.constraint(equalToConstant: 0)
        height.isActive = true
        findHeight = height
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 24, right: 8)
    }

    private func buildChrome() {
        chrome.backgroundColor = .systemBackground

        let samples = UIButton(type: .system)
        samples.setTitle("Samples", for: .normal)
        samples.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        var children: [UIMenuElement] = SampleDocuments.all.map { sample in
            UIAction(title: sample.title) { [weak self] _ in
                self?.loadSample(sample.text)
            }
        }
        samples.menu = UIMenu(children: children)
        samples.showsMenuAsPrimaryAction = true

        let find = UIButton(type: .system)
        find.setTitle("Find", for: .normal)
        find.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        find.addTarget(self, action: #selector(toggleFind), for: .touchUpInside)

        let tune = UIButton(type: .system)
        tune.setTitle("Tune", for: .normal)
        tune.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        tune.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [samples, UIView(), find, tune])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        chrome.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: chrome.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: chrome.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: chrome.topAnchor),
            stack.bottomAnchor.constraint(equalTo: chrome.bottomAnchor),
        ])
    }

    private func loadDocument() {
        if let saved = DocumentStore.load() {
            textView.text = saved
        } else {
            textView.text = SampleDocuments.rust.text
        }
        textView.applyFont()
        textView.applyWrapping()
        controller.syncAnchorFromSelection()
        gutter.reload()
    }

    private func loadSample(_ text: String) {
        textView.text = text
        textView.selectedRange = NSRange(location: 0, length: 0)
        persistSoon()
        gutter.reload()
    }

    private func observeLifecycle() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(resetModes), name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(resetModes), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillHide() {
        resetModes()
        persistSoon()
    }

    @objc func resetModes() {
        navTimer?.invalidate()
        symTimer?.invalidate()
        navHeld = false
        selectHeld = false
        symHeld = false
        setMode(.normal)
        accessory.applyMode(.normal)
    }

    private func persistSoon() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            DocumentStore.save(self.textView.text ?? "")
        }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    @objc private func toggleFind() {
        showFind(findBar.isHidden)
    }

    private func showFind(_ visible: Bool) {
        findBar.isHidden = !visible
        findHeight?.constant = visible ? 44 : 0
        view.layoutIfNeeded()
        if visible {
            findBar.focus()
        }
    }

    @objc private func openSettings() {
        let host = UIHostingController(rootView: DebugSettingsView(
            onChange: { [weak self] in
                self?.textView.applyFont()
                self?.textView.applyWrapping()
                self?.gutter.reload()
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
                self?.textView.becomeFirstResponder()
            }
        ))
        present(host, animated: true)
    }

    private func setMode(_ mode: InputMode) {
        inputMode = mode
        accessory.applyMode(mode)
    }

    private func enterNav() {
        guard navHeld else { return }
        symHeld = false
        setMode(selectHeld ? .navigationSelecting : .navigation)
        EditorHaptics.modeEnter()
        EditorLog.event("NAV_DOWN")
    }

    private func enterSym() {
        guard symHeld else { return }
        navHeld = false
        selectHeld = false
        setMode(.symbols)
        EditorHaptics.modeEnter()
        EditorLog.event("SYM_DOWN")
    }

    // MARK: UITextViewDelegate

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return !controller.handleReturn()
        }
        if controller.skipCloserIfNeeded(text) {
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        persistSoon()
        gutter.reload()
        controller.clearPreferredColumn()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        gutter.reload()
        if !inputMode.isSelecting {
            controller.syncAnchorFromSelection()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        gutter.reload()
    }

    // MARK: Accessory

    func accessoryNavDown() {
        navHeld = true
        let delay = EditorSettings.shared.longPressDelay
        navTimer?.invalidate()
        if EditorSettings.shared.navMomentary {
            if delay <= 0 {
                enterNav()
            } else {
                navTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.enterNav()
                }
            }
        } else {
            if inputMode.isNavigating {
                navHeld = false
                selectHeld = false
                setMode(.normal)
                EditorLog.event("NAV_UP")
            } else {
                enterNav()
            }
        }
    }

    func accessoryNavUp() {
        navTimer?.invalidate()
        navHeld = false
        selectHeld = false
        if EditorSettings.shared.navMomentary {
            if inputMode.isNavigating {
                setMode(.normal)
                EditorLog.event("NAV_UP")
            }
        }
    }

    func accessorySelectDown() {
        guard inputMode.isNavigating || navHeld else { return }
        selectHeld = true
        controller.rememberAnchorForSelection()
        setMode(.navigationSelecting)
        EditorHaptics.selectionStart()
        EditorLog.event("SELECT_DOWN")
    }

    func accessorySelectUp() {
        selectHeld = false
        EditorLog.event("SELECT_UP")
        if navHeld || inputMode.isNavigating {
            setMode(.navigation)
        }
    }

    func accessorySymDown() {
        if navHeld { return }
        symHeld = true
        let delay = EditorSettings.shared.longPressDelay
        symTimer?.invalidate()
        if EditorSettings.shared.symMomentary {
            if delay <= 0 {
                enterSym()
            } else {
                symTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.enterSym()
                }
            }
        } else {
            if inputMode == .symbols {
                symHeld = false
                setMode(.normal)
                EditorLog.event("SYM_UP")
            } else {
                enterSym()
            }
        }
    }

    func accessorySymUp() {
        symTimer?.invalidate()
        symHeld = false
        if EditorSettings.shared.symMomentary, inputMode == .symbols {
            setMode(.normal)
            EditorLog.event("SYM_UP")
        }
    }

    func accessoryIndent() { controller.indent() }
    func accessoryOutdent() { controller.outdent() }
    func accessoryInsertPair(open: String, close: String) { controller.insertPair(open: open, close: close) }
    func accessoryInsertText(_ text: String) {
        if controller.skipCloserIfNeeded(text) { return }
        controller.insertText(text)
    }
    func accessoryUndo() { controller.undo() }
    func accessoryRedo() { controller.redo() }
    func accessoryCopy() { controller.copy() }
    func accessoryCut() { controller.cut() }
    func accessoryPaste() { controller.paste() }
    func accessoryMoveLeft(extending: Bool) { controller.moveLeft(extending: extending) }
    func accessoryMoveRight(extending: Bool) { controller.moveRight(extending: extending) }
    func accessoryMoveUp(extending: Bool) { controller.moveUp(extending: extending) }
    func accessoryMoveDown(extending: Bool) { controller.moveDown(extending: extending) }
    func accessoryMoveWordLeft(extending: Bool) { controller.moveWordLeft(extending: extending) }
    func accessoryMoveWordRight(extending: Bool) { controller.moveWordRight(extending: extending) }
    func accessoryHome(extending: Bool) { controller.moveLineStart(extending: extending) }
    func accessoryEnd(extending: Bool) { controller.moveLineEnd(extending: extending) }
    func accessoryPageUp(extending: Bool) { controller.pageUp(extending: extending) }
    func accessoryPageDown(extending: Bool) { controller.pageDown(extending: extending) }
    func accessoryExpandSelection() { controller.expandSelection() }

    func accessoryTrackpadBegan() { controller.trackpadBegan() }
    func accessoryTrackpadChanged(dx: CGFloat, dy: CGFloat, velocity: CGPoint) {
        controller.trackpadChanged(dx: dx, dy: dy, velocity: velocity, extending: isTrackpadSelecting)
    }
    func accessoryTrackpadEnded() { controller.trackpadEnded() }
}

final class FindBar: UIView, UITextFieldDelegate {
    var onNext: ((String) -> Void)?
    var onPrev: ((String) -> Void)?
    var onClose: (() -> Void)?

    private let field = UITextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        field.placeholder = "Find"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        field.returnKeyType = .search
        field.delegate = self
        field.addTarget(self, action: #selector(goNext), for: .primaryActionTriggered)

        let prev = UIButton(type: .system)
        prev.setTitle("◀", for: .normal)
        prev.addTarget(self, action: #selector(goPrev), for: .touchUpInside)
        let next = UIButton(type: .system)
        next.setTitle("▶", for: .normal)
        next.addTarget(self, action: #selector(goNext), for: .touchUpInside)
        let close = UIButton(type: .system)
        close.setTitle("Done", for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [field, prev, next, close])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            prev.widthAnchor.constraint(equalToConstant: 36),
            next.widthAnchor.constraint(equalToConstant: 36),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func focus() {
        field.becomeFirstResponder()
    }

    @objc private func goNext() { onNext?(field.text ?? "") }
    @objc private func goPrev() { onPrev?(field.text ?? "") }
    @objc private func closeTapped() { onClose?() }
}
