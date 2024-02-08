// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import WebKit

protocol UserAgentProviding {
    var userAgent: String? { get }
    func updateUserAgent()
}

/// Upon `init`, `UserAgentProvider` creates a `WKWebView` instance from main thread to obtain
/// the user agent value by evaluating JavaScript "navigator.userAgent".
final class UserAgentProvider: UserAgentProviding {
    /// Only for obtaining the user agent value.
    private var webView: WKWebView?
    @Injected(\.taskDispatcher) private var taskDispatcher

    private(set) var userAgent: String?

    func updateUserAgent() {
        taskDispatcher.async(on: .main) { [weak self] in
            guard let self else { return }
            let webView = WKWebView()
            self.webView = webView
            webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, error in
                defer {
                    self?.webView = nil
                }

                guard error == nil, let result = result as? String else {
                    logger.error("Failed to obtain user agent with error: \(String(describing: error)), result: \(String(describing: result))")
                    return
                }

                self?.userAgent = result
            }
        }
    }
}
