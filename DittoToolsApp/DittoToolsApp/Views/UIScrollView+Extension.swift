//
//  UIScrollView+Extension.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

#if os(tvOS)

import UIKit

extension UIScrollView {

    /// Overrides the `clipsToBounds` property to always return `false`.
    ///
    /// This is a workaround to avoid SwiftUI content in a scroll view appearing clipped on tvOS.
    open override var clipsToBounds: Bool {
        get { false }
        set { /* Intentionally left blank */ }
    }
}
#endif
