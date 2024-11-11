//
//  UIScrollView+Extension.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

#if os(tvOS)
import UIKit

extension UIScrollView {
    open override var clipsToBounds: Bool {
        get { false }
        set { /* Intentionally left blank */ }
    }
}
#endif
