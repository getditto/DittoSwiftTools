//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoPresenceViewer
import DittoSwift

#if canImport(WebKit)
struct PresenceViewer: View {

    var ditto: Ditto
    
    var body: some View {
        PresenceView(ditto: ditto)
    }
}
#endif
