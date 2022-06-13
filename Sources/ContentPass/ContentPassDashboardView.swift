//
//  File.swift
//  
//
//  Created by Paul Weber on 10.06.22.
//

import WebKit

public class ContentPassDashboardView: WKWebView {
    internal convenience init(with url: URL) {
        self.init(frame: .zero, configuration: .init())

        let request = URLRequest(url: url)
        load(request)
    }

    internal override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }

    required internal init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
