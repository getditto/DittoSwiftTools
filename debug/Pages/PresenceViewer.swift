//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//
import SwiftUI
import UIKit
import DittoSwiftPresenceViewer

struct PresenceViewer: View{

    var body: some View {
        PV()
    }
}

struct PV: UIViewRepresentable {
    typealias UIViewType = UIView
    func makeUIView(context: Self.Context) -> Self.UIViewType {
        return DittoPresenceView(ditto: DittoManager.shared.ditto!)
    }
    func updateUIView(_: Self.UIViewType, context: Self.Context) {
        return
        
    }
    
}
