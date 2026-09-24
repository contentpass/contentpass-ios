import ContentPass
import SwiftUI
import UIKit
import os

private let initialURL = URL(string: "https://cmp-didomi.contenttimes.net/")!
private let popupTriggerHost = "my.contentpass.net"
private let handoverLog = Logger(subsystem: "de.contentpass.WebViewPopupExample", category: "Handover")

struct ContentView: View {
    @State private var mainURL = initialURL

    var body: some View {
        WebView(url: mainURL, shouldLoad: handleMainNavigation)
            .ignoresSafeArea()
    }

    /// The main webview never loads `my.contentpass.net` itself; that host opens in the
    /// ContentPass SDK's popup sheet instead.
    private func handleMainNavigation(_ url: URL) -> Bool {
        guard url.host == popupTriggerHost, let presenter = UIApplication.shared.keyWindowRootViewController else {
            return true
        }
        handoverLog.debug("Main webview handing off to contentpass popup: \(url.absoluteString, privacy: .public)")
        ContentPassWebViewPopup.present(url: url, from: presenter) { destination in
            handoverLog.debug("Popup handed back to main webview: \(destination.absoluteString, privacy: .public)")
            mainURL = destination
        }
        return false
    }
}

private extension UIApplication {
    var keyWindowRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}
