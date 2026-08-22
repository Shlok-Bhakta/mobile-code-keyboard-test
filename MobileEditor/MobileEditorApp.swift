import SwiftUI

@main
struct MobileEditorApp: App {
    var body: some Scene {
        WindowGroup {
            EditorScreen()
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

struct EditorScreen: View {
    var body: some View {
        EditorRepresentable()
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct EditorRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> EditorViewController {
        EditorViewController()
    }

    func updateUIViewController(_ uiViewController: EditorViewController, context: Context) {}
}
