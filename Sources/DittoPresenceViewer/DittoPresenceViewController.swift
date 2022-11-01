//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/**
 The `DittoPresenceViewController` is an internal view controller designed
 to wrap a `DittoPresenceView`.

 This VC will attempt to autoconfigure to the best of its ability to support a
 variety of plug-and-play use cases:
 - In all situations:
   - A navigation bar will be displayed, regardless of presentation within a
     `UINavigationController`
   - A localized title will be set in the navigation bar
 - If pushed onto a navigation controller:
   - the back button will be supported if a previous view controller existed on
     the stack
   - a close button will be added if a left navigation button doesn't already
     exist (in this situation we can safely assume we were presented in a
     UINavigationController only to provide us with a UINavigationBar as a place
     for our title and defensively in the event that we tried to push further
     content).
 - If presented modally:
   - a close button will be added alongside any swipe to dismiss gestures to
     ensure that the modal view is accessible to assistive technologies.
 */
final class DittoPresenceViewController: PlatformViewController {

    // MARK: Constants

    private struct LocalizedStrings {
        static let title = NSLocalizedString("Ditto Presence",
                                             bundle: Bundle.presenceViewerResourceBundle,
                                             comment: "View controller title for the presence UI")
    }

    // MARK: - Properties

#if canImport(UIKit)
    /**
     A close button added to the navigation bar when we are modally presented
     in some manner that doesn't allow an iOS 13 modal sheet drag to dismiss
     action.
     */
    lazy var leftNavButton: UIBarButtonItem! = {
        return .init(title: "Close",
                     style: .done,
                     target: self,
                     action: #selector(self.close))
    }()

    /**
     A standalone navigation bar which will be used in the event that we're not
     being presented within a `UINavigationController`.
     */
    private lazy var navigationBar: UINavigationBar! = UINavigationBar()
#endif

    // MARK: - Initialization

    init(view: DittoPresenceView) {
        super.init(nibName: nil, bundle: nil)
        self.view = view
#if canImport(UIKit)
        self.modalPresentationStyle = .fullScreen
#endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = LocalizedStrings.title

#if canImport(UIKit)
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
#endif
    }

#if canImport(UIKit)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addStandaloneNavigationBarIfNeeded()
        addCloseButtonIfNeeded()
    }
#endif

#if canImport(AppKit)
    override func viewWillAppear() {
        super.viewWillAppear()

        addStandaloneNavigationBarIfNeeded()
        addCloseButtonIfNeeded()
    }
#endif

    // MARK: - Private Functions

    /**
     Adds a `UINavigationBar` to our view if we're not being presented inside a
     `UINavigationController`.

     - Postcondition: The view controller should not be instantiated and then displayed
     in various contexts, sometimes within a `UINavigationController` and sometimes outside
     of one. We expect to be displayed in the same context each time.
     */
    private func addStandaloneNavigationBarIfNeeded() {
#if canImport(UIKit)
        guard navigationController == nil else { return }

        navigationItem.title = LocalizedStrings.title
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor),
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)])
        navigationBar.items = [navigationItem]
        navigationBar.delegate = self
#endif
    }

    /**
     Adds a close button to our navigation bar if required.

     - Precondition: There should be no existing `leftBarButtonItem`. We don't want
                     to mess with the navigation item if a developer has already placed
                     a button there, or if a system-provided back button exists.
     */
    private func addCloseButtonIfNeeded() {
#if canImport(UIKit)
        if let navigationController = navigationController,
            navigationController.viewControllers.count > 1,
            !navigationController.navigationItem.hidesBackButton {
            return
        }

        guard navigationItem.leftBarButtonItem == nil else {
            return
        }

        navigationItem.leftBarButtonItem = leftNavButton
        navigationBar.setNeedsDisplay()
#endif
    }

    /**
     Ordinarily, `dismiss(animated:)` should be invoked by the parent `UIViewController`,
     but our parent doesn't know about the temporary back button we added if required.
     Regardless, this is safe to call on ourselves as UIKit will forward the invocation
     to our parent in this case.
     */
    @objc private func close() {
#if canImport(UIKit)
        dismiss(animated: true)
#endif
#if canImport(AppKit)
        dismiss(self)
#endif
    }

}

#if canImport(UIKit)
// MARK: - UINavigationBarDelegate

extension DittoPresenceViewController: UINavigationBarDelegate {

    /**
     In the event that we created our own `UINavigationBar`, we ensure
     that it is correctly docked underneath the system status bar and
     visually indistinguishable from a `UINavigationBar` provided by a
     `UINavigationController`.
     */
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

}
#endif
