//
//  IdentityConfigurationView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift


struct IdentityConfigurationView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var dittoService = DittoService.shared

    @State private var formData:IdentityFormData
    
    @State var isPresentingAlert = false
    
    var errorMessage: String?

    init() {
        if let configuration = IdentityConfigurationService.shared.activeConfiguration {
            formData = IdentityFormData(with: configuration)
        } else {
            formData = IdentityFormData()
        }
    }

    
    var body: some View {
        NavigationView {
            Group {
#if os(tvOS)
                HStack {
                    Image(systemName: "gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(200)
                        .blendMode(.overlay)

                    IdentityForm(
                        formData: $formData,
                        onSubmit: { configuration in
                            apply(configuration)
                        },
                        onClearCredentials: {
                            clearCredentials()
                        }
                    )
                }
#else
                IdentityForm(
                    formData: $formData,
                    onSubmit: { configuration in
                        apply(configuration)
                    },
                    onClearCredentials: {
                        clearCredentials()
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarButtons }
#endif
            }
            .navigationTitle("Configuration")
        }
        .onAppear {
            // Disable interactive dismissal
            if let topController = UIApplication.shared.windows.first?.rootViewController?.presentedViewController {
                topController.isModalInPresentation = true
            }
        }
        
#warning("TODO: error messaging")
//        .onChange(of: self.errorMessage) { errorMessage in
//            if errorMessage != nil {
//                isPresentingAlert = true
//            }
//        }
//        .alert(isPresented: $isPresentingAlert) {
//            return Alert(
//                title: Text("An error occurred."),
//                message: Text(viewModel.errorMessage ?? "Unknown Error"),
//                dismissButton: .default(Text("OK")) {
//                    presentationMode.wrappedValue.dismiss()
//                }
//            )
//        }
    }
    
#warning("TODO: Add Stop and Start buttons")

    func apply(_ identityConfiguration: IdentityConfiguration) {
        do {
            IdentityConfigurationService.shared.activeConfiguration = identityConfiguration
            print("Identity configuration applied and saved to Keychain.")
            
            try dittoService.initializeDitto(with: identityConfiguration)
            
            presentationMode.wrappedValue.dismiss()
        } catch let error {
            print("Error when starting ditto \(error)")
        }
    }
    
    func clearCredentials() {
        dittoService.deinitDitto(clearKeychain: true)
        presentationMode.wrappedValue.dismiss()
        print("IdentityConfigurationView: Credentials cleared.")
    }

    private var ToolbarButtons: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Apply") {
                    let identityConfiguration = formData.toIdentityConfiguration()
                    #warning("TODO: Validate configuration")
                    apply(identityConfiguration)
                }
            }
            ToolbarItemGroup(placement: .cancellationAction) {
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}
