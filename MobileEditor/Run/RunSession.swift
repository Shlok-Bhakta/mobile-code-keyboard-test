import Combine
import Foundation

enum RunStatus {
    case running
    case passed
    case failed
    case info
}

/// Owns one run: the code, the language, and the observable outcome.
/// The console view only renders this.
final class RunSession: ObservableObject {
    @Published private(set) var status: RunStatus = .running
    @Published private(set) var summary = "Running…"
    @Published private(set) var output = ""

    let language: RunLanguage
    private let code: String
    private var task: Task<Void, Never>?

    init(code: String, language: RunLanguage) {
        self.code = code
        self.language = language
    }

    static func info(language: RunLanguage, message: String) -> RunSession {
        let session = RunSession(code: "", language: language)
        session.status = .info
        session.summary = "Nothing to run"
        session.output = message
        return session
    }

    func start() {
        task?.cancel()
        status = .running
        summary = "Running…"
        output = ""
        task = Task { await execute() }
    }

    func cancel() {
        task?.cancel()
    }

    @MainActor
    private func execute() async {
        do {
            let result = try await GodboltRunner.shared.run(language: language, code: code)
            guard !Task.isCancelled else { return }
            output = result.display
            summary = result.summary
            status = result.succeeded ? .passed : .failed
            EditorHaptics.runFinished(success: result.succeeded)
            EditorLog.event(result.succeeded ? "RUN_PASS" : "RUN_FAIL")
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            status = .failed
            summary = "Run failed"
            output = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            EditorLog.event("RUN_ERROR")
        }
    }
}
