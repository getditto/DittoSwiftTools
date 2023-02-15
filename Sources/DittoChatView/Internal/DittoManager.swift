//
//  DittoManager.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import DittoSwift
import Combine

@available(iOS 15.0, *)
final class DataManager: ObservableObject {

    // MARK: - Internal Access Properties

    @Published private(set) var messages = [Message]()

    @Published private(set) var users = [User]()

    @Published private(set) var chatGroupID: String

    let newMessageRecieved = PassthroughSubject<String, Never>()

    let localPeerUserID: String


    // MARK: - Private Access Properties

    private var userName: String

    private let ditto: Ditto

    private var subscriptions = [DittoSubscription]()
    private var liveQueries = [DittoLiveQuery]()


    // MARK: - Initializer

    init(ditto: Ditto, chatGroupID: String, localPeerUserID: String, userName: String) {
        self.ditto = ditto
        self.chatGroupID = chatGroupID
        self.localPeerUserID = localPeerUserID
        self.userName = userName

        upsertLocalPeerUser()

        observeCollections()
    }

    deinit {
        subscriptions.forEach {
            $0.cancel()
        }
        subscriptions = []
        liveQueries = []
    }


    // MARK: - Upsert data

    func insertNew(message: String) {
        do {
            let message = Message(userID: localPeerUserID, text: message, timestamp: Date())
            try messagesCollection.upsert(message.dict)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func upsertLocalPeerUser() {
        do {
            let user = User(id: localPeerUserID, name: userName)
            try usersCollection.upsert(user.dict)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    // MARK: - Update data

    func updateUser(name: String) {

        self.userName = name

        usersCollection.findByID(localPeerUserID).update { doc in
            doc?["name"].set(name)
        }
    }


    // MARK: - Evict data

    func evictAll() {
        messagesCollection.findAll().evict()
        usersCollection.findAll().evict()
    }

}
// MARK: - Private Methods / Computed Properties

@available(iOS 15.0, *)
extension DataManager {

    private var messagesCollection: DittoCollection {
        let collectionName = "ditto-chat-messages-\(chatGroupID)"
        return ditto.store.collection(collectionName)
    }

    private var usersCollection: DittoCollection {
        let collectionName = "ditto-chat-users-\(chatGroupID)"
        return ditto.store.collection(collectionName)
    }


    // MARK: - Observe changes

    private func observeCollections() {
        observeMessages()
        observeUsers()
    }

    private func observeMessages() {
        let query = messagesCollection.findAll()

        subscriptions.append(query.subscribe())

        liveQueries.append(
            query.observeLocal(deliverOn: DispatchQueue.global(qos: .default)) { [weak self] docs, event in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.messages = docs.map { Message(doc: $0) }

                    // Send notification signal
                    switch event {
                    case .update:
                        guard let latest = self.messages.last else { return }
                        guard !latest.isCurrentUser(id: self.localPeerUserID) else { return } // no notification for message made myself
                        self.newMessageRecieved.send(latest.text)
                    case .initial:
                        break // no notificateion
                    @unknown default:
                        break
                    }
                }
            }
        )
    }

    private func observeUsers() {
        let query = usersCollection.findAll()

        subscriptions.append(query.subscribe())

        liveQueries.append(
            query.observeLocal(deliverOn: DispatchQueue.global(qos: .default)) { [weak self] docs, event in
                DispatchQueue.main.async {
                    self?.users = docs.map { User(doc: $0) }
                }
            }
        )
    }
}
