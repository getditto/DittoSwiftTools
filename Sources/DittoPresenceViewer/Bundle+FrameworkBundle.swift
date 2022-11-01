//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation

extension Bundle {

    // https://blog.sabintsev.com/simultaneously-supporting-bundle-resources-in-swift-package-manager-and-cocoapods-3fa35f4bce4e
    static var presenceViewerResourceBundle: Bundle {
#if SWIFT_PACKAGE
        // Auto-generated for swift package
        // https://developer.apple.com/forums/thread/650158?answerId=614513022#614513022
        Bundle.module
#else
        Bundle(for: DittoPresenceView.self)
#endif
    }

}
