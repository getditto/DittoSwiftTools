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

    /// Bound data that holds the form's input values
    @Binding var formData:IdentityFormData
    
    /// Callback to be executed when the form is submitted
    var onSubmit: (IdentityConfiguration) -> Void

    /// Callback to be executed when the credentials are cleared
    var onClearCredentials: () -> Void

    var body: some View {
        Form {
            // Section for selecting the identity type
            Section(header: Text("Identity Type")) {
                Picker("Type", selection: $formData.identityType) {
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
                
                switch(formData.identityType) {
                case .offlinePlayground:
                    IdentityFormTextField(label: "App ID", placeholder: "App ID UUID", text: $formData.appID)
                    IdentityFormIntInputView(label: "Site ID", placeholder: "Site ID (Number)", int: $formData.siteID)
                    IdentityFormTextField(label: "Offline License Token", placeholder: "Token", text: $formData.offlineLicenseToken)
                    
                case .onlinePlayground:
                    IdentityFormTextField(label: "App ID", placeholder: "App ID", text: $formData.appID, isRequired: true)
                    IdentityFormTextField(label: "Playground Token", placeholder: "Playground UUID", text: $formData.playgroundToken, isRequired: true)
                    IdentityFormTextField(label: "Custom Auth URL", placeholder: "Auth Endpoint URL", text: $formData.customAuthURL)
                    Toggle("Enable Cloud Sync", isOn: $formData.enableDittoCloudSync)
                    
                case .onlineWithAuthentication:
                    IdentityFormTextField(label: "App ID", placeholder: "App ID", text: $formData.appID, isRequired: true)
                    IdentityFormTextField(label: "Custom Auth URL", placeholder: "Auth Endpoint URL", text: $formData.customAuthURL)
                    Toggle("Enable Cloud Sync", isOn: $formData.enableDittoCloudSync)
                    IdentityFormTextField(label: "Auth Provider", placeholder: "Authentication Provider", text: $formData.authProvider)
                    IdentityFormTextField(label: "Auth Token", placeholder: "Auth Token", text: $formData.authToken)

                case .sharedKey:
                    IdentityFormTextField(label: "App ID", placeholder: "App ID", text: $formData.appID, isRequired: true)
                    IdentityFormTextField(label: "Shared Key", placeholder: "Shared Key UUID", text: $formData.sharedKey, isRequired: true)
                    
                case .manual:
                    IdentityFormTextField(label: "Certificate Config", placeholder: "Base64-encoded Certificate", text: $formData.certificateConfig, isRequired: true)
                }
            }
            
#if os(tvOS)
            Button("Apply configuration") {
                let identityConfiguration = formData.toIdentityConfiguration()
                onSubmit(identityConfiguration)
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
