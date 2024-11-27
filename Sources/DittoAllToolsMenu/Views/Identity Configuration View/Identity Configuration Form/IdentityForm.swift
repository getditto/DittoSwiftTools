// 
//  IdentityForm.swift
//
//  This file defines a view for configuring different types of identities used in the Ditto sync engine.
//  The form dynamically changes based on the selected identity type and provides options to input various details.
//  Once submitted, the configuration is applied, which may restart the sync engine.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift

/// A view that allows users to configure different identity types for Ditto.
///
/// `IdentityForm` presents a form with fields that adjust based on the selected identity type (e.g., offline, online with authentication, etc.).
/// The form gathers the necessary data and calls the provided `onSubmit` callback with the completed identity configuration.
struct IdentityForm: View {
    
    @State private var isShowingConfirmClearCredentialsAlert = false

    @ObservedObject var viewModel: IdentityFormViewModel
    
    /// Callback to be executed when the credentials are cleared
    var onClearCredentials: () -> Void

    var body: some View {
        Form {
            // Section for selecting the identity type
            Section(header: Text("Identity Type")) {
                Picker("Type", selection: $viewModel.formInput.identityType) {
                    ForEach(DittoIdentity.identityTypes, id: \.self) { type in
                        Text(type.rawValue)
                    }
                }
#if os(tvOS)
                .pickerStyle(.automatic) // #TODO: clean this up
#endif
            }
            
            // Section for inputting identity-specific details based on the selected type
            Section(header: Text("Identity Details"),
                    footer: Text("Applying the configuration will restart the Ditto sync engine.")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .padding()
                ) {
                
                let PLACEHOLDER_UUID = "123e4567-e89b-12d3-a456-426614174000"
                let PLACEHOLDER_URL = "https://example.com"
                
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
            Button("Apply configuration") {
                let identityConfiguration = formModel.toIdentityConfiguration()
                // onSubmit(identityConfiguration)
            }
                
            Button("Clear Credentials…", role: .destructive) {
                isShowingConfirmClearCredentialsAlert = true
            }
#endif
        }
#if !os(tvOS)
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
        .alert(isPresented: $isShowingConfirmClearCredentialsAlert) {
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
}
