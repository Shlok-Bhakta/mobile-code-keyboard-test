import SwiftUI

struct RunConsoleView: View {
    @ObservedObject var session: RunSession
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    statusDot
                    Text(session.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(session.language.tag)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }

                ScrollView {
                    Text(session.output.isEmpty ? " " : session.output)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(10)
                }
                .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .frame(maxHeight: .infinity)

                HStack {
                    if session.status == .running {
                        ProgressView()
                    }
                    Spacer()
                    Button("Run again") { session.start() }
                        .disabled(session.status == .running || session.status == .info)
                }
            }
            .padding()
            .navigationTitle("Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        switch session.status {
        case .running:
            Circle().fill(.blue).frame(width: 10, height: 10)
        case .passed:
            Circle().fill(.green).frame(width: 10, height: 10)
        case .failed:
            Circle().fill(.red).frame(width: 10, height: 10)
        case .info:
            Circle().fill(.gray).frame(width: 10, height: 10)
        }
    }
}
