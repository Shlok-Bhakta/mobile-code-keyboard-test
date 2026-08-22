import UIKit

enum EditorHaptics {
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() {
        impact.prepare()
        selection.prepare()
    }

    static func modeEnter() {
        guard EditorSettings.shared.hapticsEnabled else { return }
        impact.impactOccurred(intensity: 0.7)
    }

    static func selectionStart() {
        guard EditorSettings.shared.hapticsEnabled else { return }
        notify.notificationOccurred(.success)
    }

    static func wordBoundary() {
        guard EditorSettings.shared.hapticsEnabled else { return }
        selection.selectionChanged()
    }
}
