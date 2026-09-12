import UIKit

/// Lightweight regex highlighting. Runs off the main thread, applies
/// attribute-only edits with undo registration off, caret preserved.
enum SyntaxHighlighter {
    /// Full pass on `textView` for `language`. Safe to call often; stale
    /// results (text changed mid-pass) are dropped.
    static func apply(to textView: UITextView, language: RunLanguage, fontSize: CGFloat) {
        let snapshot = textView.text ?? ""
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        DispatchQueue.global(qos: .userInitiated).async {
            let spans = spans(for: snapshot as NSString, language: language)
            DispatchQueue.main.async {
                guard textView.text == snapshot else { return }
                let storage = textView.textStorage
                let full = NSRange(location: 0, length: storage.length)
                let selection = textView.selectedRange
                textView.undoManager?.disableUndoRegistration()
                storage.beginEditing()
                storage.addAttributes([.font: font, .foregroundColor: UIColor.label], range: full)
                for span in spans {
                    storage.addAttribute(.foregroundColor, value: span.color, range: span.range)
                }
                storage.endEditing()
                textView.undoManager?.enableUndoRegistration()
                let clamped = NSRange(
                    location: min(selection.location, storage.length),
                    length: min(selection.length, storage.length - min(selection.location, storage.length))
                )
                textView.selectedRange = clamped
                textView.typingAttributes = [.font: font, .foregroundColor: UIColor.label]
            }
        }
    }

    // MARK: - Rules

    struct Span {
        let range: NSRange
        let color: UIColor
    }

    private static func spans(for text: NSString, language: RunLanguage) -> [Span] {
        let rules = rules(for: language)
        var excluded: [NSRange] = []
        var out: [Span] = []
        // Strings and comments win: everything else stays out of their ranges.
        for rule in rules.exclusive {
            for range in matches(of: rule.pattern, in: text) {
                excluded.append(range)
                out.append(Span(range: range, color: rule.color))
            }
        }
        for rule in rules.token {
            for range in matches(of: rule.pattern, in: text) {
                guard !excluded.contains(where: { NSIntersectionRange($0, range).length > 0 }) else { continue }
                out.append(Span(range: range, color: rule.color))
            }
        }
        return out
    }

    private static func matches(of pattern: NSRegularExpression, in text: NSString) -> [NSRange] {
        let full = NSRange(location: 0, length: text.length)
        return pattern.matches(in: text as String, range: full).map { $0.range }
    }

    struct Rule {
        let pattern: NSRegularExpression
        let color: UIColor
    }

    struct Rules {
        /// Strings, comments: applied first, and they shadow everything else.
        let exclusive: [Rule]
        /// Keywords, types, numbers: skipped where they overlap the above.
        let token: [Rule]
    }

    private static func rx(_ pattern: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: [])
    }

    private static func words(_ list: [String]) -> String {
        "\\b(?:" + list.joined(separator: "|") + ")\\b"
    }
}

// MARK: - Per-language rules

private extension SyntaxHighlighter {
    static func rules(for language: RunLanguage) -> Rules {
        switch language {
        case .python: pythonRules
        case .typescript: typeScriptRules
        case .rust: rustRules
        case .markdown: markdownRules
        }
    }

    static var keywordColor: UIColor { .systemPink }
    static var stringColor: UIColor { .systemRed }
    static var commentColor: UIColor { .systemGreen }
    static var numberColor: UIColor { .systemBlue }
    static var typeColor: UIColor { .systemTeal }

    static var numberPattern: String {
        "\\b\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d[\\d_]*)?j?\\b"
    }

    static var pythonRules: Rules {
        let keywords = words([
            "and", "as", "assert", "async", "await", "break", "class", "continue",
            "def", "del", "elif", "else", "except", "finally", "for", "from",
            "global", "if", "import", "in", "is", "lambda", "nonlocal", "not",
            "or", "pass", "raise", "return", "try", "while", "with", "yield",
            "True", "False", "None",
        ])
        let builtins = words([
            "print", "len", "range", "str", "int", "float", "bool", "list",
            "dict", "set", "tuple", "enumerate", "zip", "map", "filter",
            "sorted", "sum", "min", "max", "abs", "open", "isinstance", "type",
        ])
        return Rules(
            exclusive: [
                Rule(pattern: rx("\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?'''|\"(?:\\\\.|[^\"\\\\\\n])*\"|'(?:\\\\.|[^'\\\\\\n])*'"), color: stringColor),
                Rule(pattern: rx("#[^\\n]*"), color: commentColor),
            ],
            token: [
                Rule(pattern: rx(keywords), color: keywordColor),
                Rule(pattern: rx(builtins), color: typeColor),
                Rule(pattern: rx(numberPattern), color: numberColor),
            ]
        )
    }

