//
//  DittoSyncSubscription+Status.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 11/16/24.
//


import DittoSwift

public typealias DittoSyncSubscriptionStatusHandler = (_ result: DittoSyncSubscriptionStatus) -> Void

public enum DittoSyncSubscriptionStatus {
    case idle
    case syncing
}

public class DittoSyncSubscriptionHelper {
    public let idleTimeoutInterval: TimeInterval = 5 // 5 seconds by default
    public var status: DittoSyncSubscriptionStatus {
        didSet {
            guard oldValue != status else { return }
            handler(status)
        }
    }

    private let subscriptions: [DittoSyncSubscription]
    private let handler: DittoSyncSubscriptionStatusHandler
    private var observers: [DittoStoreObserver] = []

    private var lastUpdated: Date = .distantPast

    init(ditto: Ditto, subscriptions: [DittoSyncSubscription], handler: @escaping DittoSyncSubscriptionStatusHandler) throws {
        self.subscriptions = subscriptions
        self.handler = handler
        self.status = .idle
        self.observers = try subscriptions.map { subscription in
            try ditto.store.registerObserver(query: subscription.queryString, handler: handleObserver)
        }
    }

    deinit {
        observers.forEach { observer in
            observer.cancel()
        }
    }

    private func handleObserver(_ result: DittoSwift.DittoQueryResult) {
        lastUpdated = Date()
        if Date().timeIntervalSince(lastUpdated) > idleTimeoutInterval {
            status = .idle
        } else {
            status = .syncing
        }
    }
}
