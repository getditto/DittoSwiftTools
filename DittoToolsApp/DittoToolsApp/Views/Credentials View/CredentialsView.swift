//
//  CredentialsView.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI

/// A SwiftUI view for managing and applying credentials.
///
/// `CredentialsView` provides a user interface for inputting, validating,
/// and applying credentials, with platform-specific adjustments for tvOS.
/// It interacts with `CredentialsService` and `DittoService` to handle
/// credentials securely and manage application state.
struct CredentialsView: View {
    @Environment(\.presentationMode) var presentationMode

    /// A shared instance of `DittoService`, responsible for managing Ditto operations.
    @ObservedObject var dittoService = DittoService.shared

    /// The view model for the credentials form, responsible for managing input and logic.
    @StateObject private var viewModel = FormViewModel(
        credentialsService: CredentialsService.shared,
        dittoService: DittoService.shared
    )

    /// Tracks whether the confirmation sheet for clearing credentials is showing.
    @State private var isShowingConfirmClearCredentials = false

    /// Tracks whether the validation error alert is showing.
    @State var isShowingValidationErrorAlert = false

    /// Holds the validation error message to display in the alert.
    @State var validationError: String?

    var body: some View {
        NavigationView {
            MultiPlatformLayoutView
                .navigationTitle("Credentials")
        }
        .onAppear { disableInteractiveDismissal() }
        .alert("Cannot Apply Credentials", isPresented: $isShowingValidationErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationError ?? "An unknown error occurred.")
        }
        .confirmationDialog("Are you sure?", isPresented: $isShowingConfirmClearCredentials, titleVisibility: .visible) {
            Button("Delete Credentials", role: .destructive) {
                viewModel.clearCredentials()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your saved credentials.")
        }
        #if os(tvOS)
            .onExitCommand {
                // Prevent navigation back if no credentials are available.
                let hasCredentials = CredentialsService.shared.activeCredentials != nil
                if hasCredentials {
                    // Allow exit command to navigate back
                    presentationMode.wrappedValue.dismiss()
                }
            }
        #endif
    }

    // MARK: - Main Layout

    /// The main content view layout for different platforms.
    /// - On tvOS: Displays a two-column layout with an image and a form.
    /// - On other platforms: Displays just the form with navigation bar settings.
    private var MultiPlatformLayoutView: some View {
        #if os(tvOS)
            HStack {
                imageView
                formView
            }
        #elseif os(macOS)
            formView
        #else
            formView
                .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    #if os(tvOS)
    /// A decorative image displayed on tvOS.
    private var imageView: some View {
        Image("key.2.on.ring.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(180)
            .foregroundColor(Color(UIColor.tertiaryLabel))
    }
    #endif

    /// The credentials form, consisting of fields and action buttons.
    private var formView: some View {
        FormView(
            viewModel: viewModel,
            applyButton: applyCredentialsButton,
            cancelButton: cancelButton,
            clearButton: clearCredentialsButton
        )
    }

    // MARK: - Apply Credentials Button

    /// The "Apply" button that submits the credentials form.
    private var applyCredentialsButton: some View {
        Button("Apply") {
            applyCredentials()
        }
    }

    // MARK: - Apply Credentials

    /// Applies the user-provided credentials by invoking the view model's `apply` method.
    ///
    /// If an error occurs during the process, it displays an alert with the error message.
    private func applyCredentials() {
        do {
            try viewModel.apply()
            presentationMode.wrappedValue.dismiss()
        } catch let error as DittoServiceError {
            // Show a detailed error message for Ditto-related issues
            validationError = error.localizedDescription
            isShowingValidationErrorAlert = true
        } catch {
            // Fallback for unknown errors
            validationError = "An unknown error occurred."
            isShowingValidationErrorAlert = true
        }
    }

    // MARK: - Cancel Button

    /// The "Cancel" button that dismisses the credentials form.
    /// It is disabled if no active credentials are available.
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
        .disabled(CredentialsService.shared.activeCredentials == nil)
    }

    // MARK: - Clear Credentials Button

    /// The "Clear Credentials" button that prompts the user to confirm their action.
    private var clearCredentialsButton: some View {
        Button("Clear Credentials…") {
            isShowingConfirmClearCredentials = true
        }
        #if os(macOS)
        .foregroundColor(viewModel.canClearCredentials() ? Color(NSColor.systemRed) : nil)
        #else
        .foregroundColor(viewModel.canClearCredentials() ? Color(UIColor.systemRed) : nil)
        #endif
        .disabled(!viewModel.canClearCredentials())
    }

    // MARK: - Clear Credentials ActionSheet

    /// Action sheet shown to confirm clearing credentials.
//    private var clearCredentialsActionSheet: ActionSheet {
//        ActionSheet(
//            title: Text("Are you sure?"),
//            message: Text("This will permanently delete your saved credentials."),
//            buttons: [
//                .cancel(),
//                .destructive(
//                    Text("Delete Credentials"),
//                    action: viewModel.clearCredentials
//                ),
//            ]
//        )
//    }

    // MARK: - Disable Interactive Dismissal

    /// Disables interactive dismissal for modally presented views to prevent accidental exits.
    ///
    /// This ensures users intentionally navigate away from the view, especially
    /// when working with important data like credentials.
    private func disableInteractiveDismissal() {
        #if os(macOS)
        if let window = NSApplication.shared.windows.first {
            window.isMovable = false
            window.styleMask.remove(.closable) // Disables the close button
        }
        #else
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController?.presentedViewController {
            rootVC.isModalInPresentation = true
        }
        #endif
    }
}
