//
//  CredentialsView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI

struct CredentialsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dittoService = DittoService.shared

    @StateObject private var viewModel = IdentityFormViewModel(
        credentialsService: CredentialsService.shared,
        dittoService: DittoService.shared
    )

    @State var isPresentingAlert = false
    @State var validationError: String?

    var body: some View {
        NavigationView {
            MultiPlatformLayoutView
                .navigationTitle("Credentials")
        }
        .onAppear { disableInteractiveDismissal() }
        .alert(isPresented: $isPresentingAlert) {
            Alert(
                title: Text("Cannot Apply Credentials"),
                message: Text(validationError ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    /// The main content of the view, a two column layout for tvos with an image and a form, otherwise just the form
    @ViewBuilder
    private var MultiPlatformLayoutView: some View {
        #if os(tvOS)
            HStack {
                imageView
                formView
            }
        #else
            formView
                .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private var imageView: some View {
        Image(systemName: "key.2.on.ring.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(180)
            .foregroundColor(Color(UIColor.tertiaryLabel))
    }

    /// form for the user to input parameters to create a configuration and apply it
    @ViewBuilder
    private var formView: some View {
        IdentityForm(viewModel: viewModel)
            .toolbar {
                ToolbarButtons
            }
    }

    private var ToolbarButtons: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Apply") {
                    applyCredentials()
                }
            }

            #if !os(tvOS)
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(CredentialsService.shared.activeCredentials == nil)
                }
            #endif
        }
    }

    private func applyCredentials() {
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

    /// Disables interactive dismissal for modally presented views.
    private func disableInteractiveDismissal() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = scene.windows.first?.rootViewController?.presentedViewController
        else { return }
        rootVC.isModalInPresentation = true
    }
}
