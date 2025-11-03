//
//  ExportLogsToPortalView.swift
//  DittoSwiftTools
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift

/// SwiftUI view that presents a dialog for exporting device logs to the Ditto Portal
///
/// This view displays an alert dialog that allows users to request log export to the Portal
/// associated with their app ID. When confirmed, it updates a special Ditto collection that
/// signals the Ditto cloud service to collect logs from this device.
///
/// # Example Usage
/// ```swift
/// .sheet(isPresented: $showExportToPortal) {
///     ExportLogsToPortalView(ditto: ditto) {
///         showExportToPortal = false
///     }
/// }
/// ```
public struct ExportLogsToPortalView: View {
    private let ditto: Ditto
    private let onDismiss: () -> Void

    @StateObject private var viewModel = ExportLogsToPortalViewModel()
    @State private var showAlert = true

    /// Creates a new Export Logs to Portal view
    ///
    /// - Parameters:
    ///   - ditto: The active Ditto instance
    ///   - onDismiss: Callback invoked when the dialog is dismissed
    public init(ditto: Ditto, onDismiss: @escaping () -> Void) {
        self.ditto = ditto
        self.onDismiss = onDismiss
    }

    public var body: some View {
        // Using ZStack with alert modifier for better cross-platform compatibility
        Color.clear
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Export Logs to Portal"),
                    message: Text(alertMessage),
                    primaryButton: .default(Text(buttonTitle)) {
                        viewModel.uploadLogs(ditto: ditto)
                    },
                    secondaryButton: .cancel {
                        if viewModel.state != .exporting {
                            onDismiss()
                        }
                    }
                )
            }
            .onChange(of: viewModel.state) { newState in
                switch newState {
                case .success:
                    onDismiss()
                case .error:
                    // Re-show alert for retry
                    showAlert = true
                default:
                    break
                }
            }
    }

    private var buttonTitle: String {
        if case .error = viewModel.state {
            return "Retry"
        } else if viewModel.state == .exporting {
            return "Exporting..."
        }
        return "Export"
    }

    private var alertMessage: String {
        let appId = ditto.appID
        switch viewModel.state {
        case .idle:
            return "Logs will be exported to Portal for appID: \(appId)"
        case .exporting:
            return "Exporting logs for appID: \(appId)..."
        case .error(let message):
            return "Failed: \(message)"
        case .success:
            return "Export requested successfully"
        }
    }
}

/// View model managing the export logs to portal flow
@MainActor
class ExportLogsToPortalViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case exporting
        case success
        case error(String)
    }

    @Published var state: State = .idle

    func uploadLogs(ditto: Ditto) {
        // Reset from error state if retrying
        if case .error = state {
            state = .idle
        }

        guard state == .idle else { return }

        state = .exporting

        Task {
            do {
                try await DittoTools.uploadLogsToPortal(ditto: ditto)
                state = .success
            } catch {
                state = .error("Log export failed: \(error.localizedDescription)")
            }
        }
    }
}

#if DEBUG
struct ExportLogsToPortalView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Trigger Alert")
            .onAppear {
                // Preview would need a mock Ditto instance
            }
    }
}
#endif
