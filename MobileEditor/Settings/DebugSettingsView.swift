import SwiftUI

struct DebugSettingsView: View {
    @State private var delay = EditorSettings.shared.longPressDelay
    @State private var haptics = EditorSettings.shared.hapticsEnabled
    @State private var indent = Double(EditorSettings.shared.indentWidth)
    @State private var wrap = EditorSettings.shared.lineWrap
    @State private var navMomentary = EditorSettings.shared.navMomentary
    @State private var symMomentary = EditorSettings.shared.symMomentary
    @State private var fontSize = EditorSettings.shared.fontSize
    @State private var useTabs = EditorSettings.shared.useTabs
    @State private var runLanguage = EditorSettings.shared.runLanguage

    var onChange: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Run") {
                    Picker("Language", selection: $runLanguage) {
                        ForEach(RunLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .onChange(of: runLanguage) { _, new in
                        EditorSettings.shared.runLanguage = new
                        onChange()
                    }
                    Text("Sets the runner and highlighting. The editing bar stays the same.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Modes") {
                    Toggle("NAV momentary", isOn: $navMomentary)
                        .onChange(of: navMomentary) { _, new in EditorSettings.shared.navMomentary = new }
                    Toggle("SYM momentary", isOn: $symMomentary)
                        .onChange(of: symMomentary) { _, new in EditorSettings.shared.symMomentary = new }
                    stepper("NAV/SYM delay (s)", value: $delay, range: 0...0.4, step: 0.05) {
                        EditorSettings.shared.longPressDelay = delay
                    }
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in EditorSettings.shared.hapticsEnabled = new }
                }
                Section("Editor") {                    stepper("Indent width", value: $indent, range: 2...8, step: 2) {
                        EditorSettings.shared.indentWidth = Int(indent)
                    }
                    Toggle("Use tabs", isOn: $useTabs)
                        .onChange(of: useTabs) { _, new in EditorSettings.shared.useTabs = new }
                    Toggle("Wrap lines", isOn: $wrap)
                        .onChange(of: wrap) { _, new in
                            EditorSettings.shared.lineWrap = new
                            onChange()
                        }
                    stepper("Font size", value: $fontSize, range: 12...22, step: 1) {
                        EditorSettings.shared.fontSize = fontSize
                        onChange()
                    }
                }
            }
            .navigationTitle("Tune")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }

    private func stepper(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, save: @escaping () -> Void) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(0...2))))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .onChange(of: value.wrappedValue) { _, _ in save() }
    }
}
