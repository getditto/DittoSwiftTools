//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/26/24.
//

import SwiftUI
import DittoPermissionsHealth

struct PermissionsHealthViewer: View {
    var body: some View {
#if !os(macOS)

        PermissionsHealth()
        #endif
    }
}

#Preview {
    PermissionsHealthViewer()
}
