//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

#if !os(macOS)


import SwiftUI
import UIKit
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
#endif
