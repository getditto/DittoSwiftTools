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

    @StateObject private var viewModel = IdentityFormViewModel(
        identityConfigurationService: IdentityConfigurationService.shared,
        dittoService: DittoService.shared
    )
    
    @State var isPresentingAlert = false
    @State var validationError: String?
    
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
                        viewModel: viewModel,
                        onApply: handleApplyResult,
                        onClearCredentials: clearCredentials
                    )
                }
                #else
                IdentityForm(
                    viewModel: viewModel,
                    onClearCredentials: clearCredentials
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
        .alert(isPresented: $isPresentingAlert) {
            Alert(
                title: Text("Cannot Apply Configuration"),
                message: Text(validationError ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
#warning("TODO: Add Stop and Start buttons")

    func clearCredentials() {
        dittoService.resetDitto(clearingActiveConfiguration: true)
        presentationMode.wrappedValue.dismiss()
        print("IdentityConfigurationView: Credentials cleared.")
    }

    
    #if os(tvOS)
    func handleApplyResult(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            presentationMode.wrappedValue.dismiss()
        case .failure(let error as DittoServiceError):
            validationError = error.localizedDescription
            isPresentingAlert = true
        case .failure(let error):
            validationError = "An unknown error occurred: \(error.localizedDescription)"
            isPresentingAlert = true
        }
    }
    #else
    
    private var ToolbarButtons: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Apply") {
                    applyConfiguration()
                }
            }
            ToolbarItemGroup(placement: .cancellationAction) {
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .disabled(IdentityConfigurationService.shared.activeConfiguration == nil)
            }
        }
    }
    
    private func applyConfiguration() {
        do {
            try viewModel.apply()
            presentationMode.wrappedValue.dismiss()
        } catch let error as DittoServiceError {
            validationError = error.localizedDescription
            isPresentingAlert = true
        } catch {
            validationError = "An unknown error occurred."
            isPresentingAlert = true
        }
    }
    #endif
}
