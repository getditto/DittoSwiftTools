//
//  MessageBubbleView.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import SwiftUI

@available(iOS 15.0, *)
struct MessageBubbleView: View {
    let message: String
    let isCurrentUser: Bool

    var body: some View {
        Text(message)
            .font(.system(size: 18))
            .padding(8)
            .background(isCurrentUser ? Color.blue : Color.gray)
            .foregroundColor(Color.white)
            .cornerRadius(11)
            .frame(maxWidth: (screenWidth * 0.7), alignment: isCurrentUser ? .trailing : .leading)
    }

    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
}
