//
//  DittoSyncStatusHelper.swift
//  DittoSwiftTools
//
//  Created by Brian Plattenburg on 11/16/24.
//

import Combine
import DittoSwift

public typealias DittoSyncSubscriptionStatusHandler = (_ result: DittoSyncSubscriptionsStatus) -> Void

/// A status that describes whether a set of `DittoSyncSubscription`s is syncing or idle.
/// This can be combined with an online / offline check to provide an approximation of whether this subscription is up to date
public enum DittoSyncSubscriptionsStatus: String {
    case idle
    case syncing
}

/**
 A helper which provide the sync status of a set of DittoSyncSubscriptions, either idle or syncing.
 This tells you if this peer is actively receiving data about this subscription from connected peers or idling
 It can be used to provide an approximation of whether this peer is up to date with other connected peers.
 It works by creating local store observers for each passed in subscription, then tracking when they fire and comparing against the `idleTimeoutInterval`
 */
public class DittoSubscriptionsStatusHelper {
    /// The interval after which a subscription is considered to be idle. Defaults to 1 second.
    public var idleTimeoutInterval: TimeInterval = 1

    /// The current status for the total set of subscriptions monitored by this helper. This is both `@Published`
    /// fired to `handler` via `didSet` when the value changes.
    @Published public private(set) var status: DittoSyncSubscriptionsStatus = .idle {
        didSet {
            guard oldValue != status else { return }
            handler?(status)
        }
    }

    private let subscriptions: Set<DittoSyncSubscription>
    private let handler: DittoSyncSubscriptionStatusHandler?

    private var timer: Timer? = nil
    private var observers: [DittoStoreObserver] = []
    private var lastUpdated: Date = .distantPast

    /**
     Creates a new `DittoSyncStatusHelper` for a given set of `DittoSyncSubscription`s
     - Parameters:
        - ditto: A Ditto instance for which sync status is being checked. Used internally to create `DittoStoreObserver`s tracking each query.
        - subscriptions: Which subscriptions to include for this status helper. The aggregate status for all of them will be tracked here, such that  it is only considered `idle` if all subscriptions are `idle`.
        - handler: An closure called each time the `status` changes. Defaults to `nil`
     */
    init(ditto: Ditto, subscriptions: Set<DittoSyncSubscription>, handler: DittoSyncSubscriptionStatusHandler? = nil) throws {
        self.subscriptions = subscriptions
        self.handler = handler
        handler?(.idle)
        self.observers = try subscriptions.map { subscription in
            try ditto.store.registerObserver(query: subscription.queryString, arguments: subscription.queryArguments, handler: handleObserver)
        }
    }

    /**
     Creates a new `DittoSyncStatusHelper` for all of the currently active subscriptions on this Ditto instance *at the time this is created*. It will not update if those subscriptions change
     - Parameters:
       - ditto: A Ditto instance for which sync status is being checked. Used internally to create `DittoStoreObserver`s tracking each query.
       - handler: A closure called each time the `status` changes.
     */
    convenience init(ditto: Ditto, handler: DittoSyncSubscriptionStatusHandler?) throws {
        try self.init(ditto: ditto, subscriptions: ditto.sync.subscriptions, handler: handler)
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
