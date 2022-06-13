import SwiftUI
import ContentPass

struct DashboardView: UIViewRepresentable {
    let dashboard: ContentPassDashboardView

    func makeUIView(context: Context) -> ContentPassDashboardView {
        return dashboard
    }

    func updateUIView(_ uiView: ContentPassDashboardView, context: Context) {

    }
}
