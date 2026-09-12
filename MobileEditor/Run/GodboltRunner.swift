import Foundation

struct RunResult {
    /// Combined program output (stdout + stderr lines, in order).
    let display: String
    let exitCode: Int
    let succeeded: Bool
    let summary: String
}

enum RunError: LocalizedError {
    case unreachable
    case badResponse
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .unreachable:
            return "Couldn't reach the run server. Check your connection and try again."
        case .badResponse:
            return "The run server answered in a way I don't understand."
        case .serverMessage(let message):
            return message
        }
    }
}

/// Executes buffer text via Compiler Explorer's execution API.
/// No keys, no backend of ours. Compiler ids are pinned; see RunLanguage.
final class GodboltRunner {
    static let shared = GodboltRunner()

    private let base = URL(string: "https://godbolt.org/api/compiler")!
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    func run(language: RunLanguage, code: String) async throws -> RunResult {
        guard let compiler = language.godboltCompiler else { throw RunError.badResponse }
        let request = CompileRequest(
            source: code,
            compiler: compiler,
            options: CompileOptions(
                userOptions: [],
                executeParameters: ExecuteParameters(args: [], stdin: ""),
                compilerOptions: ["executorRequest": true],
                filters: ["execute": true],
                tools: [],
                libraries: []
            ),
            lang: language.godboltLang,
            allowStoreCodeDebug: true
        )
        var urlRequest = URLRequest(url: base.appendingPathComponent("\(compiler)/compile"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw error.code == .cancelled ? error : RunError.unreachable
        } catch is CancellationError {
            throw CancellationError()
        }
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw RunError.serverMessage("The run server refused the request (HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)).")
        }
        let decoded: CompileResponse
        do {
            decoded = try JSONDecoder().decode(CompileResponse.self, from: data)
        } catch {
            throw RunError.badResponse
        }
        return summarize(decoded)
    }

    // MARK: - Result

    private func summarize(_ response: CompileResponse) -> RunResult {
        // Compiled languages report here; interpreted ones usually do too.
        var lines = (response.stdout ?? []).map(\.text) + (response.stderr ?? []).map(\.text)
        var code = response.code ?? -1
        // Fall back to the executor payload when the top level is empty.
        if lines.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
           let exec = response.execResult {
            let execLines = (exec.stdout ?? []).map(\.text) + (exec.stderr ?? []).map(\.text)
            if !execLines.isEmpty {
                lines = execLines
                code = exec.code ?? code
            }
        }
        let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let display = text.isEmpty ? (code == 0 ? "(no output)" : "(failed with no output)") : text
        let ok = code == 0
        return RunResult(display: display, exitCode: code, succeeded: ok, summary: ok ? "Exit 0" : "Exit \(code)")
    }
}

// MARK: - Wire types

private struct CompileRequest: Encodable {
    let source: String
    let compiler: String
    let options: CompileOptions
    let lang: String
    let allowStoreCodeDebug: Bool
}

private struct CompileOptions: Encodable {
    let userOptions: [String]
    let executeParameters: ExecuteParameters
    let compilerOptions: [String: Bool]
    let filters: [String: Bool]
    let tools: [String]
    let libraries: [String]
}

private struct ExecuteParameters: Encodable {
    let args: [String]
    let stdin: String
}

private struct CompileResponse: Decodable {
    let code: Int?
    let stdout: [OutputLine]?
    let stderr: [OutputLine]?
    let execResult: ExecResult?
}

private struct ExecResult: Decodable {
    let code: Int?
    let stdout: [OutputLine]?
    let stderr: [OutputLine]?
}

private struct OutputLine: Decodable {
    let text: String
}
