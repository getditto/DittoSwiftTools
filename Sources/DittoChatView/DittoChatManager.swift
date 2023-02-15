//
//  DittoChatManager.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import DittoSwift
import Combine
import SwiftUI

@available(iOS 15.0, *)
public final class DittoChatManager: ObservableObject {

    // MARK: - Properties

    // MARK: Public Access (get-only)

    @Published public var roomTitle: String

    @Published public internal(set) var hasUnreadMessage = false


    // MARK: Internal Access

    let dataManager: DataManager

    @Published private(set) var messages = [Message]()

    @Published private(set) var users = [User]()

    @Published private(set) var userName: String


    // MARK: Private Access

    private let chatView = ChatView()

    private var cancellables = Set<AnyCancellable>()

    private let userDefaults: UserDefaults

    private let notificationManager: NotificationManager


    // MARK: - Public Access

    // MARK:  Initializer

    public init(ditto: Ditto, chatGroupID: String, userDefaults: UserDefaults = .standard, userNotificationCenter: UNUserNotificationCenter = .current()) {

        self.userDefaults = userDefaults
        self.notificationManager = NotificationManager(notificationCenter: userNotificationCenter)

        if userDefaults.userID == nil {
            userDefaults.userID = UUID().uuidString
        }
        let userID = userDefaults.userID!

        self.roomTitle = "Chat" // default title

        let userName = userDefaults.userName ?? UIDevice.current.name
        self.userName = userName

        self.dataManager = DataManager(ditto: ditto, chatGroupID: chatGroupID, localPeerUserID: userID, userName: userName)

        dataManager.$messages
            .assign(to: \.messages, on: self)
            .store(in: &cancellables)

        dataManager.$users
            .assign(to: \.users, on: self)
            .store(in: &cancellables)

        dataManager.newMessageRecieved
            .sink { [weak self] in

                self?.notificationManager.showNotification(newMessage: $0)
                self?.hasUnreadMessage = true

            }.store(in: &cancellables)
    }

    // MARK: Methods / Computed Properties

    public func evictCurrentChatGroup() {
        dataManager.evictAll()
    }

    public var viewController: UIViewController {
        return UIHostingController(rootView: chatView.environmentObject(self))
    }

    public var view: some View {
        return chatView.environmentObject(self)
    }
}


// MARK: - Internal Access

@available(iOS 15.0, *)
extension DittoChatManager {

    func send(messege: String) {
        dataManager.insertNew(message: messege)
    }

    func change(userName: String) {
        dataManager.updateUser(name: userName)
        userDefaults.userName = userName
        self.userName = userName
    }
}
