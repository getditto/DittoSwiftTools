//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import UIKit
import DittoPresenceViewer

#if !os(tvOS)
struct PresenceViewer: View {

    var body: some View {
        PresenceView(ditto: DittoManager.shared.ditto!)
    }
}
#endif

