import UIKit
import os.log

/// Presents a contentpass.net web flow — such as login or payment — in a native sheet that
/// slides up over three quarters of `presentingViewController`, and hands control back to your
/// app the moment the flow navigates away from contentpass.net.
///
/// Use this when a webview you already control (for example one showing a publisher's site)
/// tries to open a `my.contentpass.net` URL: instead of loading that URL in your own webview,
/// pass it here. Navigation within contentpass.net or contentpass.com (including their
/// subdomains, and including inside an iframe — such as the third-party-cookie check on
/// `autologin.contentpass.com`) stays in the sheet; navigating to any other host dismisses the
/// sheet and calls `onLeaveContentpass` with that destination URL so you can load it in your
/// own webview.
///
/// This is independent of `ContentPass`'s authentication state and doesn't require a
/// `contentpass_configuration.json` in your bundle.
@available(iOS 16.0, *)
public enum ContentPassWebViewPopup {
    /// Presents `url` in a sheet sliding up over `presentingViewController`.
    ///
    /// - Parameters:
    ///   - url: The contentpass.net URL to open in the sheet.
    ///   - presentingViewController: The view controller to present the sheet from.
    ///   - onLeaveContentpass: Called with the destination URL as soon as the sheet's webview
    ///     navigates to a host other than `my.contentpass.net` or `www.contentpass.net`. The
    ///     sheet has already been dismissed by the time this is called.
    public static func present(
        url: URL,
        from presentingViewController: UIViewController,
        onLeaveContentpass: @escaping (URL) -> Void
    ) {
        os_log("Presenting contentpass popup for %{public}@", log: webViewPopupLog, type: .debug, url.absoluteString)
        let popup = WebViewPopupViewController(url: url, onLeaveContentpass: onLeaveContentpass)
        if let sheet = popup.sheetPresentationController {
            let threeQuarters = UISheetPresentationController.Detent.custom(identifier: .threeQuarters) { context in
                context.maximumDetentValue * 0.75
            }
            sheet.detents = [threeQuarters]
            sheet.prefersGrabberVisible = true
        }
        presentingViewController.present(popup, animated: true)
    }
}

@available(iOS 16.0, *)
private extension UISheetPresentationController.Detent.Identifier {
    static let threeQuarters = Self("threeQuarters")
}
