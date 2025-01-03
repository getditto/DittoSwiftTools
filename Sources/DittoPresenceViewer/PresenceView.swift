//
//  PresenceView.swift
//
//
//  Created by Ben Chatelain on 9/23/22.
//

import DittoSwift

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(WebKit)
public struct PresenceView: View {
    private var ditto: Ditto

    public init(ditto: Ditto) {
        self.ditto = ditto
    }

    public var body: some View {
        DittoPresenceViewRepresentable(ditto: ditto)
    }
}

// MARK: - UIViewRepresentable
#if os(iOS)
private struct DittoPresenceViewRepresentable: UIViewRepresentable {
    let ditto: Ditto

    func makeUIView(context: Context) -> UIView {
        return DittoPresenceView(ditto: ditto)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

// MARK: - NSViewRepresentable
#elseif os(macOS)
private struct DittoPresenceViewRepresentable: NSViewRepresentable {
    let ditto: Ditto

    func makeNSView(context: Context) -> NSView {
        return DittoPresenceView(ditto: ditto)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
#endif
#endif
