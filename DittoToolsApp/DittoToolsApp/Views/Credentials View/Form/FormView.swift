//
//  FormView.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI

/// A view that allows users to configure different identity types for Ditto.
///
/// `FormView` dynamically adjusts its input fields based on the selected identity type
/// and allows users to create and apply a `Credentials` configuration. It provides
/// buttons for applying, canceling, or clearing the credentials.
struct FormView<ApplyButton: View, CancelButton: View, ClearButton: View>: View {
    /// The view model containing the identity form state and logic.
    @ObservedObject var viewModel: FormViewModel

    /// The button for applying credentials.
    let applyButton: ApplyButton

    /// The button for discarding changes and dismissing the view.
    let cancelButton: CancelButton

    /// The button for deleting the existing credentials.
    let clearButton: ClearButton

    var body: some View {
        Group {
            #if os(tvOS)
                // Use a simplified layout on tvOS to fit platform conventions.
                Form {
                    identityTypePickerSection
                    identityDetailsSection
                    formButtonsSection
                }
            #else
                // Use a standard form layout with a toolbar for actions on other platforms.
                Form {
                    identityTypePickerSection
                    identityDetailsSection
                }
                .toolbar {
                    ToolbarItemGroup(placement: .confirmationAction) {
                        applyButton
                    }
                    ToolbarItemGroup(placement: .cancellationAction) {
                        cancelButton
                    }
                    ToolbarItem(placement: .bottomBar) {
                        clearButton
                    }
                }
            #endif
        }
    }

    // MARK: - Form Buttons Section

    /// A section displaying the buttons for applying, canceling, and clearing credentials.
    private var formButtonsSection: some View {
        Section {
            clearButton
            cancelButton
            applyButton
        }
    }

    // MARK: - Identity Type Picker Section

    /// A section displaying the identity type picker, allowing users to choose the type of credentials to configure.
    private var identityTypePickerSection: some View {
        Section(header: Text("Identity Type")) {
            Picker("Type", selection: $viewModel.formState.identityType) {
                ForEach(DittoIdentity.identityTypes, id: \.self) { type in
                    Text(type.rawValue)
                }
            }
        }
    }

    // MARK: - Identity Details Section

    /// A section displaying input fields specific to the selected identity type.
    ///
    /// The fields adjust dynamically based on the `identityType` selected in the picker.
    @ViewBuilder
    private var identityDetailsSection: some View {
        Section(
            header: Text("Identity Details"),
            footer: Text("Applying these credentials will restart the Ditto sync engine.")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding()
        ) {
            // Dynamically display fields based on the selected identity type.
            switch viewModel.formState.identityType {
            case .offlinePlayground:
                FormField(type: .text(.uuid), label: "App ID (UUID)", value: $viewModel.formState.appID)
                FormField(label: "Site ID", value: $viewModel.formState.siteID, placeholder: "Site ID (Number)")
                FormField(type: .text(.uuid), label: "Offline License Token (UUID)", value: $viewModel.formState.offlineLicenseToken)

            case .onlinePlayground:
                FormField(type: .text(.uuid), label: "App ID (UUID)", value: $viewModel.formState.appID, isRequired: true)
                FormField(
                    type: .text(.uuid), label: "Playground Token (UUID)", value: $viewModel.formState.playgroundToken, isRequired: true)
                FormField(type: .text(.url), label: "Custom Auth URL", value: $viewModel.formState.customAuthURLString)
                FormField(label: "Enable Cloud Sync", value: $viewModel.formState.enableDittoCloudSync)

            case .onlineWithAuthentication:
                FormField(type: .text(.uuid), label: "App ID (UUID)", value: $viewModel.formState.appID, isRequired: true)
                FormField(type: .text(.url), label: "Custom Auth URL", value: $viewModel.formState.customAuthURLString)
                FormField(
                    type: .text(.plain), label: "Auth Provider", value: $viewModel.formState.authProvider,
                    placeholder: "Authentication Provider")
                FormField(type: .text(.uuid), label: "Auth Token (UUID)", value: $viewModel.formState.authToken)
                FormField(label: "Enable Cloud Sync", value: $viewModel.formState.enableDittoCloudSync)

            case .sharedKey:
                FormField(type: .text(.uuid), label: "App ID (UUID)", value: $viewModel.formState.appID, isRequired: true)
                FormField(type: .text(.uuid), label: "Shared Key (UUID)", value: $viewModel.formState.sharedKey, isRequired: true)
                FormField(
                    type: .text(.uuid), label: "Offline License Token (UUID)", value: $viewModel.formState.offlineLicenseToken,
                    isRequired: true)

            case .manual:
                FormField(
                    type: .text(.base64), label: "Certificate Config",
                    value: $viewModel.formState.certificateConfig,
                    placeholder: "Base64-encoded Certificate",
                    isRequired: true)
            }
        }
    }
}
