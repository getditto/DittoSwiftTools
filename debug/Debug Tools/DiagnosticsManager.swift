//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation
import DittoSwift

/// A singleton which manages additional diagnostics logging (to the console only - not to
/// the Ditto persistent log file). Useful when debugging/testing only via Xcode.
class DiagnosticsManager {

    // MARK: - Public Properties

    /// Enable or disable diagnostics console logging.
    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                self.startDiagnostics()
            } else {
                self.stopDiagnostics()
            }
        }
    }

    // MARK: - Properties

    private var diagnosticsTimer: Timer?
    private var observer: DittoObserver?

    // MARK: - Singleton

    /// Singleton instance. All access is via `Diagnostics.shared`.
    static var shared = DiagnosticsManager()

    // MARK: - Private Functions

    private init() {}

    // MARK: - Private Functions

    func startDiagnostics() {
        diagnosticsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // This can take a while so take it off the main thread
            DispatchQueue.global().async {
                if let diag = try? DittoManager.shared.ditto!.transportDiagnostics() {
                    print("--- Diagnostics")
                    for transport in diag.transports {
                        var out = "Transport \(transport.connectionType) -"
                        if !transport.connecting.isEmpty {
                            out += " connecting:\(transport.connecting)"
                        }
                        if !transport.connected.isEmpty {
                            out += ", connected:\(transport.connected)"
                        }
                        if !transport.disconnecting.isEmpty {
                            out += ", disconnecting:\(transport.disconnecting)"
                        }
                        if !transport.disconnected.isEmpty {
                            out += ", disconnected:\(transport.disconnected)"
                        }
                        print(out)
                    }
                } else {
                    print("Error getting diagnostics")
                }
            }
        }

        self.observer = DittoManager.shared.ditto!.observePeers { peers in
            print("Presence Update:")
            dump(peers)
        }
    }

    private func stopDiagnostics() {
        self.diagnosticsTimer?.invalidate()
        self.observer?.stop()

        self.diagnosticsTimer = nil
        self.observer = nil
    }

}
