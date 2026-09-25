import SwiftUI
import WebKit
import os

private let webViewLog = Logger(subsystem: "de.contentpass.WebViewPopupExample", category: "WebView")

/// Thin `WKWebView` wrapper whose only job is to hand every navigation to `shouldLoad`
/// before it happens, so the owning view can redirect it elsewhere instead.
struct WebView: UIViewRepresentable {
    let url: URL
    var shouldLoad: (URL) -> Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.load(url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.shouldLoad = shouldLoad
        if url != context.coordinator.lastLoadedURL {
            context.coordinator.load(url, in: webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldLoad: shouldLoad)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var shouldLoad: (URL) -> Bool
        private(set) var lastLoadedURL: URL?

        init(shouldLoad: @escaping (URL) -> Bool) {
            self.shouldLoad = shouldLoad
        }

        func load(_ url: URL, in webView: WKWebView) {
            lastLoadedURL = url
            webView.load(URLRequest(url: url))
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            webViewLog.debug("Navigation requested: \(url.absoluteString, privacy: .public)")
            if shouldLoad(url) {
                lastLoadedURL = url
                webViewLog.debug("Allowing navigation: \(url.absoluteString, privacy: .public)")
                decisionHandler(.allow)
            } else {
                webViewLog.debug("Cancelling navigation, handled elsewhere: \(url.absoluteString, privacy: .public)")
                decisionHandler(.cancel)
            }
        }

        // Links with target="_blank" (and window.open calls) have no target frame, so WebKit
        // asks for a brand new WKWebView here instead of running the navigation through
        // decidePolicyFor. Resolve it the same way and, if allowed, load it in this webview
        // rather than handing back a second live WKWebView.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            webViewLog.debug("window.open/target=_blank requested: \(url.absoluteString, privacy: .public)")
            if shouldLoad(url) {
                load(url, in: webView)
            }
            return nil
        }
    }
}
