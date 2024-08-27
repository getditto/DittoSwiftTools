//
//  AllToolsViewer.swift
//  DittoToolsApp
//
//  Created by Walker Erekson on 8/27/24.
//

import Foundation
import Combine
import DittoDataBrowser
import DittoSwift
import SwiftUI
import DittoAllToolsMenu

struct AllToolsViewer: View {
    var body: some View {
       AllToolsMenu(ditto: DittoManager.shared.ditto!)
    }
}
