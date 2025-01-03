//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

#if canImport(WebKit)
import WebKit
#endif

import DittoSwift

#if canImport(UIKit)
import UIKit
public typealias PlatformView = UIView
public typealias PlatformViewController = UIViewController
#endif

#if !targetEnvironment(macCatalyst)
#if canImport(AppKit)
import AppKit
public typealias PlatformView = NSView
public typealias PlatformViewController = NSViewController
#endif
#endif

/**
 The `DittoPresenceView` offers a visualization of the current
 state of peers in a ditto mesh.

 A `DittoPresenceView` can be added to any view as a child or
 alternatively, it can be added as a view controller.

 ```swift
 import DittoSwift
 import DittoSwiftPresenceViewer

 let ditto: Ditto

 func showPresence() {
 let presenceView = DittoPresenceView(ditto: ditto)
 // maybe add it to an existing view
 self.view.addSubview(presenceView)

 // or add it as a view controller
 let viewController = DittoPresenceView(ditto: ditto).viewController
 present(viewController: viewController, animated: true)
 }
 ```
 */
public class DittoPresenceView: PlatformView {

    // MARK: Public Properties

    /**
     The `Ditto` object for which you would like to visualize presence data.
     The `DittoPresenceView` will not display any presence information
     until the `ditto` property has been set.
     */
    public weak var ditto: Ditto? {
        willSet {
            if (ditto !== newValue) {
                self.stopObservingPresence()
            }
        }

        didSet {
            if (oldValue !== ditto) {
                self.startObservingPresence()
            }
        }
    }

    deinit {
        stopObservingPresence()
        webView.removeFromSuperview()
        _vc = nil
    }

    /**
     Returns a `UIViewController` containing this view.
     */
    public var viewController: PlatformViewController {
        // Note that this is a highly unusual inversion of the typical
        // `UIViewController` → `UIView` relationship based on the original
        // specification for this work(https://github.com/getditto/ditto/issues/789)
        // but it seems to make for a nice plug-and-play API.
        //
        // The inversion will likely trip up more experienced native iOS
        // developers, but they're also the group likely to be designing their
        // own `UIViewControllers` which renders this a non-issue in most cases.
        //
        // Also note that we can't hold the view controller strongly here because
        // this would lead to a retain cycle. Therefore, we'll hold it weakly
        // and create a new one whenever the previous one is dealloced:
        if let vc = self._vc {
            return vc
        }

        let vc = DittoPresenceViewController(view: self)
        self._vc = vc
        return vc
    }

    // MARK: Private Properties

    private var peersObserver: DittoObserver?

    private var webView = VisJSWebView()

    private weak var _vc: DittoPresenceViewController?

    // MARK: Initializer

    /**
     Initializes a new `DittoPresenceView`.

     - Parameter ditto: A reference to the `Ditto` which you would like
     to visualize presence status for.
     */
    public convenience init(ditto: Ditto) {
        self.init(frame: .zero)
        self.ditto = ditto
        startObservingPresence()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }


    // MARK: Private Functions

    private func setup() {

#if canImport(UIKit)
        backgroundColor = .clear
#endif

        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leftAnchor.constraint(equalTo: leftAnchor),
            webView.rightAnchor.constraint(equalTo: rightAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func startObservingPresence() {
        if let ditto = ditto {
            self.peersObserver = ditto.presence.observe { presenceGraph in
                let encoder = JSONEncoder()
                encoder.dataEncodingStrategy = .custom({ data, enc in
                    var container = enc.unkeyedContainer()
                    data.forEach { byte in
                        try! container.encode(byte)
                    }
                })
                let presenceGraphJSON = try! encoder.encode(presenceGraph)
                let presenceGraphJSONString = String(data: presenceGraphJSON, encoding: .utf8)!
                DispatchQueue.main.async { [weak self] in
                    self?.webView.updateNetwork(json: presenceGraphJSONString, completionHandler: nil)
                }
            }
        }
        //        // Comment out the ditto observer above and toggle following to test presence with
        //        // fake data. Several different mock drivers exist:
        //        // - runFrequentConnectionChanges()
        //        // - runFrequentRSSIChanges()
        //        // - runLargeMesh()
        //        // - runMassiveMesh()
        //        MockData.runLargeMesh() { [weak self] json in
        //            self?.webView.updateNetwork(json: json, completionHandler: nil)
        //        }
    }

    private func stopObservingPresence() {
        peersObserver?.stop()
        peersObserver = nil
    }
}
