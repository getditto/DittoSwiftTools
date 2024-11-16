//
//  DittoSyncSubscription+Status.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 11/16/24.
//


import DittoSwift

public enum DittoSyncSubscriptionStatus {
    case idle
    case syncing
}

public class DittoSyncSubscriptionHelper {
    public let idleTimeoutInterval: TimeInterval = 5 // 5 seconds by default

    private let subscriptions: [DittoSyncSubscription]
    private var observers: [DittoStoreObserver] = []

    private var lastUpdated: Date = .distantPast

    init(ditto: Ditto, subscriptions: [DittoSyncSubscription]) throws {
        self.subscriptions = subscriptions
        self.observers = try subscriptions.map { subscription in
            try ditto.store.registerObserver(query: subscription.queryString, handler: handleObserver)
        }
    }

    deinit {
        observers.forEach { observer in
            observer.cancel()
        }
    }

    public var status: DittoSyncSubscriptionStatus {
        if Date().timeIntervalSince(lastUpdated) > idleTimeoutInterval {
            return .idle
        } else {
            return .syncing
        }
    }

    private func handleObserver(_ result: DittoSwift.DittoQueryResult) {
        lastUpdated = Date()
    }
}
