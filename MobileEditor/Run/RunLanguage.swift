import Foundation

/// Language of the current buffer. Drives the runner and the highlighter.
/// The editing bar itself stays language-blind.
enum RunLanguage: String, CaseIterable, Identifiable {
    case python
    case typescript
    case rust
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .python: "Python"
        case .typescript: "TypeScript"
        case .rust: "Rust"
        case .markdown: "Markdown"
        }
    }

    /// Short tag shown in the chrome.
    var tag: String {
        switch self {
        case .python: "py"
        case .typescript: "ts"
        case .rust: "rs"
        case .markdown: "md"
        }
    }

    /// Godbolt compiler id, or nil when not runnable.
    var godboltCompiler: String? {
        switch self {
        case .python: "python313"
        case .typescript: nil
        case .rust: "r1980"
        case .markdown: nil
        }
    }

    /// Godbolt language id for the compile request.
    var godboltLang: String {
        switch self {
        case .python: "python"
        case .typescript: "typescript"
        case .rust: "rust"
        case .markdown: "markdown"
        }
    }

    var fileExtension: String {
        switch self {
        case .python: "py"
        case .typescript: "ts"
        case .rust: "rs"
        case .markdown: "md"
        }
    }

    var isRunnable: Bool { godboltCompiler != nil }

    var notRunnableMessage: String {
        switch self {
        case .typescript:
            "TypeScript doesn't run in this build yet — pick the Python or Rust sample to run."
        case .markdown:
            "Markdown isn't runnable. Pick a code sample from the documents menu to run."
        case .python, .rust:
            ""
        }
    }
}
