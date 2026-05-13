//
//  DiskUsageInspectorViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Combine
import Foundation
import SwiftUI
import DittoSwift

/// Subscribes to the SDK's public `diskUsagePublisher()` and republishes each
/// emission as a ``StorageBreakdown``. Registers no observers or subscriptions
/// on user collections and performs no recursive file-system inspection.
@MainActor
public final class DiskUsageInspectorViewModel: ObservableObject {

    @Published public private(set) var breakdown: StorageBreakdown = .empty
    @Published public private(set) var hasReceivedFirstSnapshot: Bool = false

    private let ditto: Ditto
    private let now: () -> Date
    private let animation: Animation?
    private var cancellable: AnyCancellable?

    public init(
        ditto: Ditto,
        now: @escaping () -> Date = Date.init,
        animation: Animation? = .easeOut(duration: 0.5)
    ) {
        self.ditto = ditto
        self.now = now
        self.animation = animation
        subscribe()
    }

    deinit {
        cancellable?.cancel()
    }

    private func subscribe() {
        cancellable = ditto.diskUsage
            .diskUsagePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.apply(item)
            }
    }

    private func apply(_ item: DiskUsageItem) {
        let next = StorageBreakdown(item: item, capturedAt: now())
        if let animation {
            withAnimation(animation) {
                breakdown = next
            }
        } else {
            breakdown = next
        }
        hasReceivedFirstSnapshot = true
    }
}
