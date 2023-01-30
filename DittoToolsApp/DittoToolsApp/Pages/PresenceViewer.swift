//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import UIKit
import DittoPresenceViewer

struct PresenceViewer: View {

    var body: some View {
        PresenceView(ditto: DittoManager.shared.ditto!)
    }
}

