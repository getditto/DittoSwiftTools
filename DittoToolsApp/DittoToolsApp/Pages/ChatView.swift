//
//  ChatView.swift
//  
//
//  Created by Shunsuke Kondo on 2023/02/15.
//

import SwiftUI
import DittoSwift
import DittoChatView

struct ChatView: View {

    var body: some View {
        chatManager.view
    }

    private var chatManager: DittoChatManager {
        let chatManager = DittoChatManager(ditto: DittoManager.shared.ditto!, chatGroupID: "DittoToolsApp")
        chatManager.roomTitle = "Ditto Chat"
        return chatManager
    }
}
