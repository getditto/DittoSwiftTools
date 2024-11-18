//
//  DittoSyncStatusHelper.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 11/16/24.
//


import DittoSwift

public typealias DittoSyncSubscriptionStatusHandler = (_ result: DittoSyncSubscriptionStatus) -> Void

/// A status that describes whether a set of `DittoSyncSubscription`s is syncing or idle.
/// This can be combined with an online / offline check to provide an approximation of whether this subscription is up to date
public enum DittoSyncSubscriptionStatus {
    case idle
    case syncing
}

/**
 A helper which provide the sync status of a set of DittoSyncSubscriptions, either idle or syncing.
 This tells you if this peer is actively receiving data about this subscription from connected peers or idling
 It can be used to provide an approximation of whether this peer is up to date with other connected peers.
 It works by creating local store observers for each passed in subscription, then tracking when they fire and comparing against the `idleTimeoutInterval`
 */
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

    private var timer: Timer? = nil
    private var observers: [DittoStoreObserver] = []
    private var lastUpdated: Date = .distantPast

    /**
     Creates a new` DittoSyncStatusHelper` for a given set of `DittoSyncSubscription`s
     - Parameters:
        - ditto: A Ditto instance for which sync status is being checked. Used internally to create `DittoStoreObserver`s tracking each query..
        - idleTimeoutInterval: How long after the last update is received before this subscription is considered `idle`. Defaults to 5 seconds.
        - subscriptions: Which subscriptions to include for this status helper. The aggregate status for all of them will be tracked here, such that  it is only considered `idle` if all subscriptions are `idle`.
        - handler: A closure called each time the `status` changes.
     */
    init(ditto: Ditto,
         subscriptions: [DittoSyncSubscription],
         handler: @escaping DittoSyncSubscriptionStatusHandler) throws {
        self.subscriptions = subscriptions
        self.handler = handler
        self.status = .idle
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

    private func handleObserver(_ result: DittoSwift.DittoQueryResult) {
        status = .syncing
        lastUpdated = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: idleTimeoutInterval, repeats: false, block: { [weak self] _ in
            self?.status = .idle
        })
    }
}
