import UIKit
import WebKit
import os.log

let webViewPopupLog = OSLog(subsystem: "de.contentpass.ContentPass", category: "WebViewPopup")

/// A `WKWebView` confined to contentpass.net/contentpass.com: navigation to
/// those domains or any of their subdomains proceeds normally. Navigation to
/// any other host dismisses this view controller and reports the destination
/// via `onLeaveContentpass` instead of loading it.
final class WebViewPopupViewController: UIViewController {
    private static let contentpassBaseDomains = ["contentpass.net", "contentpass.com"]

    private static func isContentpassHost(_ host: String) -> Bool {
        contentpassBaseDomains.contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    private let url: URL
    private let onLeaveContentpass: (URL) -> Void
    private var webView: WKWebView!

    init(url: URL, onLeaveContentpass: @escaping (URL) -> Void) {
        self.url = url
        self.onLeaveContentpass = onLeaveContentpass
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.webView = webView
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: url))
    }

    private func shouldLoad(_ url: URL) -> Bool {
        guard let host = url.host, Self.isContentpassHost(host) else {
            os_log(
                "Popup leaving contentpass.net/contentpass.com at %{public}@ — dismissing and handing back to host app",
                log: webViewPopupLog,
                type: .debug,
                url.absoluteString
            )
            dismiss(animated: true) { [onLeaveContentpass] in
                onLeaveContentpass(url)
            }
            return false
        }
        os_log("Popup staying on contentpass.net/contentpass.com: %{public}@", log: webViewPopupLog, type: .debug, url.absoluteString)
        return true
    }
}

extension WebViewPopupViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        os_log("Popup navigation requested: %{public}@", log: webViewPopupLog, type: .debug, url.absoluteString)
        decisionHandler(shouldLoad(url) ? .allow : .cancel)
    }

    // Links with target="_blank" (and window.open calls) have no target frame, so WebKit asks
    // for a brand new WKWebView here instead of running the navigation through
    // decidePolicyFor. Resolve it the same way and, if allowed, load it in this webview rather
    // than handing back a second live WKWebView.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        os_log("Popup window.open/target=_blank requested: %{public}@", log: webViewPopupLog, type: .debug, url.absoluteString)
        if shouldLoad(url) {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
