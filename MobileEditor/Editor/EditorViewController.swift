import SwiftUI
import UIKit

final class EditorViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, EditingAccessoryDelegate {
    let controller = EditorController()
    private let textView = CodeTextView()
    private let gutter = LineNumberGutter()
    private let accessory = EditingAccessoryView()
    private let chrome = UIView()
    private let findBar = FindBar()
    private let jumpField = FlashJumpTextField()
    private let jumpOverlay = FlashJumpOverlay()
    private let langTag = UILabel()
    private var runButton: UIButton?
    private var experimentButton: UIButton?
    private var findHeight: NSLayoutConstraint?
    private var saveWork: DispatchWorkItem?
    private var highlightWork: DispatchWorkItem?
    private var navTimer: Timer?
    private var symTimer: Timer?
    private var navHeld = false
    private var selectHeld = false
    private var symHeld = false
    private var jumpActive = false
    private var jumpTargets: [FlashJumpTarget] = []
    private(set) var inputMode: InputMode = .normal

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        controller.textView = textView
        textView.controller = controller
        textView.delegate = self
        textView.onFind = { [weak self] in self?.showFind(true) }
        textView.onRun = { [weak self] in self?.runTapped() }
        textView.inputView = nil
        textView.inputAccessoryView = accessory
        accessory.delegate = self
        accessory.usesInternalSymbolPad = true
        accessory.configure(language: EditorSettings.shared.runLanguage)

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
        updateRunChrome()
        observeLifecycle()
        EditorHaptics.prepare()
        textView.becomeFirstResponder()
        highlightSoon()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.inputView = nil
        textView.inputAccessoryView = accessory
        if !jumpField.isFirstResponder {
            textView.becomeFirstResponder()
            textView.reloadInputViews()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gutter.reload()
        textView.applyWrapping()
        refreshJump()
    }

    private func layoutParts() {
        chrome.translatesAutoresizingMaskIntoConstraints = false
        findBar.translatesAutoresizingMaskIntoConstraints = false
        gutter.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        jumpOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chrome)
        view.addSubview(findBar)
        view.addSubview(gutter)
        view.addSubview(textView)
        view.addSubview(jumpOverlay)

        NSLayoutConstraint.activate([
            chrome.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chrome.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chrome.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chrome.heightAnchor.constraint(equalToConstant: 28),

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
            jumpOverlay.topAnchor.constraint(equalTo: textView.topAnchor),
            jumpOverlay.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            jumpOverlay.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            jumpOverlay.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
        ])

