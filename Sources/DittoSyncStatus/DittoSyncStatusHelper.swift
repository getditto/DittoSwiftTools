//
//  DittoSyncStatusHelper.swift
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

public class DittoSyncStatusHelper {
    public var idleTimeoutInterval: TimeInterval = 5

    public var status: DittoSyncSubscriptionStatus {
        didSet {
            guard oldValue != status else { return }
            handler(status)
        }
    }

    private let subscriptions: [DittoSyncSubscription]
    private let handler: DittoSyncSubscriptionStatusHandler
    private let pollingInterval: TimeInterval

    private var timer: Timer? = nil
    private var observers: [DittoStoreObserver] = []
    private var lastUpdated: Date = .distantPast

    init(ditto: Ditto,
         subscriptions: [DittoSyncSubscription],
         pollingInterval: TimeInterval = 0.1,
         handler: @escaping DittoSyncSubscriptionStatusHandler) throws {
        self.subscriptions = subscriptions
        self.handler = handler
        self.status = .idle
        self.pollingInterval = pollingInterval
        self.timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true, block: { [weak self] _ in
            self?.updateStatus()
        })
        self.observers = try subscriptions.map { subscription in
            try ditto.store.registerObserver(query: subscription.queryString, handler: handleObserver)
        }
    }

    deinit {
        timer?.invalidate()
        observers.forEach { observer in
            observer.cancel()
        }
    }

    private func updateStatus() {
        if Date().timeIntervalSince(lastUpdated) > idleTimeoutInterval {
            status = .idle
        } else {
            status = .syncing
        }
    }

    private func handleObserver(_ result: DittoSwift.DittoQueryResult) {
        lastUpdated = Date()
    }
}
