import SwiftUI

struct DebugSettingsView: View {
    @State private var horizontal = EditorSettings.shared.horizontalThreshold
    @State private var vertical = EditorSettings.shared.verticalThreshold
    @State private var delay = EditorSettings.shared.longPressDelay
    @State private var haptics = EditorSettings.shared.hapticsEnabled
    @State private var indent = Double(EditorSettings.shared.indentWidth)
    @State private var wrap = EditorSettings.shared.lineWrap
    @State private var navMomentary = EditorSettings.shared.navMomentary
    @State private var symMomentary = EditorSettings.shared.symMomentary
    @State private var trackpadSelect = EditorSettings.shared.trackpadSelectWithNav
    @State private var accel = EditorSettings.shared.accelerationEnabled
    @State private var medium = EditorSettings.shared.mediumVelocity
    @State private var fast = EditorSettings.shared.fastVelocity
    @State private var fontSize = EditorSettings.shared.fontSize
    @State private var useTabs = EditorSettings.shared.useTabs

    var onChange: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Trackpad") {
                    stepper("Horizontal pt/char", value: $horizontal, range: 6...24, step: 1) {
                        EditorSettings.shared.horizontalThreshold = horizontal
                    }
                    stepper("Vertical pt/line", value: $vertical, range: 12...48, step: 2) {
                        EditorSettings.shared.verticalThreshold = vertical
                    }
                    Toggle("Acceleration", isOn: $accel)
                        .onChange(of: accel) { _, new in EditorSettings.shared.accelerationEnabled = new }
                    stepper("Medium velocity", value: $medium, range: 200...800, step: 50) {
                        EditorSettings.shared.mediumVelocity = medium
                    }
                    stepper("Fast velocity (word)", value: $fast, range: 400...1600, step: 50) {
                        EditorSettings.shared.fastVelocity = fast
                    }
                    Toggle("NAV + trackpad selects", isOn: $trackpadSelect)
                        .onChange(of: trackpadSelect) { _, new in EditorSettings.shared.trackpadSelectWithNav = new }
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
                Section("Editor") {
                    stepper("Indent width", value: $indent, range: 2...8, step: 2) {
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
