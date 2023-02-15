//
//  KeyboardResponder.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import SwiftUI
import Combine

@available(iOS 15.0, *)
final class KeyboardResponder: ObservableObject {
    private var notificationCenter: NotificationCenter
    @Published private(set) var currentHeight: CGFloat = 0

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        currentHeight = 0
    }
}
