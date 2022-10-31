//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import WebKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

class JSWebView: PlatformView {

    // MARK: - Data Types

    typealias JavaScript = String

    /**
     In the event that the page load hasn't completed before the first JavaScript
     function is invoked, we must store the invocation and only request that the
     webView interpret it once the page has fully loaded.
     */
    private struct PendingJavascriptInvocation {
        let coalescingIdentifier: String?
        let javascript: JavaScript
        let completionHandler: ((Any?, Error?) -> Void)?
    }

    // MARK: - Internal Properties

    let webView = WKWebView()


    // MARK: - Private Properties

    private var observers = [NSObjectProtocol]()

    private var pendingInvocations = [PendingJavascriptInvocation]()

    private var isInitialLoadComplete = false { didSet { processPendingInvocations() } }

    private var isBackgrounded = false { didSet { processPendingInvocations() } }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setup() {
#if canImport(UIKit)
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
            webView.backgroundColor = .systemBackground
            webView.scrollView.backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
            webView.backgroundColor = .white
            webView.scrollView.backgroundColor = .white
        }
        webView.isOpaque = false

        webView.scrollView.isScrollEnabled = false
#endif
#if canImport(AppKit)
#endif
        webView.navigationDelegate = self
        addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leftAnchor.constraint(equalTo: leftAnchor),
            webView.rightAnchor.constraint(equalTo: rightAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        addBackgroundGuards()
    }

    // MARK: - Internal Functions

    /**
     Enqueues a javascript command for execution.

     - parameter javascript: A JavaScript command as a string.
     - parameter coalescingIdentifier: An optional identifier which, if present will
       replace all other enqueued invocations with the same ID. This is useful if the
       newly enqueued invocation should completely supersede any other previously enqueued
       but not yet executed invocations of the same function.
     - parameter completionHandler: A completion handler which will be invoked
     */
    func enqueueInvocation(javascript: JavaScript,
                           coalescingIdentifier: String? = nil,
                           completionHandler: ((Result<Any?, Error>) -> Void)? = nil) {
        let completionHandlerShim: (Any?, Error?) -> Void = { result, error in
            defer {
                // Lets map our old school (Any?, Error?) response to the newer swift Result type.
                if let error = error {
                    completionHandler?(.failure(error))
                } else {
                    completionHandler?(.success(result))
                }
            }

            guard let error = error else { return }
            let nsError = error as NSError
            guard nsError.domain == WKErrorDomain, let code = WKError.Code(rawValue: nsError.code) else { return }

            switch code {
            case .javaScriptExceptionOccurred, .javaScriptResultTypeIsUnsupported:
                // There is no reason to fail with these errors. We control the inputs and outputs
                // and all resources are fully-offline. This is likely caused by incorrectly packaged
                // webpack content or drift between the JS code and the JS function names/signatures
                // hardcoded in Swift.
                print("VisJSWebView: Failed to evaluate javascript: \(error)")
            case .unknown:
                print("VisJSWebView: an unknown error occurred: \(error)")
            case .webContentProcessTerminated:
                print("VisJSWebView: web content process was terminated. Possibly out of memory or terminated for " +
                    "battery optimization (i.e. not in visible view hierarchy when requested to evaluate JS): \(error)")
            case .webViewInvalidated:
                // Web view has been torn down. We can safely ignore this message.
                break
            case .contentRuleListStoreCompileFailed, .contentRuleListStoreLookUpFailed,
                 .contentRuleListStoreRemoveFailed, .contentRuleListStoreVersionMismatch:
                break
            default:
                // .attributedStringContentFailedToLoad (iOS 13)
                // .attributedStringContentLoadTimedOut (iOS 13)
                break
            }
        }

        if let coalescingIdentifier = coalescingIdentifier {
            pendingInvocations.removeAll {
                $0.coalescingIdentifier == coalescingIdentifier
            }
        }

        pendingInvocations += [PendingJavascriptInvocation(coalescingIdentifier: coalescingIdentifier,
                                                           javascript: javascript,
                                                           completionHandler: completionHandlerShim)]
        processPendingInvocations()
    }

    // MARK: - Private Functions

    /**
     We don't want to execute JS commands if we're in the background.
     */
    private func addBackgroundGuards() {
#if canImport(UIKit)
        let didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main) { [weak self] (_) in self?.isBackgrounded = false }

        let willResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main) { [weak self] (_) in self?.isBackgrounded = true }

        observers = [didBecomeActiveObserver, willResignActiveObserver]
#endif
#if canImport(AppKit)
#endif
    }

    private func processPendingInvocations() {
        guard isInitialLoadComplete, !isBackgrounded else { return }

        pendingInvocations.forEach {
            webView.evaluateJavaScript($0.javascript, completionHandler: $0.completionHandler)
        }

        pendingInvocations.removeAll()
    }

}

//MARK: - WKNavigationDelegate

extension JSWebView: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isInitialLoadComplete = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("JSWebView: didFailNavigationWithError: %@", error)
    }

}
