import UIKit

final class CodeTextView: UITextView {
    var onReturn: (() -> Bool)?
    var onShouldChange: ((NSRange, String) -> Bool)?
    var controller: EditorController?

    init() {
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        layoutManager.allowsNonContiguousLayout = true
        let container = NSTextContainer(size: .zero)
        container.widthTracksTextView = false
        container.heightTracksTextView = false
        container.lineFragmentPadding = 4
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        super.init(frame: .zero, textContainer: container)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .systemBackground
        textColor = .label
        tintColor = .systemBlue
        alwaysBounceVertical = true
        alwaysBounceHorizontal = true
        keyboardDismissMode = .interactive
        autocapitalizationType = .none
        autocorrectionType = .no
        spellCheckingType = .no
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        keyboardType = .default
        keyboardAppearance = .default
        dataDetectorTypes = []
        allowsEditingTextAttributes = false
        adjustsFontForContentSizeCategory = false
        textContentType = nil
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        if #available(iOS 17.0, *) {
            inlinePredictionType = .no
        }
        if #available(iOS 18.0, *) {
            mathExpressionCompletionType = .no
        }
        applyFont()
        applyWrapping()
    }

    func applyFont() {
        let size = CGFloat(EditorSettings.shared.fontSize)
        let font = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        self.font = font
        typingAttributes = [
            .font: font,
            .foregroundColor: UIColor.label,
        ]
    }

    func applyWrapping() {
        let wrap = EditorSettings.shared.lineWrap
        textContainer.widthTracksTextView = wrap
        textContainer.lineBreakMode = wrap ? .byWordWrapping : .byClipping
        if wrap {
            let inset = textContainerInset
            let width = max(50, bounds.width - inset.left - inset.right - textContainer.lineFragmentPadding * 2)
            textContainer.size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            alwaysBounceHorizontal = false
            showsHorizontalScrollIndicator = false
        } else {
            textContainer.size = CGSize(width: 8000, height: CGFloat.greatestFiniteMagnitude)
            alwaysBounceHorizontal = true
            showsHorizontalScrollIndicator = true
        }
        layoutManager.ensureLayout(for: textContainer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if EditorSettings.shared.lineWrap {
            applyWrapping()
        }
    }

    override func paste(_ sender: Any?) {
        if let string = UIPasteboard.general.string {
            insertText(string)
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: "z", modifierFlags: .command, action: #selector(handleUndo)),
            UIKeyCommand(input: "z", modifierFlags: [.command, .shift], action: #selector(handleRedo)),
            UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(handleCopy)),
            UIKeyCommand(input: "x", modifierFlags: .command, action: #selector(handleCut)),
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(handlePaste)),
            UIKeyCommand(input: "a", modifierFlags: .command, action: #selector(handleSelectAll)),
            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(handleFind)),
        ]
    }

    override var canBecomeFirstResponder: Bool { true }

    @objc private func handleUndo() { controller?.undo() }
    @objc private func handleRedo() { controller?.redo() }
    @objc private func handleCopy() { controller?.copy() }
    @objc private func handleCut() { controller?.cut() }
    @objc private func handlePaste() { controller?.paste() }
    @objc private func handleSelectAll() { controller?.selectAll() }

    var onFind: (() -> Void)?
    @objc private func handleFind() { onFind?() }
}
