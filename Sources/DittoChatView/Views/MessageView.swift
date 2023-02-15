//
//  MessageView.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import SwiftUI

@available(iOS 15.0, *)
struct MessageView: View {
    let message: Message
    let localPeerUserID: String
    let userName: String?

    var body: some View {
        VStack(spacing: 2) {

            if !isCurrentUser, let userName = userName {
                Text(userName)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            MessageBubbleView(message: message.text, isCurrentUser: isCurrentUser)
                .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)

            Text(message.dateString)
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray))
                .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        }
    }

    private var isCurrentUser: Bool {
        return message.isCurrentUser(id: localPeerUserID)
    }
}
