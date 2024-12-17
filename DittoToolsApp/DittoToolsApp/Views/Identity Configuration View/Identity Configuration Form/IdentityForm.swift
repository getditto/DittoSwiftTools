// 
//  IdentityForm.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift

/// A view that allows users to configure different identity types for Ditto.
///
/// `IdentityForm` displays a dynamic form where fields adjust based on the selected identity type.
/// The form gathers input data for creating and applying a `DittoIdentityConfiguration`.
/// - For tvOS: Includes a button to apply the configuration within the form.
/// - For non-tvOS: Applies the configuration via the parent view's toolbar.
struct IdentityForm: View {
    
    /// The view model containing the identity form state and logic.
    @ObservedObject var viewModel: IdentityFormViewModel

    /// Tracks whether the confirmation alert for clearing credentials is shown.
    @State private var isShowingConfirmClearCredentialsAlert = false
    
    /// Callback executed when credentials are cleared.
    /// Invoked by both tvOS and non-tvOS implementations.
    var onClearCredentials: () -> Void

    var body: some View {
        Form {
            // Section for selecting the identity type.
            Section(header: Text("Identity Type")) {
                Picker("Type", selection: $viewModel.formInput.identityType) {
                    ForEach(DittoIdentity.identityTypes, id: \.self) { type in
                        Text(type.rawValue)
                    }
                }
            }

            // Section for inputting identity-specific details based on the selected type.
            Section(header: Text("Identity Details"),
                    footer: Text("Applying the configuration will restart the Ditto sync engine.")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding()
            ) {
                // Predefined placeholders
                let PLACEHOLDER_UUID = "123e4567-e89b-12d3-a456-426614174000"
                let PLACEHOLDER_URL = "https://example.com"
                
                // Dynamically display fields based on the selected identity type.
                switch(viewModel.formInput.identityType) {
                case .offlinePlayground:
                    IdentityFormTextField(label: "App ID (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.appID)
                    IdentityFormIntInputView(label: "Site ID", placeholder: "Site ID (Number)", int: $viewModel.formInput.siteID)
                    IdentityFormTextField(label: "Offline License Token (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.offlineLicenseToken)
                    
                case .onlinePlayground:
                    IdentityFormTextField(label: "App ID (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.appID, isRequired: true)
                    IdentityFormTextField(label: "Playground Token (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.playgroundToken, isRequired: true)
                    IdentityFormTextField(label: "Custom Auth URL", placeholder: PLACEHOLDER_URL, text: $viewModel.formInput.customAuthURLString)
                    Toggle("Enable Cloud Sync", isOn: $viewModel.formInput.enableDittoCloudSync)
                    
                case .onlineWithAuthentication:
                    IdentityFormTextField(label: "App ID (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.appID, isRequired: true)
                    IdentityFormTextField(label: "Custom Auth URL", placeholder: PLACEHOLDER_URL, text: $viewModel.formInput.customAuthURLString)
                    Toggle("Enable Cloud Sync", isOn: $viewModel.formInput.enableDittoCloudSync)
                    IdentityFormTextField(label: "Auth Provider", placeholder: "Authentication Provider", text: $viewModel.formInput.authProvider)
                    IdentityFormTextField(label: "Auth Token (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.authToken)
                    
                case .sharedKey:
                    IdentityFormTextField(label: "App ID (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.appID, isRequired: true)
                    IdentityFormTextField(label: "Shared Key (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.sharedKey, isRequired: true)
                    IdentityFormTextField(label: "Offline License Token (UUID)", placeholder: PLACEHOLDER_UUID, text: $viewModel.formInput.offlineLicenseToken, isRequired: true)
                    
                case .manual:
                    IdentityFormTextField(label: "Certificate Config", placeholder: "Base64-encoded Certificate", text: $viewModel.formInput.certificateConfig, isRequired: true)
                }
            }
            
            #if os(tvOS)
            // tvOS-specific buttons for clearing credentials.
            Button("Clear Credentials…", role: .destructive) {
                isShowingConfirmClearCredentialsAlert = true
            }
            #endif
        }
        // Alert for confirming clearing credential, as this is destructive.
        .alert(isPresented: $isShowingConfirmClearCredentialsAlert) {
            clearCredentialsAlert
        }
        #if !os(tvOS)
        // Toolbar for non-tvOS platforms with a "Clear Credentials" button.
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    isShowingConfirmClearCredentialsAlert = true
                }, label: {
                    Text("Clear Credentials…")
                        .font(.body)
                })
                .foregroundColor(.red)
            }
        }
        #endif
    }
    
    /// Alert for clearing credentials.
    private var clearCredentialsAlert: Alert {
        Alert(
            title: Text("Are you sure?"),
            message: Text("This will permanently clear your saved credentials."),
            primaryButton: .destructive(Text("Clear")) {
                onClearCredentials()
            },
            secondaryButton: .cancel()
        )
    }
}