    static var typeScriptRules: Rules {
        let keywords = words([
            "break", "case", "catch", "class", "const", "continue", "debugger",
            "default", "delete", "do", "else", "enum", "export", "extends",
            "false", "finally", "for", "function", "if", "implements", "import",
            "in", "instanceof", "interface", "let", "new", "null", "return",
            "super", "switch", "this", "throw", "true", "try", "typeof",
            "undefined", "var", "void", "while", "with", "yield", "async",
            "await", "as", "from", "of", "satisfies", "declare", "namespace",
            "abstract", "readonly", "static", "get", "set", "type",
        ])
        let globals = words([
            "string", "number", "boolean", "any", "unknown", "never", "object",
            "symbol", "bigint", "console", "JSON", "Math", "Object", "String",
            "Number", "Boolean", "Array", "Promise", "Date", "Error",
        ])
        return Rules(
            exclusive: [
                Rule(pattern: rx("\"(?:\\\\.|[^\"\\\\\\n])*\"|'(?:\\\\.|[^'\\\\\\n])*'|`(?:\\\\.|[^`\\\\])*`"), color: stringColor),
                Rule(pattern: rx("//[^\\n]*|/\\*[\\s\\S]*?\\*/"), color: commentColor),
            ],
            token: [
                Rule(pattern: rx(keywords), color: keywordColor),
                Rule(pattern: rx(globals), color: typeColor),
                Rule(pattern: rx("\\b0[xX][\\da-fA-F_]+\\b|" + numberPattern), color: numberColor),
            ]
        )
    }

    static var rustRules: Rules {
        let keywords = words([
            "as", "async", "await", "break", "const", "continue", "crate",
            "dyn", "else", "enum", "extern", "false", "fn", "for", "if",
            "impl", "in", "let", "loop", "match", "mod", "move", "mut",
            "pub", "ref", "return", "self", "Self", "static", "struct",
            "super", "trait", "true", "type", "union", "unsafe", "use",
            "where", "while", "yield",
        ])
        let types = words([
            "i8", "i16", "i32", "i64", "i128", "u8", "u16", "u32", "u64",
            "u128", "isize", "usize", "f32", "f64", "bool", "char", "str",
            "String", "Vec", "Option", "Result", "Box", "Rc", "Arc", "HashMap",
        ])
        return Rules(
            exclusive: [
                // Double-quoted strings and exact char literals only. Bare
                // lifetimes ('a, 'static) are left alone on purpose: a loose
                // single-quote pattern would swallow code up to the next quote.
                Rule(pattern: rx("\"(?:\\\\.|[^\"\\\\\\n])*\"|'(?:\\\\.|[^'\\\\])'"), color: stringColor),
                Rule(pattern: rx("//[^\\n]*|/\\*[\\s\\S]*?\\*/"), color: commentColor),
            ],
            token: [
                Rule(pattern: rx(keywords), color: keywordColor),
                Rule(pattern: rx("\\b[A-Za-z_][A-Za-z0-9_]*!"), color: keywordColor),
                Rule(pattern: rx(types), color: typeColor),
                Rule(pattern: rx("\\b\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d[\\d_]*)?(?:u8|u16|u32|u64|u128|usize|i8|i16|i32|i64|i128|isize|f32|f64)?\\b"), color: numberColor),
            ]
        )
    }

    static var markdownRules: Rules {
        Rules(
            exclusive: [
                Rule(pattern: rx("`[^`\\n]+`"), color: stringColor),
            ],
            token: [
                Rule(pattern: rx("(?m)^#{1,6}\\s.*$"), color: .systemIndigo),
            ]
        )
    }
}
