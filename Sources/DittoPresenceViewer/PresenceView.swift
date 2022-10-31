//
//  File.swift
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

@available(iOS 13, macOS 10.15, *)
public struct PresenceView: View {
    public var ditto: Ditto

    public init(ditto: Ditto) {
        self.ditto = ditto
    }

    var body: some View {
        PresenceView(ditto: ditto)
    }
}

// MARK: - UIViewRepresentable
#if os(iOS)
@available(iOS 13, *)
extension PresenceView: UIViewRepresentable {
    public typealias Body = Never
    public typealias UIViewType = UIView

    public func makeUIView(context: Self.Context) -> Self.UIViewType {
        return DittoPresenceView(ditto: self.ditto)
    }

    public func updateUIView(_: Self.UIViewType, context: Self.Context) {
        return
    }
}
#endif

// MARK: - NSViewRepresentable
#if os(macOS)
@available(macOS 10.15, *)
extension PresenceView: NSViewRepresentable {
    public typealias Body = Never
    public typealias NSViewType = NSView

    public func makeNSView(context: Self.Context) -> Self.NSViewType {
        return DittoPresenceView(ditto: self.ditto)
    }

    public func updateNSView(_: Self.NSViewType, context: Self.Context) {
        return
    }
}
#endif
