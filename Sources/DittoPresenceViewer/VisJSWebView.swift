//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation

#if canImport(WebKit)
import WebKit
#endif

/**
 `VisJSWebView` is a simple `UIView` subclass containing a `WKWebView` which it
 manages. The `VisJSWebView` ensures that any attempt to execute javascript will
 be delayed until the initial page load is complete.
 */
class VisJSWebView: JSWebView {

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let bundle = Bundle.module
        let webDistDirURL = bundle.bundleURL.appendingPathComponent("dist")
        let htmlURL = bundle.url(forResource: "index", withExtension: "html")!
        let htmlString = try! String(contentsOf: htmlURL, encoding: .utf8)
#if canImport(WebKit)
        webView.loadHTMLString(htmlString, baseURL: webDistDirURL)
#endif
    }

    // MARK: - Functions

    /**
     Updates the vis.js network visualization. If the page is not yet loaded, the javascript
     will be enqueued and executed as soon as the page load is complete.

     - Parameters:
       - json: A V2 presence payload as JSON string containing all nodes
         and edges (not just the updated nodes/edges).
       - completionHandler: An optional completion handler to be invoked when the update
         completes. The completion handler always runs on the main thread.
     */
    func updateNetwork(json: String, completionHandler: (() -> Void)? = nil) {
        // To avoid characters in our JSON string being interpreted as JS, we pass our JSON
        // as base64 encoded string and decode on the other side.
        let base64JSON = json.data(using: .utf8)!.base64EncodedString()

        enqueueInvocation(javascript: "Presence.updateNetwork('\(base64JSON)');",
                          coalescingIdentifier: "updateNetwork") { result in
            if case let .failure(error) = result {
                print("VisJSWebView: failed to update network: %@", error)
            }

            // In release mode, we should never fail (we control all inputs and outputs an
            // all resources are offline). An assertion crash should have triggered during
            // unit tests or development testing if our JS was incorrectly packaged or if
            // there was drift between the JS code and the JS function names/signatures
            // hardcoded in Swift.
            //
            // We log to the console to help catch errors during active development, but
            // otherwise always report success to our caller.
            completionHandler?()
        }
    }

}