        let height = findBar.heightAnchor.constraint(equalToConstant: 0)
        height.isActive = true
        findHeight = height
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 24, right: 8)
    }

    private func buildChrome() {
        chrome.backgroundColor = .systemBackground

        let samples = iconButton("doc.text")
        var children: [UIMenuElement] = SampleDocuments.all.map { sample in
            UIAction(title: sample.title) { [weak self] _ in
                self?.loadSample(sample)
            }
        }
        samples.menu = UIMenu(children: children)
        samples.showsMenuAsPrimaryAction = true

        langTag.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        langTag.textColor = .secondaryLabel

        let run = iconButton("play.fill")
        run.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        runButton = run

        let find = iconButton("magnifyingglass")
        find.addTarget(self, action: #selector(toggleFind), for: .touchUpInside)

        let tune = iconButton("slider.horizontal.3")
        tune.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let experiments = UIButton(type: .system)
        experiments.setTitle("KEYS", for: .normal)
        experiments.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        experiments.tintColor = .systemBlue
        experiments.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.16)
        experiments.layer.cornerRadius = 6
        experiments.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        experiments.accessibilityLabel = "Keyboard experiments"
        experiments.menu = makeExperimentMenu()
        experiments.showsMenuAsPrimaryAction = true
        experimentButton = experiments

        jumpField.placeholder = "JUMP"
        jumpField.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        jumpField.textAlignment = .center
        jumpField.textColor = .label
        jumpField.tintColor = .systemPurple
        jumpField.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.16)
        jumpField.layer.cornerRadius = 6
        jumpField.autocapitalizationType = .none
        jumpField.autocorrectionType = .no
        jumpField.spellCheckingType = .no
        jumpField.smartQuotesType = .no
        jumpField.smartDashesType = .no
        jumpField.textContentType = UITextContentType(rawValue: "")
        if #available(iOS 17.0, *) {
            jumpField.inlinePredictionType = .no
        }
        jumpField.returnKeyType = .go
        let cancelJump = UIButton(type: .system)
        cancelJump.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11)), for: .normal)
        cancelJump.tintColor = .secondaryLabel
        cancelJump.accessibilityLabel = "Cancel jump"
        cancelJump.addTarget(self, action: #selector(cancelJumpTapped), for: .touchUpInside)
        cancelJump.frame = CGRect(x: 0, y: 0, width: 20, height: 28)
        jumpField.rightView = cancelJump
        jumpField.rightViewMode = .whileEditing
        jumpField.delegate = self
        jumpField.addTarget(self, action: #selector(jumpQueryChanged), for: .editingChanged)
        jumpField.onEscape = { [weak self] in self?.stopJump(restoreEditor: true) }
        jumpField.accessibilityLabel = "Jump to visible code"
        jumpField.accessibilityIdentifier = "flashJumpField"
        jumpField.widthAnchor.constraint(equalToConstant: 68).isActive = true
        jumpField.heightAnchor.constraint(equalToConstant: 28).isActive = true
        jumpField.isHidden = !EditorSettings.shared.experimentFlashJump

        let stack = UIStackView(arrangedSubviews: [samples, langTag, UIView(), run, find, jumpField, experiments, tune])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        chrome.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: chrome.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: chrome.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: chrome.topAnchor),
            stack.bottomAnchor.constraint(equalTo: chrome.bottomAnchor),
        ])
    }

    private func iconButton(_ system: String) -> UIButton {
        let button = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: system, withConfiguration: cfg), for: .normal)
        button.tintColor = .label
        return button
    }

    private func loadDocument() {
        if let saved = DocumentStore.load() {
            textView.text = saved
        } else {
            textView.text = SampleDocuments.python.text
        }
        textView.applyFont()
        textView.applyWrapping()
        controller.syncAnchorFromSelection()
        gutter.reload()
    }

    private func loadSample(_ sample: SampleDocuments.Sample) {
        stopJump(restoreEditor: false)
        textView.text = sample.text
        textView.selectedRange = NSRange(location: 0, length: 0)
        setLanguage(sample.language)
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
        if !jumpField.isFirstResponder { stopJump(restoreEditor: false) }
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
        if visible { stopJump(restoreEditor: false) }
        findBar.isHidden = !visible
        findHeight?.constant = visible ? 44 : 0
        view.layoutIfNeeded()
        if visible {
            findBar.focus()
        }
    }

    @objc private func openSettings() {
        stopJump(restoreEditor: false)
        let host = UIHostingController(rootView: DebugSettingsView(
            onChange: { [weak self] in
                self?.textView.applyFont()
                self?.textView.applyWrapping()
                self?.gutter.reload()
                self?.updateRunChrome()
                self?.accessory.configure(language: EditorSettings.shared.runLanguage)
                self?.highlightSoon()
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

    // MARK: Run

    private func setLanguage(_ language: RunLanguage) {
        EditorSettings.shared.runLanguage = language
        accessory.configure(language: language)
        updateRunChrome()
        highlightSoon()
    }

    private func makeExperimentMenu() -> UIMenu {
        let settings = EditorSettings.shared
        func option(_ title: String, on: Bool, change: @escaping () -> Void) -> UIAction {
            UIAction(title: title, state: on ? .on : .off) { [weak self] _ in
                change()
                self?.refreshExperimentMenu()
            }
        }
        return UIMenu(title: "Keyboard experiments", children: [
            option("Larger code keys", on: settings.experimentCodeKeys) {
                settings.experimentCodeKeys.toggle()
            },
            option("Compact controls", on: settings.experimentCompactControls) {
                settings.experimentCompactControls.toggle()
            },
            option("Fixed 50 pt bar", on: settings.experimentFixedBar) {
                settings.experimentFixedBar.toggle()
            },
            option("Operator swipes on code keys", on: settings.experimentOperatorSwipes) {
                settings.experimentOperatorSwipes.toggle()
            },
            option("Flash jump", on: settings.experimentFlashJump) {
                settings.experimentFlashJump.toggle()
            },
            UIMenu(title: "Presets", children: [
                UIAction(title: "All experiments on") { [weak self] _ in
                    settings.experimentCodeKeys = true
                    settings.experimentCompactControls = true
                    settings.experimentFixedBar = true
                    settings.experimentOperatorSwipes = true
                    settings.experimentFlashJump = true
                    self?.refreshExperimentMenu()
                },
                UIAction(title: "Original keyboard bar") { [weak self] _ in
                    settings.experimentCodeKeys = false
                    settings.experimentCompactControls = false
                    settings.experimentFixedBar = false
                    settings.experimentOperatorSwipes = false
                    settings.experimentFlashJump = false
                    self?.refreshExperimentMenu()
                },
            ]),
        ])
    }

    private func refreshExperimentMenu() {
        accessory.configure(language: EditorSettings.shared.runLanguage)
        if !EditorSettings.shared.experimentFlashJump { stopJump(restoreEditor: true) }
        jumpField.isHidden = !EditorSettings.shared.experimentFlashJump
        experimentButton?.menu = makeExperimentMenu()
    }

    private func updateRunChrome() {
        let language = EditorSettings.shared.runLanguage
        langTag.text = language.tag
        runButton?.tintColor = language.isRunnable ? .label : .tertiaryLabel
    }

    @objc private func runTapped() {
        stopJump(restoreEditor: false)
        EditorLog.event("RUN")
        let language = EditorSettings.shared.runLanguage
        guard language.isRunnable else {
            let session = RunSession.info(language: language, message: language.notRunnableMessage)
            presentConsole(session)
            return
        }
        let session = RunSession(code: textView.text ?? "", language: language)
        presentConsole(session)
        session.start()
    }

    private func presentConsole(_ session: RunSession) {
        let host = UIHostingController(rootView: RunConsoleView(
            session: session,
            onDismiss: { [weak self] in self?.dismiss(animated: true) }
        ))
        present(host, animated: true)
    }

    // MARK: Flash jump

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField === jumpField else { return }
        resetModes()
        if !findBar.isHidden { showFind(false) }
        jumpActive = true
        jumpField.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.28)
        refreshJump()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === jumpField else { return }
        stopJump(restoreEditor: false)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard textField === jumpField else { return true }
        if range.length == 0, range.location == (jumpField.text ?? "").utf16.count,
           let target = FlashJumpModel.target(for: string, among: jumpTargets) {
            completeJump(to: target)
            return false
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField === jumpField else { return true }
        if let target = jumpTargets.first {
            completeJump(to: target)
        } else {
            stopJump(restoreEditor: true)
        }
        return false
    }

    @objc private func jumpQueryChanged() {
        refreshJump()
        if let target = FlashJumpModel.automaticTarget(query: jumpField.text ?? "", targets: jumpTargets) {
            completeJump(to: target)
        }
    }

    @objc private func cancelJumpTapped() {
        stopJump(restoreEditor: true)
    }

    private func refreshJump() {
        guard jumpActive, let query = jumpField.text, !query.isEmpty,
              textView.bounds.width > 0, textView.bounds.height > 0 else {
            jumpTargets = []
            jumpOverlay.clear()
            return
        }
        let text = (textView.text ?? "") as NSString
        let layout = textView.layoutManager
        layout.ensureLayout(for: textView.textContainer)
        let visibleRect = CGRect(origin: textView.contentOffset, size: textView.bounds.size)
        let glyphs = layout.glyphRange(forBoundingRect: visibleRect, in: textView.textContainer)
        let visible = layout.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)
        jumpTargets = FlashJumpModel.targets(
            in: text,
            query: query,
            visibleRange: visible,
            caretOffset: textView.selectedRange.location,
            isVisible: { [weak self] range in
                guard let self,
                      let start = self.textView.position(from: self.textView.beginningOfDocument, offset: range.location),
                      let end = self.textView.position(from: start, offset: range.length),
                      let uiRange = self.textView.textRange(from: start, to: end)
                else { return false }
                let rect = self.textView.firstRect(for: uiRange)
                let keyboardTop = self.textView.convert(self.view.keyboardLayoutGuide.layoutFrame, from: self.view).minY
                let viewport = CGRect(
                    x: 0, y: 0,
                    width: self.textView.bounds.width,
                    height: max(0, min(self.textView.bounds.height, keyboardTop))
                )
                return rect.intersects(viewport) && rect.width > 0 && rect.height > 0
            }
        )
        jumpOverlay.show(jumpTargets, in: textView)
    }

    private func completeJump(to target: FlashJumpTarget) {
        stopJump(restoreEditor: true)
        controller.jump(toUTF16Offset: target.range.location)
        EditorHaptics.modeEnter()
    }

    private func stopJump(restoreEditor: Bool) {
        guard jumpActive || jumpField.isFirstResponder else { return }
        jumpActive = false
        jumpTargets = []
        jumpOverlay.clear()
        jumpField.text = nil
        jumpField.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.16)
        jumpField.resignFirstResponder()
        if restoreEditor { textView.becomeFirstResponder() }
    }

    // MARK: Highlight

    private func highlightSoon() {
        highlightWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            SyntaxHighlighter.apply(
                to: self.textView,
                language: EditorSettings.shared.runLanguage,
                fontSize: CGFloat(EditorSettings.shared.fontSize)
            )
        }
        highlightWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
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
        stopJump(restoreEditor: false)
        persistSoon()
        gutter.reload()
        controller.clearPreferredColumn()
        highlightSoon()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        gutter.reload()
        if !inputMode.isSelecting {
            controller.syncAnchorFromSelection()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        gutter.reload()
        refreshJump()
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
        field.textContentType = UITextContentType(rawValue: "")
        if #available(iOS 17.0, *) {
            field.inlinePredictionType = .no
        }
        field.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        field.returnKeyType = .search
        field.delegate = self
        field.addTarget(self, action: #selector(goNext), for: .primaryActionTriggered)

        let prev = UIButton(type: .system)
        prev.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prev.addTarget(self, action: #selector(goPrev), for: .touchUpInside)
        let next = UIButton(type: .system)
        next.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        next.addTarget(self, action: #selector(goNext), for: .touchUpInside)
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
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
